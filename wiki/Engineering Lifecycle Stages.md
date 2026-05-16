<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Engineering Lifecycle Stages

> **Status — Forward-compat scope for v0.1; full mechanism lands in v0.2.** This page documents engineering lifecycle stages as first-class metadata on scopes (named graphs). v0.1 ships the **vocabulary** (`rtm:lifecycleStage` and the INCOSE-aligned stage IRIs) so adopters can tag scopes today; the **stage-aware oracle behavior and lifecycle state machine** ship in v0.2. This is the **next roadmap item after v0.1** — distinct from the topological framework, which is still in research phase ([[Topological Framework Future Work]]). Adopters who tag scopes in v0.1 get forward-compatible data; the v0.2 oracle activates the stage-aware semantics against that data. Locked in [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]].

## Motivation

Systems do not come into existence ex nihilo. They emerge from engineering work that often starts with **exploratory** phases, leads into formal **requirements specification** which cascades across scopes (subgraphs), and only then proceeds into **development**, **production**, **utilization**, **support**, and eventually **retirement**. New scopes come into existence underspecified and gain detail over time; some scopes that reach production are returned to earlier stages by changes that invalidate prior certifications.

The INCOSE Systems Engineering Handbook treats lifecycle stages as a first-class organizing concept (see [[INCOSE V2 Review]]). `flexo-rtm` should be able to assign lifecycle stages to scopes (named graphs) and to use those stages to gate which checks apply, which gaps are blocking vs. informational, and when re-certification is prompted. This is engineering work that complements the structural traceability and attestation infrastructure v0.1 ships — it does not require the topological framework or new research, but it does require coordinated oracle + operational-layer + skill work that is properly scoped for v0.2.

