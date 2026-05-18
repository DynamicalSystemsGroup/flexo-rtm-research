<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-020: Vocabulary Alignment with Zargham 2026

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-003 Topological Framework Documented as Future Work]]; [[ADR-013 Simplicial Complex as Derived View When Built]]; [[ADR-021 Three Attestation Subclasses Ship in v0.1]]; [[Vertices Edges Faces]]; [[Topological Framework Future Work]]; [[Design Spec]]

## Context

The Zargham 2026 RTM paper uses a specific vocabulary for the topological framework: **assurance complex**, **assurance face**, **assurance triple/triangle**, **closed face**, **named approver**, etc. This vocabulary is committed in the paper's mathematics and discussed in standards-engagement conversations. `flexo-rtm` v0.1 could either (a) adopt the paper's vocabulary verbatim in the RDF ontology, or (b) introduce a parallel project-specific vocabulary (e.g., "traceability triangle," "complete trace face") that the paper might be cited alongside but does not literally appear in. The latter creates a mapping problem between paper and implementation that future readers and standards engagement have to navigate. See [[Design Spec]] §6.8 and [[Topological Framework Future Work]].

## Decision

`flexo-rtm` v0.1 ontology uses the **Zargham 2026 vocabulary verbatim**: `rtm:AssuranceComplex`, `rtm:AssuranceFace`, `rtm:AssuranceTriple` (and supporting terms) are the canonical class names in the RDF ontology. Paper and implementation are mutually citable without translation. Per [[ADR-032 Methodology Agnosticism as Foundational Axiom]], the vocabulary alignment is **forward-compatible interop for the related topological research line, not a commitment that the topological framework is `flexo-rtm`'s eventual destination**. Adopters who choose to run topological analysis as a downstream-analysis mode benefit from the alignment (their accumulated data is in the right vocabulary without translation); adopters who do not are unaffected. The vocabulary is equally readable by other downstream-analysis paths (SLSA, GSN, ARP4754A, in-house) — its presence in v0.1 ontology does not privilege any one of them.

## Consequences

### Positive

- Paper and implementation are mutually citable — no translation table required for standards engagement, research dialogue, or reader navigation
- Adopters reading the Zargham 2026 paper can directly look up the same class names in the v0.1 ontology
- Forward-compatible interop for the topological research line (see [[ADR-003 Topological Framework Documented as Future Work]] and [[ADR-032 Methodology Agnosticism as Foundational Axiom]]) is built in — adopters who choose to run topological analysis as a downstream-analysis mode read `rtm:AssuranceFace` instances directly, and adopters who don't are unaffected
- Standards engagement (INCOSE IS 2026 paper, future OMG submissions) operates on a single vocabulary

### Negative / Tradeoffs

- Adopters unfamiliar with the Zargham 2026 paper see vocabulary (assurance complex, face, triangle) that does not map to traditional RTM concepts directly; mitigated by class documentation and by the fact that traditional RTM analysis in v0.1 (see [[ADR-003a v0.1 Ships Traditional Analysis Only]]) operates over `rtm:Requirement` / `rtm:DesignElement` / `rtm:VerificationActivity` — the topological vocabulary surfaces only when the derived view is requested
- Locks the v0.1 vocabulary to the paper's terminology — major paper revisions ripple into ontology; mitigated by the paper being a research publication that converges before v0.1 release

### Neutral

- The vocabulary commitment is one of the foundations-first decisions (see [[ADR-001 Foundations First Approach]]) — getting the vocabulary right at v0.1 is part of why foundations-first matters

## Alternatives Considered

- **Parallel "traceability triangle" vocabulary:** Define `rtm:TraceabilityTriangle` (etc.) as project-specific vocabulary, cite the Zargham 2026 paper as related work, and provide a mapping document. Rejected: creates a translation burden between paper and implementation; every standards-engagement conversation has to navigate the mapping; researchers reading the paper cannot directly look up the class names in the ontology. Verbatim adoption is cleaner for the foundations-first cadence (see [[ADR-001 Foundations First Approach]]) where paper and implementation evolve together.

## Implementation Notes

- v0.1 ontology defines: `rtm:AssuranceComplex`, `rtm:AssuranceFace`, `rtm:AssuranceTriple`, `rtm:closedFace` (boolean property), `rtm:namedApprover` (used in attestations — see [[ADR-021 Three Attestation Subclasses Ship in v0.1]])
- These classes have documented mappings to the paper's mathematical objects; ontology annotations include the paper section reference
- The derived simplicial-complex view (see [[ADR-013 Simplicial Complex as Derived View When Built]]) produces instances of these classes from the underlying RTM graph
- See [[Vertices Edges Faces]] for the canonical vocabulary documentation

## References

- [[Design Spec]] §6.8 (Vocabulary Alignment), §6.9 (Paper-Ontology Mapping)
- [[Vertices Edges Faces]] — the vocabulary documentation
- [[Topological Framework Future Work]] — the related research line whose vocabulary this aligns with
- [[ADR-003 Topological Framework Documented as Future Work]] — `flexo-rtm` does not commit to the framework
- [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — vocabulary alignment as forward-compatible interop, not commitment to a specific downstream-analysis destination
- Zargham (2026), "Typed Simplicial Complexes for Requirements Traceability" (forthcoming)
