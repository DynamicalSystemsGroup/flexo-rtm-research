<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-001: Foundations First Approach

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-009 Two-Repo Strategy]]; [[Mission and Thesis]]; [[Design Spec]]

## Context

`flexo-rtm` sits at the intersection of three uncommonly-combined fields: model-based systems engineering (SysMLv2, OSLC), formal RTM theory (Zargham 2026 typed simplicial complex framework), and human-AI accountability infrastructure (named approvers, signed envelopes, verifiable certification). Each of these areas is moving, and the research that would normally precede engineering — what vocabulary to commit to, what ontology to bake in, what audit invariants to enforce — is partially complete. The question shaping v0.1 is: do we build the operator UX first and let the ontology and research drift to fit, or do we lock the foundations (ontology, certification predicate, profile mechanism) first and let UX follow? See [[Design Spec]] §1 (mission and thesis) and §2 (research-then-implement-then-standardize cadence).

## Decision

`flexo-rtm` v0.1 is built **foundations-first**: ontology, certification predicate semantics, profile mechanism, scope algebra, and approver binding are specified and frozen as the v0.1 invariants before operator UX is fleshed out. The iteration cadence is **research → implement → standardize**, applied per concept rather than per release.

## Consequences

### Positive

- Operator UX choices cannot accidentally freeze the wrong ontology — the ontology is locked first, and UX is built to surface it
- The research-implement-standardize cadence is publishable; partners and standards bodies can engage at the foundation layer
- Forward-compatibility (e.g., shipping topological-framework vocabulary in v0.1 ontology even though the framework itself is deferred — see [[ADR-003 Topological Framework Documented as Future Work]]) is a deliberate consequence of this ordering
- The ADCS prototype's "deferred" infrastructure (signed envelopes, identity, attestation) all becomes addressable because the foundation is settled before the operator skin starts demanding it

### Negative / Tradeoffs

- Slower time-to-first-screenshot — early-stage stakeholders who expect a UI demo will see ontology and SHACL profiles instead
- Risks over-engineering the foundation relative to actual operator need; mitigated by keeping v0.1 scoped to the ADCS regression corpus and known partner contexts
- Foundation-first work is harder to fundraise and harder to recruit against than a screenshot-driven roadmap

### Neutral

- Forces the research-repo / implementation-repo split (see [[ADR-009 Two-Repo Strategy]]) because foundations-first work generates research artifacts that don't belong in a clean implementation repo

## Alternatives Considered

- **Operator-skin first:** Build the Flexo-style UX first, bind it to a placeholder ontology, evolve the ontology as users complain. Rejected: UX gestures (button labels, screen flows, what a "claim" looks like in a list view) silently fix ontology commitments that are then expensive to change. The ADCS prototype experience showed that hardcoded UX assumptions are the most durable form of technical debt.
- **End-to-end vertical slice:** Pick one workflow (e.g., "certify one requirement against one model") and build it end-to-end across UX, storage, analysis. Rejected: a vertical slice across a half-formed ontology rebakes the same UX-freezes-ontology problem, just narrower; and the slice's choices propagate horizontally as the system fills out.
- **Spec-first reference implementation:** Write the full v1.0 specification, then implement it. Rejected: the foundation isn't settled enough yet to write v1.0 — the topological framework alone requires research and community engagement that won't conclude in v0.1's timeline. The research-implement-standardize cadence is per concept, not per release.

## Implementation Notes

This decision shapes the v0.1 work order across both repos: research artifacts in `flexo-rtm-research` (this wiki, Topological Framework Future Work, INCOSE IS 2026 paper preparation) land first, and `flexo-rtm` implementation code references those artifacts from its ADRs. See [[ADR-009 Two-Repo Strategy]] for the two-repo mechanism that follows from this ordering.

## References

- [[Design Spec]] §1 (Mission and Thesis), §2 (Cadence and Approach)
- [[Mission and Thesis]] — wiki page that elaborates the foundations-first stance
- [[ADR-009 Two-Repo Strategy]] — the repo mechanism this decision creates
