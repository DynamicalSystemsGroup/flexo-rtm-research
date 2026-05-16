<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Analysis Layer Scope Algebra

The analysis layer of `flexo-rtm` does not certify a global model. It certifies a **named, composable subset** of the graph — a scope. This page specifies `rtm:Scope` as a first-class RDF resource, the three composition operators (`rtm:extends`, `rtm:intersectsWith`, `rtm:union`), the resolution algorithm that turns a scope IRI into an executable graph selection, and the v0.1-vs-future boundary on materialization. The premise: institutional accountability is exercised over a *scope*, not over "the model in general." If you cannot name what you are certifying, you cannot certify it.

See [[Three-Layer Architecture]] for where analysis sits relative to operational and storage layers, and [[Design Spec]] §5.3 for the originating specification.

## `rtm:Scope` as first-class RDF

A scope is an RDF resource stored in Flexo, versioned alongside the data it selects, dereferenceable by IRI, and reusable across certification runs. It is not a parameter to a script; it is an *artifact*.

The minimal vocabulary:

| Predicate | Range | Role |
|---|---|---|
| `rdfs:label` | xsd:string | Human-readable name |
| `rtm:includesGraph` | named-graph IRI | Direct membership of a named graph |
| `rtm:includesAllGraphsMatching` | xsd:string (glob) | Pattern membership over the named-graph namespace |
| `rtm:scopeFilter` | xsd:string (SPARQL FILTER fragment) | Restriction applied at evaluation time |
| `rtm:extends` | rtm:Scope | Parent scope; this scope inherits its graphs + filters |
| `rtm:intersectsWith` | rtm:Scope | Intersection partner; result is restricted to both |
| `rtm:union` | rtm:Scope | Explicit union partner (rare; see below) |

A scope without any of `extends`, `intersectsWith`, `union` is a **base scope** — it stands alone and lists its graphs and filters directly. A scope with at least one composition predicate is a **derived scope** — its meaning is computed from its parents.

Because scopes are RDF resources in Flexo, they carry full provenance: who authored them, when, in what commit, under what branch. The certification predicate ([[Certification Predicate]]) takes a scope IRI as one of its inputs, and the input-hash that feeds the deterministic transcript covers that IRI — so re-running with the same scope at the same commit is byte-stable. Two different scopes over the same data are two different certifications, with two different audit graphs.

## Composition operators

### `rtm:extends` — subscope extension

A scope `S2 rtm:extends S1` inherits everything `S1` selects, then adds local graphs and filters. Semantically:

- The graph set of `S2` is the union of `S1`'s resolved graphs and any graphs `S2` adds directly via `rtm:includesGraph` / `rtm:includesAllGraphsMatching`.
- The filter of `S2` is the conjunction of `S1`'s resolved filter and any local `rtm:scopeFilter`.

This is how teams build coherent hierarchies: a program-level scope, a subsystem scope that extends it, a regression scope that extends the subsystem scope and pins additional graphs for the corpus under test. Authority delegation (see [[Identity Boundaries and Policy Projections]]) routinely follows the same hierarchy — a policy `rtm:withinScope` a parent scope projects onto every descendant.

### `rtm:intersectsWith` — restriction

A scope `S3 rtm:intersectsWith S4` keeps only the part of `S3` that is also in `S4`. Semantically:

- The graph set is the intersection of the two resolved graph sets.
- The filter is the conjunction of the two resolved filters.

Intersection is the workhorse of cross-cutting concerns. "ADCS attitude control, restricted to safety-critical aspects" is the intersection of a subsystem scope (graphs about attitude control) and an aspect-level scope (filter on `?aspect = rtm:safety`). Neither parent is altered; the intersection is a new, named, citable resource.

### `rtm:union` — explicit union (rare)

`rtm:union` exists for completeness but is uncommon in practice. Most unions of graphs are expressed directly via `rtm:includesGraph` lists on a single base scope. Explicit `rtm:union` is reserved for the case where you want to name two pre-existing scopes and assert "the certification this run applies to the disjunctive union of these," typically when the two parents have non-trivial filter structure that you do not want to inline.

When used, the graph set is the union of both resolved graph sets and the filter is the disjunction of both resolved filters.

## Turtle examples

The canonical examples from [[Design Spec]] §5.3:

```turtle
rtm:scope/adcs-attitude-control a rtm:Scope ;
    rtm:includesGraph <adcs:structural>, <adcs:requirements/attitude> ;
    rtm:scopeFilter "FILTER(?aspect IN (rtm:functional, rtm:performance))" .

rtm:scope/safety-critical a rtm:Scope ;
    rtm:scopeFilter "FILTER(?aspect = rtm:safety)" ;
    rtm:includesAllGraphsMatching "adcs:*" .

rtm:scope/adcs-safety a rtm:Scope ;
    rtm:extends rtm:scope/adcs-attitude-control ;
    rtm:intersectsWith rtm:scope/safety-critical .
```

