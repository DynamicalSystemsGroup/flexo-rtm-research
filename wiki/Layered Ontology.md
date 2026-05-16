<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Layered Ontology

The Flexo-RTM ontology is partitioned into six layers, each with a distinct role, dependency direction, and editorial discipline. The layering is not cosmetic: it is what makes the assembled `rtm.ttl` stay small (≤ 2000 triples), keeps domain semantics independent of external-vocab churn, and lets different institutional contexts apply different constraints without forking the core. See [[Design Spec]] §6.1 for the canonical table.

## The six layers

| Layer | Path | Role |
|---|---|---|
| Core | `ontology/core/` | Domain-general TBox — vertices, edges, faces, attestation, scope, transcript, deferred-judgment, aspect base classes |
| Alignment | `ontology/alignment/` | Interop bindings (`owl:equivalentClass`, `skos:closeMatch`) to OSLC-RM, OSLC-QM, SysMLv2, INCOSE, GSN, PROV, EARL, P-PLAN |
| Profiles | `ontology/profiles/` | Composable SHACL contracts selectable per oracle run |
| Shapes | `ontology/shapes/` | Always-active structural enforcement (cannot be disabled) |
| Imports | `ontology/imports/` | Vendored full external vocabs (read-only) for reproducibility |
| Parsimony | `ontology/parsimony/` | MIREOT / SLME extracts; `manifest.yaml` audit trail |

Layers depend strictly downward: Profiles and Shapes reference Core and Parsimony extracts; Alignment references Core and Imports; Imports and Parsimony are leaf layers. Core depends on nothing but standard W3C vocabularies (RDF, RDFS, OWL, SHACL, PROV, EARL).

## Core (`ontology/core/`)

Core is the normative TBox. Everything novel about Flexo-RTM lives here:

- **Vertex types** — `Requirement`, `Guidance`, `Artifact`. These are the three V-classes the certification predicate ranges over. See [[Vertices Edges Faces]].
- **Edge types** — `Verification` (R→A), `Coupling` (R↔G), `Validation` (G→A). Edges are first-class resources with their own IRIs, not reified predicates.
- **Face types** — `AssuranceFace` and its specializations. Faces close two-edge paths into 2-cells and are the structural foundation for adequacy/sufficiency reasoning.
- **Attestation** — the EARL-typed result attached to a `certifies` triple. Carries `approved_by`, `earl:result`, `prov:atTime`, optional `transcript_ref`, and (when policy demands) a signature envelope.
- **DeferredJudgment** — explicit "not-yet" record. Distinguished from absence; required when an aspect is in scope but evidence is pending.
- **Scope** — first-class resource with `includes_graphs`, `scope_filter`, `extends`, `intersects_with`. Scope algebra lives in `spec/scope-semantics.md`.
- **Transcript** and **TranscriptStep** — the deterministic replay record. Hash-chained per RDFC-1.0.
- **AuditReport** — top-level oracle output binding scope, profile, input hash, transcript, attestation graph, coverage, topology, gaps, and the boolean `certified`.
- **Aspect base classes** — extensible vocabulary roots so domain extensions (safety aspects, performance aspects, regulatory aspects) attach without changing Core.

Core is the only layer where novel classes and properties are minted. If a term does not exist in Core, it must not be invented in any other layer.

## Alignment (`ontology/alignment/`)

One file per external vocabulary. Alignment files contain **only** these predicates:

- `owl:equivalentClass`
- `owl:equivalentProperty`
- `rdfs:subClassOf`
- `skos:closeMatch`
- `skos:exactMatch`

No novel classes. No novel properties. No SHACL. Alignment is purely interop wiring — it lets a Flexo-RTM `Requirement` round-trip to an `oslc_rm:Requirement` or anchor to a `sysmlv2:RequirementDefinition` without redefining either side. Strict matches (`equivalentClass`, `exactMatch`) are reserved for vocabularies whose semantics genuinely coincide with Core; lossy bindings use `closeMatch` and are documented in the per-vocab ADR.

This discipline matters because external vocabularies evolve on their own cadence. By isolating bindings to small Alignment files, an OSLC-RM 3.0 update is a one-file change, not a Core revision. See [[Alignment Strategy]].

## Profiles (`ontology/profiles/`)

Profiles are **composable SHACL contracts** — sets of constraint shapes that the oracle activates only when invoked. The v0.1 profile catalog:

- `oslc-rm-roundtrip` — requirements survive RDF→OSLC-RM→RDF without semantic loss
- `oslc-qm-roundtrip` — verification activities round-trip to OSLC-QM
- `sysmlv2-anchored` — every requirement is anchored to a SysMLv2 element
- `incose-aligned` — INCOSE GfWR conformance for requirement quality
- `signed-commits` — Git commit signatures required on author paths
- `data-integrity-attestations` — attestations carry `dataIntegrityProof` envelopes
- `dsse-activities` — PROV activities carry DSSE signatures
- `cosign-images` — container artifacts must have cosign signatures
- `rekor-transparency` — signatures must be witnessed in a transparency log
- `attested-satisfies` — `satisfies` edges require attestations
- `attested-adequacy` — adequacy claims require GSN-pattern attestations
- `attested-sufficiency` — sufficiency claims require GSN-pattern attestations
- `aspect-coverage` — every requirement covers all in-scope aspects
- `strict-provenance` — full PROV chains required on every authored triple

