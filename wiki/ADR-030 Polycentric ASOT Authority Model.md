<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-030: Polycentric ASOT Authority Model

**Status:** Accepted
**Date:** 2026-05-17
**Deciders:** Michael Zargham
**Related:** [[ADR-007 Scope as First-Class RDF Resource]]; [[ADR-024 Identity by Thin Projection of External Sources]]; [[ADR-025 Reproducibility is Structural and Local]]; [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]]; [[Analysis Layer Scope Algebra]]; [[Federated Audit and Composition]]; [[Identity Boundaries and Policy Projections]]; [[Design Spec]] §1, §5.3

## Context

Requirements traceability for mission- and safety-critical systems (aerospace, defense, medical devices, nuclear, automotive autonomy) is organized around a recognizable institutional reality: **multiple organizations hold scoped authorities over different parts of the system**. Engineering teams own their subsystem models. Prime contractors integrate across subsystem suppliers. Regulatory authorities adjudicate compliance. Qualified third-party auditors reproduce evidence. Customer engineering teams accept deliverables. None of these parties is "the" source of truth for the whole system, and any architecture that treats one of them as such generates institutional friction in proportion to how unrealistic that single-source-of-truth assumption is in practice.

This is not just `flexo-rtm`'s observation — it is the explicit posture of the **Modular Open Systems Approach (MOSA)** mandated for DoD acquisition under [10 U.S.C. §4401](https://www.law.cornell.edu/uscode/text/10/4401) and elaborated in the [DoD MOSA Implementation Guidebook (Feb 2025)](https://www.cto.mil/wp-content/uploads/2025/03/MOSA-Implementation-Guidebook-27Feb2025-Cleared.pdf): modular, loosely-coupled authorities with well-defined interfaces, competed and acquired separately. The complementary data-architecture concept — **Authoritative Source of Truth (ASOT)** — is defined by the [DAU Glossary](https://www.dau.edu/glossary/authoritative-source-truth) and the [OMG MBSE Wiki](https://www.omgwiki.org/MBSE/doku.php?id=mbse:authoritative_source_of_truth) as **the governed, access-controlled system of record for a defined scope of data or models** — scoped, not global; multiple ASOTs coexist when their authorities are partitioned by data element, lifecycle phase, discipline, or context, with controlled interfaces between them.

Early framing of `flexo-rtm`'s deployment model occasionally drifted toward "peer-cooperative" or "every collaborator is a peer" language. That overshoots: flat peer-to-peer is unrealistic in the institutional contexts SysMLv2 and RTM are used in. The accurate model is **polycentric** — multiple authority centers, each governing a scope, cooperating through controlled interfaces. This ADR locks that framing as the design's institutional substrate.

## Decision

`flexo-rtm` adopts the **polycentric ASOT authority model** as its institutional-topology commitment. Specifically:

