<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-003a: v0.1 Ships Traditional Analysis Only

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-003 Topological Framework Documented as Future Work]]; [[ADR-021 Three Attestation Subclasses Ship in v0.1]]; [[Traditional Forward and Backward Analysis]]; [[Design Spec]]

## Context

Once the topological framework is deferred (see [[ADR-003 Topological Framework Documented as Future Work]]), a natural follow-up question is: how much of the framework should still ship, and how much of v0.1's analysis should be **traditional** (forward / backward trace coverage, gap reports, coverage percentages) versus an early subset of the framework? Earlier drafts of the design spec used "Level 1" and "Level 2" framing — Level 1 being traditional analysis, Level 2 being the topological audit. That framing fragmented the deferral story and implied a partial topological shipment that the research had not actually validated. The question is whether to simplify to a single coherent v0.1 analysis story. See [[Design Spec]] §3.3 and [[Traditional Forward and Backward Analysis]].

## Decision

`flexo-rtm` v0.1 ships **traditional bidirectional analysis only**: forward trace (requirements → design → verification), backward trace (verification → design → requirements), gap reports, and quantitative coverage metrics (see [[ADR-004 Quantitative Certification Outcome]]). Named-approver attestation infrastructure (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) ships alongside as a separate v0.1 capability — but the **closed-triangle audit** (the topological audit that consumes attestations) does **not** ship in v0.1. The "Level 1 / Level 2" framing from earlier drafts is collapsed into "v0.1's analysis" (traditional) and "the topological framework" (future).

## Consequences

### Positive

- Single coherent v0.1 analysis story: traditional bidirectional analysis with quantitative coverage; named-approver attestation as a separate, well-scoped v0.1 capability
- Eliminates the half-shipped Level 2 problem — no partial topological audit that depends on registry decisions deferred to future work
- Traditional analysis is trusted and familiar to RTM practitioners; v0.1 adoption is not gated on understanding the topological framework
- Forward-compatible interop (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]): today's attestations (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) are independently meaningful as `flexo-rtm`'s named-signer accountability, and equally readable by any downstream-analysis path adopters may choose (topological closed-triangle audit, SLSA, GSN, ARP4754A, in-house)

### Negative / Tradeoffs

- v0.1 does not deliver the topological framework's headline claim ("the RTM is closed iff every face is approved by a registered type") — adopters expecting that from the Zargham 2026 paper get traditional analysis plus accountability infrastructure instead
- Some sophistication of the topological research line is invisible to v0.1 users — `rtm:AssuranceFace` instances may exist in their graph (via vocabulary alignment per [[ADR-020 Vocabulary Alignment with Zargham 2026]]) without any v0.1 tooling that consumes them. That is by design: `flexo-rtm` does not commit to the topological audit, and adopters who choose to run topological analysis as a downstream-analysis mode read the data without translation

### Neutral

- The collapse simplifies the design spec's framing: `flexo-rtm` v0.1's analysis is traditional bidirectional + named-signer attestation, and the topological framework is a related research line, not `flexo-rtm`'s destination (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]). Vocabulary alignment ships as forward-compatible interop (see [[ADR-020 Vocabulary Alignment with Zargham 2026]])

## Alternatives Considered

- **Ship traditional analysis + named-approver attestation + closed-triangle audit (some subset of the topological framework):** A "Level 2-lite" that ships the triangle audit but not the full registry-of-pre-approved-types recursive completeness check. Rejected: the closed-triangle audit *is* the topological audit; what makes it meaningful is the recursive completeness check, which requires the registry. Shipping the triangle audit without that check produces a misleading certification outcome — every triangle "closes" trivially because the recursion termination is hand-waved. The chosen decoupling — ship attestation (named-approver SHACL) but **not** the triangle audit — is what makes v0.1's analysis coherent: traditional analysis + accountability infrastructure, with the topological audit deferred as a single unit along with the framework it belongs to.

## Implementation Notes

v0.1's analysis layer in `flexo-rtm` (`oracle/src/oracle/analysis/`) implements: forward-trace SPARQL queries (requirements with no satisfying design), backward-trace SPARQL queries (verifications with no covered requirement), aspect-coverage reports (see [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]] and [[Aspect Coverage with Adequacy and Sufficiency]]), and quantitative coverage metric computation (see [[ADR-004 Quantitative Certification Outcome]] and [[ADR-019 Derived Binary View from Quantitative Metrics]]). Named-approver SHACL profiles (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) enforce attestation integrity but do **not** aggregate into closed-triangle audits — that's deferred.

## References

- [[Design Spec]] §3.3 (Analysis Scope), §4.1 (Traditional Forward/Backward)
- [[Traditional Forward and Backward Analysis]] — the v0.1 analysis vocabulary and SPARQL recipes
- [[ADR-003 Topological Framework Documented as Future Work]] — the framework-level deferral this ADR refines
- [[ADR-021 Three Attestation Subclasses Ship in v0.1]] — the attestation infrastructure that ships separately
