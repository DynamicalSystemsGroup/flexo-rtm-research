<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-024: Identity by Thin Projection of External Sources

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-021 Three Attestation Subclasses Ship in v0.1]]; [[ADR-023 Cryptography by Composition of Battle-Tested Standards]]; [[ADR-016 Composable SHACL Profiles]]; [[Identity Boundaries and Policy Projections]]; [[Design Spec]]

## Context

Named-approver attestations (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) require identity — the `rtm:approvedBy` property references a person, and SHACL enforces that the reference is a real IRI with a real identity behind it. Institutional adopters already own user identity: corporate SSO (OIDC, SAML), LDAP/AD, GitHub/GitLab Enterprise, Okta, Auth0, Keycloak. The question for v0.1 is whether `flexo-rtm` (a) **owns** user accounts and authentication itself, (b) **hardcodes** a single identity provider (the ADCS prototype hardcoded GitHub IDs), or (c) **projects** identity from external authoritative sources via a thin adapter pattern. The first two options put `flexo-rtm` in the business of authentication, credential storage, and identity governance — a domain where mistakes are catastrophic and the institutional adopter would never trust an early-stage tool. See [[Design Spec]] §11 and [[Identity Boundaries and Policy Projections]].

## Decision

`flexo-rtm` v0.1's identity model is **thin projection of external authoritative sources, never ownership**. `flexo-rtm` does **not** authenticate users, does **not** store credentials, does **not** own user records. Named approvers (per [[ADR-021 Three Attestation Subclasses Ship in v0.1]]) are IRIs referencing identities owned by institutional SSO (OIDC, SAML), LDAP/AD, GitHub/GitLab, etc.

**Vocabulary** in v0.1: `rtm:hasExternalIdentity`, `foaf:Person`, `org:Membership`, `rtm:Attribute`, `rtm:Policy`. **Three configurable policy primitives** (all SPARQL-evaluable): role-based, attribute-based, scope-based. **Single SHACL bottleneck** ensures policy authority can be certified. **Reference adapters** ship for: GitHub, generic OIDC, GitHub Actions OIDC. Adopters extend for SAML, LDAP/AD, Okta, Auth0, Keycloak via the documented **thin adapter pattern**.

## Consequences

### Positive

- Adopters keep their existing identity infrastructure; integration is at the boundary via a thin adapter, not by replacing what they already trust
- No credential storage in `flexo-rtm`: a class of security failures (credential leak, account compromise propagation, credential drift) is structurally eliminated
- Policy is RDF + SPARQL — the same data model `flexo-rtm` already requires — so adopters don't add a new policy engine; role/attribute/scope policies are SPARQL queries
- The single SHACL bottleneck means policy authority itself can be certified (a cert run can attest "the active identity policy was P at projection time T")
- Refresh policy is adopter-configurable (every cert run / on commit / scheduled / static); transcript records projection-as-of-time for reproducibility (see [[ADR-025 Reproducibility is Structural and Local]])
- Closes the ADCS prototype's hardcoded-GitHub-IDs gap by generalizing the integration boundary

### Negative / Tradeoffs

- Adopters must implement (or use the reference) thin adapter for their identity provider; mitigated by the adapter pattern being documented and by GitHub/OIDC reference adapters covering many cases
- Policy refresh introduces an additional governance question per scope — adopters must decide their refresh cadence; mitigated by clear defaults and per-scope configurability
- Projection-at-cert-time semantics has to be understood by adopters and auditors; mitigated by the transcript model and by the locality property (see [[ADR-025 Reproducibility is Structural and Local]])

### Neutral

- The thin-projection pattern parallels the crypto decision (see [[ADR-023 Cryptography by Composition of Battle-Tested Standards]]): both integrate at the boundary via standardized vocabularies and let the external authoritative source own the truth

## Alternatives Considered

- **Own user accounts and authentication inside `flexo-rtm`:** Build user registration, password storage, session management, and identity governance into `flexo-rtm`. Rejected: this is precisely the institutional adoption blocker. Adopters will not trust an early-stage tool with credential storage; the security review burden is enormous; the resulting identity store is redundant with institutional infrastructure. The right move is to integrate at the boundary, not duplicate the authoritative source.
- **Hardcode a single identity provider (GitHub-only, as the ADCS prototype did):** Bind to GitHub IDs in the vocabulary. Rejected: forces every institution to either move to GitHub or carry a shim layer; defeats the open-source-interoperability story; doesn't generalize to enterprise SSO. The thin adapter pattern generalizes the GitHub-only case to any provider exposing identity claims.

## Implementation Notes

- v0.1 ontology vocabulary: `rtm:hasExternalIdentity`, `foaf:Person`, `org:Membership`, `rtm:Attribute`, `rtm:Policy` (plus supporting properties)
- Three combinable policy primitives — all SPARQL-evaluable — surfaced as `rtm:RoleBasedPolicy`, `rtm:AttributeBasedPolicy`, `rtm:ScopeBasedPolicy`
- SHACL bottleneck enforces policies at attestation write time — a single shape graph governs identity policy enforcement
- Reference adapters in `oracle/src/oracle/storage/identity/`: `github_adapter.py`, `oidc_adapter.py`, `github_actions_oidc_adapter.py`
- Adapter contract documented in [[Identity Boundaries and Policy Projections]] — adopters extending for SAML / LDAP / Okta / Auth0 / Keycloak / arbitrary providers follow the contract
- Refresh policy is configured per cert run (`every-run`, `on-commit`, `scheduled`, `static`); transcript records the projection-as-of-time
- **No custom policy engine** — uses RDF + SPARQL, the data model `flexo-rtm` already requires

## References

- [[Design Spec]] §11 (Identity Projection), §11.1–11.4 (Policy Primitives, Adapter Contract, Refresh, SHACL Bottleneck)
- [[Identity Boundaries and Policy Projections]] — canonical identity-projection documentation
- [[ADR-021 Three Attestation Subclasses Ship in v0.1]] — the attestations that depend on identity
- [[ADR-023 Cryptography by Composition of Battle-Tested Standards]] — parallel thin-boundary pattern
- [[ADR-025 Reproducibility is Structural and Local]] — projection-at-cert-time semantics
- W3C Organization Ontology: https://www.w3.org/TR/vocab-org/
- FOAF: http://xmlns.com/foaf/spec/
