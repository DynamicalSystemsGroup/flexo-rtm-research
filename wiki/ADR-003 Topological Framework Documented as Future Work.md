<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-003: Topological Framework Documented as Future Work

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-003a v0.1 Ships Traditional Analysis Only]]; [[ADR-018 V minus F Invariant Deferred with Topological Framework]]; [[ADR-020 Vocabulary Alignment with Zargham 2026]]; [[Topological Framework Future Work]]; [[Design Spec]]

## Context

The Zargham 2026 RTM paper introduces a **typed simplicial complex** framework in which requirements, design elements, and verification activities form vertices of typed faces (assurance triangles), and a complete RTM is one whose assurance complex is closed: every claim has a face, every face has a named approver, every approver is bound. The framework is mathematically powerful and gives a principled basis for what "the RTM is complete" actually means. The question is whether v0.1 should ship the topological framework as its certification engine, or document the framework as future work and ship a more traditional analysis. The blocking issue surfaced during the v0.1 design pass: a proper topological audit requires **recursive completeness** — every evidence artifact has its own assurance triangle — and that recursion only terminates against a **community-curated registry of pre-approved artifact types**. That registry is a research and community-engagement effort, not a v0.1 deliverable. See [[Design Spec]] §3.2 (topological framework deferral) and [[Topological Framework Future Work]] for the full elaboration.

## Decision

`flexo-rtm` v0.1 **defers the typed simplicial complex topological framework to future work**. The framework's vision, motivation, recursion-termination challenge, registry concept, and open research questions are documented comprehensively in `flexo-rtm-research` (see [[Topological Framework Future Work]]). The framework's **vocabulary** ships in v0.1 ontology forward-compatibly so that adopters accumulate data the future framework will analyze, but no v0.1 audit, SHACL profile, or certification predicate depends on the framework's completeness predicate.

## Consequences

### Positive

- v0.1 ships on a tractable timeline; the registry of pre-approved artifact types becomes its own research program rather than a v0.1 blocker
- The research repo's documentation of the framework gives the community something concrete to engage with — registry types can be proposed, debated, and converged in the open before being committed
- Vocabulary forward-compatibility means v0.1 adopters' data is not abandoned when the framework lands; their accumulated `rtm:Attestation` instances become the inputs the future audit consumes
- Decouples "is the RTM complete by traditional bidirectional analysis?" (v0.1) from "is the RTM topologically closed against a registry?" (future) — both are useful, and conflating them forced premature scope

### Negative / Tradeoffs

- v0.1's certification outcome is weaker than the topological framework promises — coverage % and named-approver attestation, not closed-triangle audit
- Adopters expecting "the topological RTM oracle" from the paper will see traditional analysis plus accountability infrastructure and have to read the design spec to understand the deferral
- The deferral risks the framework never landing if the registry research stalls — mitigated by treating the research-implement-standardize cadence as iterative (see [[ADR-001 Foundations First Approach]])

### Neutral

- Forces explicit separation between v0.1's analysis (traditional bidirectional, see [[ADR-003a v0.1 Ships Traditional Analysis Only]]) and v0.1's attestation infrastructure (named-approver SHACL, see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]); both ship, but only the latter is "advance work" on the future framework

## Alternatives Considered

- **Adopt typed simplicial complex as the primary v0.1 certification model:** Make closed-triangle audit the v0.1 certification predicate. Rejected: requires the registry of pre-approved artifact types to terminate the recursion in completeness checking; that registry is premature for v0.1 scope and would commit to type definitions before research and community engagement.
- **Ship the topological framework with a thin / placeholder registry:** Define a starter registry inside v0.1 with a few obvious types (e.g., test reports, signed-off requirement documents) and ship the audit against it. Rejected: would lock in poor registry decisions before research and community engagement; the registry is the high-leverage commitment, and getting it wrong in v0.1 is worse than deferring it.
- **Chosen approach (this ADR):** Defer the entire topological framework. Document it comprehensively as future work in the research repo. Ship the framework's vocabulary forward-compatibly in v0.1 ontology so adopters accumulate data the future framework will analyze. Ship traditional bidirectional analysis (see [[ADR-003a v0.1 Ships Traditional Analysis Only]]) and named-approver attestation (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) as v0.1 deliverables.

## Implementation Notes

The deferred framework lives entirely in the research repo: [[Topological Framework Future Work]] documents the vision, recursion challenge, registry concept, and open research questions. v0.1 ontology in `flexo-rtm` includes the Zargham-2026 vocabulary (`rtm:AssuranceComplex`, `rtm:AssuranceFace`, `rtm:AssuranceTriple` — see [[ADR-020 Vocabulary Alignment with Zargham 2026]]) but no v0.1 SHACL profile or certification predicate enforces the framework's completeness predicate. The `knowledgecomplex` optional extras (see [[ADR-017 knowledgecomplex as Optional Extras]]) provide derived-view tooling for research users who want to experiment with simplicial-complex views on v0.1 data, but the framework's audit is not a v0.1 product feature.

## References

- [[Design Spec]] §3.2 (Topological Framework Deferral), §6.2 (Vocabulary Forward-Compatibility)
- [[Topological Framework Future Work]] — the canonical future-work documentation
- [[ADR-003a v0.1 Ships Traditional Analysis Only]] — the v0.1 analysis story
- [[ADR-018 V minus F Invariant Deferred with Topological Framework]] — the topological invariant that's deferred along with the framework
- [[ADR-020 Vocabulary Alignment with Zargham 2026]] — forward-compatible vocabulary
- Zargham (2026), "Typed Simplicial Complexes for Requirements Traceability" (forthcoming)
