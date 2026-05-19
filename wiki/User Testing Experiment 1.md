<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# User Testing Experiment #1 — Engineer skill walkthrough on the ADCS arc

> **Status:** First live user-acceptance walkthrough of the
> [`flexo-rtm` skills layer](https://github.com/dynamicalsystemsgroup/flexo-rtm/tree/main/.claude/skills)
> against the [ADCS-lifecycle-demo](https://github.com/dynamicalsystemsgroup/ADCS-lifecycle-demo)
> arc. Conducted 2026-05-19. One human user playing the engineer
> role; one LLM running the `flexo-rtm-engineer` catechism + invoking
> the `flexo-rtm constructor` CLI under the two-gate
> verbatim-reflection contract.

## Why this experiment

The skills layer + CLI shipped as v0.1 (constructor + four
role-scoped skills + UAT walkthroughs in
[`tests/acceptance/`](https://github.com/dynamicalsystemsgroup/flexo-rtm/tree/main/tests/acceptance)).
The fixture-based tests (221 passing) validate the CLI's mechanical
correctness. They do NOT validate that the *catechisms* produce
sensible engineering RDF when driven by a real engineer making
real judgement calls. This experiment is the first attempt to do
that.

The pre-existing walkthrough doc
([`01-engineer-walkthrough.md`](https://github.com/dynamicalsystemsgroup/flexo-rtm/blob/main/tests/acceptance/01-engineer-walkthrough.md))
was treated as a script; deviations from the script are the
interesting findings.

## Scope actually covered

The walkthrough was paused after completing **REQ-001's
pre-commitment layer**. Specifically what landed in the session's
TriG state file:

| Entity | IRI | Notes |
|---|---|---|
| 1 Requirement | `https://rtm.example/adcs/REQ-001` | Pointing Accuracy. Statement refined mid-walkthrough to be the bare claim only (envelope details moved out) |
| 1 Model artifact (structural) | `https://rtm.example/adcs/MOD-STRUCTURAL` | satellite.ttl + parameters.ttl @ ADCS-lifecycle-demo commit `5bb6886713a31c22d2cf474b0e20c41d0ab03282` |
| 1 Model artifact (symbolic) | `https://rtm.example/adcs/MOD-BEHAVIORAL-SYMBOLIC` | analysis/symbolic.py @ same commit |
| 1 Model artifact (numerical) | `https://rtm.example/adcs/MOD-BEHAVIORAL-NUMERICAL` | analysis/numerical.py @ same commit |
| 1 Adequacy attestation | `urn:rtm:attest/545383f2-…` | appliesTo MOD-BEHAVIORAL-SYMBOLIC; pre-commitment; reason text carries simplifying assumptions |
| 1 Adequacy attestation | `urn:rtm:attest/39885356-…` | appliesTo MOD-BEHAVIORAL-NUMERICAL; pre-commitment; reason text carries simplifying assumptions + complementarity-with-symbolic note |
| 1 Sufficiency attestation | `urn:rtm:attest/5336744a-…` | appliesTo REQ-001; conjunctive pre-commitment naming both upstream adequacy claims |

**Total:** 7 writes through 14 verbatim-reflection gates (7×GATE-1
pre-execution + 7×GATE-2 post-execution read-back). Every gate
passed without rejection or correction; the engineer-skill's
proposed reason text was confirmed verbatim in each case.

**Approver IRI** for all attestations:
`urn:rtm:engineer/d94ecc77c4f6d72f` (deterministic hash of
`git config user.email`).

## What was NOT covered (parked for Experiment #2 or later)

- **REQ-002 / REQ-003 / REQ-004 pre-commitment layers.** Same shape
  expected as REQ-001 but each carries its own claim-specific
  simplifying assumptions; REQ-003 has only symbolic evidence (no
  numerical sim), making it a useful contrast.
- **Evidence artifacts** (`EV-PROOF-REQ-N`, `EV-SIM-REQ-N`). These
  are the post-experimental outputs and need separate registration.
- **Satisfaction attestations.** Including the deliberately-failed
  REQ-001 case from the prototype, where the actual sim's narrow
  envelope makes the deterministic-sim + symbolic-stability
  combination insufficient for the 3-sigma claim. The sufficiency
  pre-commitment's "Critical limitation acknowledged at
  pre-commitment time" clause pre-positions this exact failure.
- **Reviewer / Auditor / Reconcile skill walkthroughs.** Only the
  engineer skill was exercised. Cross-skill routing was discussed but
  not exercised live.

## What we learned

Eight findings, each one filed as an issue. The findings fall into
two clusters: **ontology gaps** (vocabulary that doesn't yet
express engineering primitives the work actually demands) and
**workflow gaps** (catechism or CLI surface gaps).

### 1. The walkthrough's order of operations was wrong

The walkthrough doc scripted adequacy + sufficiency attestations
AFTER artifacts in Act 5. The engineer correctly flagged that
adequacy and sufficiency are **pre-commitments** — design-time
judgements made BEFORE the evidence is produced. Only satisfaction
is properly retrospective. Filed as
[**research-repo #31**](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/31).
The walkthrough re-ordered itself mid-flight to capture
pre-commitments at design time.

### 2. Two kinds of artifact, not one

There are **model artifacts** (design-time: code, structural specs)
and **evidence artifacts** (experimental-time: simulation outputs,
proof results). Adequacy attestations bind to model artifacts;
sufficiency / satisfaction attestations bind to evidence artifacts.
v0.1 has a single undifferentiated `rtm:Artifact` class. Filed as
[**research-repo #32**](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/32).

### 3. Adequacy ≠ sufficiency at the content level

Within an adequacy attestation, the reason text holds **simplifying
assumptions about the model** (rigid body, gravity-gradient-only,
no flex). Within a sufficiency attestation, the reason text holds
**threshold criteria + evaluation methods** (settling within 120 s,
evaluated by deterministic IVP integration). v0.1 collapses both
into `rdfs:comment` prose — neither queryable. Filed as
[**research-repo #30**](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/30).

### 4. Operational envelopes need first-class vocabulary

The original SysMLv2 REQ-001 text used "under nominal disturbance
conditions" — a placeholder phrase that hides a load-bearing
engineering decision (what's the disturbance envelope?). Same
pattern for mission phases, performance regimes, failure modes
considered. v0.1 buries all of these in `rdfs:comment` text. Filed
as [**research-repo #29**](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/29).

### 5. Independent corroborating evidence is structural

REQ-001 needs BOTH a symbolic stability proof AND a numerical
settling-time simulation — neither alone is adequate evidence; the
two methods corroborate each other under matched assumptions. The
sufficiency attestation is therefore a **conjunctive claim**
("both lines together are sufficient"). v0.1 has no structural way
to express conjunction — it lives in reason text. Covered by
[**research-repo #32**](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/32)
(the proposed `rtm:byMeansOf` repeatable predicate generalizes to
conjunctive evidence references).

### 6. Cross-attestation dependencies are load-bearing for audit

The numerical adequacy claim conceptually DEPENDS on the symbolic
adequacy claim ("settling time is meaningless without convergence").
That dependency is currently captured ONLY in prose. When the
deprecation flow fires on an upstream attestation, downstream
attestations don't auto-propagate. Audit-side propagation is the
framework's main correctness mechanism for evolving judgements;
without structural dependency vocabulary it can't operate
automatically. Filed as
[**research-repo #34**](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/34).

### 7. Reason text needs externalization for security-sensitive adopters

For defense / proprietary / privacy-sensitive engineering, the
reasoning text in attestations is frequently classified or
competitive. The RDF graph (IRI shape, dependencies, approver
identity) can be auditable across organizational boundaries; the
text content cannot. Need content-addressed references (CIDs) with
org-controlled dereferencing. Filed as
[**research-repo #33**](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/33).

### 8. Identity binding needs to be visible

The engineer had to ask "what IRI am I about to bind to my
attestations?" — and the answer required invoking the Python
function manually. Should be one CLI call (`flexo-rtm constructor
whoami`), surfaced as the first action when the engineer skill is
invoked. Filed as
[**flexo-rtm #8**](https://github.com/DynamicalSystemsGroup/flexo-rtm/issues/8)
(impl repo — primarily a CLI + skill ergonomics gap).

## Issues surfaced (full index)

Research repo (vocabulary / ontology / design):

- [#29](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/29) — Operational envelopes (and similar requirement preconditions) need first-class vocabulary
- [#30](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/30) — Distinguish simplifying-assumptions (adequacy) from threshold-criteria (sufficiency) in attestation vocabulary
- [#31](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/31) — Adequacy + sufficiency are pre-evidence commitments, not post-hoc judgments — temporal partition
- [#32](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/32) — Distinguish model artifacts (design-time) from evidence artifacts (experimental-time); adequacy binds to models, sufficiency/satisfaction bind to evidence
- [#33](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/33) — Sensitive text fields (rdfs:comment, attestation reasons) need content-addressed externalization with org-controlled dereferencing
- [#34](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/34) — Cross-attestation dependencies need first-class RDF, not narrative prose

Impl repo (CLI / skill / catechism):

- [flexo-rtm #8](https://github.com/DynamicalSystemsGroup/flexo-rtm/issues/8) — Identity helper: `flexo-rtm constructor whoami` for deterministic + reproducible identity binding surfacing

## Synthesis

### The vocabulary is the bottleneck, not the workflow

The framework's CORE WORK — the two-gate verbatim-reflection
contract, role-scoped catechisms, the constructor CLI, the
storage layer — held up cleanly through every gate. No flow-control
failure, no spurious automation, no LLM hallucination in the RDF
output. The pressure was uniformly on the **vocabulary**: the
engineer had nuanced things to say that the ontology had no
structural slot for, and so they ended up in prose.

This is a useful finding. It says: the immediate v0.2 work is
ontology, not CLI. The CLI handles whatever we throw at it; the
ontology determines what's worth throwing.

### Six issues, one underlying theme

Issues #29–#34 all describe the same engineering ontology from
different angles:

- #29 — what preconditions a requirement holds under
- #30 — partition of justification content (assumptions vs criteria)
- #31 — when in the workflow attestations are made
- #32 — what kind of artifact an attestation binds to
- #33 — how sensitive textual content lives outside the graph
- #34 — how attestations depend on each other

A **GSN-aligned resolution** (`gsn:Argument`, `gsn:Assumption`,
`gsn:Justification`, `gsn:Context`, `gsn:supportedBy`,
`gsn:inContextOf`) resolves all six together. OntoGSN is named in
[`MVC Pattern from RIME TRL ANT`](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/wiki/MVC-Pattern-from-RIME-TRL-ANT)
as a candidate integration ontology; v0.1 didn't extract it. v0.2
adding the OntoGSN extract to the parsimony manifest probably
unblocks the structural work these issues collectively demand.

### Pre-commitment is the right primary mode

The walkthrough's mid-flight reordering (capturing
adequacy + sufficiency BEFORE artifacts and evidence) felt
natural to the engineer immediately. The original "register
artifacts then attest about them" order was a documentation
artifact, not a workflow truth. Pre-commitment attestations are
how engineers actually think — "I commit to this approach; we'll
see if the evidence meets the commitments."

This has implications beyond ontology: the engineer skill's
default catechism flow should lead with pre-commitments after
requirement registration, NOT wait until after evidence is in
hand. The walkthrough docs at
[`tests/acceptance/`](https://github.com/dynamicalsystemsgroup/flexo-rtm/tree/main/tests/acceptance)
will need rewriting after the spec resolution of #31 lands.

### Cross-line corroboration is a framework demonstration, not a niche feature

REQ-001's adequacy/sufficiency story — two independent analytical
methods (symbolic + numerical) with explicit complementarity —
turned out to be one of the most important things to demonstrate.
It shows that the framework respects the *epistemological*
structure of real engineering V&V, not just the *administrative*
structure. Future walkthroughs should make conjunctive evidence
the default scenario, not an edge case.

### Sensitive-content externalization is a v0.2 readiness gate

[#33](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/33)
is the one finding that goes BEYOND "make the ontology richer" and
into "make the architecture support a different class of adopter."
Without org-controlled dereferenceable references for reason
content, classified / proprietary engineering programs cannot
adopt — the RDF would leak too much. Resolving #33 should be near
the top of v0.2 sequencing if those adopter classes are in the
target audience.

## Forward work

Tracked elsewhere:

- All seven issues above have their resolution tracked in their
  respective repos.
- The walkthrough docs in
  [`tests/acceptance/`](https://github.com/dynamicalsystemsgroup/flexo-rtm/tree/main/tests/acceptance)
  need a rewrite once the v0.2 vocabulary lands — at minimum
  reflecting the pre-commitment ordering (#31) and the model/
  evidence artifact split (#32). The CURRENT v1 docs remain useful
  but are now known to script the wrong workflow order.

What's missing from this page that should land in **User Testing
Experiment #2** (whenever that runs):

- The reviewer / auditor / reconcile skill walkthroughs (#2 should
  extend the same ADCS session through those three skills end-to-end).
- The prototype's REQ-001 deliberately-failed case (would have
  surfaced more deprecation-flow gaps).
- The reconcile skill exercised with a real two-source conflict
  (synthesizing a wider-envelope simulation that supersedes the
  original).
- A non-ADCS arc (perhaps the OSLC-RM roundtrip or the SysMLv2
  ingestion) to verify the vocabulary findings generalize beyond
  satellite ADCS.

## Process retrospective

What worked:

- **Two-gate verbatim reflection.** Every CLI write was reviewed
  pre- and post-execution; no silent surprises. The cost (extra
  exchange per write) was worth the auditability.
- **One question at a time.** The catechism's discipline prevented
  batching that would have collapsed nuance.
- **The engineer's authority over their reason text.** No
  paraphrasing, no summarization. Several long reason texts were
  drafted by the LLM and confirmed by the engineer verbatim;
  several were corrected by the engineer for content; in all cases
  the engineer's wording was the final wording.
- **Filing issues inline.** Every gap got captured the moment it
  surfaced; nothing was lost between turns.

What needs work:

- The walkthrough doc and the actual flow diverged within minutes.
  The doc anticipates a thinner ontology than what the engineer
  actually wants to express. (This is the finding, not a problem
  per se — it's what the experiment is FOR.)
- The CLI's lack of `--by-means-of` / `--depends-on` / model-vs-
  evidence flags meant that conjunctive structure and cross-attestation
  dependencies all collapsed into prose. Useful pressure for #32 +
  #34.
- The identity-binding surface friction (#8) was a small but
  perfectly representative example of the kind of ergonomic gap
  that doesn't show up in fixture-based tests.

## See also

- [MVC Pattern from RIME TRL ANT](MVC%20Pattern%20from%20RIME%20TRL%20ANT) — the operational pattern this UAT exercises
- [Design Spec](Design%20Spec) — particularly §4.2 (attestation infrastructure) which #29–#34 collectively refine
- [`tests/acceptance/`](https://github.com/dynamicalsystemsgroup/flexo-rtm/tree/main/tests/acceptance) — the v1 walkthrough scripts that were exercised
- [`.claude/skills/flexo-rtm-engineer.md`](https://github.com/dynamicalsystemsgroup/flexo-rtm/blob/main/.claude/skills/flexo-rtm-engineer.md) — the skill driving this experiment
