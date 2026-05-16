<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Quantitative Outcomes

> What `flexo-rtm` v0.1 actually reports when an audit run finishes — coverage percentages along every active dimension, gap counts by T-code, and a configurable binary view *derived from* those metrics. The audit report never collapses to a single rolled-up "% certified" number; that prohibition is normative ([[Design Spec]] §9.A.5 **X3**). The quantitative-first stance is locked decision **D4**, and the configurable binary view is locked decision **D19**.

## Why quantitative, not pass/fail

Pass/fail is fine for a paper. It is not fine for a 4,000-requirement program where the safety subsystem moved from 60 % adequacy coverage to 78 % adequacy coverage commit-over-commit, while the human-factors subsystem regressed from 91 % to 84 % because two approvers left the team. A single boolean cannot tell anyone what to do next; a gradient can.

Institutional adoption of a traceability discipline depends on the gradient. Engineers need to see *where* coverage is incomplete and *which* direction the trend is moving. Programme managers need to see which subsystems are converging and which are falling behind. Auditors need to see exactly which requirements lack incoming `rtm:satisfies` edges and exactly which `rtm:satisfies` triples lack named-approver attestations. None of that information survives the rollup to a single percentage. The whole point of `flexo-rtm` is to surface that structure, not erase it.

The paper Zargham (2026) formulates certification as a TDD-style boolean — every face closed, every node attested, certificate issued or not. The industrial reality, captured in [[ADCS Prototype Lessons]], is incremental: coverage improves trace-by-trace, attestation-by-attestation, sprint-by-sprint. Locked decision **D4** reconciles the two — quantitative outcomes are primary, the binary view (per **D19**) is *derived* from them with a configurable threshold so a team can choose when to call themselves "certified."

## v0.1 coverage metrics

Every metric below is a fraction over a scoped population. Scope is defined by the [[Analysis Layer Scope Algebra]]: a subgraph chosen by repository slice, namespace, or aspect filter.

### Traditional bidirectional coverage

These are the two metrics every RTM tool from DOORS onward has reported. v0.1 reports them whether or not any attestation profile is active.

- **Forward coverage %** = (Requirements with ≥1 incoming `rtm:satisfies` edge) / (total Requirements in scope)
- **Backward coverage %** = (Artifacts with ≥1 outgoing `rtm:satisfies` edge) / (total non-foundational Artifacts in scope)

"Non-foundational" excludes leaf artifacts marked `rtm:isFoundational true` — the explicit terminators of recursive descent ([[External URI References]]). Counting them as backward-uncovered would generate noise.

The full mechanics — what gets counted, what gets excluded, the SPARQL forms — are in [[Traditional Forward and Backward Analysis]].

### Per-attestation-kind coverage (profile-gated)

When one of the attestation profiles is active, an additional coverage metric becomes meaningful for that kind. Each is reported only when its profile is on; otherwise the metric is omitted from the audit report rather than reported as 100 %, to avoid implying coverage was checked when it wasn't.

- **Satisfaction-attestation coverage** (when `attested-satisfies` is active) = (`rtm:satisfies` triples with a corresponding `rtm:SatisfactionAttestation`) / (total `rtm:satisfies` triples in scope)
- **Adequacy-attestation coverage** (when `attested-adequacy` is active) = (`rtm:satisfies` triples with an `rtm:AdequacyAttestation` for the artifact) / (total `rtm:satisfies` triples in scope)
- **Sufficiency-attestation coverage** (when `attested-sufficiency` is active) = (`rtm:satisfies` triples with an `rtm:SufficiencyAttestation` for the artifact) / (total `rtm:satisfies` triples in scope)

The three are separable — a programme can adopt them in any order. The class hierarchy and approver-required SHACL shape backing each kind are documented in [[Attestation Infrastructure in v0.1]].

### Per-aspect-per-claim-type matrix coverage

When the `aspect-coverage` profile is active, every multi-aspect requirement (one tagged with `rtm:hasAspect` values such as `safety`, `human-factors`, `performance`) is checked aspect-by-aspect and claim-type-by-claim-type. The report renders this as a two-dimensional matrix:

- Rows: aspects declared on requirements in scope (`safety`, `security`, `human-factors`, …)
- Columns: claim types (satisfaction, adequacy, sufficiency)
- Each cell: (attestations present for that aspect × that claim type) / (declared aspects × required claim-types for that aspect)

The matrix view is the principal audit display when `aspect-coverage` is active because it shows the engineer exactly which (aspect, claim-type) cells are open. A 92 % overall adequacy number can hide a 0 % safety-adequacy column; the matrix cannot. The full semantics — what "declared" means for an aspect, how multi-aspect requirements decompose — are in [[Aspect Coverage with Adequacy and Sufficiency]].

