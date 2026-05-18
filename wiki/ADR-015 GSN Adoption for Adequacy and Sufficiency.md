<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-015: GSN Adoption for Adequacy and Sufficiency

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]]; [[ADR-014 Parsimony Layer Build-Time Extraction]]; [[ADR-021 Three Attestation Subclasses Ship in v0.1]]; [[GSN Integration]]; [[PROV EARL GSN P-PLAN]]; [[Design Spec]]

## Context

Adequacy and sufficiency claims (see [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]]) are not unique to `flexo-rtm` — they are the same arguments that **Goal Structuring Notation (GSN)** has standardized in the assurance-case community for two decades. GSN gives a formal structure for assurance arguments: Goal nodes (the claim), Strategy nodes (how the claim is decomposed), Solution nodes (the evidence), and Context/Assumption/Justification nodes. The ADCS prototype (`flexo-rtm`'s predecessor — see [[ADCS Prototype Lessons]]) used a flat `AdequacyClaim` / `SufficiencyClaim` vocabulary that did not interoperate with GSN tooling. The question is whether v0.1 adopts GSN as the elaborated argument structure for adequacy and sufficiency claims, or stays with flat claim types. See [[Design Spec]] §8 and [[GSN Integration]].

## Decision

`flexo-rtm` v0.1 **adopts GSN** (parsimony-extracted per [[ADR-014 Parsimony Layer Build-Time Extraction]]) for adequacy and sufficiency claim structure. `rtm:AdequacyGuidance` and `rtm:SufficiencyGuidance` (see [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]]) map onto GSN's Goal/Strategy/Solution structure; assurance arguments can be authored in GSN-compatible tools and projected to RDF. Attestations (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) reference the GSN Goal they attest to.

## Consequences

### Positive

- Interoperability with the assurance-case community: GSN tools (Astah GSN, Adelard ASCE, NOR-STA, AdvoCATE) become potential authoring surfaces for `flexo-rtm` adequacy and sufficiency arguments
- Consistency with the ADCS prototype's experience: ADCS prototype lessons (see [[ADCS Prototype Lessons]]) showed that flat claim types lose argument structure that reviewers need; GSN restores it
- PROV-O + EARL + GSN + P-PLAN compose into a coherent assurance-trace vocabulary (see [[PROV EARL GSN P-PLAN]]) — adopters get a familiar argument structure plus rigorous provenance
- Forward-compatible with any downstream-analysis path that consumes adequacy/sufficiency attestations (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]): adopters who choose to run topological analysis as a downstream-analysis mode (see [[ADR-003 Topological Framework Documented as Future Work]]), GSN-based assurance-case audits, or other in-house analyses read the surrounding argument structure natively. GSN is the elaborated argument structure; the topological framework is one possible downstream-analysis methodology that may compose with it

### Negative / Tradeoffs

- Adopters not already using GSN have to learn its vocabulary; mitigated by the fact that the RTM-level claim types remain `rtm:AdequacyGuidance` / `rtm:SufficiencyGuidance` — GSN is the elaborated structure underneath, not a replacement
- GSN ontology is large; parsimony extraction (see [[ADR-014 Parsimony Layer Build-Time Extraction]]) has to be careful to import only what `flexo-rtm` actually references
- GSN tool maturity varies; v0.1 cannot guarantee a specific authoring tool experience, only that the RDF projection is GSN-conformant

### Neutral

- GSN aliases (flat `rtm:AdequacyClaim` shortcuts to GSN Goal nodes) are not introduced — the GSN structure is the canonical representation

## Alternatives Considered

- **Flat `rtm:AdequacyClaim` / `rtm:SufficiencyClaim` without GSN:** Stay with the ADCS prototype's flat vocabulary. Rejected: loses argument structure that reviewers and assurance-case auditors expect; foregoes interoperability with the assurance-case tool ecosystem; the ADCS prototype's lessons (see [[ADCS Prototype Lessons]]) explicitly identified flat-claim-loss-of-structure as a gap to close in v0.1.
- **GSN + flat aliases:** Adopt GSN but also introduce flat `rtm:AdequacyClaim` aliases for adopters who want them. Rejected: aliasing is a vocabulary maintenance burden and invites adopters to use the aliases instead of learning GSN — defeating the interoperability purpose. The RTM-level Guidance subtypes (see [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]]) are already the abstraction layer; below that, GSN is the canonical argument structure.

## Implementation Notes

- GSN vocabulary parsimony-extracted into `ontology/imports/gsn.ttl` (see [[ADR-014 Parsimony Layer Build-Time Extraction]])
- `rtm:AdequacyGuidance` and `rtm:SufficiencyGuidance` defined as compatible with GSN Goal nodes; canonical RTM examples show the GSN argument structure
- PROV-O + EARL + GSN + P-PLAN integration documented in [[PROV EARL GSN P-PLAN]]
- Attestations (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) reference GSN Goal IRIs via `rtm:attestsClaim`

## References

- [[Design Spec]] §8 (Assurance Argument Structure)
- [[GSN Integration]] — the canonical GSN integration documentation
- [[PROV EARL GSN P-PLAN]] — the composed assurance-trace vocabulary
- [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]] — the Guidance subtypes GSN elaborates
- [[ADCS Prototype Lessons]] — what the prototype taught about flat-claim limitations
- [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — GSN and topological framework are independent downstream-analysis paths, each composable with `flexo-rtm`'s named-signer substrate
- GSN Community Standard v3 (Assurance Case Working Group)
