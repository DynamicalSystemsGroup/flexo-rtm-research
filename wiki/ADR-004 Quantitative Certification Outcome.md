<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-004: Quantitative Certification Outcome

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-019 Derived Binary View from Quantitative Metrics]]; [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]]; [[Quantitative Outcomes]]; [[Design Spec]]

## Context

The Zargham 2026 paper, in TDD framing, characterizes certification as a pass/fail outcome: the RTM is complete or it isn't. Real institutional practice, however, treats RTM completeness as a **gradient** — coverage grows over a project's life from sparse to comprehensive, and adoption depends on stakeholders being able to see and reason about partial states. A binary-only certification outcome forces an institution into a "fail" state for the entire project life until the final claim is satisfied, which contradicts the way safety and assurance cases are actually built in industry. The question is whether the v0.1 certification outcome is binary or quantitative. See [[Design Spec]] §4 (certification model) and [[Quantitative Outcomes]].

## Decision

`flexo-rtm` v0.1's primary certification outcome is **quantitative**: coverage percentages per claim type (satisfaction, adequacy, sufficiency — see [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]]) per aspect (forward, backward, attestation), gap counts, and a per-scope coverage matrix. The binary view (see [[ADR-019 Derived Binary View from Quantitative Metrics]]) is **derived** from the quantitative metrics against a configurable threshold, not produced separately.

## Consequences

### Positive

- Adoption-friendly: institutions can adopt `flexo-rtm` on day-one with sparse RTM data and watch coverage grow toward thresholds
- The gradient framing is what audit committees and assurance-case reviewers actually want — they need to see "where are we?" not just "are we done?"
- The configurable threshold gives institutions agency over their own definition of "complete enough"; safety-critical contexts can set 100%, exploratory contexts can set lower
- Per-aspect / per-claim-type granularity surfaces gaps in the form most actionable to engineers (e.g., "verification coverage is 80% but adequacy attestation is 30%")

### Negative / Tradeoffs

- The Zargham 2026 paper's TDD-framed pass/fail language requires bridging in the design spec (see [[ADR-019 Derived Binary View from Quantitative Metrics]])
- Threshold-tuning becomes a governance question per scope, not a global constant — institutional policy work that didn't exist with pure binary
- Reporting consumers must understand the quantitative model; tooling that just wants "pass/fail" gets a derived signal that may obscure underlying gaps

### Neutral

- The quantitative outcome composes cleanly with scope algebra (see [[ADR-007 Scope as First-Class RDF Resource]]): each scope has its own coverage matrix, and scopes compose as expected

## Alternatives Considered

- **Binary pass/fail only (paper's TDD framing):** Treat the RTM as either complete (all claims satisfied with valid attestation) or not. Rejected: forces a "fail" outcome for essentially every project that isn't done. Institutional adoption requires the gradient — auditors, reviewers, and engineers need to see where coverage stands today, not just whether the project has reached 100%. The binary view is still useful as a derived signal (see [[ADR-019 Derived Binary View from Quantitative Metrics]]) when stakeholders want a single number, but it's a projection of the quantitative model, not the primary outcome.

## Implementation Notes

The quantitative outcome lives in v0.1's analysis layer (`oracle/src/oracle/analysis/`). Coverage metrics are computed via SPARQL queries against the RTM graph, parameterized by scope (see [[ADR-007 Scope as First-Class RDF Resource]]). Output is a structured coverage report (per-scope, per-aspect, per-claim-type) plus a derived binary view against a configurable threshold (see [[ADR-019 Derived Binary View from Quantitative Metrics]]). Audit reports include both views — quantitative as primary, binary as derived summary.

## References

- [[Design Spec]] §4.1–4.3 (Certification Model, Coverage Metrics, Aspect Coverage)
- [[Quantitative Outcomes]] — the wiki page elaborating the coverage model and report structure
- [[ADR-019 Derived Binary View from Quantitative Metrics]] — how the binary view derives from this
- [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]] — the claim types this counts over
