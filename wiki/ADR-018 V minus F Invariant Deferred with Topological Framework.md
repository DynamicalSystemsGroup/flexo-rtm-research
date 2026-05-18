<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-018: V minus F Invariant Deferred with Topological Framework

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-003 Topological Framework Documented as Future Work]]; [[ADR-013 Simplicial Complex as Derived View When Built]]; [[Vertices Edges Faces]]; [[Design Spec]]

## Context

The Zargham 2026 topological framework includes a topological invariant of the form **V − F** (vertices minus faces, or a related Euler-characteristic-style combinatorial invariant — see [[Vertices Edges Faces]]) that is computationally cheap to evaluate on a simplicial complex view of the RTM. It surfaces some structural defects (e.g., faces with missing vertices, vertices with no faces) without requiring the full topological audit or the registry of pre-approved artifact types. The natural question is: even though the rest of the topological framework is deferred (see [[ADR-003 Topological Framework Documented as Future Work]]), should V−F survive as a cheap pre-check in v0.1? See [[Design Spec]] §3.4.

## Decision

`flexo-rtm` v0.1 **defers V−F along with the rest of the topological framework**. The invariant is not computed or reported as a v0.1 certification signal. Reasoning: further research determined that the purely numerical V−F check is not a preferred signal — it catches some defects but does **not** enforce the **recursive completeness condition** that makes the topological audit meaningful. A V−F that passes can still be topologically incomplete; a V−F that fails surfaces issues already surfaced by traditional bidirectional analysis (see [[ADR-003a v0.1 Ships Traditional Analysis Only]]). Shipping V−F alone would be a misleading partial signal.

## Consequences

### Positive

- v0.1's certification surface is coherent: traditional analysis (see [[ADR-003a v0.1 Ships Traditional Analysis Only]]) plus accountability infrastructure (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]), with no half-shipped topological-framework signals
- Avoids the failure mode where a passing V−F is interpreted as topological completeness when it is no such thing
- Forward-compatible: if the topological research line matures into an applied downstream audit (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]), V−F would be computed and reported as one signal among that audit's signals — in context, where its meaning is well-defined. The invariant tracks the research line, not `flexo-rtm`'s roadmap

### Negative / Tradeoffs

- Adopters familiar with V−F from the Zargham 2026 paper may expect it as a v0.1 signal and have to read the design spec to understand the deferral
- A cheap structural pre-check that *could* have surfaced some defects is not surfaced in v0.1; mitigated by traditional bidirectional analysis surfacing the same defects through a more interpretable lens (e.g., "requirement R has no satisfying design")

### Neutral

- The derived-view tooling (see [[ADR-013 Simplicial Complex as Derived View When Built]] and [[ADR-017 knowledgecomplex as Optional Extras]]) makes V−F computable on demand for research users; v0.1 just doesn't make it a certification signal

## Alternatives Considered

- **Keep V−F as a cheap pre-check in v0.1 even though the rest of the topological framework is deferred:** Compute V−F over the simplicial-complex derived view and report it as a v0.1 audit signal. Rejected: further research determined the purely numerical invariant is insufficient. It catches some structural defects but does not enforce the recursive completeness condition that makes the topological audit meaningful. A V−F that passes can still be topologically incomplete (because the recursion termination — every evidence artifact having its own assurance triangle — is what the V−F count assumes and does not check); a V−F that fails surfaces issues already caught by traditional bidirectional analysis. Shipping V−F alone would produce a misleading partial signal. Better to defer V−F along with the framework it belongs to, and let traditional analysis carry the v0.1 audit.

## Implementation Notes

V−F is not computed or reported by any `flexo-rtm` analysis surface. The vocabulary supporting it (vertex/face counts derived from `rtm:AssuranceComplex` — see [[ADR-020 Vocabulary Alignment with Zargham 2026]]) ships in v0.1 ontology as forward-compatible interop; the derived view (see [[ADR-013 Simplicial Complex as Derived View When Built]]) materializes the necessary resources when research users request them. If the topological research line matures into an applied downstream audit, V−F would be computed in context against a populated registry of pre-approved types (internal to that research line — see [[ADR-003 Topological Framework Documented as Future Work]] and [[ADR-032 Methodology Agnosticism as Foundational Axiom]]).

## References

- [[Design Spec]] §3.4 (V−F Deferral), §7.6 (Topological Invariants in the research line)
- [[Vertices Edges Faces]] — the topological vocabulary V−F operates over
- [[ADR-003 Topological Framework Documented as Future Work]] — the research line V−F belongs to
- [[ADR-013 Simplicial Complex as Derived View When Built]] — the derived view that would host V−F as a downstream-analysis output
- [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — the V−F invariant tracks the topological research line, not `flexo-rtm`'s roadmap
