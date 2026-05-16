<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-029: Engineering Lifecycle Stages as Scope Metadata

**Status:** Accepted
**Date:** 2026-05-17
**Deciders:** Michael Zargham
**Related:** [[ADR-003 Topological Framework Documented as Future Work]]; [[ADR-007 Scope as First-Class RDF Resource]]; [[ADR-021 Three Attestation Subclasses Ship in v0.1]]; [[ADR-024 Identity by Thin Projection of External Sources]]; [[Engineering Lifecycle Stages]]; [[Analysis Layer Scope Algebra]]; [[INCOSE V2 Review]]; [[Design Spec]]

## Context

Systems do not come into existence ex nihilo. The user's framing in research issue #6 names the engineering reality directly: systems emerge from engineering work that often starts with exploratory phases, leads into formal requirements specification which cascades across scopes (subgraphs), and only then proceeds into development, production, utilization, support, and eventually retirement. New scopes come into existence underspecified and gain detail over time; some scopes reach certification and then return to earlier stages when changes invalidate prior certifications. Per the INCOSE Systems Engineering Handbook (see [[INCOSE V2 Review]]), lifecycle stages are a first-class organizing concept — and `flexo-rtm` should be able to assign them to scopes (named graphs).

The user's framing identifies two direct consequences:

1. **Early-stage models (named graphs) that do not satisfy requirements traceability are not expected to** — gating on T1 (orphan requirement) or T2 (dangling evidence) during exploratory or concept work would be noisy and create UX issues.
2. **Later-stage models that have previous certifications fall back into earlier states** when changes are committed that invalidate prior certifications. Some are automatically rerunnable via the reproducibility machinery; others require human re-attestation. The lifecycle state machine is the mechanism that ensures recertification is prompted when appropriate and no unintended regressions go undetected.

The question is what `flexo-rtm` ships in v0.1 and what is deferred. There is a critical framing distinction here: lifecycle stages are **engineering-phase deferred** (vocabulary is settled; mechanism is straightforward but requires coordinated rollout) and explicitly **NOT** research-phase deferred like the topological framework ([[ADR-003 Topological Framework Documented as Future Work]]). Adopters can rely on the lifecycle stage roadmap landing in v0.2; the topological framework's timeline is open. See [[Design Spec]] §5 and [[Engineering Lifecycle Stages]] for full context.

## Decision

`flexo-rtm` ships **engineering lifecycle stages as scope metadata** with a clear v0.1-vs-v0.2 split:

**v0.1 ships the vocabulary** so adopters can begin tagging scopes today, accumulating forward-compatible data the v0.2 oracle will activate:

1. **Predicate** `rtm:lifecycleStage` on `rtm:Scope` and on named-graph metadata.
2. **Class** `rtm:LifecycleStage` and **seven stage IRIs** aligned with the INCOSE Systems Engineering Handbook stages via `skos:closeMatch` (per the [[INCOSE V2 Review]] adoption pattern): `rtm:stage/exploratory`, `rtm:stage/concept`, `rtm:stage/requirements-specification`, `rtm:stage/development`, `rtm:stage/production`, `rtm:stage/utilization`, `rtm:stage/support`, `rtm:stage/retirement`. The six INCOSE-canonical stages (concept, development, production, utilization, support, retirement) are present verbatim; `exploratory` and `requirements-specification` are `flexo-rtm` additions giving programs a first-class home for pre-Concept framing and for finer-grained tracking between concept and development.
3. **Provenance** `rtm:lifecycleStageRecordedAt` (`xsd:dateTime`) and `rtm:lifecycleStageTransition` (`rtm:LifecycleStageTransition` instances with `rtm:fromStage`, `rtm:toStage`, `rtm:approvedBy`, `prov:atTime`, `prov:wasGeneratedBy`).
4. **SHACL shape** requiring `rtm:Scope` instances to declare a lifecycle stage (warning by default; error under `--profile=lifecycle-stages-required`).
5. **Commit-metadata round-trip** of lifecycle stage per [[Storage Layer Flexo Conventions]] F4 — the v0.1 oracle reads the stage and includes it in transcript provenance but does not yet apply stage-aware gate relaxation.

**v0.2 lands the mechanism:**

1. **Stage-aware gate relaxation.** Gap codes T1 / T2 / T3 / T4 / T5 / T8 are reported as **informational, not blocking**, at early stages (exploratory, concept). T1 becomes blocking at requirements-specification. T2–T5 and T8 become blocking at development. T6 (failed attestation) and T7 (unapproved attestation, structurally impossible) are unchanged across stages — recorded failure is always recorded failure; unapproved attestation is always SHACL-rejected.
2. **Lifecycle state machine.** Transition rules, fall-back triggers (new requirements → requirements-specification; evidence invalidation → development; guidance change → development), auto-rerunnable detection via [[Transcript Replay Semantics]] dispatch, and re-cert prompts in the operational-layer skill.
3. **Cross-scope dependency cascade.** When a downstream scope depends on an upstream scope's certification, lifecycle-aware regression cascades — either the downstream falls back, or it carries an explicit attestation that the upstream change is irrelevant.
4. **`lifecycle-stage-transition-attested` SHACL profile** requiring named-approver on every `rtm:LifecycleStageTransition` (the same `sh:minCount 1 ; sh:nodeKind sh:IRI` discipline as other attestations).

