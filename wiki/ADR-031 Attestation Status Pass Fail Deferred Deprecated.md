<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-031: Attestation Status — Pass / Fail / Deferred / Deprecated

**Status:** Accepted
**Date:** 2026-05-18
**Deciders:** Michael Zargham
**Related:** [[ADR-021 Three Attestation Subclasses Ship in v0.1]]; [[ADR-025 Reproducibility is Structural and Local]]; [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]]; [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]]; [[Attestation Infrastructure in v0.1]]; [[Verifiable Self-Certification]]; [[Gap Taxonomy]]; [[Engineering Lifecycle Stages]]; [[Design Spec]] §4.3

## Context

v0.1's earlier design used `earl:result` (passed / failed / inapplicable / cantTell) as the outcome property on `rtm:Attestation`, supplemented by a separate `rtm:DeferredJudgment` concept for "engineer surfaced the judgment moment but hasn't resolved it." For **regression handling** — when an upstream change invalidates a downstream attestation — the design relied on a **scope-level lifecycle state machine** (per [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]]'s earlier framing): the scope falls back to an earlier lifecycle stage, and the v0.2 auto-rerun mechanism re-evaluates affected attestations against the new state.

That scope-level state machine violated the **methodology-neutrality axiom**. Making engineering lifecycle stages first-class metadata on every named graph privileges a specific lifecycle vocabulary (INCOSE / ISO/IEC/IEEE 15288). Real-world adopters use different lifecycle models — DO-178C DAL gates in airborne software, NASA Phase A–F, ISO 9001 process gates, Agile sprint cycles, MIL-STD-498 phasing, customer-program-specific milestones — and the framework should not require translation into INCOSE just to participate. Additionally, maintaining a state machine on every named graph added substantial complexity to the core ruleset for what is fundamentally a per-attestation regression-handling concern.

This ADR replaces the scope-level state-machine mechanism with a **four-state attestation status** vocabulary that operates at the attestation level. Lifecycle stages remain available — see the reframed [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]] — but as **optional** organizational-convenience metadata, not first-class state.

## Decision

v0.1 introduces **`rtm:attestationStatus`** as a required functional property on every `rtm:Attestation`, with four permissible values:

| Status IRI | Meaning |
|---|---|
| `rtm:status/pass` | Attestation is valid and the claim holds. Equivalent to `earl:passed`. |
| `rtm:status/fail` | Attestation is valid and the claim does not hold. Equivalent to `earl:failed`. |
| `rtm:status/deferred` | Engineer surfaced the judgment moment but has not yet resolved it. Subsumes the prior `rtm:DeferredJudgment` concept. |
| `rtm:status/deprecated` | Attestation existed and was valid, but is now invalidated by upstream changes. A new attestation is required. |

**EARL alignment** via SKOS exact-match (`rtm:status/pass skos:exactMatch earl:passed`; same for fail) preserves interop with EARL tooling. The `deferred` and `deprecated` states have no EARL analogues; they are RTM-native.

**Deprecation provenance.** When an attestation is marked `rtm:status/deprecated`, it SHOULD carry `prov:wasInvalidatedBy` (W3C PROV-O standard) referencing the activity, commit, or upstream change that invalidated it. This makes deprecation forensically traceable through the cert artifact.

**SHACL discipline.** The named-approver shape on `rtm:Attestation` is unchanged ([[ADR-021 Three Attestation Subclasses Ship in v0.1]] continues to govern). A new shape `rtm:AttestationStatusShape` requires `rtm:attestationStatus` (`sh:minCount 1`, `sh:in (rtm:status/pass rtm:status/fail rtm:status/deferred rtm:status/deprecated)`) on every `rtm:Attestation` instance.

**Cert pass criterion** (updated). A graph passes certification at scope S iff every required attestation in scope exists AND is in `rtm:status/pass`. The default behavior treats `fail`, `deferred`, and `deprecated` as cert-blocking; profiles `--profile=accept-deferred` and `--profile=accept-deprecated` allow adopters to relax for non-production cert runs.

**Gap codes** (extension to [[Gap Taxonomy]]):

- **T6.failed-attestation** — attestation with `rtm:status/fail`. Unchanged in spirit; vocabulary updated.
- **T9.deprecated-attestation** (new) — attestation with `rtm:status/deprecated` and no replacement attestation in scope. The audit report enumerates these with their `prov:wasInvalidatedBy` cause so the team knows what to re-attest.
- **T10.deferred-attestation** (new) — attestation with `rtm:status/deferred`. Always reported as informational; becomes cert-blocking when `--profile=no-deferred` is active.

**Lifecycle stages decoupled.** Engineering lifecycle stages remain available via the optional `rtm:lifecycleStage` vocabulary (per the reframed [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]]) for organizational convenience, but the core ruleset does NOT maintain a state machine on them. The regression-handling mechanism that previously rode on lifecycle-stage rollback now rides on attestation deprecation: when upstream changes invalidate a downstream claim, the affected attestation is marked `rtm:status/deprecated` with `prov:wasInvalidatedBy`, and the cert artifact surfaces it as a T9 gap with provenance.

## Consequences

### Positive