The third scope, `adcs-safety`, is the auditable accountability unit "safety-critical aspects of the attitude-control subsystem." It is named, citable, versioned. An approver authorized over it can sign attestations whose authority closure (per [[Identity Boundaries and Policy Projections]]) is exactly that scope. Certifications produced against it have a known graph union and a known filter — neither the auditor nor the engineering team has to reconstruct what was being certified after the fact.

A rare explicit union form:

```turtle
rtm:scope/adcs-plus-power a rtm:Scope ;
    rtm:union rtm:scope/adcs-attitude-control,
              rtm:scope/power-subsystem .
```

## Scope resolution algorithm

Given a scope IRI, the analysis layer computes its **resolved form**: a pair `(graph_set, filter_expr)` where `graph_set` is a concrete list of named-graph IRIs in the current commit and `filter_expr` is a single SPARQL FILTER expression (possibly compound).

Resolution is recursive over the composition DAG, evaluated post-order:

1. **Dereference the scope IRI** against Flexo at the active commit. Fetch its direct properties.
2. **Resolve direct membership** — collect every `rtm:includesGraph` IRI directly. For each `rtm:includesAllGraphsMatching` glob, enumerate the named-graph namespace at the active commit and add matches. The result is the local graph set.
3. **Resolve local filter** — read `rtm:scopeFilter` if present; otherwise treat as the identity filter (`true`).
4. **Recurse over `rtm:extends`** — resolve the parent scope, union its `graph_set` into the local graph set, conjoin its filter with the local filter.
5. **Recurse over each `rtm:intersectsWith`** — resolve the partner, intersect its `graph_set` with the local graph set, conjoin its filter.
6. **Recurse over each `rtm:union`** — resolve the partner, union the graph set, *disjoin* its filter (this is the only operator that introduces disjunction).
7. **Detect cycles** — composition predicates form a DAG; cycles are an authoring error and resolution fails fast with the offending IRI named.
8. **Memoize** — resolved scopes are cached by `(scope IRI, commit hash)`, which is a stable key.

The output is then handed to a SPARQL `CONSTRUCT` over the `graph_set` with the composite filter applied. The resulting triples are the **materialized scope content** — the working substrate the analysis layer operates on. SPARQL `SELECT` queries over the same `(graph_set, filter_expr)` compute coverage statistics (see [[Aspect Coverage with Adequacy and Sufficiency]] and [[Quantitative Outcomes]]).

## What v0.1 ships, what defers

This is a Phase-5 distinction and worth stating cleanly.

**v0.1 ships:**

- `rtm:Scope` vocabulary and the three composition predicates.
- The resolution algorithm above, implemented in `oracle/analysis/scope.py`.
- SPARQL `CONSTRUCT` materialization to in-memory rdflib graphs for the resolved scope content.
- SPARQL `SELECT` coverage statistics (counts, ratios, gap enumerations per [[Gap Taxonomy]]) keyed by scope IRI.
- Per-commit scope metadata in Flexo (interface contract F4 in [[Design Spec]] §5.2 — round-trip recoverable, citable in audit graphs).
- Scope IRI participating in the input-hash that makes certification deterministic.

**Deferred to the topological framework:**

- Materializing the constructed triples into a `KnowledgeComplex` instance.
- Topological operations on that complex — boundary, star, link, closure.
- The V − F invariant (see [[Vertices Edges Faces]]) computed over the materialized complex.
- Higher-order coverage statistics that depend on simplicial structure rather than triple counts.

Per locked decisions D13 and D17 in [[Design Spec]] §13 (and ADR-013, ADR-017), the simplicial complex is a *derived view* available through the optional `[analysis]` extras with `knowledgecomplex`, and is opt-in rather than mandatory. v0.1 ships the algebra and the SPARQL substrate; the topology lands with the broader topological framework on the v0.2+ roadmap. See [[Topological Framework Future Work]] for the future-work envelope.

The boundary is deliberate. The algebra and SPARQL coverage are sufficient for traditional bidirectional traceability ([[Traditional Forward and Backward Analysis]]) and for scope-relative certification. The topological layer is additive and earns its way in when the operational pull (TDA on requirements coverage, simplicial gap geometry) is loud enough to justify the dependency surface.

## Why scope-relative certification matters

A certification claim is only meaningful if both the *aspects* claimed and the *substrate* claimed over are nameable and citable.

- **Institutional accountability is per scope.** "The propulsion team's safety-aspect certification at baseline 2026-Q2" is an auditable unit. "Our certification" is not.
- **Different scopes have different gap profiles.** Coverage at the subsystem level may pass while coverage at the full-model level fails. Both are correct. Both are useful. Surfacing the difference is what enables prioritization — it tells the program where to invest review effort.
- **Incremental delivery is feasible.** A subsystem certification can land while a full-model certification is still incomplete, without misrepresenting either.
- **Authority closure is per scope.** Policy projections (see [[Identity Boundaries and Policy Projections]]) attach to scopes; an approver's authority is exactly the closure under `rtm:extends` of the scopes their policy names.