## v0.1 gap counts

The audit report enumerates open gaps by T-code ([[Design Spec]] §4.4, [[Gap Taxonomy]]).

| Code | Reported in v0.1? | Profile dependency |
|---|---|---|
| `T1.orphan-requirement` | Always | None |
| `T2.dangling-evidence` | Always | None |
| `T3.unattested-satisfaction` | When active | `attested-satisfies` |
| `T4.unattested-adequacy` | When active | `attested-adequacy` |
| `T5.unattested-sufficiency` | When active | `attested-sufficiency` |
| `T6.failed-attestation` | Always (whenever any attestation profile is active) | Any attestation profile |
| `T7.unapproved-attestation` | **Structurally absent** | SHACL rejects at write — cannot exist in stored graph |
| `T8.aspect-uncovered` | When active | `aspect-coverage` |

`T7` deserves the emphasis. SHACL shapes on each attestation subclass require `rtm:approvedBy` at write time. A graph containing an unapproved attestation cannot be persisted, so the audit will never see one and so cannot count one. The "by construction" property — accountability enforced by the schema rather than by reviewer diligence — is the reason `T7` lives in the enumeration only for code-completeness.

Each gap is reported with its subject IRI(s), the rule that flagged it, and any contextual metadata (aspect, claim type, approver-missing diagnostic). Programmes consume the enumeration as a worklist.

## Configurable thresholds

Each coverage metric has an associated threshold. The audit configuration file sets them; defaults err toward strict (100 %) because the gradient story is about choosing your own bar and reporting where you are against it.

| Threshold | Default | Active when |
|---|---|---|
| `θ_forward` | 100 % | Always |
| `θ_backward` | 100 % | Always |
| `θ_sat_attest` | 100 % | `attested-satisfies` |
| `θ_adequacy_attest` | 100 % | `attested-adequacy` |
| `θ_sufficiency_attest` | 100 % | `attested-sufficiency` |
| Per-aspect-per-claim-type thresholds | 100 % | `aspect-coverage` |

A programme that has just turned on `attested-adequacy` may legitimately set `θ_adequacy_attest = 30 %` for the first sprint and increment it as the discipline catches up. The threshold is policy. The measurement is structural.

## The derived binary view (D19)

The single boolean that the paper formulates is recoverable as a **derivation over the quantitative metrics**:

`certified == True` if and only if all of the following hold:

- `forward ≥ θ_forward` AND `backward ≥ θ_backward`
- AND (if `attested-satisfies` is active) `satisfaction_attest_coverage ≥ θ_sat_attest`
- AND (if `attested-adequacy` is active) `adequacy_attest_coverage ≥ θ_adequacy_attest`
- AND (if `attested-sufficiency` is active) `sufficiency_attest_coverage ≥ θ_suff_attest`
- AND (if `aspect-coverage` is active) every per-aspect-per-claim-type cell ≥ its threshold
- AND **zero `T6.failed-attestation`** — non-configurable

`T6` is the only non-configurable gate. A failed attestation (`earl:result earl:failed`) is a named human saying "no" on the record. No threshold can erase that; it must be resolved (either by re-attestation or by removing the underlying triple from scope) before a programme can claim certification. This is the structural minimum the paper's pass/fail discipline cashes out to.

The derived boolean appears in the audit report top-line as PASS or FAIL, with the threshold configuration printed alongside it so any reader sees what bar was used. Locked decision **D19** is explicit: the binary view is *derived* from the quantitative metrics, never the other way around. A programme that wants to publish only the boolean is welcome to; the per-dimension metrics still must appear in the audit report itself, because **X3** prohibits collapsing them away.

## The principal audit-report views

Every v0.1 audit report carries these sections in this order. The shape is enforced by `tests/conformance/test_audit_report_shape.py` referenced in [[Design Spec]] §9.A.5.

**Top-line.** PASS/FAIL from the derived binary view, plus the active profile set, plus the threshold configuration. No rolled-up percentage.

**Section 1 — Coverage table.** Forward % and backward % unconditionally; satisfaction/adequacy/sufficiency attestation coverage each on their own row when the corresponding profile is active. Each row carries its threshold and a met/not-met indicator. No row averages with another.

**Section 2 — Aspect × claim-type matrix** (only when `aspect-coverage` is active). The full matrix as defined above, rendered as a table. Each cell is a fraction and a met/not-met indicator against its per-cell threshold.

**Section 3 — Gap enumeration.** T1–T8 (minus T7), each as a list with subject IRIs and contextual detail. Programmes work this list directly.

