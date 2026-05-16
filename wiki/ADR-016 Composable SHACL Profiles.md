<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-016: Composable SHACL Profiles

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-007 Scope as First-Class RDF Resource]]; [[ADR-021 Three Attestation Subclasses Ship in v0.1]]; [[ADR-023 Cryptography by Composition of Battle-Tested Standards]]; [[Profile Mechanism]]; [[Design Spec]]

## Context

`flexo-rtm` v0.1's certification model has many optional constraints: named-approver attestation (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]), signed commits, DSSE-signed activities, cosigned images, Rekor transparency log inclusion (see [[ADR-023 Cryptography by Composition of Battle-Tested Standards]]), aspect-coverage thresholds, strict-provenance requirements, etc. Different scopes require different combinations of these constraints: a safety-critical cert may require everything; an exploratory cert may require only basic SHACL hygiene. The question is how the **profile mechanism** — the selection of which constraints apply to a given cert run — interacts with the data selection (scope, see [[ADR-007 Scope as First-Class RDF Resource]]). The two should be **orthogonal**: scope says *which facts* to certify; profile says *which rules* to certify them against. See [[Design Spec]] §6.7 and [[Profile Mechanism]].

## Decision

`flexo-rtm` v0.1's profile mechanism is **composable SHACL contracts**: each profile is a named bundle of SHACL shapes (`signed-commits`, `attested-satisfies`, `aspect-coverage`, `dsse-activities`, `cosign-images`, `rekor-transparency`, `strict-provenance`, etc.); cert runs declare a set of profiles by name; the active SHACL graph is the union of the selected profiles' shapes. Profiles are **orthogonal to scope** — the same profile can apply to different scopes, and the same scope can be certified under different profiles.

## Consequences

### Positive

- Orthogonality: profile selection (which rules) and scope selection (which facts) compose freely; every cert run is parameterized by both
- Composability: profiles are named SHACL shape bundles that union cleanly — adding a profile to a cert run is purely additive; no profile-merge logic required
- Discoverability: profile names are first-class IRIs; cert reports declare which profiles were active; reproduction can re-run with the same profile set
- Extensibility: institutional adopters can author their own SHACL profile bundles (e.g., `acme-org-safety-critical`) and add them alongside the v0.1-shipped profiles without modifying core

### Negative / Tradeoffs

- Cert run configuration has two orthogonal axes (scope, profiles) instead of one; mitigated by clear documentation and sensible default profile sets per institutional context
- SHACL profile composition relies on shape-graph union semantics being well-defined; mitigated by SHACL spec being clear on this point and by CI tests over profile combinations
- Conflicting constraints across profiles (e.g., one profile requires X, another forbids X) are a configuration error; mitigated by CI verifying default profile combinations are internally consistent

### Neutral

- The v0.1 set of shipped profiles is enumerated in the design spec and may grow over versions; profile names are versioned alongside the ontology

## Alternatives Considered

- **Profile-as-graph-tag:** Tag each fact in the graph with the profiles it complies with; certify by filtering for matching tags. Rejected: confuses data and rules — facts shouldn't carry rule metadata. Profile compliance is a property of a cert run, not of individual facts. Also fragile under graph updates (tags can go stale).
- **Hybrid tag+SHACL:** Use SHACL for structural constraints and graph tags for selection. Rejected: same data/rules conflation problem, plus the maintenance burden of two profile mechanisms. SHACL alone is expressive enough — profiles are SHACL shape bundles, and shape selection is the cert-run configuration.

## Implementation Notes

- SHACL profile bundles ship as TTL files in `ontology/profiles/` (one file per profile)
- Cert run configuration declares profiles by name (IRI); the analysis layer (`oracle/src/oracle/analysis/`) computes the active SHACL graph as the union of selected profile graphs
- Cert reports include the active profile set as a first-class field
- Profile catalog documented in [[Profile Mechanism]] with the v0.1 shipped profiles enumerated
- Identity profiles (see [[ADR-024 Identity by Thin Projection of External Sources]]) and crypto profiles (see [[ADR-023 Cryptography by Composition of Battle-Tested Standards]]) compose via the same mechanism

## References

- [[Design Spec]] §6.7 (Profile Mechanism), §9.A.4 (Profile Acceptance)
- [[Profile Mechanism]] — the canonical profile-mechanism documentation
- [[ADR-007 Scope as First-Class RDF Resource]] — the orthogonal data selection mechanism
- [[ADR-023 Cryptography by Composition of Battle-Tested Standards]] — crypto profiles
- W3C SHACL: https://www.w3.org/TR/shacl/
