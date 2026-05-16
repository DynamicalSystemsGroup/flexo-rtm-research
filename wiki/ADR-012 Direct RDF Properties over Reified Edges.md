<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-012: Direct RDF Properties over Reified Edges

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-021 Three Attestation Subclasses Ship in v0.1]]; [[Layered Ontology]]; [[Design Spec]]

## Context

The core RTM relations — `rtm:satisfies`, `rtm:verifies`, `rtm:dependsOn`, `rtm:traces` — are edges between resources. In RDF, edges can be modeled as **direct properties** (`<R> rtm:satisfiedBy <D>`) or as **reified edges** (`<E> a rtm:Satisfaction; rtm:from <R>; rtm:to <D>`). Reification gives every edge an IRI to which attestations, timestamps, evidence, and provenance can attach; direct properties are leaner but require attestation and provenance to attach via the edge's endpoints rather than the edge itself. For RTM, the relevant question is whether **attestations** need to attach to the edge or whether they can attach to a separate `rtm:Attestation` resource that *references* the edge's endpoints. See [[Design Spec]] §6 and [[Layered Ontology]].

## Decision

`flexo-rtm` v0.1 uses **direct RDF properties for edges** (not reified). `rtm:satisfies`, `rtm:verifies`, `rtm:dependsOn` are direct properties between resources. **Attestations** are separate `rtm:Attestation` resources (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) that reference both endpoints of the edge they attest to via `rtm:attestsClaim` (a triple-shaped reference) plus `rtm:approvedBy`. SHACL enforces structural validity — `rtm:Attestation` instances must reference a real edge — without requiring the edge itself to be reified.

## Consequences

### Positive

- Leaner data model: a satisfaction edge is a single triple, not a four-triple reification (resource + from + to + type)
- Attestation infrastructure (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) is decoupled from edge representation — attestations can be added or revoked without rewriting the edge
- SPARQL queries over the RTM graph are simpler and faster — forward and backward trace are direct property paths, not joins through reification
- OSLC adapter mapping (see [[ADR-010 OSLC-RM and OSLC-QM in v0.1]]) is straightforward — OSLC's `oslc_rm:satisfiedBy` maps to `rtm:satisfiedBy` directly

### Negative / Tradeoffs

- Properties on the edge itself (e.g., "this satisfies-edge was approved by X with confidence Y") cannot attach to the edge — they have to attach to an `rtm:Attestation` resource that references both endpoints
- Some assurance-case tooling expects reified edges; an export-time projection may be needed to surface reification-style views

### Neutral

- Forward-compatible to the topological framework (see [[ADR-003 Topological Framework Documented as Future Work]]): the framework consumes `rtm:AssuranceFace` instances (themselves first-class resources) that reference vertex IRIs — the framework does not require the underlying RTM edges to be reified

## Alternatives Considered

- **Reified edges:** Every satisfies/verifies edge is a first-class `rtm:Satisfaction` resource with `rtm:from` and `rtm:to`. Attestations attach directly to the edge resource. Rejected: heavier data model, more SPARQL join overhead, OSLC adapter mapping less direct. The benefit (attestations attach to the edge itself) is achievable equivalently by `rtm:Attestation` resources that reference the edge's endpoints — and SHACL on `rtm:Attestation` enforces structural validity equally well.

## Implementation Notes

The v0.1 ontology in `flexo-rtm` defines edges as direct properties:

- `rtm:satisfiedBy` (Requirement → DesignElement)
- `rtm:verifiedBy` (DesignElement → VerificationActivity)
- `rtm:traces` (general trace relation)
- inverses where relevant

`rtm:Attestation` (and its subclasses — see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) is a separate resource with:

- `rtm:attestsClaim` — references the edge's source endpoint
- `rtm:attestsClaimTarget` — references the edge's target endpoint
- `rtm:attestationKind` — satisfaction / adequacy / sufficiency
- `rtm:approvedBy` — named approver IRI (enforced via SHACL `sh:minCount 1` + `sh:nodeKind sh:IRI`)

SHACL profiles (see [[ADR-016 Composable SHACL Profiles]]) enforce that referenced endpoints exist and have the expected types.

## References

- [[Design Spec]] §6.3 (Edge Representation), §6.4 (Attestation Vocabulary)
- [[Layered Ontology]] — the layered ontology model
- [[ADR-021 Three Attestation Subclasses Ship in v0.1]] — the attestation resources that decouple
- [[Attestation Infrastructure in v0.1]] — the attestation contract and SHACL enforcement
