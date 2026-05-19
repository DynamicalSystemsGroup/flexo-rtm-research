<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# CLAUDE.md — `flexo-rtm-research`

## What this repo is

The **research and specification** repo for `flexo-rtm` — a verifiable self-certification oracle for bidirectional requirements traceability of SysMLv2 models. Design lives here as wiki pages, ADRs, and open issues. **Code lives elsewhere**, in [`flexo-rtm`](https://github.com/DynamicalSystemsGroup/flexo-rtm).

## The double-loop architecture

`flexo-rtm`'s development discipline pairs two loops, one per repo, plus a coupling loop between them. Get this framing right and the two repos divide labor cleanly; get it wrong and changes wander between the two without ever landing.

```
                      ┌────────────────────────────────┐
                      │   RESEARCH LOOP (this repo)    │
                      │                                │
                      │   principles  ─→  design       │
                      │        ↑          spec         │
                      │        │           │           │
                      │   assumptions     ADRs         │
                      │   re-examined     ↓            │
                      │        ↑      (handoff to      │
                      │        │       development)   │
                      └────────┼────────────────────┬──┘
                               │                    │
                       (validation)            (spec)
                               │                    │
                      ┌────────┼────────────────────▼──┐
                      │   DEVELOPMENT LOOP             │
                      │   (flexo-rtm repo)             │
                      │                                │
                      │      spec  ─→  code  ─→  CI    │
                      │        ↑          ↓            │
                      │        │       behavior        │
                      │        │       (observed)      │
                      │        │          ↓            │
                      │   verification  (escalates     │
                      │   findings       up if         │
                      │   shape the      assumptions   │
                      │   next spec      fail)         │
                      │   amendment       │            │
                      └────────────────── ┼ ───────────┘
                                          │
                                  (back to research)
```

### V&V mapped to the loops

| Loop | Question | Repo | Activity |
|---|---|---|---|
| Research | "Are we building the right thing?" (validation) | `flexo-rtm-research` | Refining principles; deciding what behavior is desirable; testing assumptions against observed behavior |
| Development | "Are we building it right?" (verification) | `flexo-rtm` | Implementing the spec; CI gates against acceptance criteria; observing the resulting behavior |
| Coupling | "What did we learn that changes the question?" | both | Findings from observed behavior return to research and may amend the spec |

The coupling loop is the load-bearing piece. Without it, the research repo becomes a stale spec and the dev repo accumulates undocumented behavior. With it, every observed gap (a UAT walkthrough that surfaces a missing vocabulary, an integration test that finds a real-world divergence) becomes a research-repo issue that informs the next spec amendment.

### Direction of information flow

- **Research → Development.** New principles / ADR decisions / wiki amendments produce **spec changes** in the wiki. Spec changes that require implementation produce a **research-repo issue** describing what implementation needs to do, plus (often) an **impl-repo issue** as the actual work ticket.
- **Development → Research.** Behavior observed during implementation, integration tests, UAT walkthroughs, or live-test sweeps that **does not match the spec's assumptions** is escalated by filing a **research-repo issue** describing what the spec is missing. The development side never silently works around a spec gap — gaps come back.

This is the same discipline the engineer skill enforces ([`tests/acceptance/01-engineer-walkthrough.md`](https://github.com/DynamicalSystemsGroup/flexo-rtm/blob/main/tests/acceptance/01-engineer-walkthrough.md) demonstrates it): never paraphrase, never silently resolve, always file when in doubt.

### User testing as structured coupling

The coupling loop has two channels, and they are not equivalent:

1. **Ad-hoc behavior observation.** A CI failure, an integration test surprise, a bug report, a live-test divergence (the v0.1 build's slice-time issues, [#11–#22](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues?q=is%3Aissue+is%3Aclosed)). Filed when noticed; cadence is whatever-the-code-makes-you-find.

2. **Structured user testing (UAT).** A deliberate, scheduled exercise of the shipped framework against a realistic engineering arc, with a human driving the skills and the LLM running the catechisms. Findings are captured inline as research-repo issues; the experiment ends with a consolidation page in the wiki.

UAT is the structured face of the coupling loop. CI verifies that the framework runs mechanically (constructor commits, audits produce JSON, push lands on Flexo); UAT validates whether **the framework expresses what an engineer actually needs to say**. CI cannot replace UAT — verification cannot substitute for validation. The two layers are complementary and the coupling loop fires through both.

**Cadence and artifacts:**

| Artifact | Repo | Convention |
|---|---|---|
| Walkthrough script | `flexo-rtm` | [`tests/acceptance/N-<role>-walkthrough.md`](https://github.com/DynamicalSystemsGroup/flexo-rtm/tree/main/tests/acceptance) — versioned per skill role; engineer / reviewer / auditor / reconcile so far |
| Findings (inline) | both | Filed as GitHub issues during the experiment, never buffered |
| Consolidation page | this repo | `wiki/User Testing Experiment <N>.md` — numbered; covers scope actually covered, findings, links to filed issues, synthesis |

**The first experiment** is [`User Testing Experiment 1`](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/wiki/User-Testing-Experiment-1) — engineer-skill walkthrough on the ADCS arc, completed REQ-001's pre-commitment layer, surfaced [#29–#34](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues?q=is%3Aissue+is%3Aopen+number%3A29..34). That experiment's pattern is the template: scope, findings, issues, synthesis, what's parked for the next experiment.

**Each experiment numbered separately.** Experiment #N's consolidation references Experiment #(N–1)'s parked work and may extend or invalidate prior findings. The numbered series is the auditable record of "how the framework evolves under contact with real engineering."

**The framework's evolution is driven by UAT findings.** v0.1 was built against the Design Spec's 45 acceptance criteria (verification ground). v0.2's vocabulary work (the GSN promotion direction, the precondition vocabulary, the temporal partition, the model-vs-evidence partition) is driven by Experiment #1's findings (validation ground). The two are not interchangeable: 45 acceptance criteria do not anticipate every engineering primitive an engineer wants to express; only running the framework against a real arc surfaces those.

## Where work lives in this repo

| What | Where |
|---|---|
| The canonical design | [`wiki/Design Spec.md`](wiki/Design%20Spec.md) (§6 = 45 acceptance criteria; §7 = code structure) |
| Architectural decisions | [`wiki/ADR-*.md`](wiki/) — 33 ADRs |
| Normative contracts | [`wiki/<name> Contract.md`](wiki/) (Flexo REST Binding, OSLC Roundtrip Acceptance, SysMLv2 Ingestion Contract, Signed Envelope Shapes, Identity Adapter Contract, External URI Rules) |
| Open spec / design questions | GitHub issues, mirrored to [`Open Issues - Research`](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/wiki/Open-Issues---Research) (auto-regenerated; see [`scripts/sync-issues-to-wiki.sh`](scripts/sync-issues-to-wiki.sh)) |
| Cross-loop visibility into impl backlog | [`Open Issues - Implementation`](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/wiki/Open-Issues---Implementation) (auto-regenerated mirror of `flexo-rtm`'s open issues) |
| UAT findings + retrospectives | [`wiki/User Testing Experiment <N>.md`](wiki/) — running record of what we learned by USING the framework |

## Issue dashboards (the loop's status board)

Two wiki pages mirror open issues from both repos:

- [**Open Issues — Research**](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/wiki/Open-Issues---Research) — spec / ontology / design decisions tracked here.
- [**Open Issues — Implementation**](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/wiki/Open-Issues---Implementation) — code / CLI / test work tracked in the impl repo.

These regenerate automatically via [`.github/workflows/sync-issues.yml`](.github/workflows/sync-issues.yml) on every issue event (in this repo), daily cron, or manual dispatch. The source of truth is GitHub; the wiki is the published mirror.

**When triaging:** check both dashboards. A research-side issue that turns out to be a pure implementation gap should move to the impl repo (via "Transfer issue" or close-with-redirect — see precedent at `flexo-rtm-research#28`). Conversely, an impl-side issue that's actually waiting on a spec decision should be cross-linked back here.

## Working with the wiki

The wiki source-of-truth lives in `wiki/` in this repo's `main` branch. The published GitHub wiki is a mirror.

```bash
# After editing any wiki/*.md file:
scripts/sync-wiki.sh                    # propagate to GitHub wiki

# After issues change (filed, closed, edited, labeled):
scripts/sync-issues-to-wiki.sh          # regenerate the two dashboards
scripts/sync-wiki.sh                    # publish
# Or just push and let the GitHub Actions workflow handle it.
```

The GitHub Actions workflow handles regeneration + publication automatically. Manual runs are for offline / iterative work.

## When to file a research-repo issue

File here when:

- A **spec amendment** is needed (wiki page is out of date with respect to either an ADR or shipped code — example precedent: [#11–#22](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues?q=is%3Aissue+is%3Aclosed) closed batch, all spec amendments after the v0.1 build).
- An **ontology / vocabulary gap** is observed (the engineer needs to express something the ontology doesn't structurally support — example precedent: [#29–#34](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues) from UAT Experiment #1, covering operational envelopes, adequacy/sufficiency content partition, temporal partition, model-vs-evidence artifacts, sensitive-text externalization, cross-attestation dependencies).
- A **principle or assumption** is being challenged by observed behavior (e.g., the prototype's deliberately-failed REQ-001 case demonstrates that the deterministic-evidence vs 3-sigma-claim mismatch is a real engineering concern; that finding may prompt new principles around statistical sufficiency).
- A **decision needs human input** that the spec is silent on (live-test point selection, identity provider choice, conformance-vs-private cryptosuite — example precedent: [#23–#27](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues)).

## When to escalate from research to development

Once a research-repo decision lands (ADR merged, wiki amendment committed, spec resolved), if the change requires implementation:

1. File an **impl-repo issue** describing the implementation work, with a cross-link to the research-repo decision.
2. Mark the original research-repo issue as `blocked-by: flexo-rtm#N` if the implementation must complete before the research issue closes; close the research issue otherwise.
3. Update the impl repo's [CLAUDE.md](https://github.com/DynamicalSystemsGroup/flexo-rtm/blob/main/CLAUDE.md) if the decision changes the project's permission model, skill routing, or testing surface.

## When to escalate from development to research

Once implementation surfaces a gap (live test fails for a structural reason; UAT walkthrough reveals missing vocabulary; CI catches a spec/code divergence):

1. File a **research-repo issue** describing the gap. Use the precedent of [#11–#22](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues?q=is%3Aissue+is%3Aclosed) (slice-time divergences) and [#29–#34](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues) (UAT-time divergences) for shape.
2. Keep an `impl#N` work-around in the impl repo if the live system needs to keep functioning; mark the work-around explicitly as such, and link to the research-repo issue.
3. When the spec resolution lands, the impl-side workaround is replaced with the spec-aligned implementation (and the spec divergence note in the impl-side CLAUDE.md is removed).

## Style

- Markdown for everything; Turtle inside fenced code blocks only.
- ADRs follow the [`ADR Template`](wiki/ADR%20Template.md) convention.
- Wiki cross-references use `[[Page Name]]` markdown wikilinks (rendered by GitHub wiki).
- Commit messages reference the relevant ADR / acceptance criterion / issue (e.g., "amend Flexo REST Binding §3 per #20").

## See also

- [`MVC Pattern from RIME TRL ANT`](wiki/MVC%20Pattern%20from%20RIME%20TRL%20ANT.md) — the operational pattern flexo-rtm inherits
- [`Human-AI Accountability`](wiki/Human-AI%20Accountability.md) — why the discipline of human-judgement-at-judgement-moments is structural, not stylistic
- [`User Testing Experiment 1`](wiki/User%20Testing%20Experiment%201.md) — first live UAT walkthrough; the issues it surfaced
- [`flexo-rtm/CLAUDE.md`](https://github.com/DynamicalSystemsGroup/flexo-rtm/blob/main/CLAUDE.md) — the development-side companion to this file