## Scopes as polycentric ASOTs

The deeper design commitment underwriting the algebra: **each scope is an [Authoritative Source of Truth (ASOT)](https://www.dau.edu/glossary/authoritative-source-truth) for the data in its named graph, and authority is held by an identifiable organization, not the framework.** This is the polycentric institutional topology of mission- and safety-critical systems engineering: multiple organizations (engineering teams, prime contractors, subsystem suppliers, regulatory authorities, qualified auditors) hold scoped authorities over different parts of the system, and the data model reflects this directly. See [[ADR-030 Polycentric ASOT Authority Model]] for the locked decision and the [Modular Open Systems Approach](https://www.cto.mil/sea/mosa/) lineage.

Three operational consequences flow from this commitment:

- **Scopes may overlap.** Two organizations may legitimately hold authority over the same subject matter from different perspectives — e.g., a safety authority and a performance authority both having scoped concern over the same propulsion-subsystem requirements. The scope algebra supports overlap via `rtm:intersectsWith`; intersected scopes carry both authorities' policies as conjunctive constraints. Overlap is the norm in real engineering organizations, not an exceptional case.
- **Composition is across ASOTs, not into a single super-ASOT.** A higher-order scope `rtm:extends` its sub-scopes; it does NOT subsume their authority. Each sub-scope continues to be governed by its own authority holder. The higher-order scope's certification (per [[Federated Audit and Composition]]) is a composition claim *about* the sub-scope certifications, not a replacement for them.
- **The framework does not own authority.** `flexo-rtm` provides the substrate — RDF, SHACL, identity projections, attestation infrastructure — but the **authority over what a scope says** is held externally by the organization the projection identifies. The framework can certify that policies were enforced (per [[Identity Boundaries and Policy Projections]]); it cannot adjudicate which organization is the right authority for a given scope. That is an institutional arrangement adopters configure.

## Lifecycle-aware scope metadata

Scopes can carry **engineering lifecycle stage** metadata via the `rtm:lifecycleStage` predicate, identifying where in the canonical INCOSE / ISO/IEC/IEEE 15288 lifecycle (concept, development, production, utilization, support, retirement) the scope currently sits. The vocabulary ships in v0.1 for forward-compat data accumulation; the stage-aware oracle behavior — early-stage gate relaxation, lifecycle state machine, auto-rerunnable regression handling — lands in v0.2 (per [[Engineering Lifecycle Stages]] and [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]]). The lifecycle stage is **scope-level metadata**, not a property of individual triples within the scope; the same scope-as-first-class-RDF discipline applies. Per [[Storage Layer Flexo Conventions]] F4, lifecycle stage is captured in commit metadata alongside scope IRI so the v0.2 oracle can read it. Adopters tagging scopes today produce stable data the v0.2 oracle will activate against without rework. `flexo-rtm` uses the canonical six-stage set exactly — no parallel `flexo-rtm`-specific sub-stages.

## Reproducibility and baseline comparison

The scope IRI is part of the input-hash that drives canonical transcript replay (see [[Verifiable Self-Certification]]). Same scope IRI + same canonical input graph + same transcript ⇒ byte-identical output. This makes the *unit of reproducibility* a `(commit, scope)` pair, not a `commit` alone — appropriate, since the same commit can be certified under many different scopes and each yields a distinct, equally valid certification.

The same property makes baseline comparison clean. Evaluate `rtm:scope/adcs-safety` at commit `A`. Evaluate the same scope at commit `B`. The two resolved forms may differ (the named-graph namespace evolved, the glob matches changed), but both are deterministic from their commits, and the **coverage delta** between them is a well-defined audit artifact. The question "is safety coverage growing or shrinking?" reduces to a SPARQL diff over two reproducible runs — usable for management review, regulator dialogue, and internal continuous-improvement reporting.

## See also

- [[Three-Layer Architecture]] — where the analysis layer fits
- [[Design Spec]] §5.3 — originating specification, §5.2 for scope metadata round-trip
- [[Storage Layer Flexo Conventions]] — how scope IRIs are persisted and recovered per commit
- [[Certification Predicate]] — how scope IRI enters the certification function
- [[Quantitative Outcomes]] — coverage statistics computed against a scope
- [[Aspect Coverage with Adequacy and Sufficiency]] — aspect filtering inside scope evaluation
- [[Gap Taxonomy]] — what `SELECT` queries against the resolved scope enumerate
- [[Topological Framework Future Work]] — deferred `knowledgecomplex` materialization and topology
- [[Vertices Edges Faces]] — V − F invariant in the future topological view
- [[Identity Boundaries and Policy Projections]] — scope-closure semantics for authority
- [[Engineering Lifecycle Stages]] — `rtm:lifecycleStage` scope metadata; vocabulary v0.1, mechanism v0.2
- [[Federated Audit and Composition]] — composition-scale adequacy and sufficiency built over scope composition operators
