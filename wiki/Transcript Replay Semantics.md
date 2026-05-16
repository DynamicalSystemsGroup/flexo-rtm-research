<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Transcript Replay Semantics

The **transcript** is the load-bearing primitive of the v0.1 certification artifact ([[Design Spec]] §4.8). It is the recorded execution log of every SPARQL query and SHACL shape evaluation that the oracle ran while producing a certification. Everything downstream — the [[Certification Predicate]], the [[Verifiable Self-Certification]] story, the federated reproducibility property — rests on the transcript being **deterministic** (replay yields byte-identical results) and **local** (any single fact's steps can be replayed without re-running the whole cert).

This page specifies (a) what a transcript is as an RDF structure, (b) the schema of a `TranscriptStep`, (c) the replay algorithm, (d) the determinism requirements that make replay sound, (e) the tampering-detection chain, (f) versioning, and (g) storage.

## 1. What a transcript is

A transcript is an **RDF graph** whose contents are `prov:Activity` records — one per atomic evaluation step performed during the cert run. Each step is one of:

- a **SPARQL query** executed against the input dataset,
- a **SHACL shape** evaluated against an input subset,
- a **canonicalization** operation (RDFC-1.0 applied to a graph or solution set), or
- a **knowledge-curation operation** (an `rtm:` library operation invoked by the oracle, e.g. profile assembly).

The transcript is **not** a free-form log: each step is a structured `prov:Activity` carrying the canonical query text or shape IRI it executed, the SHA-256 hash of its canonical inputs, the SHA-256 hash of its canonical results, and a `prov:wasInformedBy` pointer to the preceding step. The transcript is therefore a linearly chained PROV record whose hash sequence is itself a Merkle commitment to the entire cert computation.

Transcripts live in named graphs `<rtm:transcript/{run-id}>` and are immutable post-publish (see §7).

## 2. TranscriptStep schema

A `TranscriptStep` is the formal type carried by every entry in a transcript graph. The schema:

```turtle
<rtm:transcript/{run-id}/step/{n}>
    a prov:Activity, rtm:TranscriptStep ;
    rtm:stepKind          "sparql" ;   # or "shacl", "canonicalize", "kc-operation"
    rtm:queryText         "PREFIX ... SELECT ..." ;   # canonicalized; SPARQL/SHACL only
    rtm:shapeIRI          <https://example.org/shapes/Req> ;  # SHACL only
    rtm:inputsHash        "a3f1...c0"^^xsd:hexBinary ;  # SHA-256 over canonical inputs
    rtm:resultHash        "9b2e...4d"^^xsd:hexBinary ;  # SHA-256 over canonical results
    prov:wasInformedBy    <rtm:transcript/{run-id}/step/{n-1}> ;
    prov:startedAtTime    "2026-05-16T13:42:01Z"^^xsd:dateTime ;
    prov:endedAtTime      "2026-05-16T13:42:01.087Z"^^xsd:dateTime ;
    prov:wasAssociatedWith <rtm:oracle/v0.1> .
```

The five `rtm:` properties listed above are mandatory:

- **`rtm:stepKind`** — one of `sparql`, `shacl`, `canonicalize`, `kc-operation`. Determines which of the other properties are required.
- **`rtm:queryText`** — required for `sparql` and `shacl` steps. The canonicalized text (§4) of the query or shapes graph; carried inline so replay does not require external dereferencing (this is what makes X8 — structural completeness without dereferencing — possible).
- **`rtm:shapeIRI`** — required for `shacl` steps; identifies the validated shape so replayers can locate the shape's source profile.
- **`rtm:inputsHash`** — SHA-256 over the RDFC-1.0 canonical N-Quads of the input subset (or canonical bytes, for non-RDF inputs). This is what the replayer recomputes and compares.
- **`rtm:resultHash`** — SHA-256 over the canonicalized result. For SPARQL SELECT, this is the hash of the lexically-sorted solution-set serialization; for SPARQL CONSTRUCT/DESCRIBE and SHACL validation reports, it is the hash of the RDFC-1.0 canonical N-Quads of the result graph.
- **`prov:wasInformedBy`** — the preceding step; the very first step has no `prov:wasInformedBy` (or points to a designated genesis activity carrying the input-hash of the entire cert run).

`rtm:TranscriptStep` is a subclass of `prov:Activity`; no novel epistemic vocabulary is introduced.

## 3. Replay algorithm

The replay routine takes a **transcript IRI** and a **canonical input dataset** and either certifies replay PASS or pinpoints the divergence step.

```
replay(transcript_iri, input_dataset, versions):
    steps   := load_transcript(transcript_iri) sorted by prov:wasInformedBy chain
    state   := input_dataset                            # current evaluation context
    prev_h  := genesis_inputs_hash(input_dataset)

    for step in steps:
        # 1. Inputs-hash check: this step's inputs must hash to prev_h
        assert step.inputsHash == prev_h, divergence(step, "inputs")

        # 2. Execute the recorded operation
        match step.stepKind:
            "sparql":         result := rdflib.query(state, step.queryText)
            "shacl":          result := pyshacl.validate(state, shape=resolve(step.shapeIRI))
            "canonicalize":   result := rdfc10(state)
            "kc-operation":   result := apply_kc_op(state, step.queryText)

        # 3. Canonicalize, hash, compare
        canonical_result := canonicalize(result)
        computed_h       := sha256(canonical_result)
        assert computed_h == step.resultHash, divergence(step, "result")

        # 4. Chain advance
        state  := apply(state, result)
        prev_h := step.resultHash

    return PASS
```

Pass means every recorded hash matched. Fail means some step's `rtm:inputsHash` or `rtm:resultHash` diverged — and because steps are linearly chained, the **first** divergence pinpoints the tampered or non-deterministic step (see §5).

Replay is **local** in the sense that the loop can be run over any contiguous subchain — see X6 below.

## 4. Determinism requirements

For replay to be sound, every recorded operation must be a pure function of its inputs (up to canonicalization). The v0.1 stack relies on:

- **SPARQL execution (rdflib).** rdflib's SPARQL evaluator is deterministic for a fixed input graph and query text, *but solution-set ordering for SELECT without `ORDER BY` is not guaranteed*. The replay layer therefore canonicalizes solution sets — sort solutions lexically by a stable serialization of bindings — before hashing.
- **SHACL evaluation (pyshacl).** pyshacl is deterministic for a fixed data graph and shapes graph. Validation-report graphs are RDFC-1.0 canonicalized before hashing (validation reports include `sh:resultMessage` strings whose insertion order would otherwise leak into the bytes).
- **Canonicalization.** [[RDFC-1.0 Canonicalization]] is the sole canonicalization algorithm for RDF graphs in the transcript. The same algorithm canonicalizes both inputs (before hashing for `rtm:inputsHash`) and graph-shaped results.
- **Non-RDF artifacts.** Non-RDF inputs (file blobs referenced by external URIs per [[External URI References]]) are hashed as raw bytes; canonicalization is a no-op.

**Canonical query text** for `rtm:queryText` means:

- Whitespace normalized (collapse runs of whitespace; LF line endings).
- Prefix bindings sorted by prefix label.
- Literal forms normalized (canonical lexical forms for `xsd:integer`, `xsd:decimal`, `xsd:boolean`; quoted-string escapes normalized).
- Comments stripped.

The point of canonical query text is that two semantically-identical SPARQL strings hash to the same bytes, so cosmetic re-formatting of an oracle's query template does not break replay across versions of the oracle.

## 5. Tampering detection (Merkle chain)

Because each step's `rtm:inputsHash` is *the prior step's `rtm:resultHash`*, the transcript is a hash chain. Any modification to step *k* — its query text, its inputs, its result, or its hashes — propagates: either step *k*'s recorded `rtm:resultHash` no longer matches the re-computed hash, or step *k+1*'s `rtm:inputsHash` no longer matches step *k*'s `rtm:resultHash`. The first mismatch in replay-order is the divergence point.

A transcript-level commitment — the SHA-256 of the *terminal* step's `rtm:resultHash` concatenated with `inputs_hash` of the genesis step — serves as a Merkle-style root that a signed cert envelope can sign over (see §4.6 of [[Design Spec]] and [[Verifiable Self-Certification]]).

## 6. Versioning

Replay only certifies "same canonical input → same recorded result" *for the same toolchain*. A transcript therefore pins:

- **Oracle version** (`rtm:oracleVersion`),
- **Ontology version** (the assembled `rtm.ttl` content-hash),
- **Profile version** (the active [[Profile Mechanism]] profile IRIs and their content-hashes),
- **rdflib version** (the SPARQL engine),
- **pyshacl version** (the SHACL engine),
- **RDFC-1.0 implementation version**.

These pins live in a `rtm:ToolchainVersionRecord` referenced by the transcript's genesis step via `prov:wasAssociatedWith`. A replayer running a different toolchain MAY still attempt replay; mismatches in `rdflib`/`pyshacl` patch versions usually replay clean, but mismatches MUST be reported alongside the PASS/FAIL verdict.

## 7. Storage

Transcripts are stored in named graphs of the form `<rtm:transcript/{run-id}>` per [[Storage Layer Flexo Conventions]]. They are **immutable post-publish**: once an audit report (§4.8.3) references a transcript IRI, the contents of that named graph MUST NOT change. Re-running the oracle produces a *new* transcript with a new run-id.

Garbage collection is optional and policy-driven: implementations MAY prune transcripts older than a retention threshold provided no live cert references them. Pruning a referenced transcript invalidates the cert.

## 8. Phase discipline — mapping to §9.A.5 acceptance criteria

The transcript schema and replay algorithm above are precisely what the v0.1 cross-cutting acceptance criteria in [[Design Spec]] §9.A.5 demand:

- **X1 (Determinism).** Same canonical input → byte-identical transcript across runs. The §4 requirements (RDFC-1.0 canonicalization, sorted SPARQL solution sets, deterministic pyshacl) are exactly the conditions for X1. The acceptance test `tests/determinism/test_byte_identical_transcripts.py` exercises this.
- **X2 (Replay).** Anyone with the canonical input-hash and the transcript can re-execute every step and produce byte-identical result hashes. §3's algorithm *is* the replay procedure; `tests/conformance/test_transcript_replay.py` is its acceptance test.
- **X6 (Local fact reproducibility).** A fact's transcript steps form a contiguous subchain — the steps `prov:wasInformedBy`-reachable from the fact-producing step. A verifier with read access to the fact's local RDF neighborhood plus dereference access to the relevant external URIs can run §3's loop over that subchain alone. No global permissions required.
- **X7 (Federated reproducibility composes).** Because each fact's subchain is independently replayable (X6), multiple parties with non-overlapping permission subsets can each verify their slice; the union of their PASS verdicts equals a global PASS over the union of their permissions. The chain is hash-linked, so subchain results compose without any party owning the whole.
- **X8 (Structural completeness without dereferencing).** Because `rtm:queryText` and `rtm:shapeIRI` are carried *inline* in each step, a verifier without fetch access to external URIs can still confirm structural completeness — every referenced URI is well-formed, every recorded step parses, every chain link resolves — by reading the transcript RDF alone. Dereferencing is required for re-execution; it is **not** required for structural validation.

Cross-link: [[Design Spec]] §4.8 (three-layer artifact) and §9.A.5 (the X-criteria normative gate).

## Related pages

- [[Design Spec]] — §4.8 places the transcript inside the three-layer cert artifact; §9.A.5 gives the normative acceptance gate.
- [[Verifiable Self-Certification]] — the transcript is the substrate the self-certification claim signs over.
- [[RDFC-1.0 Canonicalization]] — the sole canonicalization algorithm referenced above.
- [[Certification Predicate]] — the predicate evaluated by replaying a transcript.
- [[Storage Layer Flexo Conventions]] — named-graph layout for `<rtm:transcript/{run-id}>`.
- [[External URI References]] — how non-RDF transcript inputs are referenced and hashed.