1. **Each [`rtm:Scope`](§5.3) is an [Authoritative Source of Truth](https://www.dau.edu/glossary/authoritative-source-truth) for the data in its named graph.** Authority over a scope's content is held by an identifiable organization, externally projected (per [[ADR-024 Identity by Thin Projection of External Sources]]); `flexo-rtm` does not adjudicate which organization holds which scope's authority.
2. **Multiple ASOTs coexist.** Different scopes are governed by different organizations; the framework does not centralize authority. Authority is partitioned by scope and (optionally) by aspect (`rtm:hasAspect`).
3. **Scopes compose into higher-order scopes without subsuming sub-scope authority.** The scope-algebra operators (`rtm:extends`, `rtm:intersectsWith`, `rtm:union`; see [[Analysis Layer Scope Algebra]]) construct higher-order scopes; the sub-scopes' authorities persist in the composition.
4. **Scopes may overlap.** Two organizations may hold legitimate scoped authority over the same subject matter from different perspectives (a safety authority and a performance authority both having scoped concern over the same propulsion-subsystem requirements). The algebra supports overlap via `rtm:intersectsWith`; the SHACL policy bottleneck enforces both authorities' policies as conjunctive constraints in the intersection. Overlap is the norm in real engineering organizations.
5. **The framework provides substrate; orgs hold authority.** `flexo-rtm` supplies RDF, SHACL, identity projections, attestation infrastructure, scope algebra, and the certification artifact; the **authority over what a scope says** is held externally by the organization the projection identifies. The framework can certify that policies were enforced; it cannot adjudicate which organization is the right authority for a given scope.

The decision is consistent with [MOSA](https://www.cto.mil/sea/mosa/) at the institutional level (modular, loosely-coupled authorities) and [ASOT](https://www.dau.edu/glossary/authoritative-source-truth) at the data level (scoped systems of record). It is the institutional substrate over which the operational primitives of [[Federated Audit and Composition]] (composition certification, scope-level adequacy + sufficiency, qualified-role attestations) operate.

## Consequences

### Positive

- **The data model matches the institutional reality.** Mission/safety-critical engineering already operates polycentrically; the framework reflects that rather than fighting it.
- **No single-database friction.** Authorities are not forced to funnel claims through one runtime; the OSLC adapter contract and v0.2 live connectors integrate incumbent RM tools as additional ASOTs in the composition.
- **Composition is meaningful as more than a union.** Higher-order scopes carry the structure of which sub-authority signed which patch (per [[Federated Audit and Composition]]) — the composition is a real institutional fact, not just a set-theoretic union.
- **Overlap is supported, not pathological.** Real engineering organizations have overlapping authorities; the design models this directly.
- **Aligns with DoD MOSA mandate and DAU/OMG MBSE standard terminology.** Adopters in defense and regulated industries can map `flexo-rtm` constructs to terminology their acquisition and compliance offices already use.

### Negative / Tradeoffs

- **Adopters must declare scoped authority structure.** There is no "default global authority" fallback; small projects must still declare at least one scope and its authority holder. The friction is small for the smallest case but is non-zero.
- **Cross-scope conflict resolution is the adopter's responsibility.** When two overlapping authorities reach incompatible conclusions, the framework reports the conflict via SHACL but does not resolve it; the institutional arrangement decides. (This is the right place to draw the line — adjudication is an institutional act, not a framework act.)
- **The terminology adds a layer of vocabulary** (ASOT, MOSA, scoped authority, polycentric) that adopters new to MBSE governance may need orientation on. Linking back to the canonical DAU/DoD/OMG MBSE definitions keeps the lift contained.

### Neutral

- The polycentric ASOT framing is a clarification of architectural intent that was already implicit in the scope-as-first-class-RDF decision (ADR-007), the identity-as-thin-projection decision (ADR-024), and the locality/federation reproducibility decision (ADR-025). This ADR makes the institutional-topology commitment explicit so future contributors do not drift back toward peer-cooperative or single-source-of-truth framings.

## Alternatives Considered

- **Flat peer-to-peer model** ("every collaborator's git checkout is a peer"). **Rejected.** Unrealistic in aerospace, defense, medical, automotive, and other institutional contexts where SysMLv2 and RTM are used. Erases the legitimate authority structure of regulators, primes, suppliers, and qualified auditors. The framework would model a fiction.
- **Single-source-of-truth model** (one canonical RM database; all authorities funnel through it). **Rejected.** This is the model `flexo-rtm` is specifically designed to improve over. Concentrates institutional friction at the runtime layer; misaligns with the polycentric reality of regulated engineering; works against MOSA principles.
- **Strictly hierarchical authority** (primes own everything below them). **Rejected.** Real engineering authority is not strictly hierarchical: regulators can act outside the contracting hierarchy, qualified auditors can act in parallel, customer engineering teams can act laterally. A strict hierarchy would not represent these legitimate authority flows.
- **Framework-owned authority registry** (`flexo-rtm` maintains a list of who can sign what). **Rejected.** Symmetric with [[ADR-024 Identity by Thin Projection of External Sources]]: identity and authority are owned externally; the framework projects them. Owning the registry would either replicate the single-source-of-truth pathology or force adopters into a registry governance the framework has no standing to operate.

## Implementation Notes

This ADR documents an architectural commitment that is implemented through the **existing** vocabulary and mechanisms of the v0.1 design, plus the org-level identity extension. No new vocabulary terms are added by this ADR itself; the polycentric ASOT model is the **interpretation** that ties them together.

- **Scope authority binding.** Each `rtm:Scope` instance carries `rtm:authorityHolder` (or equivalent — to be confirmed against the canonical RDF schema during v0.1 implementation) referencing the `foaf:Organization` / `org:Organization` that holds authority. See [[Identity Boundaries and Policy Projections]] for the org-level identity surface.
- **Scope overlap.** `rtm:intersectsWith` (per [[Analysis Layer Scope Algebra]]) is the operator that supports overlap; the resulting intersected scope is itself a first-class scope with its own authority composition (typically the conjunction of both source scopes' authorities).
- **Conflict reporting.** When SHACL policy evaluation reveals that two overlapping authorities have conflicting requirements, the conflict is reported in the audit report as an explicit named gap (not silently resolved). v0.1 ships the reporting; conflict-resolution policy (per [[Flexo Git Coexistence]]) is the institutional arrangement, not the framework.
- **Adopter scoping.** Adopters declare their institutional authority structure as part of their `flexo-rtm` configuration: which org holds which scope, which scopes overlap, which qualified-role orgs are part of the composition. The framework does not ship a "default" structure.

## References

- [[Design Spec]] §1 (polycentric institutional topology language), §5.3 (Scope as first-class), §4.4 (identity boundaries), §4.9 (locality + federated verification)
- [[ADR-007 Scope as First-Class RDF Resource]] — the prior decision that scope is a first-class RDF resource; this ADR extends the interpretation
- [[ADR-024 Identity by Thin Projection of External Sources]] — the symmetric decision for identity (org and person)
- [[ADR-025 Reproducibility is Structural and Local]] — locality and federation as the reproducibility commitments that polycentric ASOT enables
- [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]] — the operational primitives that build on polycentric ASOT
- [[Analysis Layer Scope Algebra]] — the scope algebra, including the new "Scopes as polycentric ASOTs" section
- [[Federated Audit and Composition]] — composition certification across polycentric ASOTs
- [DoD Modular Open Systems Approach (MOSA)](https://www.cto.mil/sea/mosa/)
- [10 U.S.C. §4401 — MOSA in major weapon systems](https://www.law.cornell.edu/uscode/text/10/4401)
- [DoD MOSA Implementation Guidebook (Feb 2025)](https://www.cto.mil/wp-content/uploads/2025/03/MOSA-Implementation-Guidebook-27Feb2025-Cleared.pdf)
- [DAU Glossary: Authoritative Source of Truth](https://www.dau.edu/glossary/authoritative-source-truth)
- [OMG MBSE Wiki: Authoritative Source of Truth](https://www.omgwiki.org/MBSE/doku.php?id=mbse:authoritative_source_of_truth)
- [NIST CSRC Glossary: Authoritative Source (SP 800-63)](https://csrc.nist.gov/glossary/term/authoritative_source)
