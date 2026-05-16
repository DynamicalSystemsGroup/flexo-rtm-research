<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-028: Scope-Level Adequacy and Sufficiency for Federated Audit

**Status:** Accepted
**Date:** 2026-05-17
**Deciders:** Michael Zargham
**Related:** [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]]; [[ADR-021 Three Attestation Subclasses Ship in v0.1]]; [[ADR-024 Identity by Thin Projection of External Sources]]; [[ADR-025 Reproducibility is Structural and Local]]; [[ADR-027 Bit-Exactness vs Numerical Tolerances Are Both First-Class]]; [[Federated Audit and Composition]]; [[Identity Boundaries and Policy Projections]]; [[Design Spec]]

## Context

Self-certification at the component or subsystem level is the v0.1 floor — every claim has a named approver, every fact replays bit-exact (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]), every fact is structurally complete locally ([[ADR-025 Reproducibility is Structural and Local]]). In real institutional contexts, however, large systems are not certified by one team alone. They are **composed** from many self-certified scopes, each of which is then audited by additional parties — peer reproducibility auditors, qualified third-party hosts, sister-organization verifiers, regulatory reviewers, accredited test labs. The user's framing in research issue #3 names this directly: federated auditing reproduces self-certified models and adds additional signatures reinforcing the self-certifications with auditors' attestations. At the scale of a system-of-systems, the natural form for the certifier is to look at **each scope (named graph) as a patch in a larger topology**, where it is infeasible to reproduce all the evidence. The certifier then enforces rules over how many additional certifications are present per scope, whether the scopes adequately cover the composed model, and whether the number or specific roles of the orgs signing each scope meet criteria for global model certification.

The user explicitly identifies this framing as matching v0.1's existing **adequacy and sufficiency** criteria, lifted to a larger scale: **adequacy** is composed scope coverage of system-of-interest; **sufficiency** is the number and nature of the orgs providing scope-level certifications. The lowest bar is all scopes are self-certified; in practice one or more qualified reproducibility audits per scope is the expectation. The question is whether v0.1 ships this composition-scale primitive as first-class machinery or defers it. The cross-cutting acceptance criteria X6 (local fact reproducibility) and X7 (federated reproducibility composes) in [[Design Spec]] §9.A.5 already presuppose the model — federated audit is the natural operationalization. See [[Design Spec]] §4.9 and [[Federated Audit and Composition]] for the full context.

## Decision

`flexo-rtm` v0.1 ships **scope-level adequacy and sufficiency for federated audit** as a new analytical primitive layered on the existing scope, attestation, and identity-projection infrastructure. The decision has four parts:

1. **Three new `rtm:Attestation` subclasses** for the scope and composition dimension, all inheriting the named-approver SHACL discipline of [[ADR-021 Three Attestation Subclasses Ship in v0.1]]:
   - `rtm:ScopeCertificationAttestation` — a named approver (typically representing a qualified org) attests that a scope's certification at a recorded commit was reviewed (or reproduced) and is considered valid for the auditor's purposes
   - `rtm:CompositionCoverageAttestation` — a named approver attests that a set of constituent scopes adequately covers a stated system-of-interest (the **adequacy** criterion at composition scale)
   - `rtm:CompositionSufficiencyAttestation` — a named approver attests that the number and roles of the signing orgs across the composition meet stated criteria (the **sufficiency** criterion at composition scale)

2. **Three new composable SHACL profiles**, off by default per [[ADR-016 Composable SHACL Profiles]]: `composition-adequacy`, `composition-sufficiency`, `qualified-audit-per-scope`.

3. **Org-level identity projection** extends [[ADR-024 Identity by Thin Projection of External Sources]] — `foaf:Organization` / `org:Organization` projections become first-class subjects via `rtm:approverOrganization` and `rtm:hasQualifiedRole`, projected through the same thin-adapter pattern as person-level identities.

4. **Four-level certification ladder** documented in [[Federated Audit and Composition]]: self-certification (the floor) → reproducibility audit (partial or full) → qualified-role audit → composition certification. Each level is enumerable in the audit report so consumers see exactly which slice of the cert artifact relies on which level.

What's **deferred**: the **community-curated registry of qualified-auditor orgs and roles**. Adopters define qualified-role sets in their own identity projection in v0.1; a community-federated registry is similar in spirit to the topological framework's pre-approved-types registry and is future work.

