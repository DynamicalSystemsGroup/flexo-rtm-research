<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Engineering Lifecycle Stages

> **Status — Optional scope metadata in v0.1; methodology-neutral.** INCOSE / ISO 15288 is one example lifecycle vocabulary; programs using DO-178C, NASA Phase A–F, ISO 9001, Agile, MIL-STD-498, or custom phasing tag scopes with their own vocabularies on the same footing. Regression handling is at the attestation level via [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]], not via scope-level state machines. Locked in the revised [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]].

## Motivation

Systems do not come into existence ex nihilo — they emerge from engineering work organized into phases. Programs adopt different vocabularies for those phases. INCOSE / ISO/IEC/IEEE 15288 names six (Concept, Development, Production, Utilization, Support, Retirement). DO-178C names Design Assurance Levels (A–E) gated by certification activities. NASA's project lifecycle names Phases A through F. ISO 9001 organizes work around process gates. Agile programs work in sprints with no top-level phase concept at all. MIL-STD-498 names a different progression again. Customer-program-specific milestone vocabularies are common in defence and aerospace primes.

An earlier framing of this page (and of [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]]) made lifecycle stages **first-class** scope metadata with a v0.2 state machine that drove gate relaxation and regression handling. Subsequent review identified that framing as violating the **methodology-neutrality axiom**: requiring a privileged lifecycle vocabulary on every named graph privileges INCOSE / ISO 15288 over alternatives real-world adopters use. The polycentric ASOT model ([[ADR-030 Polycentric ASOT Authority Model]]) is explicit that different organizations cooperate from different methodological starting points; the framework should provide a substrate, not a methodological lens.

Two design moves resolve this:

1. **Lifecycle stages become OPTIONAL** scope metadata. The `rtm:lifecycleStage` property is available; adopters tag scopes if it helps their organization. The framework imposes no requirement and ships no state machine. Adopters using INCOSE can adopt the INCOSE vocabulary module; adopters using DO-178C, NASA, Agile, ISO 9001, or anything else declare their own SKOS concept scheme. All vocabularies participate on the same footing.
2. **Regression handling moves to the attestation level** via [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]. When upstream changes invalidate a downstream claim, the affected attestation is marked `rtm:status/deprecated` with `prov:wasInvalidatedBy` recording the cause. The cert artifact surfaces deprecated attestations as **T9** gaps. This mechanism is local to the attestation, methodology-neutral, and does not require any scope-level lifecycle tracking.

The result is a tighter substrate: the framework ships vocabulary primitives and the attestation-status mechanism; adopters compose those into whatever methodology profile fits their program.

## The vocabulary (ships in v0.1, optional)

v0.1 ships the following vocabulary so adopters who *do* use a lifecycle vocabulary can tag scopes today:

| Term | Type | Role |
|---|---|---|
| `rtm:lifecycleStage` | `owl:ObjectProperty` | **Optional.** Asserts a scope's current lifecycle stage. Domain: `rtm:Scope` (and named-graph metadata per [[Storage Layer Flexo Conventions]] F4). Range: `skos:Concept` — any adopter-defined SKOS concept slots in. |
| `rtm:LifecycleStage` | `owl:Class` | Marker class for lifecycle stage IRIs. Subclass of `skos:Concept`. Optional. |
| `rtm:lifecycleStageRecordedAt` | `owl:DatatypeProperty` | `xsd:dateTime` of when the stage was assigned. Optional, useful as provenance. |
| `rtm:lifecycleStageTransition` | `owl:ObjectProperty` | Provenance of a stage transition. Subject: `rtm:Scope`. Object: a `rtm:LifecycleStageTransition` node carrying `prov:wasGeneratedBy`, `rtm:fromStage`, `rtm:toStage`, `rtm:approvedBy`, `prov:atTime`. |
| `rtm:LifecycleStageTransition` | `owl:Class` | A first-class transition event. May be configured as a target of the named-approver SHACL bottleneck under the optional `lifecycle-stage-transition-attested` profile. |

The core ontology does NOT impose a SHACL shape that requires `rtm:lifecycleStage` on `rtm:Scope` instances. The previously-proposed `--profile=lifecycle-stages-required` is removed. Programs that want lifecycle-stage tagging to be required build an adopter-specific profile.

## Example vocabularies (adopters pick one, or none)

The framework treats every lifecycle vocabulary as a SKOS concept scheme. An adopter declares the scheme they use in their own ontology module and tags scopes with its concept IRIs. The framework does not privilege any specific vocabulary; the examples below are illustrative.

