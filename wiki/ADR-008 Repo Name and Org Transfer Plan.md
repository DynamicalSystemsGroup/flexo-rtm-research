<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-008: Repo Name and Org Transfer Plan

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-009 Two-Repo Strategy]]; [[Flexo Git Coexistence]]; [[Design Spec]]

## Context

The implementation repository needs a stable name before publication, and an organizational home that signals the project's MBSE and OSLC alignment. A name that bakes in "oracle" or "protocol" terminology forecloses framing decisions; a name that is too generic ("rtm") collides with prior art. The org-home question matters because partner institutions and standards bodies engage with the org, not just the repo. See [[Design Spec]] §0 (repo identity) and [[Flexo Git Coexistence]].

## Decision

The implementation repository is named **`flexo-rtm`**. Initial development happens in the author's personal namespace; **at MVP service milestone**, the repo transfers to the **OpenMBEE** GitHub organization as its long-term home.

## Consequences

### Positive

- `flexo-rtm` reads naturally and signals the relationship to Flexo (the storage-layer authority pattern) without baking in "oracle" or "protocol" terminology
- The OpenMBEE org home aligns the project with the MBSE / SysMLv2 community of practice and with the standards bodies the research-implement-standardize cadence targets
- Deferring transfer until MVP service avoids early-stage governance overhead while the project is still iterating on foundations
- Personal-namespace development keeps the iteration cadence fast in the foundations-first phase (see [[ADR-001 Foundations First Approach]])

### Negative / Tradeoffs

- A future rename or org-transfer creates URL churn that adopters have to track; mitigated by waiting until MVP service to transfer
- The "transfer at MVP service" milestone has to be defined explicitly; ambiguity here invites delay

### Neutral

- The two-repo strategy (see [[ADR-009 Two-Repo Strategy]]) means `flexo-rtm-research` (this repo) also has an org-home question; it follows the same plan

## Alternatives Considered

- **`rtm-oracle`:** Bakes "oracle" terminology into the repo name. Rejected: "oracle" is one framing of the certification predicate, not the project's identity. The Flexo coexistence story (see [[Flexo Git Coexistence]]) is more central than the oracle framing.
- **`sysml-rtm-oracle`:** Adds SysMLv2 anchoring (see [[ADR-002 SysMLv2 Anchoring]]) to the name. Rejected: SysMLv2 anchoring is the v0.1 scope reducer, not a permanent identity commitment; the architecture supports other anchors over time. Baking SysMLv2 into the name forecloses the future.
- **`rtm-protocol`:** Frames the project as a protocol. Rejected: while there is a protocol component (OSLC adapters, attestation contracts), the project is more than a protocol — it is an oracle service plus the storage / analysis infrastructure that surrounds it. "Protocol" undersells the architecture.

## Implementation Notes

The `flexo-rtm` repo URL is the canonical reference in all wiki cross-links and in the design spec. At MVP service milestone, an org transfer to OpenMBEE is executed via GitHub's repository transfer; old URLs continue to redirect, but documentation and CI configurations are updated to reference the new canonical URL. The same plan applies to `flexo-rtm-research` (this repo) — see [[ADR-009 Two-Repo Strategy]].

## References

- [[Design Spec]] §0 (Repo Identity)
- [[Flexo Git Coexistence]] — the Flexo relationship the name signals
- [[ADR-009 Two-Repo Strategy]] — the companion repo that follows the same plan
- OpenMBEE organization: https://github.com/Open-MBEE
