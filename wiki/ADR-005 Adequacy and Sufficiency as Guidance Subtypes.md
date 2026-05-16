<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-005: Adequacy and Sufficiency as Guidance Subtypes

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-015 GSN Adoption for Adequacy and Sufficiency]]; [[ADR-021 Three Attestation Subclasses Ship in v0.1]]; [[Aspect Coverage with Adequacy and Sufficiency]]; [[Design Spec]]

## Context

A satisfaction claim ("design element D satisfies requirement R") is mechanically checkable in principle but rests on two engineering judgments that are not: (a) **adequacy** — is the model itself adequate to make the claim? (i.e., is D the right kind of artifact for this claim?); (b) **sufficiency** — is the evidence sufficient to support the claim? (i.e., does the cited verification actually demonstrate what the claim says?). These judgments are where institutional reviewers and assurance-case authors spend their attention, but a flat `rtm:satisfies` relation hides them. The question is whether to surface adequacy and sufficiency as **first-class Guidance subtypes** in the v0.1 ontology, or to fold them into a single Guidance type and rely on tagging. See [[Design Spec]] §4.4 and [[Aspect Coverage with Adequacy and Sufficiency]].

## Decision

`flexo-rtm` v0.1 ontology defines two **explicit Guidance subtypes**: `rtm:AdequacyGuidance` and `rtm:SufficiencyGuidance`. The corresponding attestation subclasses (`rtm:AdequacyAttestation`, `rtm:SufficiencyAttestation`) — see [[ADR-021 Three Attestation Subclasses Ship in v0.1]] — surface the engineer-judgment checkpoints as named, queryable, attestable claim types alongside `rtm:SatisfactionAttestation`. Coverage metrics (see [[ADR-004 Quantitative Certification Outcome]]) report coverage per type per aspect.

## Consequences

### Positive

- Engineer judgment is **surfaced**, not hidden: an audit report can show "satisfaction coverage is 100% but adequacy attestation coverage is 30%" — which is exactly the gap a reviewer needs to see
- GSN integration (see [[ADR-015 GSN Adoption for Adequacy and Sufficiency]]) maps cleanly to these subtypes — GSN's adequacy and sufficiency arguments become RDF-projectable
- Attestation infrastructure (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) is uniform across all three claim types: same SHACL named-approver enforcement, same coverage metrics, same audit report format
- Forward-compatible to the topological framework (see [[ADR-003 Topological Framework Documented as Future Work]]): the future closed-triangle audit consumes adequacy and sufficiency attestations directly

### Negative / Tradeoffs

- Two more vocabulary commitments to maintain and explain; adopters must understand the distinction between adequacy (about the model) and sufficiency (about the evidence)
- Some institutions conflate the two informally — they will need to either adopt the distinction or carry attestations of both type uniformly

### Neutral

- The split aligns with how INCOSE and assurance-case communities already discuss the topic — it's a vocabulary commitment to an existing distinction, not an invention

## Alternatives Considered

- **Single Guidance type with tagging:** Define one `rtm:Guidance` class and tag instances as `adequacy` or `sufficiency` via a property. Rejected: tagging is structurally weaker than subclassing — SHACL profiles cannot enforce per-type constraints as cleanly, and downstream consumers (audit reports, GSN tooling, the future topological framework) have to dispatch on tag values. Explicit subtypes make the distinction first-class in the ontology and in the attestation infrastructure that consumes it.

## Implementation Notes

`rtm:AdequacyGuidance` and `rtm:SufficiencyGuidance` are defined as subclasses of `rtm:Guidance` in the v0.1 ontology. Corresponding attestation subclasses (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) carry named-approver enforcement via SHACL. Aspect-coverage queries in `oracle/src/oracle/analysis/` report coverage per type. GSN parsimony imports (see [[ADR-015 GSN Adoption for Adequacy and Sufficiency]]) map GSN's adequacy and sufficiency arguments onto these subtypes.

## References

- [[Design Spec]] §4.4 (Adequacy and Sufficiency Surfacing), §9.A.3 (Attestation Coverage)
- [[Aspect Coverage with Adequacy and Sufficiency]] — the coverage model and SPARQL recipes
- [[ADR-015 GSN Adoption for Adequacy and Sufficiency]] — GSN as the elaborated argument structure
- [[ADR-021 Three Attestation Subclasses Ship in v0.1]] — the attestation subclasses that surface these
