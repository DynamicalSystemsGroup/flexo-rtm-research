<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-025: Reproducibility is Structural and Local

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-022 External URI References as Open-Source Foundation]]; [[ADR-023 Cryptography by Composition of Battle-Tested Standards]]; [[ADR-024 Identity by Thin Projection of External Sources]]; [[Verifiable Self-Certification]]; [[Transcript Replay Semantics]]; [[Design Spec]]

## Context

A cert artifact's value depends on its reproducibility — auditors need to verify that the recorded facts are what they say they are. The naïve framing of reproducibility is **global**: a verifier dereferences the entire RTM graph, re-fetches every external dependency, replays every transcript step, and confirms equivalence. That framing assumes a single verifier with universal permissions, which breaks in real institutional contexts: different parties have different permission slices (the safety reviewer can see safety-scope facts but not security-scope facts; the regulatory submitter can see compliance facts but not internal IP), and no single party has universal access. A reproducibility model that requires universal permissions cannot be exercised in multi-party institutional audits. The question is whether v0.1's reproducibility model is global-and-monolithic or structural-and-local. See [[Design Spec]] §9.A.5 (cross-cutting acceptance criteria X6, X7, X8) and [[Verifiable Self-Certification]].

## Decision

`flexo-rtm` v0.1's reproducibility model is **structural and local**: each fact in the cert artifact is **structurally complete for its own local context** — the RDF neighborhood, external URI references (see [[ADR-022 External URI References as Open-Source Foundation]]), projection-at-cert-time (see [[ADR-024 Identity by Thin Projection of External Sources]]), and signatures (see [[ADR-023 Cryptography by Composition of Battle-Tested Standards]]) sufficient to **reproduce that fact in isolation**. Verifying parties need only the permissions for the facts they want to verify, not universal access. Reproduction federates **computationally** (compute distributes across parties) and **organizationally** (different parties verify different permission slices, composing to a complete audit). Cross-cutting acceptance criteria **X6, X7, X8** (Design Spec §9.A.5) enforce this property.

## Consequences

### Positive

- Multi-party institutional verification works without central coordination: each party verifies its own permission slice; the composition of all slices is the complete audit
- Locality is a **property of the cert artifact**, not a property of the verifier — the artifact is structurally complete fact-by-fact, so the verifier doesn't need universal access to verify any single fact
- Refresh policy (see [[ADR-024 Identity by Thin Projection of External Sources]]) and reproducibility are **not in tension**: refresh is an authoring-time freshness setting; reproduction always operates against the **recorded projection-at-cert-time**, never against fresh data
- Federated computational verification: parties can verify in parallel; no single computational bottleneck
- Forward-compatible to the topological framework (see [[ADR-003 Topological Framework Documented as Future Work]]) — when the framework lands, the recursive completeness check operates over the same structurally-local facts

### Negative / Tradeoffs

- "Structurally complete for its own local context" is more nuanced to document and explain than "globally reproducible"; mitigated by clear documentation in [[Verifiable Self-Certification]] and by the acceptance criteria X6/X7/X8 enforcing the property mechanically
- Cert-artifact size grows with locality completeness — each fact carries its neighborhood, external references, projection-at-time, and signatures; mitigated by the lean-default ontology (see [[ADR-014 Parsimony Layer Build-Time Extraction]]) and by external references being URI-sized (cheap)
- Federation requires permission infrastructure on the verifier side; adopters integrating with their own permission systems must respect the locality property

### Neutral

- The three reproducibility dimensions compose: (1) RDFC-1.0 canonical equivalence (see [[ADR-011 Lossless Criterion A plus C]]), (2) transcript replay (see [[Transcript Replay Semantics]]), (3) external-URI re-fetch and re-execute (see [[ADR-022 External URI References as Open-Source Foundation]]) — all three operate locally per fact

## Alternatives Considered

- **Treat reproducibility as a single global property requiring a verifier to re-dereference the whole graph and hold universal permissions:** A single verifier with universal access dereferences everything, re-fetches every dependency, replays every transcript, and emits a global pass/fail signal. Rejected: that framing breaks in multi-party institutional contexts where different parties have different permission slices. No single party can hold universal permissions across safety, security, compliance, IP, and personnel boundaries. The chosen framing — each fact is structurally complete for its own local context, verification is local in the traceability graph, and reproduction federates computationally and organizationally — is what makes the cert artifact **usable in real institutional audits** where no single party has universal access. Refresh policy and reproducibility are not in tension: refresh affects authoring-time freshness; reproduction always operates against the recorded projection-at-cert-time.

## Implementation Notes

- Cross-cutting acceptance criteria **X6 (structural locality), X7 (federated computational verification), X8 (federated organizational verification)** documented in [[Design Spec]] §9.A.5 — these are the mechanical enforcement points
- Cert artifact format records, per fact: (a) RDF neighborhood (sufficient for local SPARQL verification), (b) external URI references (see [[ADR-022 External URI References as Open-Source Foundation]]), (c) projection-at-cert-time for identity policies (see [[ADR-024 Identity by Thin Projection of External Sources]]), (d) signatures and DSSE/cosign/Rekor pointers (see [[ADR-023 Cryptography by Composition of Battle-Tested Standards]])
- The cert artifact is the canonical reproducibility unit; transcript replay (see [[Transcript Replay Semantics]]) operates per fact
- Audit reports include a **reproducibility manifest** (per [[ADR-022 External URI References as Open-Source Foundation]]) enumerating every external URI per fact, supporting federated verification
- See [[Verifiable Self-Certification]] for the canonical documentation of the reproducibility model and the structural-locality property

## References

- [[Design Spec]] §9.A.5 (Cross-cutting Acceptance Criteria X6/X7/X8), §4.9 (Reproducibility Chain)
- [[Verifiable Self-Certification]] — canonical cert-artifact and reproducibility documentation
- [[Transcript Replay Semantics]] — the per-fact transcript replay model
- [[ADR-022 External URI References as Open-Source Foundation]] — external-URI dimension
- [[ADR-023 Cryptography by Composition of Battle-Tested Standards]] — signature dimension
- [[ADR-024 Identity by Thin Projection of External Sources]] — projection-at-cert-time dimension
- [[ADR-011 Lossless Criterion A plus C]] — RDFC-1.0 dimension