The v0.1-v0.2 split is **explicit**: vocabulary is forward-compat in v0.1, mechanism lands in v0.2. This is distinct from the topological framework's research-phase deferral.

## Consequences

### Positive

- **Early-stage UX is cleaner.** Exploratory and concept scopes can be tagged with their actual stage; the v0.2 oracle relaxes traceability gates appropriately. Engineers framing a new problem don't have to suppress checks they want to keep running for the data they're collecting
- **Regression handling is explicit.** When a change invalidates prior certification, the lifecycle state machine records the fall-back transparently. The cert artifact is honest about its temporal trajectory; there is no pretense that a scope was continuously at production when it was rolled back and re-certified
- **INCOSE-aligned.** Programs already organizing around INCOSE Handbook stages can tag scopes with familiar terminology; the `skos:closeMatch` alignment makes the integration explicit (per [[INCOSE V2 Review]])
- **Auto-rerunnable path leverages existing reproducibility machinery.** The structural-locality property of [[ADR-025 Reproducibility is Structural and Local]] means most prior certifications survive a stage rollback without re-attestation work — same canonical inputs ⇒ same result hash; only facts intersecting the change require human re-judgment
- **Forward-compat data accumulation.** Adopters tagging scopes in v0.1 are not at risk of rework. The IRIs, the property names, the transition-event shape are settled; the v0.2 oracle reads the data v0.1 adopters have already accumulated
- **Distinct from research-phase deferral.** The roadmap commitment is clear — vocabulary now, mechanism in v0.2. Adopters can plan accordingly; this is not subject to the open registry and invariant questions blocking the topological framework

### Negative / Tradeoffs

- **v0.2 work.** The state-machine logic, the gate-relaxation matrix, the auto-rerun handling, and the re-cert prompts require coordinated oracle + operational-layer + skill work. This is a substantial v0.2 commitment. Mitigated by the vocabulary being settled and stable, so adopters' v0.1 data is forward-compatible
- **Introduces a state machine.** State machines have transition correctness obligations (no skipped transitions; every transition is attested; cross-scope cascades terminate). Mitigated by transitions being first-class attestable events and by SPARQL diff queries dispatching the fall-back mechanically
- **Cross-scope dependency handling is open.** The cascade semantics — when a downstream scope falls back because an upstream did — are sketched but not fully designed; the exact policy is a v0.2 design question. Mitigated by the cascade being optional under a separate profile; programs that don't enable cross-scope dependency tracking are unaffected
- **Stage assignment is a per-scope governance decision.** Who can transition a scope from one stage to another is an open question for v0.2 — likely a named-approver attestation governed by the policy primitives of [[ADR-024 Identity by Thin Projection of External Sources]] (`rtm:permitsAttestationType`, `rtm:withinScope`), but the exact policy shape is to be decided
- **Stage skew across federated parties.** Different parties may perceive a scope at different stages; the on-record stage is the one recorded in the scope's metadata at the audited commit. Mitigated by federated audit attestations ([[Federated Audit and Composition]]) being commit-pinned via `rtm:atCommit`

### Neutral

- **Forward-compat data accumulates in v0.1.** Tagging scopes today produces stable data the v0.2 oracle will read. No data migration when v0.2 lands
- **The seven-stage default is configurable.** Adopters who prefer the six INCOSE-canonical stages can disable the two `flexo-rtm`-introduced stages via lifecycle profile configuration. The IRIs themselves remain stable

## Alternatives Considered

- **Ignore lifecycle and treat all scopes the same.** Apply T1–T8 uniformly regardless of stage. **Rejected.** The user's framing is explicit: gating on orphan requirements during exploratory work would be noisy and create UX issues. Engineers would either suppress the checks they actually want or develop the bad habit of ignoring the audit report. The lifecycle stage is the mechanism that aligns gate severity with what programs actually want to know at each stage of engineering work.
- **Ship the full state machine in v0.1.** Vocabulary + gate relaxation + auto-rerun + re-cert prompts + cross-scope cascade all in v0.1. **Rejected.** The state-machine logic requires coordinated oracle + operational-layer + skill work that is scope creep relative to v0.1's existing scope (which is already substantial: vocabulary, SHACL, three-layer architecture, OSLC adapters, ADCS regression corpus, federated-audit primitive). The clean split is: vocabulary now, mechanism in v0.2. Adopters accumulate forward-compatible data immediately; the v0.2 work has a well-defined surface.
- **Defer to research phase like the topological framework.** Treat lifecycle stages as an open research question on the v0.2+ horizon with no near-term commitment. **Rejected.** The mechanism is **settled engineering**, not open research. The state machine is straightforward — stages, transitions, fall-back rules, auto-rerunnable dispatch. The vocabulary is INCOSE-aligned. There is no equivalent of the topological framework's registry-or-recursion question. Conflating the two timelines would mislead adopters about which extensions they can plan around. The lifecycle stage roadmap is a near-term v0.2 commitment, distinct from the open-timeline framework.
- **Ship lifecycle vocabulary alongside the topological framework only when the framework is ready.** Bundle the two. **Rejected.** Lifecycle stages are useful **today** for tagging scopes, even before the v0.2 mechanism activates. The federated-audit primitive ([[Federated Audit and Composition]], [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]]) composes with lifecycle stages in v0.1 — for instance, a composition adequacy criterion can require "no constituent scope referenced solely from a scope flagged as exploratory" using only v0.1 vocabulary. Decoupling lifecycle from the framework lets the two extensions land on their own timelines.
- **Use a different lifecycle vocabulary (e.g., MIL-STD-498 or IEEE 15288 explicit).** **Rejected.** INCOSE Handbook stages are the systems-engineering lingua franca; `skos:closeMatch` accommodates programs that translate from MIL-STD or IEEE-15288 phasing into INCOSE-aligned vocabulary without forcing a different anchor.

