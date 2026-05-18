<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-013: Simplicial Complex as Derived View When Built

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-003 Topological Framework Documented as Future Work]]; [[ADR-017 knowledgecomplex as Optional Extras]]; [[ADR-018 V minus F Invariant Deferred with Topological Framework]]; [[Vertices Edges Faces]]; [[Design Spec]]

## Context

Per [[ADR-003 Topological Framework Documented as Future Work]] and [[ADR-032 Methodology Agnosticism as Foundational Axiom]], the topological framework is a related research line that may eventually mature into a downstream-analysis mode adopters can choose to run on top of `flexo-rtm`'s data. Whether the framework is run as such a mode, or whether research users want to materialize the **simplicial complex view** of the RTM (vertices = resources, edges = satisfies/verifies pairs, faces = assurance triples) for exploration, there is a representation question. Two storage options exist: (a) **persist the complex** — store vertices, edges, faces as first-class RDF resources alongside the underlying RTM graph; or (b) **derive the complex on demand** — compute it as a SPARQL CONSTRUCT view over the RTM graph, materialize into a separate output graph (e.g., `knowledgecomplex` — see [[ADR-017 knowledgecomplex as Optional Extras]]) only when needed. Persisting it doubles storage and forces the complex representation to be a canonical authority; deriving it keeps storage lean but requires a derivation pipeline. See [[Design Spec]] §7 and [[Vertices Edges Faces]].

## Decision

`flexo-rtm` v0.1 models the simplicial complex as a **derived view**: built by SPARQL CONSTRUCT queries from the canonical RTM graph into the optional `knowledgecomplex` output (see [[ADR-017 knowledgecomplex as Optional Extras]]) only when an analysis run requests it. The canonical RTM graph in storage does **not** persist vertex/edge/face resources; they are derived on demand.

## Consequences

### Positive

- Storage stays lean — the canonical RTM graph is the operational source of truth and is not bloated with derived complex resources
- The derivation is auditable: every vertex/edge/face is produced by a documented SPARQL CONSTRUCT against the RTM graph; reproduction is just re-running the CONSTRUCT
- Complex representation can evolve independently of the canonical graph — if the topological research line refines the simplicial-complex vocabulary, the derivation updates without migrating storage
- `knowledgecomplex` (see [[ADR-017 knowledgecomplex as Optional Extras]]) becomes an opt-in optional extra: adopters who want simplicial-complex analysis install it; adopters who don't aren't burdened

### Negative / Tradeoffs

- Each analysis run that needs the complex pays the derivation cost; mitigated by SPARQL CONSTRUCT being fast on the v0.1 graph scale (per [[ADR-014 Parsimony Layer Build-Time Extraction]] target of ~2k triples)
- Complex resources cannot be IRI-stable across runs without explicit derivation-IRI minting; mitigated by deriving IRIs deterministically from the underlying RTM resources

### Neutral

- Forward-compatible to the topological research line (see [[ADR-003 Topological Framework Documented as Future Work]] and [[ADR-032 Methodology Agnosticism as Foundational Axiom]]): if an adopter runs topological analysis as a downstream-analysis mode, the same derivation pipeline produces the input complex (potentially with a richer SPARQL CONSTRUCT) — no migration of the canonical graph required

## Alternatives Considered

- **Persisted complex (with `knowledgecomplex` storage):** Store vertex, edge, and face resources as first-class RDF in the canonical graph (or in a sibling graph) alongside the RTM relations. Rejected: doubles storage with derived data; forces the complex representation to be a canonical authority that must be migrated when the topological framework evolves; bloats the operational graph with analysis-time concerns. Derivation on demand keeps the canonical graph lean and makes the complex view tractable to evolve.

## Implementation Notes

- The SPARQL CONSTRUCT queries that derive the complex live in `oracle/src/oracle/analysis/complex/` and emit into the `knowledgecomplex` output (see [[ADR-017 knowledgecomplex as Optional Extras]])
- The complex vocabulary (`rtm:AssuranceComplex`, `rtm:AssuranceFace`, `rtm:AssuranceTriple` — see [[ADR-020 Vocabulary Alignment with Zargham 2026]]) ships in v0.1 ontology as forward-compatible interop with the topological research line, per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]
- The derivation is parameterized by scope (see [[ADR-007 Scope as First-Class RDF Resource]]) so that complex views can be produced per-scope
- See [[Vertices Edges Faces]] for the canonical mapping from RTM resources to complex resources

## References

- [[Design Spec]] §7.2 (Derived Complex View), §7.3 (SPARQL CONSTRUCT Recipes)
- [[Vertices Edges Faces]] — the canonical vertex/edge/face mapping
- [[ADR-003 Topological Framework Documented as Future Work]] — the related research line
- [[ADR-017 knowledgecomplex as Optional Extras]] — the optional package that hosts the derived view
- [[ADR-018 V minus F Invariant Deferred with Topological Framework]] — the topological invariant in the research line
- [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — the topological framework as one possible downstream-analysis path, not `flexo-rtm`'s destination
