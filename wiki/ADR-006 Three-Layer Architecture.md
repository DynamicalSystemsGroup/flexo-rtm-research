<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-006: Three-Layer Architecture

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-007 Scope as First-Class RDF Resource]]; [[ADR-009 Two-Repo Strategy]]; [[Three-Layer Architecture]]; [[Operational Layer UX Discipline]]; [[Storage Layer Flexo Conventions]]; [[Analysis Layer Scope Algebra]]; [[Design Spec]]

## Context

`flexo-rtm` has three distinct concerns that compete for the same code if not separated: (a) **operator UX** — engineers interacting with claims, attestations, evidence in a low-latency tool that doesn't feel like an audit interface; (b) **persistent authority** — the canonical RDF store of facts that institutional Flexo conventions govern; (c) **reporting and audit** — scoped, read-mostly analysis that produces coverage metrics, gap reports, and cert artifacts. Conflating these layers either bloats the UX with audit concerns (slow, hostile to adoption) or bloats the store with UX state (fragile, conflated authority). The question is whether v0.1 commits to an explicit layer boundary. See [[Design Spec]] §5 (architecture) and [[Three-Layer Architecture]].

## Decision

`flexo-rtm` v0.1 commits to a **three-layer architecture**: **operational** (UX, low-latency interactions, ephemeral state) → **storage** (canonical RDF graph, Flexo-conformant authority) → **analysis** (scoped read-mostly reporting, coverage metrics, cert artifact generation). The layer boundary is enforced at the code-organization level (`oracle/src/oracle/operational/`, `oracle/src/oracle/storage/`, `oracle/src/oracle/analysis/`) and at the data-flow level (operational writes go through storage; analysis reads from storage but does not write).

## Consequences

### Positive

- UX latency is decoupled from audit complexity — the operational layer can stay snappy because it is not responsible for coverage metrics or cert generation
- Storage is the single canonical authority — operational writes and analysis reads both go through it, so there is one truth
- Analysis is scoped and read-mostly — reports are produced over slices of the graph (see [[ADR-007 Scope as First-Class RDF Resource]]) without disturbing the store
- The layer boundary makes per-layer SHACL profile gating (see [[ADR-016 Composable SHACL Profiles]]) obvious — write-side profiles enforce on operational ingress, read-side profiles enforce on analysis projection

### Negative / Tradeoffs

- Three layers is more architectural overhead than a single-layer "everything in storage" design — adopters reading the codebase have to learn the layer boundary
- The operational layer needs its own ephemeral state model (drafts, in-progress attestations) which is not in the RDF graph — that state model has to be designed and documented (see [[Operational Layer UX Discipline]])
- Cross-layer flows (e.g., "save draft → attest → coverage updates") have to cross two layer boundaries, which is more contract surface to maintain

### Neutral

- The three-layer model maps cleanly to Flexo's conventions (see [[Storage Layer Flexo Conventions]]) — operational is the UX surface adopters integrate with; storage is Flexo-conformant; analysis is the reporting surface

## Alternatives Considered

- **Two-layer (storage + analysis only):** Bind operator UX directly to storage with a thin display layer, no operational concept. Rejected: every UX gesture becomes a storage write, which inflates the canonical graph with ephemeral state and pushes UX latency through the SHACL validation path. The operational layer's purpose is precisely to absorb ephemeral state and validate before promoting to canonical authority.
- **Single-layer (everything in storage):** Put UX, authority, and reporting all in the same RDF service. Rejected: bloats the store and conflates concerns. Reports are read-mostly over scoped slices; mixing them into the same code path as live operator interactions makes both worse.

## Implementation Notes

Code organization in `flexo-rtm`:

- `oracle/src/oracle/operational/` — UX surfaces, draft state, write-side validation entry points; latency-sensitive
- `oracle/src/oracle/storage/` — canonical RDF graph, Flexo-conformant authority, write-side SHACL validation, write-side OSLC adapters (see [[ADR-010 OSLC-RM and OSLC-QM in v0.1]])
- `oracle/src/oracle/analysis/` — scoped read-mostly reports, coverage metrics, cert artifact generation, derived views (see [[ADR-013 Simplicial Complex as Derived View When Built]])

Per-layer SHACL profiles (see [[ADR-016 Composable SHACL Profiles]]) attach at the appropriate ingress: write-time profiles enforce on storage ingress; read-time profiles enforce on analysis projection.

## References

- [[Design Spec]] §5 (Three-Layer Architecture), §9 (Per-Layer Acceptance Criteria)
- [[Three-Layer Architecture]] — wiki page elaborating the layer boundary
- [[Operational Layer UX Discipline]] — operational-layer conventions
- [[Storage Layer Flexo Conventions]] — storage-layer authority model
- [[Analysis Layer Scope Algebra]] — analysis-layer scoping
