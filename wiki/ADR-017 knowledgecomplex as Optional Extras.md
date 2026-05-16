<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-017: knowledgecomplex as Optional Extras

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-013 Simplicial Complex as Derived View When Built]]; [[ADR-003 Topological Framework Documented as Future Work]]; [[Design Spec]]

## Context

The simplicial-complex derived view (see [[ADR-013 Simplicial Complex as Derived View When Built]]) is useful to research users and to the future topological framework (see [[ADR-003 Topological Framework Documented as Future Work]]), but it is **not required** for v0.1's traditional analysis or attestation infrastructure. Bundling it into the default `flexo-rtm` install adds dependency surface (graph-analysis libraries, simplicial-complex tooling) that ordinary adopters do not need. The question is whether the simplicial-complex tooling ships as a required dependency, a vendored subset, or an optional extras package. See [[Design Spec]] §7.5 and [[ADR-013 Simplicial Complex as Derived View When Built]].

## Decision

`flexo-rtm` v0.1 ships simplicial-complex tooling as an **optional extras** package: `pip install flexo-rtm[analysis]` (or equivalent) installs the `knowledgecomplex` dependency and the SPARQL CONSTRUCT recipes that derive the complex view. The default install (`pip install flexo-rtm`) does **not** include `knowledgecomplex` — adopters who only need traditional analysis and attestation get a lean install.

## Consequences

### Positive

- Default install is lean — adopters running traditional analysis and OSLC roundtrip don't pull in simplicial-complex dependencies
- The `[analysis]` extras flag is the standard Python pattern for opt-in capability; familiar to adopters
- Research users and adopters experimenting with the future topological framework opt in explicitly via the extras flag; the experimental capability is gated by deliberate install choice
- Forward-compatible: when the topological framework lands, `[analysis]` is the natural home for its tooling — adopters upgrading to use it install the extras

### Negative / Tradeoffs

- Adopters discovering they need complex analysis after the fact have to reinstall with the extras flag; mitigated by a clear error message that points them at the install hint
- The two-install paths (with and without extras) double the CI test matrix; mitigated by the default path being the comprehensive test surface and the extras path adding only the complex-specific tests

### Neutral

- Extras pattern composes cleanly with the three-layer architecture (see [[ADR-006 Three-Layer Architecture]]) — extras are an analysis-layer optional capability, not operational- or storage-layer

## Alternatives Considered

- **Required (default install):** Bundle `knowledgecomplex` into the default install. Rejected: pulls in graph-analysis dependencies that the majority of v0.1 adopters do not need. The simplicial-complex view is an opt-in research capability today; bundling it makes every install heavier for no benefit to most adopters.
- **Vendored subset:** Vendor the parts of `knowledgecomplex` `flexo-rtm` directly uses into the core package; do not depend on the external library. Rejected: vendoring is a maintenance burden — vendored code drifts from upstream and has to be re-synced manually. The extras pattern lets `knowledgecomplex` evolve upstream and `flexo-rtm[analysis]` track it cleanly.

## Implementation Notes

- `flexo-rtm` packaging (`pyproject.toml`) declares `[project.optional-dependencies]` with an `analysis` extra that pulls `knowledgecomplex`
- The complex-derivation code in `oracle/src/oracle/analysis/complex/` imports `knowledgecomplex` lazily; default-install adopters never hit the import
- CI runs the test matrix with and without the extras; tests that exercise complex derivation are gated by `pytest.importorskip("knowledgecomplex")`
- Documentation at [[Three-Layer Architecture]] notes the optional nature; README install instructions surface both paths

## References

- [[Design Spec]] §7.5 (Optional Extras Packaging)
- [[ADR-013 Simplicial Complex as Derived View When Built]] — the derived view this extras hosts
- [[ADR-003 Topological Framework Documented as Future Work]] — the framework that this extras supports researching today