## Consequences

### Positive

- **Composition is queryable.** The composed system-of-interest is a named graph; its constituent scopes are named graphs; the attestations layered on each are RDF instances. SPARQL queries answer "is this composed model adequately covered?" and "is the signing pattern sufficient?" against the same data substrate v0.1 already requires
- **Sufficiency thresholds are enforceable.** A program can declare "every safety-critical scope MUST carry ≥ 2 reproducibility attestations from orgs in the qualified-auditor set" as a SHACL profile; SHACL evaluates it mechanically against the projection at cert time
- **Qualified-role attestations are first-class.** A regulator's review is a structurally-typed attestation with a named approver, an `rtm:approverOrganization`, and an `rtm:auditMode` — not a sidecar PDF whose authority is asserted out-of-band
- **X6/X7 operationalized.** The cross-cutting acceptance criteria already commit to local fact reproducibility and federated composition; federated audit makes the federation-level attestations first-class so audit reports can enumerate them
- **Self-certified-only slices are honest.** Where reproduction is infeasible, the audit report flags those facts as Level 1; consumers see exactly which slice of the cert relies on which assurance level. The cert artifact never pretends to global reproduction it has not earned
- **Forward-compatible to the topological framework.** When the recursive completeness check lands, federated-audit attestations slot in naturally as named-approver attestations on validation edges or assurance-face closure at composed-model scale; no rework

### Negative / Tradeoffs

- **More vocabulary to learn.** Adopters now distinguish per-claim attestations (satisfaction / adequacy / sufficiency) from scope-and-composition attestations (scope-certification / composition-coverage / composition-sufficiency). Mitigated by the uniform parent class and the parallel adequacy/sufficiency framing (the same shape of judgment at two scales)
- **Profile composition is more complex.** Six profiles (the three v0.1-existing `attested-*` plus three new `composition-*` / `qualified-*`) compose; programs need to think about which combinations apply. Mitigated by the composability principle being unchanged — profiles remain orthogonal and individually opt-in
- **Org-level identity projection adds adapter surface.** The thin-adapter pattern now projects `org:Organization` as well as `foaf:Person`; reference adapters extend to handle org claims. Mitigated by the SHACL bottleneck remaining single and by org claims composing into the same projection schema as person claims
- **Audit-report views are richer.** The report now enumerates per-scope certification level, qualified-role coverage per aspect, signer counts, and self-certified-only flagging. Mitigated by these being additive views — adopters not running federated profiles see only the per-claim views v0.1 already shipped

### Neutral

- **Orgs become first-class identity subjects.** The thin-projection discipline of [[ADR-024 Identity by Thin Projection of External Sources]] already accommodates `org:Organization`; this ADR makes the org-level subject explicit as the bearer of qualified roles. The identity boundary is unchanged — `flexo-rtm` does not own org records any more than it owns person records
- **No new SHACL bottleneck.** The existing parent-class SHACL shape (`sh:targetClass rtm:Attestation`) propagates to the three new subclasses automatically. The named-approver discipline of [[ADR-021 Three Attestation Subclasses Ship in v0.1]] is unchanged

## Alternatives Considered

- **Treat composition as out of scope for v0.1; defer with the topological framework.** Wait for the framework to land, and require federated audit only when the recursive completeness check is available. **Rejected.** Federated audit is the natural operationalization of the X6/X7 commitments [[Design Spec]] §9.A.5 already makes. The mechanism — new attestation subjects with named approvers, new SHACL profiles, SPARQL queries against the projection — uses only v0.1-existing primitives. It does not require the registry-of-pre-approved-types commitment or the recursive completeness check that block the framework. Decoupling composition from the framework lets v0.1 ship the analytical primitive that real institutional audits need, without waiting on framework-scoped research.
- **Require full reproducibility on every fact (no signing-pattern criteria).** Mandate that every constituent scope's every transcript step be re-executed by every party in a federated audit. **Rejected.** At system-of-systems scale this is **infeasible** — the user's framing in issue #3 is explicit: reproducing all the evidence cannot be assumed; the audit must instead enforce rules over the signing pattern (minimum signers, qualified-role presence, coverage). The chosen framing matches that operational reality.
- **Define a parallel attestation class hierarchy for orgs.** Build `rtm:OrgAttestation` parallel to `rtm:Attestation`, with its own SHACL discipline. **Rejected.** Attestations are named-human (or named-AI per [[Human-AI Accountability]]) judgments; the org is a property of the approver, not a parallel attestation kind. `rtm:approverOrganization` on the existing attestation class composes correctly with the existing named-approver bottleneck.
- **Bake qualified-role definitions into the v0.1 ontology.** Ship a canonical list of qualified roles (`rtm:role/notified-body`, `rtm:role/accredited-reproducibility-auditor`, etc.) in the v0.1 ontology. **Rejected.** Which roles are "qualified" is domain- and adopter-specific; baking definitions into the ontology would either over-constrain (rejecting valid adopter-specific roles) or under-constrain (admitting roles no auditor in the relevant jurisdiction would recognize). v0.1 ships the **vocabulary** (`rtm:hasQualifiedRole`) and lets adopters declare the role set; a community-curated registry is appropriate future work.

