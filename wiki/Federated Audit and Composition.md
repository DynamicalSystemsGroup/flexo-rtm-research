<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Federated Audit and Composition

> **Status — Ships in v0.1 as a new analytical primitive layered on existing scope, attestation, and identity-projection infrastructure.** Self-certification at the component or subsystem level (per [[Verifiable Self-Certification]]) remains the **floor**; federated audit stacks reproducibility attestations and qualified-role attestations on top. v0.1 ships the vocabulary, three new attestation subjects, three composable SHACL profiles, the oracle SPARQL evaluations, and the audit-report views. The **community-curated registry of qualified-auditor orgs** is deferred (similar in spirit to the topological framework's registry concept); v0.1 supports adopter-defined qualified-role sets. Closes [[Design Spec]] §4.9 X6/X7 commitments operationally. Locked in [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]].

`flexo-rtm` v0.1 ships verifiable **self**-certification: an engineering team operates the oracle against their own model and evidence, attests under named approvers, and emits a structurally-local, replayable cert artifact ([[Verifiable Self-Certification]]). That is the **floor** of accountability — every claim is bound to a named human, every step is replayable, every fact is structurally complete in its own local context (cross-cutting acceptance criteria X6, X7, X8 in [[Design Spec]] §9.A.5).

In practice, large institutional systems are not certified by one team alone. They are organized around a **polycentric** institutional topology: multiple organizations hold **scoped authorities** over different parts of the system, each scope is an [Authoritative Source of Truth (ASOT)](https://www.dau.edu/glossary/authoritative-source-truth) for its content, and the system-of-interest is **composed** from many self-certified scopes that may also overlap. See [[ADR-030 Polycentric ASOT Authority Model]] for the locked decision. On top of each scope's self-certification, additional parties — qualified third-party reproducibility auditors, sister-organization verifiers, regulatory reviewers, accredited test labs — can add signatures that reinforce (or contradict) the underlying self-certification. Each additional signature is itself an attestation under a named approver acting on behalf of an organization (per [[Identity Boundaries and Policy Projections]] org-level identities). The composed system-of-interest is a named-graph patchwork of polycentric scopes, and the **adequacy** of that patchwork (does it cover the system-of-interest?) and the **sufficiency** of its signers (are enough qualified orgs attesting?) are first-class certification questions at the composition scale.

This page documents how v0.1 makes those questions first-class. It defines new attestation subjects for the additional signatures, names the levels of certification that can stack on a scope, specifies the composable profiles that enforce composition-scale criteria, and shows where this fits the X6/X7 commitments [[Verifiable Self-Certification]] already presupposes.

## The composition model

Each scope (see [[Analysis Layer Scope Algebra]]) is a **named graph** — a citable, versioned, IRI-addressed selection of model + requirements + evidence content. The certification of a single scope is itself a named graph: the cert artifact's transcript, attestation graph, and audit report all carry the scope IRI in their input-hash and provenance ([[Storage Layer Flexo Conventions]] F4).

A **composed system-of-interest** is a topology — a union of scopes that together cover the system. The composed model is itself a named graph, declared via the scope-algebra composition operators (`rtm:union`, `rtm:intersectsWith`, `rtm:extends`). Each constituent scope acts as a **patch** in the composed topology. The composed certification is then a question about the patchwork:

- Do the patches together **cover** the composed model? (Adequacy at composition scale.)
- Are enough **qualified parties** signing each patch — and is the union of their signatures **sufficient** for the kind of certification the composed model claims? (Sufficiency at composition scale.)

The same vocabulary that ships in v0.1 for evidence-level adequacy and sufficiency ([[Aspect Coverage with Adequacy and Sufficiency]]) extends to this scale. **Adequacy** is composed scope coverage of the system-of-interest. **Sufficiency** is the number and nature of the orgs providing scope-level certifications. The framing is the same; the subjects are different.

## Three new attestation subjects (new vocabulary in v0.1)

Per [[ADR-021 Three Attestation Subclasses Ship in v0.1]] / [[Attestation Infrastructure in v0.1]], v0.1 ships three subclasses of `rtm:Attestation` over the **evidence** dimension: satisfaction, adequacy, sufficiency. Federated audit introduces **three additional subclasses over the scope and composition dimension**, each inheriting the parent's named-approver SHACL discipline (`sh:minCount 1 ; sh:nodeKind sh:IRI` on `rtm:approvedBy`):

| Class | Subject | Asserts |
|---|---|---|
| `rtm:ScopeCertificationAttestation` | an `rtm:Scope` IRI at a specific commit | "this scope's self-certification at the recorded commit was reviewed (or reproduced) and is considered valid for the auditor's purposes" |
| `rtm:CompositionCoverageAttestation` | a composed scope (typically derived via `rtm:union` / `rtm:extends`) | "this set of constituent scopes adequately covers the stated system-of-interest" (the **adequacy** criterion at composition scale) |
| `rtm:CompositionSufficiencyAttestation` | a composed scope | "the number and roles of the orgs that have signed the constituent scopes meet the stated criteria for this composed certification" (the **sufficiency** criterion at composition scale) |

All three are `rdfs:subClassOf rtm:Attestation`. All three inherit `rtm:approvedBy`, `earl:result`, `rtm:hasAspect`, and PROV provenance. The SHACL named-approver shape from [[Attestation Infrastructure in v0.1]] propagates automatically because `sh:targetClass rtm:Attestation` matches the parent class. No new SHACL bottleneck is needed; the existing one already governs them.

The crucial distinction from the evidence-level subclasses is **what they take as subject**. A satisfaction attestation is bound to a `rtm:satisfies` triple — to a single claim about a single artifact-requirement pair. A scope-certification attestation is bound to a `rtm:Scope` IRI — to the whole cert artifact for that scope. This is what makes federated audit a layered primitive: the underlying scope can carry its full set of satisfaction/adequacy/sufficiency attestations, and the scope-certification attestation rides on top of the whole set without restating the per-claim assertions.

A worked Turtle example:

```turtle
:audit-power-2026Q2 a rtm:ScopeCertificationAttestation ;
    rtm:attests rtm:scope/adcs-power ;
    rtm:atCommit "0c4f...8a" ;
    rtm:approvedBy <https://example.org/auditor/qreliability-labs/jdoe> ;
    rtm:approverOrganization :org-qreliability-labs ;
    rtm:auditMode rtm:audit-mode/reproducibility-full ;
    earl:result earl:passed ;
    prov:atTime "2026-07-15T10:22:00Z"^^xsd:dateTime ;
    gsn:byJustification "Re-fetched external URIs, re-executed activities, hashes match." .

:org-qreliability-labs a org:Organization ;
    foaf:name "Q-Reliability Labs" ;
    rtm:hasQualifiedRole rtm:role/accredited-reproducibility-auditor .
```

`rtm:auditMode` is a new predicate carrying one of: `audit-mode/review-only`, `audit-mode/reproducibility-partial`, `audit-mode/reproducibility-full`, `audit-mode/qualified-role-review`. These are SKOS concepts shipped in v0.1's reference ontology; adopters add domain-specific modes via SKOS concept extension.

`rtm:approverOrganization` (range `foaf:Organization` / `org:Organization`) is the organizational identity layered on the personal approver, per the extension to [[Identity Boundaries and Policy Projections]]. Org-level identities project the same way person-level identities do — through the same thin-adapter pattern — and `rtm:hasQualifiedRole` is the org-level analog of `org:role` on a membership.

## Scope-level adequacy and sufficiency

The user's framing of issue #3 makes the mapping to v0.1's existing adequacy/sufficiency vocabulary explicit:

- **Adequacy** at composition scale is **composed scope coverage of system-of-interest**.
- **Sufficiency** at composition scale is **the number and nature of the orgs providing scope-level certifications**.

These are the same shapes of judgment v0.1 ships at the evidence level, lifted to the composition scale. Concretely:

**Composition-adequacy criteria** can encode rules like:

- "Every requirement in the composed model has at least one constituent scope that traces evidence to it."
- "Every safety-critical aspect declared on the composed model is covered by at least one constituent scope that attests that aspect."
- "No requirement in the composed model is referenced solely from a scope flagged as exploratory" (see [[Engineering Lifecycle Stages]] for the lifecycle vocabulary this composes with).

**Composition-sufficiency criteria** can encode rules like:

- "Every constituent scope has at least one `rtm:ScopeCertificationAttestation` from an org bearing `rtm:role/accredited-reproducibility-auditor`."
- "Every safety-critical constituent scope has at least two reproducibility-mode attestations from orgs in the program's qualified-auditor set."
- "The regulator-of-record has attested at least one `rtm:ScopeCertificationAttestation` against the safety aspect of every constituent scope claiming safety relevance."

Both criteria are **RDF instances**, queryable via SPARQL, profile-toggleable. The qualified-auditor set is adopter-defined in v0.1 (a registry of orgs and roles in the adopter's identity projection); the community-curated registry is deferred.

## The four levels of certification at any scope

Federated audit makes explicit a layered ladder of certification a scope can carry. From floor to ceiling:

### Level 1 — Self-certification only (the v0.1 floor)

The engineering team's commit-time attestations: per-claim `rtm:SatisfactionAttestation`, `rtm:AdequacyAttestation`, `rtm:SufficiencyAttestation` triples (per [[Attestation Infrastructure in v0.1]]). No external party has reviewed or reproduced. This is the structural floor — the SHACL gate is satisfied because every claim has a named approver, but the named approvers are all internal.

### Level 2 — Reproducibility audit

One or more parties have re-fetched the external URIs (per [[External URI References]]), re-executed the recorded activities, and attest that the result hashes match. The audit may be **partial** (a specific subset of activities) or **full** (every recorded activity). The audit is recorded as one or more `rtm:ScopeCertificationAttestation` instances with `rtm:auditMode` of `reproducibility-partial` or `reproducibility-full`.

Reproducibility audits exercise the X6/X7 commitments mechanically: each fact is structurally complete locally ([[Verifiable Self-Certification]]), so the auditor can verify the slice they have permissions for without needing universal access. Multiple auditors can split the workload across the scope's transcript steps and compose their pass results into the union.

### Level 3 — Qualified-role audit

An org bearing a specific **qualified role** (e.g., regulatory authority, accredited test lab, customer engineering team, sister-organization verifier) has attested. The role is a property of the **org-level identity** projected through the same adapter pattern as person-level identities — see [[Identity Boundaries and Policy Projections]]. The attestation is recorded as a `rtm:ScopeCertificationAttestation` with `rtm:auditMode` of `qualified-role-review` and `rtm:approverOrganization` pointing at the qualified org.

What makes a role "qualified" is adopter-defined in v0.1. A safety-critical program might require `rtm:role/notified-body`; an export-controlled program might require `rtm:role/cleared-customer-auditor`; an open-source project might require `rtm:role/community-elected-reviewer`. The SPARQL pattern in the active sufficiency profile enumerates which roles count for which aspects.

### Level 4 — Composition certification

A system-of-systems certifier (acting as a named approver representing a qualified org) has attested `rtm:CompositionCoverageAttestation` and `rtm:CompositionSufficiencyAttestation` for the composed model. The composition certifier need not have personally reviewed every constituent scope — they assert that the *composition* meets the stated adequacy and sufficiency criteria, which themselves enforce rules over the union of lower-level attestations.

The four levels stack: a scope at Level 4 inherits Levels 1–3 below it. A scope at Level 2 may not have Level 3 or Level 4 attestations, but it still has Level 1 (the self-certification floor). The audit report enumerates each scope's level per aspect, so a consumer of the composed cert artifact can see exactly which slices rely on which certification levels.

## Where reproducing all evidence is infeasible

This is the user's specific framing in issue #3, and it's the operational reason composition-scale criteria exist. At the scale of an integrated aerospace system, a complex medical device, a federated software supply chain, **no single party can reproduce every fact**. A reproducibility audit of every transcript step of every constituent scope of every composed model would consume more compute and access than any audit budget would underwrite, and would require permissions across confidentiality boundaries that no single party legitimately holds.

Federated audit's answer is that **audit need not reproduce every fact**. Instead, compositional profiles enforce **rules over the signing pattern**:

- A **minimum number of signers** per scope (e.g., "every scope MUST carry ≥ 1 reproducibility attestation in addition to its self-certification").
- **Mandatory presence of specific qualified-role attestations** on specific aspects (e.g., "every safety-critical aspect MUST be attested by an org bearing `rtm:role/accredited-safety-auditor`").
- **Mandatory coverage of the system-of-interest** (e.g., "every requirement in the composed model MUST be reachable from evidence in at least one constituent scope").

These rules are **SPARQL-evaluable** against the scope graphs and the identity-projection graphs (per [[Identity Boundaries and Policy Projections]]). They compose with the existing SHACL bottleneck — adding signing-pattern criteria does not require a new authority-enforcement mechanism, only new SPARQL predicates and new SHACL profile shapes.

When a fact is **not** independently reproduced — only self-certified — the audit report flags it as **"self-certified only"** so consumers can see exactly which slice of the cert artifact relies on which level of attestation. The cert artifact thus carries a complete, honest picture of where the assurance is thicker and where it is thinner, without pretending that a global reproduction has been performed.

## Profiles

Three new SHACL profiles ship in v0.1, all composable (per [[ADR-016 Composable SHACL Profiles]]) and off by default:

### `composition-adequacy`

Requires that every composed scope (a scope derived through `rtm:union`, `rtm:extends`, or `rtm:intersectsWith` with at least one composition target) carries a `rtm:CompositionCoverageAttestation` whose subject is the composed scope. SHACL checks the coverage predicate — that every requirement in the composed model is reachable from evidence in at least one constituent scope — by embedding a SPARQL pattern in the shape. Adopters can override the coverage predicate by authoring their own SHACL profile that extends `composition-adequacy` and replaces the predicate's SPARQL fragment with a domain-specific variant.

### `composition-sufficiency`

Requires that every composed scope carries a `rtm:CompositionSufficiencyAttestation`. SHACL enforces the configured **signer-count thresholds** and **qualified-role coverage** per aspect. The thresholds are themselves RDF instances of `rtm:SufficiencyCriteria` ([[Aspect Coverage with Adequacy and Sufficiency]]), so the same vocabulary that ships in v0.1 for evidence-level sufficiency carries the composition-scale thresholds. A profile that requires "≥ 2 reproducibility auditors per safety scope" is a sufficiency criterion with `rtm:appliesToAspect rtm:safety`, `rtm:minimumSigners 2`, `rtm:requiredAuditMode rtm:audit-mode/reproducibility-full`.

### `qualified-audit-per-scope`

Requires that every constituent scope (every scope referenced from a composed scope, transitively) carries at least N `rtm:ScopeCertificationAttestation` instances per aspect, where N is configurable per aspect via the `rtm:SufficiencyCriteria` vocabulary. This is the lighter-weight profile for adopters who want to enforce "every scope has at least one external review" without yet committing to full composition-adequacy / composition-sufficiency evaluation.

The three profiles compose. A program rolling out federated audit might start with `qualified-audit-per-scope`, then add `composition-adequacy` once the constituent scopes are settled, then add `composition-sufficiency` once the qualified-role set is stable.

## How this fits the X6/X7 commitments

Cross-cutting acceptance criteria X6 (local reproducibility of any fact), X7 (federated reproducibility composes), and X8 (structural completeness without dereferencing) in [[Design Spec]] §9.A.5 already presuppose this model. They state that **a verifier with adequate local permissions can re-execute a fact** without needing universal access, and that **multiple verifiers' partial passes compose into a global pass**. Federated audit is the explicit operationalization of those commitments.

The contribution of this page (and of the new vocabulary) is to make the federation-level attestations **first-class**. X6 and X7 say "the artifact admits federated verification." Federated audit says "and here are the attestation subjects that **record** the federated verification when it happens." A scope's audit report can then enumerate:

- which facts have been independently reproduced (per X6, by which org, with which audit mode),
- which scopes have qualified-role attestations (and from which orgs in which qualified roles),
- which aspects of the composed system-of-interest are adequately covered (per `composition-adequacy`),
- whether the signing pattern meets the configured sufficiency thresholds (per `composition-sufficiency`).

The locality property of [[Verifiable Self-Certification]] is what makes this composable. Each scope-certification attestation is itself a fact in the cert artifact; it is structurally complete in its own neighborhood; it is verifiable locally; it composes federally. The federated-audit machinery is recursive in the right direction — audit attestations are themselves auditable, by the same primitives.

## Worked example

A composed aerospace model assembles four ADCS scopes (attitude-control, power, communications, propulsion). Each scope has a self-certification authored by its respective engineering team, with the full set of satisfaction / adequacy / sufficiency attestations passing under `attested-satisfies + attested-adequacy + attested-sufficiency + aspect-coverage`.

The composition is declared in scope algebra:

```turtle
rtm:scope/adcs-composed a rtm:Scope ;
    rtm:union rtm:scope/adcs-attitude-control,
              rtm:scope/adcs-power,
              rtm:scope/adcs-communications,
              rtm:scope/adcs-propulsion ;
    rtm:appliesToSystemOfInterest :soi-adcs-spacecraft .
```

Federated audit attestations land on each constituent scope and on the composed scope:

1. A national space agency's regulatory authority (qualified role `rtm:role/notified-body`) attests `rtm:ScopeCertificationAttestation` with `rtm:auditMode rtm:audit-mode/qualified-role-review` on the safety aspect of `rtm:scope/adcs-attitude-control`.
2. Two sister-organization reproducibility teams attest `rtm:ScopeCertificationAttestation` with `rtm:auditMode rtm:audit-mode/reproducibility-full` on the simulation activities in `rtm:scope/adcs-power` and `rtm:scope/adcs-propulsion`.
3. A peer engineering team at the prime contractor attests `rtm:ScopeCertificationAttestation` with `rtm:auditMode rtm:audit-mode/reproducibility-partial` (subset of activities) on `rtm:scope/adcs-communications`.
4. The system-of-systems certifier (acting as a named approver of the program's certification authority) attests `rtm:CompositionCoverageAttestation` and `rtm:CompositionSufficiencyAttestation` on `rtm:scope/adcs-composed`.

The oracle, running with `composition-adequacy + composition-sufficiency + qualified-audit-per-scope` profiles, verifies via SPARQL:

- (a) the four constituent scopes adequately cover `:soi-adcs-spacecraft`'s requirements (per `composition-adequacy`);
- (b) every safety-critical scope has ≥ 1 qualified-role attestation (per `composition-sufficiency`'s safety predicate);
- (c) every scope has either a reproducibility attestation or a qualified-role attestation (per `qualified-audit-per-scope`);
- (d) the composition certifier's two composition attestations are themselves named-approver-bound and PROV-provenanced.

The audit report enumerates each scope's certification level (Level 2 / Level 3 / Level 4) and the union as the composed certification level. Slices that are self-certified-only are explicitly flagged.

## What v0.1 ships vs. what's deferred

**Ships in v0.1:**

- Vocabulary: `rtm:ScopeCertificationAttestation`, `rtm:CompositionCoverageAttestation`, `rtm:CompositionSufficiencyAttestation`, `rtm:approverOrganization`, `rtm:auditMode`, `rtm:atCommit`, `rtm:appliesToSystemOfInterest`, `rtm:hasQualifiedRole`, `rtm:minimumSigners`, `rtm:requiredAuditMode`.
- Three SHACL profiles: `composition-adequacy`, `composition-sufficiency`, `qualified-audit-per-scope`.
- Oracle SPARQL support for evaluating composition-scale adequacy and sufficiency.
- Audit-report views enumerating per-scope certification level, per-aspect qualified-role coverage, signer counts, and "self-certified only" flagging.
- Org-level identity-projection extensions to [[Identity Boundaries and Policy Projections]] (`foaf:Organization` / `org:Organization` projections; `rtm:hasQualifiedRole` on org memberships).

**Deferred (similar in spirit to the topological framework's pre-approved-types registry):**

- A **community-curated registry of qualified-auditor orgs and roles**. Who is an "accredited reproducibility auditor"? Which orgs bear `rtm:role/notified-body` in which domains? A canonical, federated registry of these answers is a major scope commitment — it demands governance, versioning, domain coverage, and community uptake. v0.1 supports adopter-defined qualified-role sets (each adopter authors their own role IRIs and qualified-org list in their identity projection); a community registry is future work.
- **Closed-triangle aggregation across federated audits**. The topological framework's closed-triangle audit will operate over the union of self-cert + federated-audit attestations once it lands; v0.1 does not perform the closure.
- **Cross-adopter trust transitivity**. If org A trusts org B's qualified-role claims, and B trusts C's, v0.1 does not model the transitive trust path — each adopter declares their own qualified set. Future work on org-level trust composition will integrate here.

## Forward compatibility with the topological framework

When the topological framework's recursive completeness check lands ([[Topological Framework Future Work]]), federated audit attestations slot in naturally — they are named-approver attestations the framework can require on validation edges or on assurance-face closure at the composed-model scale. The same named-approver discipline ([[ADR-021 Three Attestation Subclasses Ship in v0.1]]) and identity-projection discipline ([[ADR-024 Identity by Thin Projection of External Sources]]) carry through. The community-curated registry of qualified-auditor orgs and the registry of pre-approved guidance types may converge on a single registry primitive when both land.

## Cross-references

- [[Verifiable Self-Certification]] — the self-certification floor federated audit stacks on; X6/X7/X8 cross-cutting acceptance criteria.
- [[Identity Boundaries and Policy Projections]] — the org-level identity projection extension this depends on.
- [[Aspect Coverage with Adequacy and Sufficiency]] — evidence-level adequacy/sufficiency vocabulary that lifts to composition scale.
- [[Attestation Infrastructure in v0.1]] — the parent class and SHACL bottleneck the three new subclasses inherit.
- [[External URI References]] — the foundation reproducibility audits exercise.
- [[Signed Envelopes and Established Standards]] — the signature substrate audit attestations carry.
- [[Analysis Layer Scope Algebra]] — `rtm:Scope` and the composition operators.
- [[Engineering Lifecycle Stages]] — the lifecycle vocabulary composition criteria compose with.
- [[Topological Framework Future Work]] — the deferred recursive completeness check this is forward-compatible with.
- [[Design Spec]] §4.9 (Reproducibility chain), §9.A.5 X6/X7/X8 (cross-cutting acceptance criteria).
- [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]] — locked decision behind this page.
