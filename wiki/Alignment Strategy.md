<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Alignment Strategy

Flexo-RTM's ontology is organized in layers (see [[Design Spec]] §6.1 and [[Layered Ontology]]). The **core** layer (`ontology/core/`) defines the domain-general TBox: vertices, edges, attestation, scope, transcript, deferred-judgment. The **alignment** layer (`ontology/alignment/`) is where flexo-rtm meets the rest of the world — OSLC-RM, OSLC-QM, SysMLv2, INCOSE, PROV, EARL, GSN, P-PLAN. The strategy for that meeting is the subject of this page.

## The rule

Alignment files contain **only** the following kinds of axioms:

- `owl:equivalentClass`
- `owl:equivalentProperty`
- `rdfs:subClassOf` (and `rdfs:subPropertyOf`)
- `skos:closeMatch`
- `skos:exactMatch`

Alignment files **never** declare novel classes or properties. They never introduce restrictions, never carry SHACL shapes, never assert domain or range. If a triple cannot be expressed as one of the five connectives above between an existing core IRI and an existing external IRI, it does not belong in `alignment/`.

This rule is not stylistic. It is the constitutional separation between the normative interior and the informative exterior of the ontology.

## Why this matters

**Core is normative; alignment is informative.** Core axioms are what flexo-rtm *means*. Alignment axioms are what flexo-rtm *says about its relationship to other vocabularies*. The two have radically different review processes, audiences, and stability guarantees. Core change requires an ADR, semver bump, and migration notes. Alignment change requires a citation to the external spec and, ideally, a roundtrip test.

**Inverting the layering makes the ontology unreviewable.** If core concepts were defined inside alignment files — e.g., declaring `rtm:Requirement` for the first time inside `alignment/oslc-rm.ttl` — then reviewing the core model would require reading every alignment file, and changing an external vocab would risk perturbing core semantics. The reviewer can no longer ask "what does flexo-rtm mean by Requirement?" and get an answer from a single file. The compositional discipline collapses.

**Strict separation enables independent evolution.** OSLC-RM 2.x may eventually become OSLC-RM 3.0. SysMLv2 is still in flux. INCOSE's handbook updates. Each of these can be tracked in a single alignment file with versioned snapshots in `ontology/imports/`, and core semantics remain unperturbed. Conversely, when flexo-rtm refactors its vertex algebra (say, splitting `rtm:Verification` from `rtm:Validation`), exactly one alignment edit per affected external vocab is needed — the impact surface is bounded.

This separation is also what makes the [[Parsimony Policy]] enforceable: parsimony-extracted external classes live in `ontology/parsimony/` and are referenced by IRI from alignment files. Alignment never *contains* an external term, only *links to* it.

## One alignment file per external vocab

The repository ships these alignment files, each scoped to a single external vocabulary:

| File | Purpose | Notes |
|---|---|---|
| `alignment/oslc-rm.ttl` | OSLC-RM 2.x mappings | `rtm:Requirement owl:equivalentClass oslc_rm:Requirement` and friends. Reviewed against [[OSLC RM and QM Review]]. |
| `alignment/oslc-qm.ttl` | OSLC-QM 2.x mappings | `rtm:TestCase`, `rtm:TestExecution`, `rtm:TestResult` correspondences. |
| `alignment/sysmlv2.ttl` | omg-sysml mappings | `RequirementUsage` is accepted as a `rtm:Requirement` via `rdfs:subClassOf` (see [[OMG SysMLv2]]). |
| `alignment/incose.ttl` | INCOSE handbook concept SKOS matches | Informative only; INCOSE definitions are prose, not a formal TBox, so `skos:closeMatch` dominates. |
| `alignment/prov.ttl` | W3C PROV-O integration | PROV is imported natively as a building block; this file mostly notes rtm-specific subclassing (e.g., `rtm:AttestationEvent rdfs:subClassOf prov:Activity`). |
| `alignment/earl.ttl` | W3C EARL evaluation results | Similar pattern: native import, alignment file declares rtm subclasses. |
| `alignment/gsn.ttl` | OntoGSN safety-case patterns | `rtm:AdequacyClaim`, `rtm:SufficiencyClaim` align to GSN solution/justification patterns. |
| `alignment/p-plan.ttl` | P-PLAN process plans | Used as a building block for transcript provenance. |