The motivation has two direct consequences (paraphrasing the user's framing in issue #6):

1. **Early-stage scopes (named graphs) that do not satisfy requirements traceability are not expected to** — gating on T1 (orphan requirement) or T2 (dangling evidence) during exploratory or concept work would be noisy and create UX issues. The lifecycle stage tells the oracle to treat those gaps as **informational, not blocking**, at early stages.
2. **Later-stage scopes that have previous certifications fall back into earlier states** when changes are committed that invalidate prior certifications. Some of these will be automatically rerunnable due to the reproducibility machinery ([[Verifiable Self-Certification]], [[Transcript Replay Semantics]]); others will require human re-attestation. The lifecycle stage machine is the mechanism that ensures recertification is **prompted when appropriate** and that no unintended regressions go undetected.

## The vocabulary (ships in v0.1 for forward-compat)

v0.1 ships the following lifecycle vocabulary so adopters can begin tagging scopes today, accumulating forward-compatible data the v0.2 oracle will activate:

| Term | Type | Role |
|---|---|---|
| `rtm:lifecycleStage` | `owl:ObjectProperty` | Asserts a scope's current lifecycle stage. Domain: `rtm:Scope` (and named-graph metadata per [[Storage Layer Flexo Conventions]] F4). Range: `rtm:LifecycleStage`. |
| `rtm:LifecycleStage` | `owl:Class` | Class of lifecycle stage IRIs; each stage IRI below is an instance. |
| `rtm:lifecycleStageRecordedAt` | `owl:DatatypeProperty` | `xsd:dateTime` of when the stage was assigned. Mandatory under v0.2 stage-aware profiles; recommended in v0.1. |
| `rtm:lifecycleStageTransition` | `owl:ObjectProperty` | Provenance of a stage transition. Subject: `rtm:Scope`. Object: a `rtm:LifecycleStageTransition` blank-or-named node carrying `prov:wasGeneratedBy`, `rtm:fromStage`, `rtm:toStage`, `rtm:approvedBy`, `prov:atTime`. |
| `rtm:LifecycleStageTransition` | `owl:Class` | A first-class transition event. Subject of named-approver SHACL (the same `sh:minCount 1 ; sh:nodeKind sh:IRI` on `rtm:approvedBy`) under the v0.2 stage-transition profile. |

### Stage IRIs (INCOSE-aligned)

The six canonical lifecycle stages from the INCOSE Systems Engineering Handbook, aligned via `skos:closeMatch` per the [[INCOSE V2 Review]] adoption pattern:

| Stage IRI | INCOSE handbook stage | Typical condition |
|---|---|---|
| `rtm:stage/exploratory` | (pre-Concept; exploratory research) | Initial framing; requirements not yet stated |
| `rtm:stage/concept` | Concept | Concept formulated; preliminary requirements emerging |
| `rtm:stage/development` | Development | Requirements specified; models built; evidence accumulating |
| `rtm:stage/production` | Production | Full certification achieved; system being produced or fielded |
| `rtm:stage/utilization` | Utilization | System in operational use; in-service evidence accruing |
| `rtm:stage/support` | Support | System maintained; modifications evaluated |
| `rtm:stage/retirement` | Retirement | System being decommissioned; legacy evidence preserved |

The INCOSE V2 review identifies six handbook stages (concept, development, production, utilization, support, retirement); `rtm:stage/exploratory` is an additional pre-Concept stage `flexo-rtm` introduces explicitly to give programs a first-class home for early framing work that precedes formal Concept entry. Similarly, `rtm:stage/requirements-specification` is added as a sub-stage between concept and development — programs that distinguish "concept agreed, requirements still settling" from "requirements specified, development started" can use the finer-grained tag:

- `rtm:stage/requirements-specification` — between Concept and Development; requirements formally stated, traceability gates begin to apply but rollback to Concept is still cheap.

The seven-stage set (`exploratory`, `concept`, `requirements-specification`, `development`, `production`, `utilization`, `support`, `retirement`) is the v0.1 default. Adopters that prefer to stay closer to INCOSE's six handbook stages can disable the two `flexo-rtm`-introduced stages via the lifecycle profile configuration. The IRIs themselves remain stable so data tagged in one adopter's ontology projects cleanly into another adopter's ontology.

A worked Turtle tag on a scope:

```turtle
rtm:scope/adcs-attitude-control a rtm:Scope ;
    rtm:lifecycleStage rtm:stage/development ;
    rtm:lifecycleStageRecordedAt "2026-05-17T10:00:00Z"^^xsd:dateTime ;
    rtm:lifecycleStageTransition :transition-2026-05-17-development .

:transition-2026-05-17-development a rtm:LifecycleStageTransition ;
    rtm:fromStage rtm:stage/requirements-specification ;
    rtm:toStage rtm:stage/development ;
    rtm:approvedBy <https://example.org/approver/lead-engineer-zargham> ;
    prov:atTime "2026-05-17T10:00:00Z"^^xsd:dateTime ;
    prov:wasGeneratedBy :commit-9a3f .
```

The transition is itself a first-class attestable event. Under the v0.2 stage-transition profile (see below), every transition MUST carry a `rtm:approvedBy` IRI just like any other attestation; the existing SHACL bottleneck from [[Identity Boundaries and Policy Projections]] applies to transitions because `rtm:LifecycleStageTransition` will be configured as a target of the bottleneck shape under the active profile.

## The two consequences from the user's issue (land in v0.2)

### Consequence 1 — Early-stage scopes don't trigger traceability-gate noise

A scope tagged `rtm:stage/exploratory` or `rtm:stage/concept` is **exempt** from traditional bidirectional certification gates. Specifically, gap codes T1 (orphan-requirement) and T2 (dangling-evidence) are **reported as informational, not blocking**, at these stages. The justification is operational: in early stages, an unsatisfied requirement is the **expected** state — the team is still framing the problem. Gating on it would be noisy and force engineers to suppress checks they actually want to keep running for the data they're collecting.

The relaxation is **stage-aware**, not blanket. Even at exploratory stage:

- T6 (failed attestation) remains blocking — a recorded failure is still a recorded failure, regardless of stage.
- T7 (unapproved attestation) remains structurally impossible — the named-approver SHACL bottleneck is on the parent class and is unconditional.
- T8 (aspect-uncovered) remains active only if the `aspect-coverage` profile is on.

At `rtm:stage/requirements-specification`, T1 begins to apply as blocking (the team has committed to specifying requirements; orphan requirements indicate the specification is incomplete). T2 remains informational at this stage and becomes blocking at `rtm:stage/development`.

The full mapping of T-code blocking-vs-informational by stage is established in v0.2; the design sketch in [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]] is:

| Stage | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 |
|---|---|---|---|---|---|---|---|---|
| exploratory | inf | inf | inf | inf | inf | **block** | n/a | inf |
| concept | inf | inf | inf | inf | inf | **block** | n/a | inf |
| requirements-specification | **block** | inf | inf | inf | inf | **block** | n/a | inf |
| development | **block** | **block** | **block** | **block** | **block** | **block** | n/a | **block** |
| production | **block** | **block** | **block** | **block** | **block** | **block** | n/a | **block** |
| utilization | **block** | **block** | **block** | **block** | **block** | **block** | n/a | **block** |
| support | **block** | **block** | **block** | **block** | **block** | **block** | n/a | **block** |
| retirement | **block** | **block** | **block** | **block** | **block** | **block** | n/a | **block** |

