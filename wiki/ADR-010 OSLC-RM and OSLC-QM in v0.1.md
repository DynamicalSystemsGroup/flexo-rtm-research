<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-010: OSLC-RM and OSLC-QM in v0.1

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-011 Lossless Criterion A plus C]]; [[OSLC RM Adapter Contract]]; [[OSLC QM Adapter Contract]]; [[OSLC RM and QM Review]]; [[Lossless Roundtrip Definition]]; [[Design Spec]]

## Context

Institutional adoption of `flexo-rtm` requires interoperability with the OSLC ecosystem — DOORS, Jama, Polarion, qTest, and other standards-conformant tools that institutions already have heavy investment in. OSLC-RM (Requirements Management) and OSLC-QM (Quality Management) are the relevant linked-data domains: RM is where requirement records, satisfies/satisfiedBy relations, and design-element links live; QM is where verification activities, test results, and verdicts live. A partial adapter (RM only) leaves the verification half of the RTM dependent on non-OSLC source data; no adapter at all forecloses the interoperability story entirely. The decisive constraint is that institutional partners have said explicitly: "we cannot get institutional adoption if we cannot demonstrably roundtrip losslessly." See [[Design Spec]] §9 and [[OSLC RM and QM Review]].

## Decision

`flexo-rtm` v0.1 ships **full OSLC-RM adapter and full OSLC-QM adapter** with **lossless roundtrip tests** (see [[ADR-011 Lossless Criterion A plus C]] and [[Lossless Roundtrip Definition]]). Both adapters support read (project upstream OSLC resources into the RTM graph) and write (project RTM-graph facts back to OSLC endpoints). Lossless roundtrip is a hard CI gate, not a "best-effort" claim.

## Consequences

### Positive

- Institutional adoption is unblocked: adopters can integrate with existing OSLC-RM and OSLC-QM tools and demonstrate to their audit teams that no data is lost in translation
- Verification coverage (the QM side) is on equal standing with requirement coverage (the RM side) — both halves of the RTM are first-class
- The lossless roundtrip CI gate makes "we support OSLC" a verifiable claim, not a marketing statement
- The OSLC adapter pattern is the integration surface that downstream identity and crypto adapters (see [[ADR-023 Cryptography by Composition of Battle-Tested Standards]] and [[ADR-024 Identity by Thin Projection of External Sources]]) follow as well

### Negative / Tradeoffs

- Two full adapters in v0.1 is significant implementation scope; the lossless requirement adds substantial test infrastructure
- OSLC-RM and OSLC-QM both have vendor extensions that real adopters depend on — the lossless criterion has to handle them (see [[ADR-011 Lossless Criterion A plus C]] for the A+C combination that addresses this)
- Adopters without OSLC sources can still use `flexo-rtm` (the RDF graph is the canonical authority), but they don't get the headline integration story

### Neutral

- The adapter contracts are first-class wiki documents ([[OSLC RM Adapter Contract]] and [[OSLC QM Adapter Contract]]) so that adopters extending to non-shipping tools have a stable contract to follow

## Alternatives Considered

- **RM only:** Ship OSLC-RM adapter, defer QM. Rejected: half-RTM. The institutional value of an RTM is precisely the bidirectional trace through requirements *and* verification. Verification coverage being non-OSLC means the QM half is non-integrated for the institutional partners that have the most legacy OSLC investment.
- **RM full + QM contract (no adapter):** Document the QM adapter contract but defer the implementation. Rejected: the contract without an implementation is unverifiable. Lossless roundtrip is a CI-enforced property, not a documented intent.
- **Neither (RDF-native only, no OSLC):** Ship the RDF graph and SHACL profiles with no OSLC adapters. Rejected: forecloses institutional adoption. The OSLC ecosystem is where the legacy investment is, and the design spec is explicit that adoption depends on demonstrable lossless integration.

## Implementation Notes

OSLC-RM and OSLC-QM adapters live in `oracle/src/oracle/storage/oslc/` (write-side adapters are part of the storage layer ingress per [[ADR-006 Three-Layer Architecture]]). The adapter contracts are documented in [[OSLC RM Adapter Contract]] and [[OSLC QM Adapter Contract]]. Lossless roundtrip tests (see [[Lossless Roundtrip Definition]] and [[ADR-011 Lossless Criterion A plus C]]) live in `tests/oslc/` and are a hard CI gate. Vendor-extension carry-through (see [[Vendor Extension Carry-Through]]) is implemented as Layer C opaque carry of source-preserving graphs.

## References

- [[Design Spec]] §9 (OSLC Adapters and Lossless Roundtrip)
- [[OSLC RM Adapter Contract]] — the RM adapter contract
- [[OSLC QM Adapter Contract]] — the QM adapter contract
- [[OSLC RM and QM Review]] — review of OSLC spec coverage
- [[Lossless Roundtrip Definition]] — the lossless property
- [[ADR-011 Lossless Criterion A plus C]] — the specific lossless criterion
