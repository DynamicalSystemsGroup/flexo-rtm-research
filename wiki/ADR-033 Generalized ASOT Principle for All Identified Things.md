<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-033: Generalized ASOT Principle for All Identified Things

**Status:** Accepted
**Date:** 2026-05-18
**Deciders:** Michael Zargham
**Related:** [[ADR-024 Identity by Thin Projection of External Sources]] (actors); [[ADR-022 External URI References as Open-Source Foundation]] (artifacts); [[ADR-030 Polycentric ASOT Authority Model]] (scopes); [[ADR-032 Methodology Agnosticism as Foundational Axiom]] (scoping discipline)

## Context

`flexo-rtm` references many kinds of identified things across the engineering work it tracks: persons, organizations, code repositories, files, directories, datasets, container images, cloud compute environments, simulation activities and their outputs, scopes, policies, roles, attributes, cryptographic keys, signed envelopes. The earlier ADRs handle pieces of this landscape:

- [[ADR-024 Identity by Thin Projection of External Sources]] establishes thin projection for **actors** — persons (and, by extension via [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]], organizations) whose identity credentials live with their identity provider.
- [[ADR-022 External URI References as Open-Source Foundation]] establishes external URI references for **artifacts and activities** — git repositories, content-addressed data, OCI image digests, with the corresponding ASOTs being the git host, the content-addressed store, the OCI registry.
- [[ADR-030 Polycentric ASOT Authority Model]] establishes that each `rtm:Scope` is an **ASOT held by an organization** — naming the polycentric institutional topology of mission- and safety-critical systems engineering.

These three ADRs describe **three applications of one underlying principle**. The principle has been implicit in the design — derivable by reading them together — but not stated as a single foundational axiom. As `flexo-rtm` matures, contributors will encounter new kinds of identified things (e.g., test environments, accreditation certificates, audit findings, simulation outputs, compute reservations, dataset versions, regulatory submissions) and need to decide how `flexo-rtm` should reference them. Without a unified principle, those decisions risk drifting toward inconsistent patterns — `flexo-rtm` incorrectly "owning" some kinds of identity, or gatekeeping access to others, or proxying content from upstream ASOTs.

The user explicitly identified this gap during design review (2026-05-18) and asked whether `flexo-rtm` had adequately clarified that the authoritative source of identity lives within the organization providing the credential — for people and for files, directories, repos, containers, cloud compute, and anything else produced, consumed, or referenced in the engineering work.

## Decision

Adopt as a **foundational design axiom**: every identified thing referenced in `flexo-rtm` data has an Authoritative Source of Truth held by an external entity. `flexo-rtm` carries thin, dereferenceable references; it never owns the authoritative content. Each ASOT enforces its own access policy; `flexo-rtm` does not authenticate, gatekeep, proxy, cache, or bypass dereferencing under any condition.

This principle applies uniformly across all kinds of identified things:

| Thing | ASOT (holder of the authoritative content) |
|---|---|
| Persons | identity provider (SSO / OIDC / SAML / LDAP / GitHub / GitLab / custom) |
| Organizations | registry, hosting provider, or accreditation body issuing the org IRI |
| Roles / attributes / policies | the identity provider that issued them |
| Cryptographic keys | PKI / KMS / OIDC issuer |
| Code, files, directories | git host or content-addressed store |
| Datasets | data publisher / content-addressed store |
| Execution environments | OCI registry, cloud platform |
| Activities (simulations, builds, tests) | the organization that ran the activity |
| Activity outputs | the organization that produced them |
| Scopes | the organization the scope's content concerns (per [[ADR-030 Polycentric ASOT Authority Model]]) |
| Signed envelopes | cosign / Rekor / VC-DI / DSSE / GPG / SSH issuer |

If a new kind of identified thing is introduced, the design question is **not** "should `flexo-rtm` own this?" but "**which external entity is its ASOT, and what reference vocabulary points to it?**"

## Consequences

### Positive

- **Single load-bearing principle.** Future design decisions follow one rule rather than three (or N) boundary-specific patterns. This is the kind of "thin, tightly constrained, no additional bloat" tool-chain discipline the broader scoping requires (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]).
- **Security / privacy property.** A `flexo-rtm` cert artifact can be **shared widely without leaking ASOT content** — the references are just identifiers. Resolution is governed by each ASOT's own access policy. A verifier without dereference permission can still confirm *structural completeness* of the references (per acceptance criterion X8 of [[Design Spec]] §6.6).
- **Federated verification scales.** Each qualified dereferencer accesses what they can; the audit composes locally without any party needing universal access (per [[Federated Audit and Composition]] and [[ADR-026 Reproducibility is Structural and Local]]).
- **No proprietary lock-in.** Every ASOT is reachable via open protocols (git, OCI Distribution, HTTPS, OIDC, …); `flexo-rtm` itself is never the bottleneck or the choke point.
- **Forecloses a class of misunderstanding.** A future contributor cannot reasonably propose "`flexo-rtm` should authenticate, gatekeep, or proxy dereferencing of [some new kind of thing]" — the axiom rules it out. The design question becomes "what's the right reference vocabulary," not "should we own this?"
- **Unifies existing ADRs.** [[ADR-022 External URI References as Open-Source Foundation]], [[ADR-024 Identity by Thin Projection of External Sources]], and [[ADR-030 Polycentric ASOT Authority Model]] become *applications* of one axiom rather than separate principles to remember.