**Reproducibility manifest.** External URIs, projection-at-cert-time, signature inventory ([[Design Spec]] §4.9). Carried in every audit report regardless of profile.

## A practitioner-adoption story

The metrics enable graduated adoption. A typical industrial trajectory:

**Day 1.** Programme imports their existing OSLC-RM data via the v0.1 adapter ([[OSLC RM and QM Review]]) and runs `certify` with no profiles active. Output is forward % + backward % + `T1` / `T2` enumeration — equivalent in information content to a DOORS RTM report. No new discipline asked of the team. Coverage gaps become a worklist; the trend over weeks of commits becomes the management metric.

**Day 30.** Programme enables `attested-satisfies`. Engineers start capturing named-approver attestations on `rtm:satisfies` triples through their existing review workflow. `T3` count begins to drop as the discipline catches on. The audit report grows a satisfaction-attestation-coverage row; the team chooses `θ_sat_attest = 50 %` as a near-term bar and tightens it quarterly.

**Day 90.** Programme enables `attested-adequacy` and `attested-sufficiency`, then turns on `aspect-coverage` once enough requirements are aspect-tagged. The matrix view appears. The safety officer sees the safety-adequacy column lighting up; the human-factors lead sees their own column. Coverage discussions move from generalities to specific cells.

**Day 365.** Full attestation discipline. All four thresholds at 100 %. Failed-attestation count tracked as a leading indicator. The team is now ready to opt into the deferred topological framework when it ships — the underlying typed attestations already exist; what changes is the addition of the closed-assurance-face gate and the V−F invariant. The transition is additive; no historical data has to be re-captured.

The story is not aspirational. Each step is a configuration change against the same v0.1 schema, executed in the same audit pipeline. The gradient is the institutional gift.

## What v0.1 does NOT compute

The following metrics belong to the deferred topological framework ([[Design Spec]] §4.10) and are out of scope for v0.1. Listing them here exists to draw the boundary explicitly so adopters do not expect them.

- **Assurance-face closure rate.** The fraction of (requirement, artifact, guidance, satisfaction-attestation, adequacy-attestation, sufficiency-attestation) tuples that form a closed face. Needs the topological face structure, not yet defined for v0.1.
- **V−F invariant.** The vertices-minus-faces structural invariant from Zargham (2026). Requires the closed-face notion.
- **Recursive completeness depth.** "Does the adequacy/sufficiency guidance itself meet adequacy and sufficiency standards?" Requires the registry-driven recursive descent and the foundational-leaf terminator semantics. Specified in [[External URI References]] but the audit is deferred.
- **Persistent homology over commit sequence.** Topological tracking of how the certification structure evolves over time. Research-stage.

None of these are claimed in any v0.1 audit report. None of the v0.1 coverage metrics depend on them.

## Why the audit report shows no single "% certified" number

[[Design Spec]] §9.A.5 **X3** is normative and uncompromising: no `flexo-rtm` audit report may contain a single rolled-up "% certified" figure. The rationale is technical, not aesthetic.

- A rolled-up number **conflates different gap types** — a 92 % composite cannot be inverted into "missing 8 % is what?" Without the disaggregation, no one knows what to do.
- A rolled-up number **breaks comparability across configurations** — two programmes with different active profiles cannot have their composites meaningfully compared.
- A rolled-up number **invites Goodhart-style optimization** — once a single number is the target, the cheapest way to raise it is to game the lowest-weighted component.
- **Per-dimension metrics preserve actionability** — every uncovered requirement, every unattested triple, every uncovered aspect-cell is independently locatable from the audit report.
- **The matrix view is best** — for aspect-coverage adopters, the matrix is the maximally informative display: every open cell is a specific (aspect, claim-type) work item.

The derived binary view per **D19** is the only allowed aggregation, and even it cannot stand without the per-dimension metrics shown alongside it in the report. Auditors, programme managers, and engineers each get the slice of information they need at the granularity they need it.

## See also

- [[Design Spec]] §4.4 (gap codes), §4.7 (gap taxonomy prose), §9.A.5 (cross-cutting acceptance criteria including **X3**), §14 (locked decisions **D4** and **D19**)
- [[Certification Predicate]] — the derived-binary derivation in formal form
- [[Gap Taxonomy]] — full T1–T8 reference
- [[Attestation Infrastructure in v0.1]] — the three typed attestation subclasses and their SHACL shapes
- [[Aspect Coverage with Adequacy and Sufficiency]] — semantics of the matrix view
- [[Traditional Forward and Backward Analysis]] — forward/backward mechanics and the legacy-tool reporting form
- [[Analysis Layer Scope Algebra]] — how "in scope" gets defined for any coverage metric
