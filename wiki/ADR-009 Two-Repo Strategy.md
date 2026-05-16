<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-009: Two-Repo Strategy

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-001 Foundations First Approach]]; [[ADR-008 Repo Name and Org Transfer Plan]]; [[Design Spec]]

## Context

The foundations-first approach (see [[ADR-001 Foundations First Approach]]) generates two qualitatively different kinds of output: (a) research artifacts — design spec, wiki pages, ADRs, mathematical elaborations, future-work documentation, paper drafts; (b) implementation artifacts — code, tests, ontology files, SHACL shapes, CI configuration, release artifacts. A monorepo holds both together but bloats the implementation repo with research history irrelevant to a software adopter; a single research-only repo with no implementation pair leaves the implementation homeless. The question is which split is right for v0.1. See [[Design Spec]] §0 and §2.

## Decision

The project uses a **two-repo strategy**: `flexo-rtm-research` (this repo) holds research, design spec, wiki, ADRs, future-work documentation, paper drafts; `flexo-rtm` (the implementation repo, see [[ADR-008 Repo Name and Org Transfer Plan]]) holds code, tests, ontology files, SHACL shapes, CI, release artifacts. The research repo is built **first**, then `flexo-rtm` is initialized referencing this repo's ADRs and design spec.

## Consequences

### Positive

- Clean separation of concerns: software adopters of `flexo-rtm` get a tidy implementation repo; researchers and reviewers of the design get a complete research artifact in `flexo-rtm-research`
- The research-first ordering is what makes the foundations-first approach (see [[ADR-001 Foundations First Approach]]) work — the design spec, wiki, and ADRs exist before code begins, and `flexo-rtm` ADRs point at this repo as their source of authority
- Two repos can be versioned, licensed, and governed independently (research repo CC-BY-4.0 + MIT for code samples; implementation repo MIT or Apache-2.0 as a separate decision)
- Cross-repo links via stable URLs (and eventual OpenMBEE org transfer — see [[ADR-008 Repo Name and Org Transfer Plan]]) are auditable and reproducible

### Negative / Tradeoffs

- Cross-repo coordination overhead: an ADR change here that affects the implementation requires a parallel change in `flexo-rtm`; mitigated by treating this repo as the canonical source of design authority and `flexo-rtm` ADRs as pointers
- Two repos to maintain, two CI setups, two release cadences; mitigated by the research repo being mostly-additive (new wiki pages, new ADRs) rather than feature-churning
- Newcomers may be unclear which repo to look at first; mitigated by a clear README in both repos with cross-links

### Neutral

- The split mirrors the conventional distinction in published research between the paper (canonical narrative) and the supplementary code (reproduction artifact), but at a larger scale and with two-way cross-references

## Alternatives Considered

- **Monorepo (research + implementation together):** One repo with `docs/`, `wiki/`, `oracle/`, `tests/` all in the same tree. Rejected: bloats the implementation repo with research history (paper drafts, design iterations, exploratory notes) that is irrelevant and confusing to software adopters. The cleanliness of an implementation repo affects adoption — adopters want a repo they can clone, read the README, and understand quickly. A monorepo undermines that.

## Implementation Notes

- `flexo-rtm-research` (this repo) is built first; this wiki, the design spec, and all 26 ADRs land here before `flexo-rtm` initialization
- `flexo-rtm` ADRs reference this repo's design spec by stable URL; the canonical authority for any design decision lives in this repo's wiki
- Both repos follow the same org-transfer plan (see [[ADR-008 Repo Name and Org Transfer Plan]]): personal namespace through foundations, OpenMBEE org at MVP service
- A sync script (`scripts/sync-wiki.sh`) mirrors this repo's `wiki/` directory to the GitHub wiki repository; the wiki repo is a published mirror and is never directly edited

## References

- [[Design Spec]] §0 (Repo Identity), §2 (Cadence and Approach)
- [[ADR-001 Foundations First Approach]] — the approach this repo strategy enables
- [[ADR-008 Repo Name and Org Transfer Plan]] — the org-home plan that applies to both repos
