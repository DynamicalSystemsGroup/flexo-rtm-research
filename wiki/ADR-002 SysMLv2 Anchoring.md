<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-002: SysMLv2 Anchoring

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-010 OSLC-RM and OSLC-QM in v0.1]]; [[OMG SysMLv2]]; [[Design Spec]]

## Context

An RTM oracle could in principle be domain-general, claiming to certify traceability for any modeling language, any requirement format, any verification tool. That generality is a scope-explosion: there is no concrete schema to bind to, no canonical IRI scheme, no community of practice to validate against. The opposite extreme — proprietary anchoring to one vendor's tool — sacrifices the open-source interoperability story that makes the cert artifact valuable. The question is which **public, standardized, vendor-neutral, OMG-conformant** anchor to commit to as the canonical modeling reference for v0.1. See [[Design Spec]] §3 (anchoring) and §6 (ontology import strategy).

## Decision

`flexo-rtm` v0.1 anchors on **OMG SysMLv2** as the canonical systems-modeling reference. Requirements, design elements, and verification activities in the RTM graph carry SysMLv2-conformant IRIs (or thin SysMLv2-projected IRIs when the source data is from a non-SysMLv2 tool reached via OSLC-RM). SysMLv2 is the **scope reducer** that makes the v0.1 schema concrete.

## Consequences

### Positive

- Gives a concrete, OMG-standardized vocabulary to bind to, eliminating the "what is a requirement, exactly?" definition battle
- SysMLv2 is itself published in a textual notation with a defined metamodel, which is friendly to MIREOT/SLME parsimony extraction (see [[ADR-014 Parsimony Layer Build-Time Extraction]])
- Aligns with INCOSE and OMG communities of practice, which are the standards bodies the research-implement-standardize cadence (see [[ADR-001 Foundations First Approach]]) ultimately targets
- Concrete enough to write SHACL profiles against and roundtrip-test (see [[ADR-010 OSLC-RM and OSLC-QM in v0.1]] and [[ADR-011 Lossless Criterion A plus C]])

### Negative / Tradeoffs

- Adopters with SysMLv1, Capella, or pure-OSLC-RM workflows must either upgrade or accept thin SysMLv2 projections of their source data
- v0.1 will surface SysMLv2 maturity gaps (especially tool support) as adoption friction
- The "anchor" framing requires we stay aligned with OMG's SysMLv2 evolution; major spec changes ripple into ontology

### Neutral

- Domain-general support remains achievable via thin adapters; SysMLv2 is the canonical anchor, not the only supported source

## Alternatives Considered

- **No anchoring (fully domain-general):** Define `rtm:Requirement` and `rtm:DesignElement` as abstract classes and let adopters bind their own modeling languages. Rejected: this defers the scope-reduction problem to every adopter, and the resulting RTM graphs are not comparable across institutions. SysMLv2 anchoring keeps the v0.1 ontology concrete enough to write SHACL profiles and roundtrip tests against, while still permitting thin projections from non-SysMLv2 sources.

## Implementation Notes

The SysMLv2 anchor manifests in v0.1 as: (a) MIREOT-extracted SysMLv2 vocabulary in the parsimony layer (see [[ADR-014 Parsimony Layer Build-Time Extraction]]); (b) SysMLv2-conformant IRIs in the canonical RTM graph examples; (c) OSLC-RM adapter (see [[ADR-010 OSLC-RM and OSLC-QM in v0.1]]) producing SysMLv2-projected RDF for non-SysMLv2 sources. Storage and analysis layers consume the SysMLv2-anchored graph identically regardless of upstream source.

## References

- [[Design Spec]] §3 (Anchoring), §6 (Ontology Import Strategy)
- [[OMG SysMLv2]] — wiki page elaborating the anchor and import strategy
- [[INCOSE V2 Review]] — relationship to INCOSE practices
- [[ADR-014 Parsimony Layer Build-Time Extraction]] — how SysMLv2 vocabulary lands in the v0.1 ontology