## Implementation Notes

- v0.1 ontology defines vocabulary in `ontology/core.ttl`: `rtm:lifecycleStage`, `rtm:LifecycleStage`, the seven stage IRIs (`rtm:stage/exploratory`, `rtm:stage/concept`, `rtm:stage/requirements-specification`, `rtm:stage/development`, `rtm:stage/production`, `rtm:stage/utilization`, `rtm:stage/support`, `rtm:stage/retirement`), `rtm:lifecycleStageRecordedAt`, `rtm:lifecycleStageTransition`, `rtm:LifecycleStageTransition`, `rtm:fromStage`, `rtm:toStage`.
- INCOSE alignment in `ontology/alignment/incose.ttl`: `skos:closeMatch` from the six canonical `rtm:stage/*` IRIs to INCOSE Handbook stage IRIs per the [[INCOSE V2 Review]] adoption pattern.
- SHACL shape `rtm:LifecycleStageShape` in `ontology/shapes/lifecycle.ttl` (warning under default; error under `--profile=lifecycle-stages-required`).
- Commit-metadata round-trip for `rtm:lifecycleStage` per [[Storage Layer Flexo Conventions]] F4 acceptance criterion; `oracle/storage/flexo.py` reads and writes lifecycle stage alongside scope IRI.
- v0.1 oracle reads lifecycle stage and includes it in transcript provenance (per [[Transcript Replay Semantics]]'s PROV metadata). v0.1 oracle does NOT yet apply stage-aware gate relaxation or auto-rerun logic — these activate in v0.2.
- v0.2 deliverables (scoped here for traceability, designed in v0.2):
  - Stage-aware gap-code dispatch in `oracle/analysis/gaps.py` per the blocking-vs-informational matrix
  - State-machine engine in `oracle/lifecycle/state_machine.py` with transition rules, fall-back triggers, auto-rerunnable detection via transcript-replay dispatch
  - Re-cert prompt integration in the operational-layer skill (per [[Operational Layer UX Discipline]])
  - SHACL profile `lifecycle-stage-transition-attested` requiring `rtm:approvedBy` on every transition event
  - Cross-scope dependency cascade in `oracle/analysis/cascade.py`
- Open questions for v0.2 design (enumerated in [[Engineering Lifecycle Stages]]): stage-transition authority policy, finer-grained stage-gate relaxation, auto-rerun replay semantics, cross-scope cascade specifics, stage skew across federated parties.

## References

- [[Design Spec]] §5 (Three-Layer Architecture and scope semantics), §9.A.1 F4 (scope metadata round-trip)
- [[Engineering Lifecycle Stages]] — canonical documentation of the lifecycle primitive
- [[Analysis Layer Scope Algebra]] — `rtm:Scope` as a first-class RDF resource; the subject of `rtm:lifecycleStage`
- [[INCOSE V2 Review]] — the source for the six INCOSE Handbook stages and the `skos:closeMatch` adoption pattern
- [[Storage Layer Flexo Conventions]] — commit-metadata round-trip for lifecycle stage (F4)
- [[Verifiable Self-Certification]] — the structural-locality property the v0.2 auto-rerun path exercises
- [[Transcript Replay Semantics]] — the per-fact replay path the auto-rerun handler dispatches over
- [[Gap Taxonomy]] — the T-codes whose blocking-vs-informational severity becomes stage-aware in v0.2
- [[Federated Audit and Composition]] — the v0.1 federated-audit primitive lifecycle composition attestations compose with
- [[ADR-003 Topological Framework Documented as Future Work]] — the research-phase deferral this decision is explicitly distinct from
- [[ADR-007 Scope as First-Class RDF Resource]] — the scope-as-RDF discipline this builds on
- [[ADR-021 Three Attestation Subclasses Ship in v0.1]] — the named-approver discipline transition events will inherit
- [[ADR-024 Identity by Thin Projection of External Sources]] — the policy primitives that will govern stage-transition authority
- [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]] — the parallel v0.1 roadmap extension
- INCOSE Systems Engineering Handbook (canonical lifecycle stages)
- Closes flexo-rtm-research issue #6 (Engineering Lifecycle as first class concept)
