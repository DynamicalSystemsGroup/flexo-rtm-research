<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Map of Content

Comprehensive index of the `flexo-rtm-research` wiki. Every page is listed once with a one-line annotation. The sidebar is for navigation; this page is for orientation. Sections mirror the sidebar's grouping.

## 0. Foundation

- [[Home]] — landing page; what this wiki is, audience, status, navigation.
- [[Mission and Thesis]] — the eight propositions; what `flexo-rtm` is and isn't.
- [[Verifiable Self-Certification]] — the core concept; structural completeness and locality.
- [[Design Spec]] — canonical normative source; every other page explains a passage from here.

## 1. Internal Research (synthesis of prior work)

- [[Flexo Git Coexistence]] — `flexo-conflict-resolution-policy-research` findings applied to RTM storage.
- [[ADCS Prototype Lessons]] — what `ADCS-lifecycle-demo` proves; what carries forward vs. what we abstract.
- [[MVC Pattern from RIME TRL ANT]] — the operator-facing pattern lifted from existing examples as UX baseline.
- [[Human-AI Accountability]] — Zargham 2026 framing applied to RTM; traceability as accountability surface.
- [[Multi-Agent Discourse Graph Precedent]] — `multi-agent-dg` as working prior art for the federated / scoped-to-named-graph approach; named graphs per owner, declared sharing policies compiled to SPARQL, post-export boundary invariants.

## 2. External Research (literature)

- [[OSLC RM and QM Review]] — OSLC RM/QM vocabulary review; the data model `flexo-rtm` adopts and the deployment-model assumptions it adjusts; lineage from IBM/Doors origins.
- [[INCOSE V2 Review]] — alignment with INCOSE's V2 concept hierarchy.
- [[OMG SysMLv2]] — canonical model vocabulary anchoring requirement and verification concepts.
- [[PROV EARL GSN P-PLAN]] — the four adopted W3C/community vocabularies and the parsimony budget over them.

## 3. v0.1 Certification Model (what ships now)

- [[Traditional Forward and Backward Analysis]] — primary user surface; Doors/Jama-familiar coverage analysis.
- [[Attestation Infrastructure in v0.1]] — three attestation subclasses (Approval, VerificationVerdict, Justification) with named-approver SHACL.
- [[Identity Boundaries and Policy Projections]] — thin RDF projections of external identities; RBAC, ABAC, scope-bounded authorization.
- [[External URI References]] — `git+commit`, content-addressed identifiers, and OCI; the open-source-first foundation.
- [[Signed Envelopes and Established Standards]] — W3C VC-DI, DSSE, Sigstore, cosign, and signed git commits as the crypto substrate.
- [[Aspect Coverage with Adequacy and Sufficiency]] — per-aspect, per-claim-type coverage matrix that drives the v0.1 outcome.
- [[Federated Audit and Composition]] — scope-level adequacy and sufficiency layered on self-certification; new attestation subjects for reproducibility audits, qualified-role audits, and composition certification.
- [[Certification Predicate]] — v0.1 basic predicate (thresholded coverage); brief note on the future-framework predicate.
- [[Gap Taxonomy]] — T1–T8 ship in v0.1; G3–G9 documented as future-framework gap classes.
- [[Quantitative Outcomes]] — v0.1 metrics, configurable thresholds, and how the binary view is derived.

## 4. Roadmap and future work

Two distinct timelines apply here. **Engineering lifecycle stages** are a v0.2 roadmap item — vocabulary is settled and ships in v0.1 for forward-compat; the full state-machine mechanism (gate relaxation, lifecycle-aware regression) lands in v0.2. The **topological framework**, by contrast, remains in research phase — its timeline depends on community-curated registry governance and open invariant research.

- [[Engineering Lifecycle Stages]] — `rtm:lifecycleStage` and INCOSE-aligned stage IRIs; vocabulary v0.1, full mechanism v0.2.
- [[Topological Framework Future Work]] — deferred (research-phase) vision, recursion structure, registry concept, open questions.
- [[Vertices Edges Faces]] — future-framework type catalog (V, E, F) that generalizes traditional traceability.

## 5. Three-Layer Architecture

- [[Three-Layer Architecture]] — operational / storage / analysis layers and the contracts between them.
- [[Operational Layer UX Discipline]] — why authoring latency is a first-class constraint.
- [[Storage Layer Flexo Conventions]] — named-graph layout and transactional semantics.
- [[Analysis Layer Scope Algebra]] — `rtm:Scope` as a first-class RDF resource; algebra of scope composition.

## 6. Ontology Design

- [[Layered Ontology]] — Core / Alignment / Profiles / Shapes / Imports / Parsimony layering.
- [[Parsimony Policy]] — MIREOT/SLME extraction; ~2k-triple target for the assembled `rtm.ttl`.
- [[Alignment Strategy]] — `owl:equivalentClass` and `skos:closeMatch` only; no novel terms in alignment.
- [[Profile Mechanism]] — composable SHACL contracts, orthogonal to scope.
- [[GSN Integration]] — Solution + Justification pattern for adequacy and sufficiency claims.

## 7. Adapter Contracts

- [[Lossless Roundtrip Definition]] — Layer A (RDFC-1.0 canonical equivalence) + Layer C (vendor carry-through).
- [[Vendor Extension Carry-Through]] — source-preserving per-resource named graphs that survive a round trip.
- [[OSLC RM Adapter Contract]] — full RM mapping table, SHACL profile, fixtures.
- [[OSLC QM Adapter Contract]] — QM test-artifact mapping, verdict vocabulary, the QM-RM bridge.

## 8. Reproducibility

- [[RDFC-1.0 Canonicalization]] — W3C dataset canonicalization; the equivalence backbone for `flexo-rtm`.
- [[Transcript Replay Semantics]] — `TranscriptStep` schema, replay algorithm, tampering detection.
- [[Approver Binding via Git]] — pre-commit hook + GitHub Actions verifying committer matches `rtm:approvedBy`.

## 9. Decision Log

The Decision Log holds 31 ADRs (ADR-001 through ADR-030, plus ADR-003a) plus an [[ADR Template]]. Each ADR documents one of the locked decisions from [[Design Spec]] §14 in the standard context/decision/consequences format. The full list is in the sidebar under **Decision Log**. ADR-028 (scope-level adequacy and sufficiency for federated audit) closes research issue #3; ADR-029 (engineering lifecycle stages as scope metadata) closes research issue #6; ADR-030 ([[ADR-030 Polycentric ASOT Authority Model]]) locks the polycentric ASOT institutional-topology commitment that underwrites the scope algebra.

## 10. Meta

- [[INCOSE IS 2026 Paper]] — pointer/stub for Zargham 2026; motivates the accountability framing used throughout.

## Reading paths

- **"I want to understand the thesis."** [[Mission and Thesis]] → [[Verifiable Self-Certification]] → [[Traditional Forward and Backward Analysis]] → [[Topological Framework Future Work]].
- **"I want to evaluate the design decisions."** [[Design Spec]] (especially §9.A and §14), then scan ADR-001 through ADR-025 in sequence from the sidebar.
- **"I want to understand a specific boundary."** Pick from the v0.1 Certification Model section above; each page cross-links to the relevant `[[Design Spec]]` §9.A acceptance criteria.
