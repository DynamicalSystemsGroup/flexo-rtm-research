<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# RDFC-1.0 Canonicalization

> Underwrites [[Design Spec]] §4.8 (three-layer certification artifact: the transcript references hashes taken over canonical inputs) and the cross-cutting acceptance criteria X1 (Determinism) and X2 (Replay) in §9.A.5. Companion to [[Verifiable Self-Certification]], [[Transcript Replay Semantics]], and [[Lossless Roundtrip Definition]].

**RDFC-1.0** is the W3C Recommendation *RDF Dataset Canonicalization 1.0* — a settled standard that defines, for any RDF dataset, a single canonical serialization to which all byte-equivalent graphs reduce. It fixes three things that vary in ordinary RDF: blank node labels, statement ordering, and serialized form. Once those are pinned, two parties holding "the same graph" — regardless of which Turtle, JSON-LD, or N-Quads file they loaded — compute the same bytes, and therefore the same hash.

`flexo-rtm` uses RDFC-1.0 as the **identity function** for its cert inputs. Every claim that the oracle makes about "what was certified" is anchored to a SHA-256 over the RDFC-1.0 canonical form of the scope-resolved graph. Without canonicalization, the oracle's hashes would describe one party's *serialization choice*, not the underlying RDF.

## What RDFC-1.0 specifies

The recommendation defines an algorithm (often abbreviated URDNA2015, later URDNA2017, and standardized as RDFC-1.0) that takes an RDF dataset as input and produces:

1. **Canonical blank node identifiers.** Blank nodes have no globally stable name. RDFC-1.0 relabels them deterministically, using a hash-based fixed-point computation over the local structure each blank node participates in. Isomorphic graphs end up with identical labels regardless of input labeling.
2. **Canonical statement ordering.** N-Quads lines are sorted lexicographically after canonical labeling, producing a unique byte sequence.
3. **Canonical serialization.** Output is N-Quads with one statement per line, canonical lexical forms for literals, and explicit datatype/language tags as required by the N-Quads specification.

The output is a deterministic byte stream. Hashing that stream (SHA-256, per §4.9 of the [[Design Spec]]) gives the **input-hash** that the transcript records.

## Why we use it

- **Hash-based equivalence.** The transcript records input-hash + result-hash per SPARQL/SHACL step. Two graphs with the same input-hash are guaranteed RDF-equivalent (modulo blank node renaming) — independent of who serialized them, in what order, with which prefixes.
- **Reproducibility across implementations.** Conformant RDFC-1.0 implementations produce identical output. A verifier may use a different RDF stack than the certifier and still confirm byte-identical hashes.
- **Settled spec.** RDFC-1.0 is a published W3C Recommendation, not a moving target. We pin the recommendation, not a vendor's API. The previous URDNA2015 drafts converged into this normative form, so legacy interop is well-understood.
- **No proprietary surface.** Pure-Python implementations satisfy acceptance criterion X4 (no proprietary deps) in [[Design Spec]] §9.A.5.

## What canonicalization does, concretely

Take a fragment with blank nodes:

```
_:a rtm:satisfies :Req1 .
_:a rtm:approvedBy <urn:approver:alice> .
_:b rtm:satisfies :Req2 .
```

Re-serialize with different blank node labels (`_:x`, `_:y`) and different statement order — RDFC-1.0 produces the same canonical N-Quads, because each blank node's canonical label is derived from its connection pattern (which predicates and objects it touches), not from the label the author happened to type.

For literals, RDFC-1.0 requires canonical lexical forms per XSD: `"01"^^xsd:integer` and `"1"^^xsd:integer` denote the same value, but only the canonical lexical form (`"1"`) appears in canonical output. Authors should produce canonical lexical forms upstream; otherwise canonicalization will surface the difference as a hash divergence.

## How `flexo-rtm` uses RDFC-1.0

Three usage sites in the codebase, each enforcing a different acceptance criterion from §9.A.5:

- **At cert time** — the scope-resolved graph (Scope IRI → union of named graphs → SPARQL/SHACL inputs) is canonicalized; the SHA-256 of the canonical form becomes the **input-hash** recorded in the transcript. This pins exactly which graph the oracle saw. Enforces X1: same canonical input → byte-identical transcript across runs, machines, and times.
- **At verify time** — the verifier canonicalizes their copy of the input, compares to the transcript's input-hash. Equal hashes ⇒ same input ⇒ replaying the recorded SPARQL/SHACL steps must produce byte-identical result hashes. Unequal hashes ⇒ the verifier and certifier are not looking at the same RDF, and the divergence is named explicitly. Enforces X2: canonical input-hash + transcript replays identically.
- **At roundtrip** — when a [[Lossless Roundtrip Definition]] check runs, the parsed input is canonicalized and the re-serialized output is canonicalized; the two canonical forms are compared byte-for-byte. Any drift (lost triples, datatype coercion, namespace mangling) shows up as a hash divergence.

## Implementation

`rdflib` exposes RDFC-1.0 via its `Graph.serialize(format='application/n-quads')` path combined with the canonicalization helper, currently labeled experimental in `rdflib.compare` / `rdflib.graph` (specifically `to_canonical_graph`). The mature alternative is `pyld`, which ships a normalization API rooted in URDNA2015 and aligned with RDFC-1.0. A custom implementation against the W3C test suite is also viable for environments needing tighter control.

The decision is to **pin one implementation** in `pyproject.toml` and gate it behind a stable interface (`flexo_rtm.canon.canonicalize(dataset) -> bytes`). The choice is recorded in the transcript's reproducibility manifest, so verifiers know which implementation produced the recorded hashes. Switching implementations is a major version bump on the cert artifact format.

## Edge cases

- **Blank node cycles.** RDFC-1.0's hash-based labeling iterates to a fixed point even when blank nodes participate in cycles. No special handling required from `flexo-rtm`; we rely on the implementation being conformant.
- **Large-graph performance.** Canonicalization scales worse than linearly with blank node count (it is essentially graph isomorphism over the blank node subgraph). For very large datasets, canonicalization is the dominant cert-time cost. Mitigation: cache canonical forms keyed by upstream content hash, so unchanged graphs skip re-canonicalization.
- **Datatype literal canonical forms.** RDFC-1.0 does not normalize literal *values* — it only sorts and labels. Authors are responsible for canonical XSD lexical forms upstream (`"true"` not `"1"` for `xsd:boolean`, normalized form for `xsd:decimal`, etc.). The roundtrip check catches non-canonical lexical forms as divergences and surfaces them as fixable warnings rather than silent re-writes.
- **Language tags vs. datatypes.** N-Quads serialization is precise about which appears; we follow the spec and reject malformed inputs at the parser, before canonicalization.

## Test fixtures

`flexo-rtm`'s canonicalization tests use the **official W3C RDFC-1.0 test suite** as the conformance baseline — vendored at a pinned commit and re-run against every release. Beyond the W3C suite, project-local fixtures cover the edge cases above (cyclic blank nodes drawn from real cert artifacts, large-graph performance benchmarks against representative scope-resolved graphs, and round-trip fixtures for each datatype `flexo-rtm` emits).

## Cross-references

- [[Verifiable Self-Certification]] — RDFC-1.0 is the "canonical inputs" component of verifiability
- [[Transcript Replay Semantics]] — replay compares hashes taken over RDFC-1.0 canonical forms
- [[Lossless Roundtrip Definition]] — roundtrip is defined as canonical-form equality
- [[Design Spec]] §4.8 (three-layer artifact), §4.9 (RDF-internal reproducibility), §9.A.5 X1 / X2
