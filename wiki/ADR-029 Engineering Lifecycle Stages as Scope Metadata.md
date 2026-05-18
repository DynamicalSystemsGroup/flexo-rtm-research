<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-029: Engineering Lifecycle Stages as Optional Scope Metadata

**Status:** Accepted (revised 2026-05-18 to honor the methodology-neutrality axiom)
**Date:** 2026-05-17 (original), 2026-05-18 (revised scope: optional, methodology-neutral)
**Deciders:** Michael Zargham
**Related:** [[ADR-003 Topological Framework Documented as Future Work]]; [[ADR-007 Scope as First-Class RDF Resource]]; [[ADR-021 Three Attestation Subclasses Ship in v0.1]]; [[ADR-024 Identity by Thin Projection of External Sources]]; [[ADR-030 Polycentric ASOT Authority Model]]; [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]; [[Engineering Lifecycle Stages]]; [[Analysis Layer Scope Algebra]]; [[INCOSE V2 Review]]; [[Design Spec]]

## Context

Systems do not come into existence ex nihilo. They emerge from engineering work that progresses through phases — stakeholder framing and requirements specification, design and development, production, utilization, support, eventual retirement. `flexo-rtm` should be able to assign **lifecycle stage metadata** to scopes (named graphs) so programs can tag where each subgraph sits in their methodology and so audit reports can reflect those tags. This was research issue #6.

An **earlier framing of this ADR** (2026-05-17) made lifecycle stages **first-class scope metadata** with a v0.2 oracle mechanism (stage-aware gate relaxation, lifecycle state machine, fall-back triggers, auto-rerun handling). Subsequent review identified that framing as violating the **methodology-neutrality axiom**: making engineering lifecycle stages first-class metadata on every named graph privileges one specific lifecycle vocabulary (INCOSE / ISO/IEC/IEEE 15288) over alternatives that real-world adopters use — DO-178C DAL gates in airborne software, NASA Phase A–F, ISO 9001 process gates, Agile sprint cycles, MIL-STD-498 phasing, customer-program-specific milestones, or no formal lifecycle at all. The polycentric ASOT model ([[ADR-030 Polycentric ASOT Authority Model]]) is explicit that different organizations cooperate from different methodological starting points; mandating a privileged lifecycle vocabulary would translate that diversity through one framework's lens unnecessarily.

The regression-handling concern that the earlier ADR's state-machine mechanism addressed — "later-stage scopes fall back when changes invalidate prior certifications" — is now handled more directly at the attestation level by [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]: an attestation invalidated by upstream change is marked `rtm:status/deprecated` with `prov:wasInvalidatedBy` recording the cause. That mechanism is local to the attestation, methodology-neutral, and does not require a state machine on the scope.

This revised ADR locks lifecycle stages as **optional** organizational-convenience metadata, with INCOSE / ISO 15288 stages documented as **one example** of a lifecycle vocabulary.

## Decision

`flexo-rtm` v0.1 ships **optional lifecycle stage metadata** on scopes, with no state machine in the core ruleset:

1. **Optional vocabulary.** `rtm:lifecycleStage` (object property; **not** required by core SHACL) on `rtm:Scope` and on named-graph metadata. Range: `rtm:LifecycleStage` (or any `skos:Concept`). Adopters tag scopes if it helps their organization; the framework does not require it.
2. **INCOSE / ISO 15288 as one example.** The six canonical INCOSE / ISO/IEC/IEEE 15288 stage IRIs (`rtm:stage/concept`, `rtm:stage/development`, `rtm:stage/production`, `rtm:stage/utilization`, `rtm:stage/support`, `rtm:stage/retirement`) ship in the optional `ontology/lifecycle/incose.ttl` module. Adopters using other methodologies declare their own stage vocabularies as SKOS concept schemes; the property `rtm:lifecycleStage` accepts any `skos:Concept`.
3. **No state machine in core.** The earlier v0.2 work — stage-aware gate relaxation, fall-back triggers, lifecycle state machine — is **removed** from the core roadmap. Programs that want stage-gate relaxation can implement adopter-specific profiles on top of their own lifecycle vocabulary. The framework does not ship that mechanism.
4. **No mandatory commit-metadata capture.** The earlier F4-adjacent commitment to round-trip `rtm:lifecycleStage` in commit metadata becomes optional. If an adopter uses lifecycle stages, the commit metadata captures them; if not, the field is absent.
5. **Provenance for transitions when used.** When an adopter records a stage transition, the recommended vocabulary remains `rtm:lifecycleStageTransition` with `rtm:fromStage`, `rtm:toStage`, `rtm:approvedBy`, `prov:atTime`, `prov:wasGeneratedBy`. Transitions are first-class attestable events under the optional `lifecycle-stage-transition-attested` profile.