Profiles are orthogonal to Scope. Scope selects **data**; Profile selects **constraints**. The oracle CLI accepts `--profile=A,B,C` and applies all named profiles in conjunction. Different institutional contexts (a defense program vs. a research lab vs. a regulated medical-device project) compose different profile sets without forking the ontology. See [[Profile Mechanism]].

## Shapes (`ontology/shapes/`)

Shapes are **always-active structural enforcement**. They are separated from Profiles for clarity: a Profile is opt-in, a Shape is non-negotiable.

The v0.1 Shapes layer carries:

- `attestation-shape` — every Attestation has `approved_by`, `earl:result`, `prov:atTime`, and certifies exactly one triple
- `identity-projection-shapes` — projected identities carry provider, projection-time, and the `dataIntegrityProof` from the identity adapter

Structural shapes from Design Spec §6.1 also live here as they mature: approver-required, face-closure, aspect-coverage gate, stale-attestation detection, and the V−F topological invariant. These cannot be disabled because they encode the structural promises of the certification predicate itself.

## Imports (`ontology/imports/`)

Vendored, read-only copies of full external vocabularies (OSLC-RM, OSLC-QM, SysMLv2 fragments, INCOSE, GSN/OntoGSN, PROV-O, EARL, P-PLAN). These are reference artifacts: they make builds reproducible across upstream changes and let auditors see exactly which version of OSLC-QM was used. Imports are **never** loaded into the assembled runtime ontology.

## Parsimony (`ontology/parsimony/`)

Parsimony holds the MIREOT/SLME extracts derived from Imports. Each external vocab has a `manifest.yaml` listing every kept class and property — the audit trail of "why is this term in our ontology?" Build-time extraction via SPARQL `CONSTRUCT` or `robot extract --method MIREOT` produces minimal subsets that carry only the terms Core actually references. See [[Parsimony Policy]].

## Build pipeline

`make ontology` assembles the runtime artifact:

1. Load Core
2. Load Parsimony extracts (each gated by its `manifest.yaml`)
3. Load Alignment files (which bind Core terms to extracted external terms)
4. Optionally run ROBOT for EL profile reasoning (precomputes `rdfs:subClassOf` closure)
5. Emit `rtm.ttl`

Profiles and Shapes are not loaded into `rtm.ttl` — they are SHACL graphs the oracle applies at validation time, selected by `--profile`. Imports are not loaded at all at runtime; they exist only as the source material for parsimony extraction.

The assembled `rtm.ttl` target is **≤ 2000 triples**. If a build exceeds this ceiling, the build fails and a parsimony review is required (per §9.A.5 X5 in [[Design Spec]]; conformance test `tests/conformance/test_ontology_parsimony.py`). Triple-count ceilings are not an aesthetic preference — they are the mechanism by which the runtime ontology stays auditable, comprehensible to reviewers, and free of accidental dependencies on external vocab churn.

## Why this layering matters

- **Core is normative; everything else is selectable.** A Flexo-RTM implementation must implement Core. Profiles are opt-in by institutional context. Alignment is opt-in by integration target. Imports are reference-only.
- **Alignment is interop-only.** Adding a `closeMatch` to a new external vocab does not change what Flexo-RTM means — it only declares that two vocabularies happen to talk about overlapping concepts.
- **Profiles let different institutions apply different constraints** without forking. A defense program enabling `signed-commits` + `rekor-transparency` + `attested-adequacy` runs the same Core as a research lab using only `incose-aligned`.
- **Parsimony bounds blast radius.** When OSLC-RM 3.1 releases, only the Imports vendor copy and the Parsimony extract change. Core, Alignment, Profiles, and Shapes are unaffected unless we deliberately choose to bind to new terms.
- **The ≤ 2000-triple ceiling is a Phase-5 acceptance gate** (§9.A.5 X5). It is the parsimony invariant that makes the entire layering meaningful — without it, layers would silently bloat and the audit trail in each `manifest.yaml` would lose its force.

## Cross-references

- [[Design Spec]] §6.1 — canonical layered ontology table
- [[Parsimony Policy]] — MIREOT/SLME extraction discipline and the ≤ 2000-triple ceiling
- [[Alignment Strategy]] — per-vocab binding rules and ADR practice
- [[Profile Mechanism]] — composable SHACL contracts and the `--profile` CLI surface
- [[Vertices Edges Faces]] — the Core domain primitives the layering protects
