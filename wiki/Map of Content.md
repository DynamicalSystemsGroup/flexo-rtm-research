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
- [[Dragon Architecture and Mission Enterprise]] — the openMBEE-community vision for a Mission Enterprise for Digital Thread approaches; the upstream methodology-neutral framing `flexo-rtm`'s certification-evidence layer is designed to serve.

## 3. v0.1 Certification Model (what ships now)

- [[Traditional Forward and Backward Analysis]] — primary user surface; Doors/Jama-familiar coverage analysis.
- [[Attestation Infrastructure in v0.1]] — three attestation subclasses (Approval, VerificationVerdict, Justification) with named-approver SHACL.
- [[Identity Boundaries and Policy Projections]] — thin RDF projections of external identities; RBAC, ABAC, scope-bounded authorization.
- [[External URI References]] — `git+commit`, content-addressed identifiers, and OCI; the open-source-first foundation.
- [[Signed Envelopes and Established Standards]] — W3C VC-DI, DSSE, Sigstore, cosign, and signed git commits as the crypto substrate.
- [[Aspect Coverage with Adequacy and Sufficiency]] — per-aspect, per-claim-type coverage matrix that drives the v0.1 outcome.
- [[Federated Audit and Composition]] — scope-level adequacy and sufficiency layered on self-certification; new attestation subjects for reproducibility audits, qualified-role audits, and composition certification.
- [[Certification Predicate]] — v0.1 basic predicate (thresholded coverage); brief note on the predicate an adopter running topological downstream analysis would compose on top.
- [[Gap Taxonomy]] — T1–T8 ship in v0.1; G3–G9 are topology-line gap classes (only meaningful if an adopter runs the optional topological audit as a downstream-analysis mode).
- [[Quantitative Outcomes]] — v0.1 metrics, configurable thresholds, and how the binary view is derived.

## 4. Roadmap and related research lines

Two distinct categories of pages live here. **`flexo-rtm`'s own roadmap items** include the methodology-neutral engineering lifecycle vocabulary — **optional organizational-convenience metadata** with INCOSE / ISO 15288 as one example among many (DO-178C, NASA, Agile, ISO 9001, MIL-STD-498, custom phasing). The framework ships the vocabulary substrate but no privileged state machine; regression handling moves to the attestation level via [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] (v0.2 ships the deprecation cascade detection). The **topological framework** is **not on `flexo-rtm`'s roadmap** — per [[ADR-032 Methodology Agnosticism as Foundational Axiom]], it is a separate, related research line with philosophical kinship to `flexo-rtm`'s named-approver discipline. If that research line matures, the resulting audit operates as one optional downstream-analysis mode on top of `flexo-rtm`'s data, among several plausible ones (SLSA, GSN, ARP4754A, in-house). `flexo-rtm`'s release schedule does not depend on it.

- [[Engineering Lifecycle Stages]] — optional `rtm:lifecycleStage` scope metadata; methodology-neutral with INCOSE / ISO 15288 as one example; no scope-level state machine in core. (`flexo-rtm` roadmap item.)
- [[Topological Framework Future Work]] — the canonical reference for the related topological research line (Zargham 2026): recursion structure, registry concept, open questions, candidate invariants. Not `flexo-rtm`'s planned destination; one downstream-analysis path among several. (Research line, not `flexo-rtm` roadmap.)
- [[Vertices Edges Faces]] — type catalog documenting the topological research line's vocabulary; aligned with v0.1 ontology per [[ADR-020 Vocabulary Alignment with Zargham 2026]] as forward-compatible interop, not as `flexo-rtm`'s data model destination.

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

The Decision Log holds 33 ADRs (ADR-001 through ADR-032, plus ADR-003a) plus an [[ADR Template]]. Each ADR documents one of the locked decisions from [[Design Spec]] §14 in the standard context/decision/consequences format. The full list is in the sidebar under **Decision Log**. ADR-028 (scope-level adequacy and sufficiency for federated audit) closes research issue #3; ADR-029 (engineering lifecycle stages as scope metadata; revised to optional + methodology-neutral) closes research issue #6; ADR-030 ([[ADR-030 Polycentric ASOT Authority Model]]) locks the polycentric ASOT institutional-topology commitment; [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] introduces the four-state attestation status vocabulary; [[ADR-032 Methodology Agnosticism as Foundational Axiom]] names methodology agnosticism as a foundational design axiom and clarifies that the topological framework is a related research line with philosophical kinship, not `flexo-rtm`'s planned destination.

## 10. Meta

- [[INCOSE IS 2026 Paper]] — pointer/stub for Zargham 2026; motivates the accountability framing used throughout.

## Reading paths

- **"I want to understand the thesis."** [[Mission and Thesis]] → [[Verifiable Self-Certification]] → [[Traditional Forward and Backward Analysis]] → [[Topological Framework Future Work]].
- **"I want to evaluate the design decisions."** [[Design Spec]] (especially §9.A and §14), then scan ADR-001 through ADR-025 in sequence from the sidebar.
- **"I want to understand a specific boundary."** Pick from the v0.1 Certification Model section above; each page cross-links to the relevant `[[Design Spec]]` §9.A acceptance criteria.