### INCOSE / ISO 15288 (one example)

The six canonical stages from the INCOSE Systems Engineering Handbook and ISO/IEC/IEEE 15288 ship as an optional module `ontology/lifecycle/incose.ttl`:

| Stage IRI | INCOSE / ISO 15288 stage | Typical condition |
|---|---|---|
| `rtm:stage/concept` | Concept | Stakeholder needs identified; concept-of-operations forming; requirements being elicited and specified |
| `rtm:stage/development` | Development | Requirements specified; models built; design and integration evidence accumulating |
| `rtm:stage/production` | Production | System being produced or fielded |
| `rtm:stage/utilization` | Utilization | System in operational use; in-service evidence accruing |
| `rtm:stage/support` | Support | System maintained; modifications evaluated |
| `rtm:stage/retirement` | Retirement | System being decommissioned; legacy evidence preserved |

INCOSE adopters import the module and tag scopes with these IRIs. See [[INCOSE V2 Review]] for the SE-content alignment.

### Other lifecycle vocabularies adopters might declare

- **DO-178C DAL gates** (airborne software). Stages organized around Design Assurance Levels A through E and the certification activities at each level. A DO-178C adopter declares `do178c:dal-a`, `do178c:dal-b`, etc. as `skos:Concept` instances under their own scheme and tags scopes accordingly.
- **NASA Phase A–F** (mission lifecycle). Pre-Phase A (concept studies), Phase A (concept development), Phase B (preliminary design and technology completion), Phase C (final design and fabrication), Phase D (system assembly, integration, test, launch), Phase E (operations and sustainment), Phase F (closeout). NASA adopters declare `nasa:phase-a` through `nasa:phase-f`.
- **ISO 9001 process gates**. Programs organized around ISO 9001 quality management can tag scopes by the process stage their work is in (planning, doing, checking, acting; or finer-grained by the program's quality manual).
- **Agile sprint cycles**. Programs working in sprints tag scopes by the sprint identifier or by a sprint-status concept (`agile:sprint-in-progress`, `agile:sprint-review`, etc.). The vocabulary is whatever the team uses; the property is the same.
- **MIL-STD-498 phasing**. Software development phasing (system requirements analysis, system design, software requirements analysis, software design, etc.). Defence adopters tag scopes with the appropriate phase IRIs.
- **Customer-program-specific milestones**. Many primes track work against program-specific named milestones rather than a textbook lifecycle. The milestone names are the SKOS concepts; the property is the same.

A program-specific Turtle declaration:

```turtle
program:milestone/m3-pdr a skos:Concept ;
    rdfs:label "Program Milestone M3 — Preliminary Design Review" ;
    skos:inScheme program:lifecycle .

rtm:scope/adcs-attitude-control a rtm:Scope ;
    rtm:lifecycleStage program:milestone/m3-pdr ;
    rtm:lifecycleStageRecordedAt "2026-05-17T10:00:00Z"^^xsd:dateTime .
```

Nothing in the framework cares that `program:milestone/m3-pdr` is not an INCOSE stage. The property accepts any `skos:Concept`. The audit-report rendering shows whatever label the adopter declares.

## Regression handling — at the attestation level

Earlier framing of this page sketched a **lifecycle state machine** with fall-back triggers, auto-rerun handling on stage rollback, and a stage-aware re-cert prompt. That mechanism is removed. The reasons are in [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]:

- The state machine required a privileged lifecycle vocabulary to operate over, which violated methodology-neutrality.
- The regression-handling concern is fundamentally per-attestation: "this specific claim was invalidated by this specific upstream change." Treating it at the attestation level is more local, more inspectable, and methodology-agnostic.
- The mechanism uses W3C standard provenance (`prov:wasInvalidatedBy`) and standard SKOS-aligned status vocabulary, both consumable without `flexo-rtm`-specific tooling.

Regression handling in v0.1 works as follows:

- When upstream changes invalidate a downstream attestation, the affected attestation is marked `rtm:status/deprecated` with `prov:wasInvalidatedBy <change-iri>`. The change IRI references the activity, commit, or upstream resource whose change invalidated the claim.
- The cert artifact surfaces deprecated attestations as **T9.deprecated-attestation** gaps per [[Gap Taxonomy]]. Each gap row carries the provenance so the team knows what to re-attest.
- A new attestation, written by the appropriate named approver, replaces the deprecated one. The historical attestation remains in the audit graph as a record of the prior state.

The v0.2 work on this mechanism is the **deprecation cascade**: when an upstream change deprecates one attestation, dependent attestations should be marked deprecated automatically. The cascade detection uses SPARQL over the diff between commits (per [[Transcript Replay Semantics]]) to identify which downstream attestations are affected. There is no scope-level state machine; the cascade operates over the attestation graph directly.

See [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] for the locked design and [[Attestation Infrastructure in v0.1]] §"Attestation status — the four-state vocabulary" for the surfacing in the v0.1 attestation infrastructure.

## Gate relaxation — adopter-built profiles, not core

A program may legitimately want to gate certifications differently at different lifecycle stages — for example, treating T1 (orphan-requirement) and T2 (dangling-evidence) as informational while requirements are still being elicited, then turning them on as blocking once requirements are specified. The framework's posture on this:

- The substrate is shipped: `rtm:lifecycleStage` as a scope property, `skos:Concept` as the range, the gap-code vocabulary in [[Gap Taxonomy]], and the composable SHACL profile mechanism (per [[Profile Mechanism]]).
- A program that wants stage-aware gate relaxation builds an adopter-specific SHACL profile that queries `rtm:lifecycleStage` and conditionally relaxes T-code severity. The policy is the adopter's.
- The framework does NOT ship a privileged lifecycle-gate profile. There is no built-in `--profile=lifecycle-stages-required`, no built-in "T1 informational at Concept stage" rule, no built-in stage-severity matrix. Programs not wanting these are not paying for them.

This is the substrate-not-policy posture that the methodology-neutrality axiom requires. The framework provides the primitives; adopters compose them into the policy that fits their program.

## Worked examples

### Example using INCOSE / ISO 15288 stages

A program using INCOSE / ISO 15288 stages tags a power-subsystem scope as `rtm:stage/concept` while the team is framing the problem and eliciting stakeholder requirements. The team chooses (in an adopter-built profile) to treat T1 and T2 as informational at the Concept stage; their profile reads `rtm:lifecycleStage` and dispatches T-code severity accordingly.

As requirements firm up, the team commits a stage transition to `rtm:stage/development`. The transition is recorded as a `rtm:LifecycleStageTransition` with the lead engineer's `rtm:approvedBy` IRI. The adopter-built profile now treats T1 and T2 as blocking. T3–T5 and T8 apply per their separately-active profiles.

Later, a new requirement is added — a late-breaking thermal constraint. This change invalidates the prior adequacy attestation on the (now-affected) artifact. The oracle marks that adequacy attestation `rtm:status/deprecated` with `prov:wasInvalidatedBy <commit-iri>`. The audit report enumerates the deprecated attestation as a T9 gap with the commit IRI as provenance. The engineer writes a new adequacy attestation that accounts for the thermal constraint; the cert artifact records both the prior (deprecated) and the new (pass) attestations, making the temporal trajectory honest.

The scope's `rtm:lifecycleStage` does not change as a result of the regression handling. The team may *choose* to transition the scope back to an earlier stage as an organizational signal, but that transition is a separate, audited event — not an automatic consequence of the attestation deprecation.

### Example using DO-178C DAL gates

A program developing airborne software uses DO-178C DAL gates. Their scope vocabulary uses DAL concepts:

```turtle
do178c:dal-b a skos:Concept ;
    rdfs:label "Design Assurance Level B" ;
    skos:inScheme do178c:dal-scheme .

rtm:scope/flight-control-software a rtm:Scope ;
    rtm:lifecycleStage do178c:dal-b .
```

The team has an adopter-built profile that activates more rigorous attestation requirements at DAL B than at DAL D (e.g., requiring sufficiency attestations on every requirement, not just safety-critical ones). The profile reads `rtm:lifecycleStage` and dispatches profile activations accordingly.

When a DO-178C objective is found unmet by a regulator review, the affected attestation is marked `rtm:status/deprecated` with `prov:wasInvalidatedBy <review-finding-iri>`. T9 surfaces it; the team re-attests. The scope's DAL classification does not change unless the team explicitly transitions it.

The same framework, the same attestation status mechanism, a completely different lifecycle vocabulary. This is what methodology-neutrality means in practice.

## What v0.1 ships

**Vocabulary:**

- `rtm:lifecycleStage` (optional object property, range `skos:Concept`).
- `rtm:LifecycleStage` (marker class for lifecycle stage IRIs; subclass of `skos:Concept`).
- `rtm:lifecycleStageRecordedAt` (optional datatype property).
- `rtm:lifecycleStageTransition`, `rtm:LifecycleStageTransition`, `rtm:fromStage`, `rtm:toStage` (transition vocabulary).
- The optional `ontology/lifecycle/incose.ttl` module with the six INCOSE / ISO 15288 stage IRIs and `skos:closeMatch` alignment to the INCOSE handbook IRIs (per [[INCOSE V2 Review]]).

**SHACL:**

- NO required shape on `rtm:Scope` for `rtm:lifecycleStage`. The previously-proposed `--profile=lifecycle-stages-required` is removed.
- Optional `lifecycle-stage-transition-attested` profile that, when active, requires a named approver on every `rtm:LifecycleStageTransition`.

**Commit metadata:**

- Optional capture of `rtm:lifecycleStage` per [[Storage Layer Flexo Conventions]] F4. Only useful if the adopter is using a lifecycle vocabulary; absent otherwise.

**Regression handling (in core):**

- The four-state attestation status vocabulary per [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] and [[Attestation Infrastructure in v0.1]].
- T9.deprecated-attestation and T10.deferred-attestation gap codes per [[Gap Taxonomy]].
- `prov:wasInvalidatedBy` (W3C PROV-O standard) on deprecated attestations.

## What v0.2 ships

**Attestation deprecation cascade.** When an upstream change deprecates one attestation, the oracle detects dependent attestations and marks them `rtm:status/deprecated` automatically, recording `prov:wasInvalidatedBy` referencing the change. The cascade detection uses SPARQL over the diff between commits. This is the locked v0.2 mechanism per [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]].