("inf" = informational; "block" = blocking; "n/a" = structurally impossible.) The exact relaxation matrix is an open question for v0.2 design — programs may want finer-grained control (per aspect, per T-code) via the lifecycle profile configuration.

### Consequence 2 — Lifecycle-aware regression handling

A scope tagged `rtm:stage/development` or later that has prior certifications, when changes are committed that invalidate prior certifications, **falls back to an earlier state** until re-certification lands. The state-machine semantics:

- **Auto-rerunnable.** Where the reproducibility machinery (per [[Verifiable Self-Certification]] and [[Transcript Replay Semantics]]) can re-execute the recorded transcript steps deterministically against the new state, the certification is **re-evaluated automatically**. The same canonical inputs + same recorded transcript ⇒ same result hash; if the change is upstream of a fact, that fact's hash changes and the cert is re-derived; if the change is independent of a fact, that fact's certification is preserved without further attestation work.
- **Manual re-cert prompted.** Where re-execution requires human judgment — attestations of adequacy or sufficiency by a named approver, qualified-role audits ([[Federated Audit and Composition]]) — the engineering team is **prompted to re-certify**. The operational-layer skill surfaces this on commit ([[Operational Layer UX Discipline]]); the prompt is part of the same judgment-surfacing flow that exists today for new attestations.

The fall-back rules:

- A change that invalidates **structural completeness** of a fact (the RDF neighborhood, external URIs, projection-at-cert-time, or signatures) drops the scope from its current stage back to `development`.
- A change that adds **new requirements** drops the scope back to `requirements-specification` (the new requirements need to be specified and traced before development-stage gates apply).
- A change that **removes or alters guidance** (the adequacy/sufficiency criteria themselves) drops the scope back to `development` and additionally invalidates prior adequacy/sufficiency attestations referencing the changed criteria.
- A change purely to **documentation, comments, or operationally-inert metadata** does not change the stage.

The dispatch is mechanical: SPARQL queries over the diff between the prior commit's audit graph and the new commit's audit graph identify which fall-back rule applies. The lifecycle state machine, in this sense, is an analytical-layer extension that operates over the cert artifact's existing structure ([[Verifiable Self-Certification]]) — it does not require new evidence kinds or new attestation types.

## The lifecycle state machine (v0.2)

Sketch of the canonical transitions (v0.2 will lock the diagram):

- `exploratory` → `concept` (requirements take shape; concept-of-operations forming)
- `concept` → `requirements-specification` (requirements formalized)
- `requirements-specification` → `development` (models built, evidence accumulating; traceability gates fully apply)
- `development` → `production` (full certification achieved)
- `production` → `utilization` (system fielded; operational evidence begins accruing)
- `utilization` → `support` (system in maintenance phase)
- `support` → `retirement` (system being decommissioned)
- Any later stage → `requirements-specification` (rollback on requirement addition or change)
- Any state → `development` (rollback on evidence invalidation or guidance change)

Transitions are themselves **attestable events** recorded with PROV provenance and named approvers (per the v0.2 stage-transition profile). The vocabulary for transitions ships in v0.1 (`rtm:lifecycleStageTransition`, `rtm:fromStage`, `rtm:toStage`); the SHACL profile that requires `rtm:approvedBy` on transitions activates in v0.2.

Cross-scope dependencies are an explicit v0.2 design question: when a downstream scope depends on an upstream scope's certification, lifecycle-aware regression must **cascade**. A downstream scope at `production` whose upstream scope falls back to `development` must itself either fall back or carry an explicit attestation that the upstream change is irrelevant to the downstream certification. The cascade semantics — and the SPARQL pattern that detects them — are in scope for v0.2.

## Why this is v0.2, not v0.1

v0.1 ships the **vocabulary** so adopters can tag scopes today. The state-machine logic, the gate-relaxation rules per stage, the auto-rerun handling, and the re-cert prompts require coordinated oracle + operational-layer + skill work that is in scope for v0.2:

- **Oracle.** The SPARQL queries that dispatch T-code severity by stage; the diff-and-fall-back analysis between commits; the auto-rerun replay path for stage-aware re-evaluation.
- **Operational layer.** The skill prompts that surface re-cert obligations on commit; the working-set materialization that filters checks by stage; the UX for asserting a stage transition.
- **Storage layer.** The commit-metadata round-trip for lifecycle stage (per [[Storage Layer Flexo Conventions]] F4); the audit-graph append for transition events.

