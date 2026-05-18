<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-019: Derived Binary View from Quantitative Metrics

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-004 Quantitative Certification Outcome]]; [[ADR-007 Scope as First-Class RDF Resource]]; [[Quantitative Outcomes]]; [[Certification Predicate]]; [[Design Spec]]

## Context

The Zargham 2026 paper, in its TDD framing, characterizes the RTM certification predicate as binary — the RTM is complete or it is not. v0.1's primary certification outcome is quantitative (see [[ADR-004 Quantitative Certification Outcome]]) because institutional adoption requires the gradient. Yet some downstream consumers — CI pipelines, dashboards, contractual sign-offs — want a single pass/fail signal. The question is whether v0.1 produces the binary view as a separate first-class outcome or **derives** it from the quantitative metrics against a configurable threshold. See [[Design Spec]] §4.5 and [[Certification Predicate]].

## Decision

`flexo-rtm` v0.1's binary certification view is **derived** from the quantitative metrics against a **configurable threshold** (per scope, per claim type, per aspect). A cert run produces the quantitative coverage matrix; the binary view applies the configured thresholds and emits pass/fail. The thresholds are part of the cert run configuration (scope + profile + thresholds — see [[ADR-007 Scope as First-Class RDF Resource]] and [[ADR-016 Composable SHACL Profiles]]); a cert artifact records both the quantitative metrics and the threshold-evaluated binary outcome.

## Consequences

### Positive

- Reconciles paper's TDD framing with industrial reality: institutions get the binary outcome the paper describes, but produced by an explicit, configurable threshold rather than implicit definition
- Threshold transparency: every cert artifact records the thresholds used; reviewers can see *why* a cert is binary-passing and *what* would have to change for it to fail
- Per-scope and per-aspect thresholds let safety-critical scopes set 100% while exploratory scopes set lower thresholds, without parallel binary-predicate definitions
- Forward-compatible with downstream-analysis paths (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]): an adopter who runs topological analysis as a downstream-analysis mode (see [[ADR-003 Topological Framework Documented as Future Work]]) can compose the closure predicate with the threshold-derived binary; adopters running SLSA, GSN, ARP4754A, or in-house analyses compose their own predicates on the same threshold-derived foundation

### Negative / Tradeoffs

- Threshold-setting is a governance question per scope; institutions have to decide and document their thresholds
- The "TDD pass/fail" semantics of the paper is not literally what v0.1 implements — v0.1's binary is threshold-derived, which is more nuanced; bridging documentation required

### Neutral

- The binary view is always a projection of the quantitative model — never a parallel computation that could disagree

## Alternatives Considered

- **Pure quantitative (no derived binary):** Emit only coverage percentages and gap reports; let downstream consumers derive their own binary signals. Rejected: forces every consumer to define their own threshold mechanism, defeating the institutional-consistency story. A cert artifact should record a binary signal alongside the metrics so that contractual sign-offs and CI gates have a stable interpretation point.

## Implementation Notes

- Cert run configuration declares thresholds as part of the run inputs (alongside scope and profile); thresholds are per claim type per aspect
- Analysis layer (`oracle/src/oracle/analysis/`) computes the quantitative coverage matrix; the cert-artifact builder applies thresholds and emits the binary view
- Cert artifact format records: (a) the quantitative coverage matrix, (b) the threshold configuration used, (c) the threshold-evaluated binary outcome per claim type per aspect, (d) the overall cert pass/fail (typically the AND of all threshold evaluations within the scope)
- See [[Certification Predicate]] for the canonical predicate semantics and threshold composition

## References

- [[Design Spec]] §4.5 (Derived Binary View), §4.6 (Threshold Configuration)
- [[Certification Predicate]] — the canonical predicate semantics
- [[Quantitative Outcomes]] — the underlying quantitative model
- [[ADR-004 Quantitative Certification Outcome]] — the primary outcome this derives from
- [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — the threshold-derived binary is `flexo-rtm`'s; downstream-analysis paths compose their own predicates on top