- **Methodology-neutral.** No adopter is forced into INCOSE / ISO 15288 lifecycle vocabulary. Programs using DO-178C, NASA Phase A–F, Agile, ISO 9001, or custom phasing participate on the same footing. The polycentric ASOT model ([[ADR-030 Polycentric ASOT Authority Model]]) extends naturally to methodology diversity: different orgs in a composition can use different lifecycle vocabularies (or none) without translating into a privileged one.
- **Simpler core ruleset.** No state machine on scopes in the core. The v0.2 work that previously included "lifecycle-aware regression handling" simplifies to "attestation deprecation cascade" — a more local, more inspectable mechanism.
- **Deprecation is provenance-traceable.** `prov:wasInvalidatedBy` is W3C PROV-O standard. Auditors can trace any deprecated attestation back to the change that deprecated it without `flexo-rtm`-specific tooling.
- **Attestation lifecycle is local to the attestation.** The status of a single attestation is determined by its own data (the four-state property and optional provenance), not by reference to a coordinating state machine. This is structurally consistent with the locality principle ([[ADR-025 Reproducibility is Structural and Local]]).
- **Federated audit composes cleanly across methodologies.** Org A using INCOSE stages and Org B using Agile sprints can both produce composable attestations because the attestation status vocabulary is common; only the (optional) lifecycle-stage tags differ.

### Negative / Tradeoffs

- **Some adopters may want scope-level lifecycle gates.** Programs that explicitly want to gate certifications on lifecycle stage transitions can still do so via optional profiles built on top of the lifecycle-stage vocabulary — but the framework does not ship that mechanism in core. Programs not wanting it are not paying for it.
- **Loses the "auto-rerun on scope rollback" affordance from the original ADR-029 design.** The equivalent mechanism is now "attestation deprecation cascade" — when upstream changes invalidate a downstream claim, dependent attestations are marked deprecated automatically (v0.2 work). The cascade is more local, but its design surface is different from a state machine.
- **Three new gap codes** (T9, T10 added; T6 vocabulary updated) require conformance test updates and audit-report rendering work.

### Neutral

- **`earl:result` becomes a parallel less-precise vocabulary.** Conformance with EARL tooling is preserved via SKOS exact-match for the two states that have EARL analogues. Tools consuming the RDF can choose either property; `rtm:attestationStatus` is canonical inside `flexo-rtm`.
- **`rtm:DeferredJudgment` is folded into `rtm:status/deferred`.** The standalone class is preserved for historical interop; new content uses the status value.

## Alternatives Considered

- **Keep the scope-level lifecycle state machine.** Rejected for methodology-neutrality reasons named in the Context. The framework should not privilege INCOSE / ISO 15288 over DO-178C, NASA, Agile, or custom phasing.
- **Use `earl:result` and add `rtm:isDeprecated` as an orthogonal axis.** Cleaner in some respects (judgment outcome vs. lifecycle status as separate dimensions), but the maintainer's framing is a single four-state union and adopting that framing simplifies the SHACL shape and the audit-report rendering. Orthogonal axes can be reintroduced later if needed.
- **Drop EARL alignment entirely.** Rejected — SKOS exact-match preserves interop with EARL tooling at trivial cost. There is no reason to break compatibility.
- **Extend EARL with new outcome values for `deferred` and `deprecated`.** Rejected — EARL is a W3C vocabulary `flexo-rtm` does not own. Adding values would create a parallel non-standard EARL that confuses both EARL consumers and `flexo-rtm` adopters. `rtm:attestationStatus` cleanly separates RTM-native states from W3C EARL.
- **Make deprecation a separate event entity (not a status on the attestation).** Rejected as adding a layer of indirection. A deprecation is conceptually a change in the attestation's status; modeling it as a status value (with PROV-O provenance) is direct.

## Implementation Notes

- **Vocabulary.** `rtm:attestationStatus` (owl:FunctionalProperty); four IRI-typed values under `rtm:status/`. SKOS concept scheme with `skos:exactMatch` to EARL for pass/fail.
- **SHACL.** `rtm:AttestationStatusShape` (separate from `rtm:AttestationShape` to keep the two enforcements independent). `sh:minCount 1`, `sh:in (...)`. Applies to all `rtm:Attestation` subclasses including the three v0.1 subclasses (satisfaction/adequacy/sufficiency per [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) and the federated-audit subclasses ([[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]]).
- **PROV-O.** `prov:wasInvalidatedBy` (W3C standard). For `rtm:status/deprecated` attestations, SHOULD be present; the strict profile `--profile=deprecated-requires-provenance` makes it MUST.
- **v0.2 deprecation cascade.** When upstream changes invalidate downstream claims, the oracle marks dependent attestations `rtm:status/deprecated` automatically and records `prov:wasInvalidatedBy` referencing the change. This replaces the lifecycle-state-machine auto-rerun mechanism in the original ADR-029 framing. The cascade detection uses SPARQL over the diff between commits (per [[Transcript Replay Semantics]]).
- **Migration from earlier text.** Pages that referenced "lifecycle state machine," "scope rollback," "fall-back to an earlier stage" now refer to "attestation deprecation cascade" with status `rtm:status/deprecated`. The user-facing semantics (recertification is prompted when prior work is invalidated) are preserved; the mechanism is more local.

## References

- [[Design Spec]] §4.3 (Attestation infrastructure — three subclasses); needs revision to add the four-state status vocabulary
- [[Attestation Infrastructure in v0.1]] — primary elaboration; updated to add the four-state section
- [[ADR-021 Three Attestation Subclasses Ship in v0.1]] — the subclass decision this orthogonally extends
- [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]] — reframed to "optional, methodology-neutral"
- [[Gap Taxonomy]] — updated for T6 vocabulary refinement and new T9 / T10 codes
- [[Verifiable Self-Certification]] — the cert pass criterion that consumes the four-state status
- [[Engineering Lifecycle Stages]] — methodology-neutral framing; INCOSE / ISO 15288 as one example
- [W3C PROV-O `prov:wasInvalidatedBy`](https://www.w3.org/TR/prov-o/#wasInvalidatedBy)
- [W3C EARL `earl:result`](https://www.w3.org/TR/EARL10-Schema/#OutcomeValue)
- [W3C SKOS `skos:exactMatch`](https://www.w3.org/TR/skos-reference/#mapping)
