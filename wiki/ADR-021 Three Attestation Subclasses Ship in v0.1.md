<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-021: Three Attestation Subclasses Ship in v0.1

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-003 Topological Framework Documented as Future Work]]; [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]]; [[ADR-024 Identity by Thin Projection of External Sources]]; [[Attestation Infrastructure in v0.1]]; [[Human-AI Accountability]]; [[Design Spec]]

## Context

The topological framework is a related research line, not `flexo-rtm`'s destination (see [[ADR-032 Methodology Agnosticism as Foundational Axiom]] and [[ADR-003 Topological Framework Documented as Future Work]]). The **attestation infrastructure** — the named-human assertions that satisfaction, adequacy, and sufficiency claims have been reviewed by an accountable person — is what `flexo-rtm` IS: settled engineering in its own right (W3C VC Data Integrity, SLSA in-toto, Sigstore + Fulcio, git GPG/SSH signing, NIST SP 800-63, W3C SHACL composed for SysMLv2 traceability). The ADCS prototype's regression corpus already contains adequacy and sufficiency attestations; v0.1 must support them to pass regression tests. The question is whether v0.1 ships (a) **no attestation infrastructure**, (b) **satisfaction attestations only**, or (c) **all three attestation subclasses** (satisfaction, adequacy, sufficiency). The answer hinges on what attestation actually requires: a single named-human assertion about a single claim, which is independent of any specific downstream-analysis methodology (topological or otherwise). See [[Design Spec]] §9.A.3 and [[Attestation Infrastructure in v0.1]].

## Decision

`flexo-rtm` v0.1 ships **three `rtm:Attestation` subclasses**: `rtm:SatisfactionAttestation` (verifies `rtm:satisfies` claims), `rtm:AdequacyAttestation` (model adequate for claim — see [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]]), `rtm:SufficiencyAttestation` (evidence sufficient for claim). All three share **named-approver SHACL enforcement** (`sh:minCount 1`, `sh:nodeKind sh:IRI` on `rtm:approvedBy`). What is **not in `flexo-rtm`** is the closed-triangle audit and the recursive completeness check ("is the guidance itself fit-for-purpose?") — these are problems in the topological research line (see [[Topological Framework Future Work]]), which is one possible downstream-analysis path adopters may choose to run on top of `flexo-rtm`'s data, not part of `flexo-rtm` itself.

## Consequences

### Positive

- Passes the ADCS regression corpus: adequacy and sufficiency attestations are first-class v0.1 features, matching the prototype's data model
- Surfaces engineer judgment (see [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]]) — adequacy and sufficiency are nameable, queryable, attestable, coverage-measurable claim types
- Uniform infrastructure across all three subclasses: same SHACL enforcement, same coverage metrics (see [[ADR-004 Quantitative Certification Outcome]]), same audit report format
- Forward-compatible interop for any downstream-analysis path that needs named human signers (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]): adopters who choose to run a topological audit as a downstream-analysis mode read these attestations as the named-approver-bearing inputs to closed-triangle analysis; adopters running SLSA, GSN, ARP4754A, or custom in-house analyses read them equally
- Identity boundary is clean (see [[ADR-024 Identity by Thin Projection of External Sources]]): `rtm:approvedBy` references identity IRIs owned by external authoritative sources

### Negative / Tradeoffs

- Three subclasses to document, test, and explain — adopters have to learn the distinction; mitigated by clear documentation and uniform infrastructure
- Named-approver enforcement requires identity infrastructure (see [[ADR-024 Identity by Thin Projection of External Sources]]) — adopters must integrate with an identity provider before they can author attestations

### Neutral

- Composable optional SHACL profiles (see [[ADR-016 Composable SHACL Profiles]]): `attested-satisfies`, `attested-adequacy`, `attested-sufficiency`, `aspect-coverage` — each can be required or relaxed per cert run

## Alternatives Considered

- **Couple attestation infrastructure to the topological research line:** Treat attestation as something to ship only when (or if) the topological framework matures. Rejected: per [[ADR-032 Methodology Agnosticism as Foundational Axiom]], `flexo-rtm` is methodology-agnostic; named-signer accountability is settled engineering on its own and not on any specific assurance methodology's critical path. The ADCS regression corpus uses adequacy and sufficiency attestations today; v0.1 must support them to pass regression tests. Each attestation is an independent named-human assertion about a single claim; it does not depend on any topological audit or registry commitment.
- **Only satisfaction attestations (no adequacy/sufficiency):** Ship `rtm:SatisfactionAttestation` only; defer adequacy and sufficiency. Rejected: cuts engineer judgment surfacing (see [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]]) — the whole point of the adequacy/sufficiency split is to make those checkpoints first-class, attestable, and coverage-measurable. Shipping satisfaction alone reproduces the flat-claim limitation that the ADCS prototype lessons (see [[ADCS Prototype Lessons]]) explicitly identified as a gap to close. The split is independently meaningful for traditional traceability and consumable by any downstream analysis adopters may choose to run.

## Implementation Notes

- v0.1 ontology defines `rtm:Attestation` (abstract) with three concrete subclasses: `rtm:SatisfactionAttestation`, `rtm:AdequacyAttestation`, `rtm:SufficiencyAttestation`
- SHACL named-approver constraints in `ontology/profiles/attested-satisfies.ttl`, `ontology/profiles/attested-adequacy.ttl`, `ontology/profiles/attested-sufficiency.ttl` (composable per [[ADR-016 Composable SHACL Profiles]])
- `aspect-coverage` profile (`ontology/profiles/aspect-coverage.ttl`) sets coverage thresholds per claim type per aspect for the derived binary view (see [[ADR-019 Derived Binary View from Quantitative Metrics]])
- `rtm:approvedBy` references identity IRIs (see [[ADR-024 Identity by Thin Projection of External Sources]])
- What is **not** in `flexo-rtm`: closed-triangle audit, recursive completeness check, registry-of-pre-approved-types — these belong to the topological research line (see [[ADR-003 Topological Framework Documented as Future Work]] and [[ADR-032 Methodology Agnosticism as Foundational Axiom]]), which is one possible downstream-analysis path on top of `flexo-rtm`'s data, not part of `flexo-rtm` itself

## References

- [[Design Spec]] §9.A.3 (Attestation Infrastructure), §9.A.4 (Profile Acceptance)
- [[Attestation Infrastructure in v0.1]] — canonical attestation infrastructure documentation
- [[Human-AI Accountability]] — the accountability framing
- [[ADCS Prototype Lessons]] — regression corpus this passes
- [[ADR-024 Identity by Thin Projection of External Sources]] — the identity infrastructure attestations depend on
- [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — names attestation as part of what `flexo-rtm` IS, independent of any specific downstream-analysis methodology