By contrast, the v0.1 work for federated audit ([[Federated Audit and Composition]]) only requires new SHACL profiles and SPARQL queries on existing vocabulary patterns — minimal new oracle work, no coordinated state-machine rollout. That asymmetry is why federated audit ships in v0.1 and lifecycle stages ship vocabulary-only in v0.1, mechanism in v0.2.

The vocabulary is **stable**. Adopters tagging scopes today are not at risk of rework: the IRIs, the property names, the transition-event shape are settled by [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]]. The v0.2 oracle activates the stage-aware semantics against the data v0.1 adopters have already accumulated.

## Distinct from the topological framework

The topological framework is **research-phase deferred** ([[Topological Framework Future Work]]). It requires a community-curated registry of pre-approved artifact types, research on alternative invariants to V−F, governance for recursive completeness, and an open question set that includes whether the framework's chosen invariants are sufficient. Its timeline is open and depends on community engagement.

Lifecycle stages are **engineering-phase deferred**. The vocabulary is settled. The mechanism — a state machine with stage-aware gate dispatch — is straightforward engineering work that operates over the v0.1 cert-artifact structure already shipped. The timeline is clear: v0.2.

The distinction matters for adopters and reviewers:

- An adopter who wants to ship lifecycle-aware certification can rely on the **v0.2 roadmap** — they will tag scopes in v0.1, accumulate the data, and the v0.2 oracle will read it without rework. The mechanism arrival is a near-term engineering commitment.
- An adopter who wants to ship topological-framework-aware certification cannot rely on a near-term roadmap — the framework's arrival depends on research outcomes and registry governance that are not yet settled.

This is what the [[Mission and Thesis]] framing is naming when it identifies lifecycle stages and federated audit as the two near-term extensions of the v0.1 baseline.

## Worked example

A power-subsystem scope starts in `rtm:stage/exploratory`. The engineering team is framing the problem; no requirements are yet stated; the named-approver discipline applies on every attestation they do author, but T1 and T2 gap codes are reported as informational, not blocking.

As requirements firm up, the team commits a stage transition to `rtm:stage/requirements-specification`. The transition is recorded as a `rtm:LifecycleStageTransition` with the lead engineer's `rtm:approvedBy` IRI. T1 now applies as blocking — orphan requirements indicate incomplete specification — but T2 remains informational at this stage.

Development proceeds. The team transitions to `rtm:stage/development`. All T-codes now apply as blocking; the team's evidence-gathering and attestation work is fully gated. The scope reaches full certification under the active profile set (`attested-satisfies + attested-adequacy + attested-sufficiency + aspect-coverage`), and is promoted to `rtm:stage/production`.

A new requirement is added — a late-breaking thermal constraint from the systems engineer. The commit triggers the lifecycle state machine:

- SPARQL diff identifies that a new `rtm:Requirement` instance has been added.
- The fall-back rule fires: addition of new requirements drops the scope to `rtm:stage/requirements-specification`.
- The lifecycle state machine records the transition with provenance.

The new requirement gets satisfied — the team adds evidence, writes attestations, runs the certification. The auto-rerunnable path handles most of the prior certifications: every fact whose canonical inputs are unchanged retains its prior result hash via [[Transcript Replay Semantics]]; every fact whose canonical inputs are unchanged but whose adequacy/sufficiency criteria are unchanged retains its prior attestations.

Where the new requirement intersects prior adequacy claims — e.g., the rigid-body assumption was attested as adequate "for the slew-rate regime," and the thermal constraint introduces a regime change — the skill prompts the engineer for re-attestation. The engineer either attests the prior adequacy still holds (with updated rationale) or attests it does not, triggering a model refresh. The cert artifact records the new attestation chain transparently.

Once all prior certifications are either auto-revalidated or re-attested, the scope advances back to `rtm:stage/production`. The audit report shows the full lifecycle history: when the scope entered each stage, when it transitioned, what triggered each transition, who attested each transition. The certification is honest about its temporal trajectory — there is no pretense that the scope was continuously at production; the regression-and-recovery is visible in the cert artifact.

## What v0.1 ships vs. what's deferred to v0.2

**Ships in v0.1 (vocabulary, forward-compat data accumulation):**