## Implementation Notes

- v0.1 ontology defines the three new subclasses in `ontology/core.ttl`: `rtm:ScopeCertificationAttestation`, `rtm:CompositionCoverageAttestation`, `rtm:CompositionSufficiencyAttestation`, all `rdfs:subClassOf rtm:Attestation`.
- Supporting predicates in v0.1 vocabulary: `rtm:approverOrganization`, `rtm:auditMode`, `rtm:atCommit`, `rtm:appliesToSystemOfInterest`, `rtm:hasQualifiedRole`, `rtm:minimumSigners`, `rtm:requiredAuditMode`.
- Audit-mode SKOS concepts in `ontology/concepts/audit-modes.ttl`: `audit-mode/review-only`, `audit-mode/reproducibility-partial`, `audit-mode/reproducibility-full`, `audit-mode/qualified-role-review`.
- SHACL profiles in `ontology/profiles/`: `composition-adequacy.ttl`, `composition-sufficiency.ttl`, `qualified-audit-per-scope.ttl` (composable per [[ADR-016 Composable SHACL Profiles]]).
- Oracle support: SPARQL evaluation of composition adequacy (every requirement in the composed model is reachable from at least one constituent scope's evidence) and composition sufficiency (signer-count thresholds per aspect, qualified-role coverage per aspect) via `oracle/analysis/composition.py`.
- Audit-report extension: new view enumerating per-scope certification level, per-aspect qualified-role coverage, signer counts per aspect, and self-certified-only flagging for facts without independent reproduction.
- Org-level identity projection: extends the projection schema in [[Identity Boundaries and Policy Projections]] with `foaf:Organization` / `org:Organization` subjects bearing `rtm:hasQualifiedRole`. Reference adapters extend to project org claims from the same providers (GitHub orgs, OIDC org claims, LDAP organizational units).
- What is **not** in v0.1: community-curated registry of qualified-auditor orgs, closed-triangle aggregation across federated audits, cross-adopter trust transitivity. Adopters define their own qualified-role sets in v0.1.

## References

- [[Design Spec]] §4.9 (Reproducibility chain), §9.A.5 X6/X7 (cross-cutting acceptance criteria the federated-audit primitive operationalizes)
- [[Federated Audit and Composition]] — canonical documentation of the new primitive
- [[Identity Boundaries and Policy Projections]] — org-level identity-projection extension
- [[Aspect Coverage with Adequacy and Sufficiency]] — evidence-level adequacy/sufficiency vocabulary that lifts to composition scale
- [[Attestation Infrastructure in v0.1]] — parent class and SHACL bottleneck the new subclasses inherit
- [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]] — the framing that lifts cleanly to composition scale
- [[ADR-021 Three Attestation Subclasses Ship in v0.1]] — the parallel evidence-dimension trio this complements
- [[ADR-024 Identity by Thin Projection of External Sources]] — the identity infrastructure org-level subjects ride on
- [[ADR-025 Reproducibility is Structural and Local]] — the locality property federated audit exercises
- [[ADR-027 Bit-Exactness vs Numerical Tolerances Are Both First-Class]] — the parallel "both regimes first-class" framing at the reproducibility level
- W3C Organization Ontology: https://www.w3.org/TR/vocab-org/
- FOAF: http://xmlns.com/foaf/spec/
- Closes flexo-rtm-research issue #3 (Beyond Self-Certification)
