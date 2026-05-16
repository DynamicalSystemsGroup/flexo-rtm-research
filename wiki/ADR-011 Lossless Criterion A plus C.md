<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-011: Lossless Criterion A plus C

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-010 OSLC-RM and OSLC-QM in v0.1]]; [[ADR-012 Direct RDF Properties over Reified Edges]]; [[RDFC-1.0 Canonicalization]]; [[Vendor Extension Carry-Through]]; [[Lossless Roundtrip Definition]]; [[Design Spec]]

## Context

The lossless roundtrip requirement (see [[ADR-010 OSLC-RM and OSLC-QM in v0.1]]) needs an operational definition. Three candidate criteria emerged: **A** — graph equivalence under RDFC-1.0 canonicalization (rigorous and machine-checkable, but rejects any structural normalization the adapter performs); **B** — semantic equivalence under OWL entailment (too lenient; entailment-equivalent graphs can differ in ways auditors care about); **C** — opaque carry-through (preserve the source bytes/graph in a sidecar, replay on export). Real OSLC sources carry vendor extensions (custom predicates, custom resource types, custom enumeration values) that adapters cannot normalize without information loss, but the *core* OSLC vocabulary can and should be normalized cleanly. The question is which criterion governs v0.1. See [[Design Spec]] §9.A.2 and [[Lossless Roundtrip Definition]].

## Decision

`flexo-rtm` v0.1's lossless criterion is **A + C**: **A (RDFC-1.0 equivalence)** governs the **core OSLC vocabulary** — the RTM graph after canonical adapter transformation must be RDFC-1.0-equivalent to the source on roundtrip; **C (opaque carry-through)** governs **vendor extensions** — non-core predicates and resources are preserved verbatim in a source-preserving graph layer (see [[Vendor Extension Carry-Through]]) and replayed on export.

## Consequences

### Positive

- Core OSLC vocabulary gets the rigorous, machine-checkable lossless guarantee adopters and auditors require
- Vendor extensions are not dropped — adopters with heavy Doors/Jama customizations don't lose their custom predicates in roundtrip
- The A vs. C distinction is decidable per-triple at adapter design time: if a triple uses core OSLC vocabulary, A applies; otherwise C
- CI gate is straightforward: RDFC-1.0 canonicalize the source, RDFC-1.0 canonicalize the post-roundtrip output, compare; vendor extensions are excluded from the RDFC comparison and compared byte-for-byte via the source-preserving graph

### Negative / Tradeoffs

- Two-tier lossless model is more complex to document and explain than a single criterion
- The boundary between "core" and "vendor extension" has to be defined explicitly per adapter version; mitigated by binding the boundary to OSLC spec versions and documenting it in [[OSLC RM Adapter Contract]] and [[OSLC QM Adapter Contract]]
- Source-preserving graphs add storage overhead — every adapter ingestion stores the original source graph plus the canonical RDF graph

### Neutral

- The A+C combination composes cleanly with the three-layer architecture (see [[ADR-006 Three-Layer Architecture]]) — source-preserving graphs live in storage alongside the canonical graph

## Alternatives Considered

- **A only (RDFC-1.0 equivalence, no vendor-extension carry):** Drop everything that does not survive canonical adapter transformation. Rejected: real OSLC adopters have vendor extensions they depend on; dropping them silently is the opposite of lossless. Hard fail for institutional adoption.
- **C only (opaque carry-through):** Treat every roundtrip as an opaque sidecar replay; do not require canonical equivalence on the core vocabulary. Rejected: the core OSLC vocabulary *is* the integration surface — losing rigor there means the canonical RDF graph in `flexo-rtm` is no longer the authoritative view, just one of many opaque copies. Auditors cannot reason about an opaque copy.

## Implementation Notes

- RDFC-1.0 canonicalization implementation lives in `oracle/src/oracle/storage/canonical/` (see [[RDFC-1.0 Canonicalization]])
- Source-preserving graphs for vendor extensions live in `oracle/src/oracle/storage/sources/` (see [[Vendor Extension Carry-Through]])
- Adapter contracts ([[OSLC RM Adapter Contract]], [[OSLC QM Adapter Contract]]) explicitly enumerate the core OSLC vocabulary the A criterion applies to and the boundary at which C takes over
- CI tests live in `tests/oslc/lossless/` and execute the A+C protocol on a regression corpus of source graphs

## References

- [[Design Spec]] §9.A.2 (Lossless Criterion)
- [[Lossless Roundtrip Definition]] — the formal property and A+C composition
- [[RDFC-1.0 Canonicalization]] — the canonicalization implementation
- [[Vendor Extension Carry-Through]] — the C-layer mechanism
- [[ADR-010 OSLC-RM and OSLC-QM in v0.1]] — the OSLC adapter scope
- W3C RDF Dataset Canonicalization 1.0 (RDFC-1.0): https://www.w3.org/TR/rdf-canon/