**Regression handling moves to attestation status** ([[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]). When upstream changes invalidate a downstream claim, the affected attestation is marked `rtm:status/deprecated` with `prov:wasInvalidatedBy` referencing the change. The cert artifact surfaces deprecated attestations as **T9** gaps with provenance. This mechanism is local to the attestation, methodology-neutral, and does not require any scope-level lifecycle tracking.

**Forward compatibility.** Adopters using the INCOSE-aligned stage vocabulary in v0.1 retain stable IRIs; any future optional gate-relaxation profile (adopter-built or shipped as a community extension) operates against the same vocabulary. The data is portable.

## Consequences

### Positive

- **Methodology-neutral.** Adopters from DO-178C, NASA Phase A–F, ISO 9001, Agile, MIL-STD-498, or custom program phasing participate on the same footing as INCOSE adopters. No translation required. Polycentric ASOT compositions ([[ADR-030 Polycentric ASOT Authority Model]]) work across orgs using different lifecycle vocabularies.
- **Simpler core ruleset.** No state machine on scopes in v0.1 or v0.2 core. The v0.2 work on lifecycle becomes "ship the deprecation cascade detection" ([[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]) — a more local, more inspectable mechanism than scope-state-machine fall-back.
- **Lifecycle tags retain organizational value.** Programs that *do* use a lifecycle vocabulary can still tag scopes for audit-report rendering, organizational reporting, and (optionally) adopter-specific profiles. The capability is preserved; just not mandatory.
- **INCOSE / ISO 15288 alignment preserved for adopters who want it.** The six-stage canonical set ships in the optional `ontology/lifecycle/incose.ttl` module with `skos:closeMatch` alignment ([[INCOSE V2 Review]]). Programs already organized around INCOSE can adopt it directly.
- **Cleaner separation of concerns.** Lifecycle stages = organizational metadata. Attestation status = certification state. The two were previously entangled; they are now orthogonal.

### Negative / Tradeoffs

- **Programs wanting scope-level gate relaxation must build it themselves** (or rely on community extensions). The framework no longer ships "T1 informational at Concept; blocking at Development." Mitigated by the gap codes being profile-aware anyway — profiles can already gate T-code severity, and adopter-specific profiles can key off whatever stage vocabulary the adopter uses.
- **Adopters relying on the earlier v0.2 roadmap must migrate to the deprecation-cascade mechanism.** The user-facing semantics (recertification is prompted when prior work is invalidated) are preserved; the implementation is at the attestation level rather than the scope level. Migration involves moving from "scope falls back to development" framing to "affected attestation is marked deprecated" framing.
- **Slightly more vocabulary to think about** if an adopter wants both lifecycle stages and attestation status. Mitigated by the two being orthogonal: lifecycle stages are optional metadata; attestation status is core.

### Neutral

- **The vocabulary IRIs (`rtm:lifecycleStage`, the six INCOSE-aligned stage IRIs, transition events) are stable.** Earlier-tagged data is forward-compatible. The change is in what the framework requires (now: nothing) and what it ships as core mechanism (now: nothing on lifecycle; deprecation cascade is on attestations per [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]).
- **The INCOSE V2 review** ([[INCOSE V2 Review]]) reframes lifecycle stages as one SE-content contribution among many; INCOSE remains an example, not the canonical thing.

## Alternatives Considered

- **Keep lifecycle stages as first-class scope metadata with the v0.2 state machine.** Rejected. Violates the methodology-neutrality axiom. Privileges INCOSE / ISO 15288 over equally legitimate alternatives. Adds significant core complexity for a regression-handling concern that is better solved locally at the attestation level.
- **Ship multiple privileged lifecycle vocabularies in core (INCOSE + DO-178C + NASA + Agile + ...).** Rejected. Still privileges some over others. Forces the framework to be opinionated about which methodologies "count." Adds vocabulary bloat without resolving the underlying coupling.
- **Drop lifecycle vocabulary entirely.** Rejected. Programs that want to tag scopes for organizational purposes lose a useful capability. The right level is optional: vocabulary present, requirement absent.
- **Keep the v0.2 state machine but make the lifecycle vocabulary itself pluggable.** Rejected as the worst of both worlds — preserves the complexity of the state machine while adding the complexity of vocabulary pluggability. The simpler resolution is to move regression handling to the attestation level (per [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]) and let lifecycle vocabularies be plain optional metadata.
- **Introduce parallel `flexo-rtm`-specific sub-stages (e.g., `exploratory` before Concept, `requirements-specification` between Concept and Development).** Rejected per research issue #8. The INCOSE handbook and ISO/IEC/IEEE 15288 define the canonical six stages; the Concept stage explicitly includes early framing and requirements-specification activities. Inventing parallel sub-stages would reinvent rather than reuse existing standards. With the v0.18 revision making lifecycle vocabulary optional, this rejection is even more emphatic — there is no privileged stage vocabulary to extend.

## Implementation Notes

- **Vocabulary location:** `ontology/lifecycle/incose.ttl` (optional module; not imported by core). The six stage IRIs, the `rtm:LifecycleStage` class, `rtm:lifecycleStageTransition`, `rtm:fromStage`, `rtm:toStage`, etc.
- **Core ontology** (`ontology/core.ttl`) defines `rtm:lifecycleStage` as a property with `skos:Concept` range so any adopter-defined vocabulary slots in. No required values; no state-machine SHACL shapes.
- **Adopter-built profiles.** A program that wants "T1 informational at Concept stage" can ship a custom SHACL profile that queries `rtm:lifecycleStage` and conditionally relaxes T1 severity. The framework provides the substrate (the `rtm:lifecycleStage` property, scope-as-first-class-RDF, the gap-code vocabulary); the policy is the adopter's.
- **Regression handling.** See [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] for the canonical mechanism (attestation deprecation cascade with `prov:wasInvalidatedBy` provenance). The v0.2 work scope on lifecycle becomes: ship the deprecation cascade detection, support optional lifecycle tagging, retire the scope-state-machine concept from the roadmap.
- **Page updates.** [[Engineering Lifecycle Stages]] is reframed to "optional pattern + INCOSE as one example"; [[INCOSE V2 Review]] reframes lifecycle stages as one SE contribution; [[Analysis Layer Scope Algebra]] downgrades the lifecycle subsection to optional; [[Storage Layer Flexo Conventions]] notes the commit-metadata capture as optional.

## References

- [[Design Spec]] §5 (Three-Layer Architecture and scope semantics), §9.A.1 F4 (scope metadata round-trip; lifecycle stage is now optional)
- [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] — the mechanism that replaces the scope-level state machine for regression handling
- [[ADR-030 Polycentric ASOT Authority Model]] — the polycentric framing that motivates methodology-neutrality (different orgs use different methodologies; the framework cooperates across)
- [[Engineering Lifecycle Stages]] — canonical documentation of the optional lifecycle primitive
- [[Analysis Layer Scope Algebra]] — `rtm:Scope` as a first-class RDF resource; the (optional) subject of `rtm:lifecycleStage`
- [[INCOSE V2 Review]] — INCOSE handbook contribution to `flexo-rtm`; lifecycle stages as one example among many
- [[Storage Layer Flexo Conventions]] — optional commit-metadata round-trip for lifecycle stage
- [[Verifiable Self-Certification]] — the structural-locality property the attestation-deprecation cascade exercises
- [[Transcript Replay Semantics]] — the per-fact replay path the deprecation-cascade detection dispatches over
- [[Gap Taxonomy]] — extended with T9 (deprecated attestation) and T10 (deferred attestation) per [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]
- [[Federated Audit and Composition]] — composition-scale criteria can optionally reference lifecycle stages when both composing parties use them
- [[ADR-003 Topological Framework Documented as Future Work]] — the research-phase deferral this remains distinct from
- INCOSE Systems Engineering Handbook + ISO/IEC/IEEE 15288 — one example lifecycle vocabulary, not the canonical one
- Closes flexo-rtm-research issue #6 (Engineering Lifecycle as first class concept) — revised: stages are optional metadata, methodology-neutral
- Closes flexo-rtm-research issue #8 (Don't force exploratory stage) — INCOSE/ISO 15288 stages are the example when used; never forced