For PROV, EARL, GSN, and P-PLAN, "alignment" is something of a misnomer: these vocabs are imported natively and used as composable building blocks rather than as external dialects we translate to. The alignment file in those cases primarily records the `rdfs:subClassOf` chain from rtm-specific terms into the imported vocab. The rule still holds: no novel classes, no shapes.

## Bidirectional vs. unidirectional

The five permitted connectives are not interchangeable. Choose deliberately:

- **`owl:equivalentClass` / `owl:equivalentProperty`** — bidirectional, strong semantic commitment. Both vocabs assert the *same* class. Use only when the external definition is precise enough that any instance valid under one is valid under the other. Round-trip serialization must be lossless.
- **`skos:exactMatch`** — bidirectional, intended for concept-scheme equivalence rather than class equivalence. Stronger than `closeMatch`, weaker than `equivalentClass` (no DL entailment).
- **`skos:closeMatch`** — informative similarity. Use when the external concept is "approximately the same" but you are not willing to commit reasoners to treating instances interchangeably. INCOSE handbook concepts almost always sit here.
- **`rdfs:subClassOf`** — unidirectional. `rtm:RegulatoryRequirement rdfs:subClassOf oslc_rm:Requirement` says every flexo-rtm regulatory requirement *is also* an OSLC requirement, but the converse does not hold.
- **`rdfs:subPropertyOf`** — same shape, for properties.

A common error is reaching for `owl:equivalentClass` when `rdfs:subClassOf` is appropriate. If in doubt, use the weaker connective. Strength is easy to add in a later revision; removing strength is a breaking change.

## Use in the oracle

Alignment graphs are **loaded at materialization time**, not at write time. Storage canonicalizes to `rtm:` IRIs — those are the ground truth. Adapters translate at the I/O boundary:

- An OSLC-RM ingestion adapter reads an `oslc_rm:Requirement` from a wire payload and stores `rtm:Requirement` in the graph.
- A SPARQL query may reference either `rtm:Requirement` or `oslc_rm:Requirement`; with alignment loaded, both yield the same instances.
- An OSLC-RM export adapter projects `rtm:Requirement` back to `oslc_rm:Requirement` for outbound serialization.

This means queries written by external integrators using *their* IRIs continue to work without rewriting, and queries written against the canonical model do not bake in OSLC-specific assumptions. The alignment file is the bridge; neither side is contaminated.

Profile selection at oracle invocation (`--profile=oslc-rm-roundtrip`, etc.) determines which alignment graphs are loaded for a given run — alignment is opt-in, not ambient.

## Conflict between alignments

Two external vocabularies may both claim to define "the same" concept yet disagree on details. OSLC-RM and SysMLv2 both have something called a requirement, but their semantics differ: SysMLv2's `RequirementUsage` is a usage of a `RequirementDefinition`, distinct from the definition itself; OSLC-RM treats `Requirement` as a single resource. Asserting `owl:equivalentClass` to both would let a reasoner infer that an OSLC requirement *is* a SysMLv2 requirement-usage, which is not what either vocabulary means.

The resolution is to **weaken the connective**. When two alignments disagree, use `skos:closeMatch` rather than `owl:equivalentClass`. Document the conflict in a TTL comment block adjacent to the relevant triple, and link to the relevant external spec section. The alignment file is then honest about the imperfection rather than papering over it.

Where conflict resolution matters for behavior — e.g., an adapter must commit to one interpretation — the resolution lives in the adapter code, not in the ontology. Adapters are profile-scoped; the alignment file remains neutral.

## Cross-links

- [[Layered Ontology]] — the layer structure this strategy operates within
- [[Parsimony Policy]] — how external IRIs enter the build before alignment can reference them
- [[OSLC RM and QM Review]] — review notes for the two largest alignment targets
- [[OMG SysMLv2]] — SysMLv2 alignment considerations
- [[Design Spec]] §6.1 — the canonical statement of the layered ontology