### Negative / Tradeoffs

- **Single ASOT per identified thing.** Conflicts between two competing claims of authority over the same thing must be resolved upstream (in the institutional / organizational layer); `flexo-rtm` does not arbitrate. This is correct behavior but means adopters with overlapping authorities must do governance work outside `flexo-rtm`.
- **Dereference failures bubble up.** If an ASOT becomes unavailable (revoked credentials, dead URL, retired registry), the reference breaks — `flexo-rtm` cannot save the artifact unilaterally. Adopters who need long-lived archival operate their own mirroring at the ASOT layer (e.g., [Software Heritage](https://www.softwareheritage.org/) for code, content-addressed storage for datasets, OCI registry mirroring for containers).
- **No central rulebook for access policies.** Each ASOT has its own access policy; verifiers must understand the policy of each ASOT they want to dereference. `flexo-rtm` does not normalize across ASOTs; this is the correct trade-off but means there is no "single login" for an auditor.
- **Names a discipline, not an implementation.** The principle is a constraint on what `flexo-rtm` may NOT do (own, gatekeep, proxy, cache, bypass). It does not, by itself, tell implementers how to build the reference vocabulary — that's specified in the individual ADRs and interface contracts.

### Neutral

- The principle is largely already implicit in the v0.1 design; this ADR makes it explicit so future contributors see it as a unified design constraint rather than rediscovering it for each new kind of identified thing.

## Alternatives considered

- **A. Have `flexo-rtm` own some kinds of identity** (e.g., embed an identity store, host an OCI mirror, run a content-addressed cache). **Rejected** — violates the "thin tool chain with no additional bloat" discipline. Owning identity means authenticating, storing credentials, gatekeeping access, and competing with the upstream ASOTs — none of which is `flexo-rtm`'s job. Adopters who need such infrastructure run it themselves, outside `flexo-rtm`.
- **B. Allow per-kind authority models** (let actors follow [[ADR-024]], artifacts follow [[ADR-022]], scopes follow [[ADR-030]], and any new thing get its own ADR). **Rejected** — would result in N parallel patterns that may drift. The current ADR-024 / ADR-022 / ADR-030 split is the *symptom* of an implicit unifying principle, not the goal. Unifying as one principle is what keeps the design tractable as it grows.
- **C. Centralize ASOT registry inside `flexo-rtm`** (a directory service that lists every ASOT, validates references, possibly even mirrors content). **Rejected** — turns `flexo-rtm` into a directory service, which is a separate concern with its own scaling, governance, and trust questions. Each ASOT discovery is the verifier's responsibility, using existing tooling for that ASOT type.

## Implementation notes

The principle is now stated explicitly in:

- [[Design Spec]] §1 ("Generalized ASOT principle" paragraph) — top-line framing alongside polycentric ASOT.
- [[Design Spec]] §4.0 ("ASOT principle (foundational)" subsection) — full per-kind ASOT mapping table + dereferencing corollary.
- [[External URI Rules]] §0 ("ASOT mapping (the principle this contract implements)") — applies the principle to URI-typed references with concrete dereferencing protocols.
- [[Identity Adapter Contract]] §2 ("The boundary discipline") — applies the principle to identity projection adapters.

The dereferencing-corollary's testable counterpart is acceptance criterion **X8 of [[Design Spec]] §6.6**: structural completeness without dereferencing — a verifier without fetch access can confirm structural soundness of references by reading the RDF alone. This is the conformance test that makes the security property verifiable.

No code changes required by this ADR beyond what the existing v0.1 design already implements; the ADR formalizes the principle so the codebase's structural discipline can be reviewed against it as a unified rule.

## References

- [[Design Spec]] §1, §4.0, §6.6 X8
- [[ADR-022 External URI References as Open-Source Foundation]] — artifact application
- [[ADR-024 Identity by Thin Projection of External Sources]] — actor application
- [[ADR-030 Polycentric ASOT Authority Model]] — scope application
- [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — adjacent scoping discipline
- [[Identity Adapter Contract]] — normative contract for actor ASOTs
- [[External URI Rules]] — normative contract for artifact ASOTs
- [[Federated Audit and Composition]] — federated verification operationalization
- [DoD MOSA Implementation Guidebook, 2025](https://www.cto.mil/wp-content/uploads/2025/03/MOSA-Implementation-Guidebook-27Feb2025-Cleared.pdf) — institutional precedent
- [DAU Glossary: Authoritative Source of Truth](https://www.dau.edu/glossary/authoritative-source-truth) — terminology
