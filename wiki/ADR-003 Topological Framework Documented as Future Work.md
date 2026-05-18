<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-003: Topological Framework Documented as Future Work

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-003a v0.1 Ships Traditional Analysis Only]]; [[ADR-018 V minus F Invariant Deferred with Topological Framework]]; [[ADR-020 Vocabulary Alignment with Zargham 2026]]; [[ADR-032 Methodology Agnosticism as Foundational Axiom]]; [[Topological Framework Future Work]]; [[Design Spec]]

## Context

The Zargham 2026 RTM paper introduces a **typed simplicial complex** framework in which requirements, design elements, and verification activities form vertices of typed faces (assurance triangles), and a complete RTM is one whose assurance complex is closed: every claim has a face, every face has a named approver, every approver is bound. The framework is mathematically interesting and shares philosophical kinship with `flexo-rtm`'s named-approver accountability discipline. The question is whether v0.1 should ship the topological framework as its certification engine, or document the framework as a related research line and ship the traditional analysis plus named-signer attestation that `flexo-rtm` actually is. The blocking issue surfaced during the v0.1 design pass: a proper topological audit requires **recursive completeness** — every evidence artifact has its own assurance triangle — and that recursion only terminates against a **community-curated registry of pre-approved artifact types**. That registry is a research and community-engagement effort, internal to the topological research line. Per [[ADR-032 Methodology Agnosticism as Foundational Axiom]] (which generalizes this ADR's commitment), `flexo-rtm` is methodology-agnostic: the topological framework is one possible downstream-analysis path on top of `flexo-rtm`'s data, not `flexo-rtm`'s eventual destination. See [[Design Spec]] §4.10 and [[Topological Framework Future Work]] for the full elaboration.

## Decision

`flexo-rtm` v0.1 **does not commit to the typed simplicial complex topological framework**. The framework is documented as a **related research line** in `flexo-rtm-research` (see [[Topological Framework Future Work]]): vision, motivation, recursion-termination challenge, registry concept, and open research questions are recorded comprehensively. The framework's **vocabulary** ships in v0.1 ontology as forward-compatible interop per [[ADR-020 Vocabulary Alignment with Zargham 2026]], so that adopters who choose to run topological analysis as a downstream-analysis mode can do so without translation. Adopters who choose other downstream-analysis paths (SLSA, GSN, ARP4754A, in-house) read the same data. No v0.1 audit, SHACL profile, or certification predicate depends on the topological framework's completeness predicate, and `flexo-rtm` does not commit to it as an eventual destination (see [[ADR-032 Methodology Agnosticism as Foundational Axiom]]).

## Consequences

### Positive

- v0.1 ships on a tractable timeline; the registry of pre-approved artifact types belongs to the topological research line, not `flexo-rtm`'s critical path
- The research repo's documentation of the framework gives the community something concrete to engage with — registry types can be proposed, debated, and converged in the open as the research line matures (or not), without coupling that progress to `flexo-rtm`'s release schedule
- Vocabulary alignment as forward-compatible interop (per [[ADR-020 Vocabulary Alignment with Zargham 2026]]) means adopters who choose to run topological analysis as a downstream-analysis mode read v0.1 data natively; adopters who choose other downstream-analysis paths read the same data; adopters who run no downstream analysis are unaffected
- Decouples "is the RTM complete by traditional bidirectional analysis plus named signers?" (`flexo-rtm` v0.1) from "is the RTM topologically closed against a registry?" (one specific possible downstream-analysis path) — the two are different artifacts, and conflating them forced premature scope

### Negative / Tradeoffs

- `flexo-rtm`'s scope is a deliberately modest claim — bidirectional traceability plus named signers reduced to practice. Some readers may expect "the topological RTM oracle" promised by the paper and have to read [[ADR-032 Methodology Agnosticism as Foundational Axiom]] to recalibrate
- The topological research line may never mature into an applied audit (registry research may stall, invariants may stay unresolved). That is fine — `flexo-rtm` does not depend on the research line maturing, and per [[ADR-032 Methodology Agnosticism as Foundational Axiom]] no specific downstream-analysis methodology is privileged. Other paths (SLSA, GSN, ARP4754A, in-house) can mature in its absence

### Neutral

- Forces explicit separation between `flexo-rtm`'s bidirectional analysis (see [[ADR-003a v0.1 Ships Traditional Analysis Only]]) and `flexo-rtm`'s attestation infrastructure (named-approver SHACL, see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]); both are part of what `flexo-rtm` IS, and both produce data that any downstream-analysis path (topological, SLSA, GSN, ARP4754A, in-house) can consume

## Alternatives Considered

- **Adopt typed simplicial complex as the primary v0.1 certification model:** Make closed-triangle audit the v0.1 certification predicate. Rejected: would commit `flexo-rtm` to one specific assurance methodology (against [[ADR-032 Methodology Agnosticism as Foundational Axiom]]), and requires the registry of pre-approved artifact types to terminate the recursion. The registry conversation is unresolved research, internal to the topological line.
- **Ship the topological framework with a thin / placeholder registry:** Define a starter registry inside v0.1 with a few obvious types (e.g., test reports, signed-off requirement documents) and ship the audit against it. Rejected: would lock in poor registry decisions before research and community engagement, and would still commit `flexo-rtm` to one specific downstream-analysis methodology against [[ADR-032 Methodology Agnosticism as Foundational Axiom]].
- **Chosen approach (this ADR):** Treat the topological framework as a related research line, not part of `flexo-rtm`. Document it comprehensively in the research repo. Ship the framework's vocabulary as forward-compatible interop in v0.1 ontology per [[ADR-020 Vocabulary Alignment with Zargham 2026]], so adopters who later choose to run topological analysis as a downstream-analysis mode can do so without translation. Ship traditional bidirectional analysis (see [[ADR-003a v0.1 Ships Traditional Analysis Only]]) and named-approver attestation (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) as what `flexo-rtm` IS.

## Implementation Notes

The topological research line lives entirely in the research repo: [[Topological Framework Future Work]] documents the vision, recursion challenge, registry concept, and open research questions. v0.1 ontology in `flexo-rtm` includes the Zargham-2026 vocabulary (`rtm:AssuranceComplex`, `rtm:AssuranceFace`, `rtm:AssuranceTriple` — see [[ADR-020 Vocabulary Alignment with Zargham 2026]]) as forward-compatible interop, but no v0.1 SHACL profile or certification predicate enforces the framework's completeness predicate. The `knowledgecomplex` optional extras (see [[ADR-017 knowledgecomplex as Optional Extras]]) provide derived-view tooling for research users who want to experiment with simplicial-complex views on v0.1 data; the topological audit is not a `flexo-rtm` product feature, and `flexo-rtm` does not commit to ever shipping one.

## References

- [[Design Spec]] §4.10 (topological framework as related research line), §4.2 (vocabulary alignment as forward-compatible interop)
- [[Topological Framework Future Work]] — the canonical reference for the related research line
- [[ADR-003a v0.1 Ships Traditional Analysis Only]] — what `flexo-rtm` v0.1 IS
- [[ADR-018 V minus F Invariant Deferred with Topological Framework]] — the topological invariant whose maturity tracks the research line, not `flexo-rtm`'s roadmap
- [[ADR-020 Vocabulary Alignment with Zargham 2026]] — vocabulary alignment as forward-compatible interop
- [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — the foundational axiom that names this ADR's position as one instance of `flexo-rtm`'s methodology-agnostic stance
- Zargham (2026), *Formalizing Document Assurance: A Topological Framework for Verification, Validation, and Human Accountability* (forthcoming)
