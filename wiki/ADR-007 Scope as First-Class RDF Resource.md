<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-007: Scope as First-Class RDF Resource

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-004 Quantitative Certification Outcome]]; [[ADR-016 Composable SHACL Profiles]]; [[Analysis Layer Scope Algebra]]; [[Design Spec]]

## Context

Certification is rarely "the whole project" — it is a named institutional commitment to a specific slice: "the safety-critical subsystem as of milestone M3," "the compliance scope for regulatory submission R-17," "the FY26-Q3 cert run." Each named scope has its own coverage matrix, its own attestation requirements, its own audit consumers. If scope is left as an oracle-config flag (passed at run time, not stored), then named scopes cannot be referenced from attestations, cannot be queried historically, and cannot compose into derived scopes (e.g., "the union of safety-critical and security-critical scopes"). The question is whether scope is a first-class RDF resource with its own composition algebra, or an external parameter. See [[Design Spec]] §5.3 and [[Analysis Layer Scope Algebra]].

## Decision

`flexo-rtm` v0.1 models **Scope as a first-class RDF resource**: `rtm:Scope` instances are stored in the canonical graph, carry IRIs, are referenced from attestations and audit reports, and compose via an explicit **scope algebra** (union, intersection, difference, named-membership). Coverage metrics (see [[ADR-004 Quantitative Certification Outcome]]) and cert reports are always produced **per scope**.

## Consequences

### Positive

- Scopes are nameable, queryable, attestable, historically referenceable — the institutional unit of accountability becomes a first-class concept
- Scope algebra (union, intersection, difference) gives institutions a principled way to combine certification commitments (e.g., "the cert artifact for the union of safety and security scopes") without ad-hoc scripting
- Attestations can reference the scope they apply to — `rtm:AdequacyAttestation` against `rtm:Scope` becomes a queryable fact
- SHACL profiles (see [[ADR-016 Composable SHACL Profiles]]) can be scope-conditional — "for scope S, require the `signed-commits` profile" — without baking scope into the profile vocabulary itself

### Negative / Tradeoffs

- Scope as RDF means scope definitions have to be authored and maintained as institutional records, not just passed at run time — more governance surface
- Scope algebra is an additional concept adopters must learn; "what scope are we asking about?" becomes a question every audit-time interaction has to answer
- Coverage metrics are always per-scope, never global — institutions wanting a single global number have to define the global scope explicitly

### Neutral

- Scope-as-RDF maps cleanly onto the three-layer architecture (see [[ADR-006 Three-Layer Architecture]]): scope definitions live in storage; analysis queries are parameterized by scope; operational UX surfaces scope as a context for every interaction

## Alternatives Considered

- **Scope as oracle config flag (not stored):** Pass scope as a CLI/API parameter at run time; do not store scope definitions in the graph. Rejected: scope is the institutional unit of accountability — every cert artifact, every audit report, every attestation is *about* a scope. If scope is not in the graph, then those facts cannot reference it, cannot be queried historically, and cannot be composed. The institutional adoption story collapses without queryable named scopes.
- **Scope per cert run only:** Define scopes ephemerally per cert run; do not persist them. Rejected: cert runs need to be reproducible (see [[ADR-025 Reproducibility is Structural and Local]]), and reproduction requires the scope definition to be available at audit time, not just at the original run time. Ephemeral scopes break reproducibility.

## Implementation Notes

`rtm:Scope` is defined in the v0.1 ontology with properties for named-membership (`rtm:scopeIncludes`, `rtm:scopeExcludes`) and algebra composition (`rtm:scopeUnion`, `rtm:scopeIntersection`, `rtm:scopeDifference`). The analysis layer (`oracle/src/oracle/analysis/`) parameterizes all coverage queries by `rtm:Scope` IRI. Attestations carry a `rtm:appliesToScope` property where applicable. See [[Analysis Layer Scope Algebra]] for the SPARQL recipes that implement scope composition.

## References

- [[Design Spec]] §5.3 (Scope Algebra), §7.4 (Scope-Parameterized Coverage)
- [[Analysis Layer Scope Algebra]] — the canonical scope-algebra documentation
- [[ADR-004 Quantitative Certification Outcome]] — coverage metrics are scope-parameterized
- [[ADR-016 Composable SHACL Profiles]] — profile selection can be scope-conditional