**NOT a lifecycle state machine.** The earlier roadmap commitment to a v0.2 lifecycle state machine, stage-aware gate dispatch, fall-back triggers, and auto-rerun on scope rollback is removed. Programs that want stage-gate relaxation build adopter-specific profiles on the v0.1 vocabulary substrate; the framework does not ship that mechanism.

## Open questions

These remain open for adopter-specific design and (where relevant) community-extension work — none are blocking v0.1:

- **Stage-transition authority.** Who can move a scope from one stage to another? When an adopter records transitions, the named-approver pattern from [[Identity Boundaries and Policy Projections]] applies; the exact policy shape is the adopter's.
- **Adopter-specific gate-relaxation policies.** Programs may want finer-grained control — per aspect, per T-code, per stage — in their own profiles. The framework provides the substrate; the policy lives in adopter ontology modules.
- **Federated audit across methodologies.** When parties to a federated audit use different lifecycle vocabularies, the composition criteria reference the parties' vocabularies separately or do not reference lifecycle at all. See [[Federated Audit and Composition]] for the composable criteria.
- **Cross-scope deprecation cascade design.** The v0.2 cascade detection design is open — exact SPARQL pattern, sequencing, and the user-facing surface in the audit report. Locked in [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] as the v0.2 mechanism; design specifics are v0.2 implementation work.