- Vocabulary: `rtm:lifecycleStage`, `rtm:LifecycleStage`, the seven stage IRIs (`exploratory`, `concept`, `requirements-specification`, `development`, `production`, `utilization`, `support`, `retirement`), `rtm:lifecycleStageRecordedAt`, `rtm:lifecycleStageTransition`, `rtm:LifecycleStageTransition`, `rtm:fromStage`, `rtm:toStage`.
- SHACL shape that requires `rtm:Scope` instances to declare a lifecycle stage (warning by default; error under `--profile=lifecycle-stages-required`).
- v0.1 oracle reads the stage and includes it in transcript provenance — but does NOT yet apply stage-aware gate relaxation or auto-rerun logic.
- Commit-metadata round-trip for `rtm:lifecycleStage` per [[Storage Layer Flexo Conventions]] F4.
- INCOSE alignment via `skos:closeMatch` from `rtm:stage/*` IRIs to INCOSE handbook stage IRIs (per [[INCOSE V2 Review]] adoption pattern).

**Ships in v0.2 (mechanism):**

- Stage-aware gate relaxation (the T-code blocking-vs-informational matrix above).
- Lifecycle state machine: transition rules, fall-back triggers, auto-rerunnable detection via transcript-replay dispatch.
- Re-cert prompts in the operational-layer skill.
- Cross-scope dependency cascade.
- SHACL profile `lifecycle-stage-transition-attested` requiring named-approver on every `rtm:LifecycleStageTransition`.

## Open questions for v0.2 design

These are the questions [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]] explicitly identifies as open for v0.2:

- **Stage-transition authority.** Who can move a scope from one stage to another? Likely a named-approver attestation with `rtm:lifecycleStageTransition` semantics analogous to other attestations — the policy primitives in [[Identity Boundaries and Policy Projections]] (`rtm:permitsAttestationType`, `rtm:withinScope`) can govern who is authorized to transition which scopes, but the exact policy shape is to be decided.
- **Stage-gate relaxation specifics.** The matrix above is a sketch; programs may want finer-grained control. Should T1 / T2 be relaxed only for non-safety aspects at exploratory stage? Should T3 / T4 / T5 always be informational until requirements-specification, or always informational until development? The defaults are settled in v0.2.
- **Reproducibility-machinery auto-rerun semantics.** Exact replay protocol for stage-aware re-evaluation. Per-fact auto-rerun is straightforward (canonical inputs unchanged ⇒ result hash unchanged); cascade across facts where one is auto-rerunnable and a dependent requires manual re-attestation needs careful sequencing.
- **Cross-scope dependencies.** When a downstream scope depends on an upstream scope's certification, lifecycle-aware regression must cascade. How is the dependency declared? (Likely via the scope-algebra composition operators in [[Analysis Layer Scope Algebra]].) How does the cascade interact with [[Federated Audit and Composition]] composition attestations? (Composition attestations on a composed scope must fall back if any constituent scope falls back, or carry an explicit attestation that the constituent change is irrelevant.)
- **Stage skew across federated parties.** If different parties to a federated audit are at different stage perceptions for the same scope, whose perception governs? The on-record stage is the one recorded in the scope's metadata at the audited commit; differing federated-audit attestations against different commits naturally carry different stages.

## Cross-references

- [[Analysis Layer Scope Algebra]] — `rtm:Scope` as a first-class RDF resource; the subject of `rtm:lifecycleStage`.
- [[Verifiable Self-Certification]] — the structural-locality property the auto-rerun path exercises.
- [[Operational Layer UX Discipline]] — the skill that surfaces re-cert prompts on commit (v0.2).
- [[Storage Layer Flexo Conventions]] — commit-metadata round-trip for lifecycle stage (F4).
- [[Aspect Coverage with Adequacy and Sufficiency]] — the adequacy/sufficiency criteria that drive re-cert prompts when guidance changes.
- [[Transcript Replay Semantics]] — the per-fact replay path the auto-rerun handler dispatches over.
- [[INCOSE V2 Review]] — the source for the six INCOSE handbook stages aligned via `skos:closeMatch`.
- [[Gap Taxonomy]] — the T-codes whose blocking-vs-informational severity is stage-aware in v0.2.
- [[Federated Audit and Composition]] — the v0.1 federated-audit primitive lifecycle composition attestations integrate with.
- [[Topological Framework Future Work]] — the research-phase deferred framework, distinct in timeline from this v0.2 roadmap item.
- [[Design Spec]] §5 (Three-Layer Architecture and scope semantics), §9.A.1 F4 (scope metadata round-trip).
- [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]] — locked decision behind this page.