## Cross-references

- [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]] — locked decision (revised) making lifecycle stages optional metadata.
- [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] — locked decision moving regression handling to the attestation level.
- [[ADR-030 Polycentric ASOT Authority Model]] — the methodology-neutrality motivation comes from the polycentric framing.
- [[Attestation Infrastructure in v0.1]] — the four-state attestation status vocabulary that handles regression locally.
- [[Gap Taxonomy]] — T9 (deprecated-attestation) and T10 (deferred-attestation) gap codes.
- [[INCOSE V2 Review]] — INCOSE / ISO 15288 as one example lifecycle vocabulary; SE-content alignment via `skos:closeMatch`.
- [[Analysis Layer Scope Algebra]] — `rtm:Scope` as a first-class RDF resource; the (optional) subject of `rtm:lifecycleStage`.
- [[Storage Layer Flexo Conventions]] — optional commit-metadata round-trip for lifecycle stage.
- [[Federated Audit and Composition]] — composition criteria may reference an adopter's lifecycle vocabulary when both parties use one.
- [[Profile Mechanism]] — composable SHACL profiles; the substrate adopters use to build stage-aware gate policies.
- [[Topological Framework Future Work]] — the research-phase deferred framework, distinct in timeline and concern.
- [[Design Spec]] §5 (Three-Layer Architecture and scope semantics); §9.A.1 F4 (scope metadata round-trip; lifecycle stage now optional).
