<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Multi-Agent Discourse Graph Precedent

> Synthesizes the [`multi-agent-dg`](https://github.com/DynamicalSystemsGroup/multi-agent-dg) Python package as **internal prior art** for `flexo-rtm`'s federated / scoped-to-named-graph approach. Elaborates [[Design Spec]] §4.9 (reproducibility chain) and §9.A.5 (cross-cutting acceptance criteria X6/X7/X8). Cross-reads with [[Federated Audit and Composition]], [[Identity Boundaries and Policy Projections]], [[Storage Layer Flexo Conventions]], [[Analysis Layer Scope Algebra]], [[ADR-007 Scope as First-Class RDF Resource]], [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]], and [[ADR-030 Polycentric ASOT Authority Model]].

`flexo-rtm`'s federated-audit primitive treats the system-of-interest as a **patchwork of named graphs**: each scope is an IRI-addressed slice owned by an organization, attested under named approvers, composable via scope algebra, and consumable by parties who hold only partial reproduction rights. The [[Federated Audit and Composition]] page commits to that model; [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]] locks it. The commitment is large enough that a working internal precedent — code that has already implemented multi-owner RDF graph isolation, declared sharing policies compiled to SPARQL, and post-export boundary invariants — substantially de-risks it.

`multi-agent-dg` is that precedent. It is a sibling DSG package (`DynamicalSystemsGroup/multi-agent-dg`) implementing the [discoursegraphs.com](https://discoursegraphs.com) information model on the same semantic-web stack `flexo-rtm` adopts: OWL 2 DL, SHACL, SPARQL, PROV-O, with a Pydantic facade so engineers do not write Turtle or SPARQL by hand. Its core problem is different — collaborative design rationale rather than verifiable RTM certification — but the multi-agent sharing machinery underneath solves the same shape of problem `flexo-rtm` confronts at the composition scale. This page records what carries across, what does not, and where the two systems compose.

## 1. What `multi-agent-dg` is

A Python package implementing a base discourse grammar (`dg:Question`, `dg:Claim`, `dg:Evidence`, `dg:Source`) and an engineering extension (`eng:Decision` and related nodes) as **two layered OWL ontologies** validated by SHACL. Each `Agent` is "an aggregate actor — an organization, team, or working group — that owns a single `DiscourseGraph` instance" addressed by a base IRI ending in `/`. Each agent's contributions live in its own named graph (`<agent-base>graph/local`), and content received from another agent lives in a dedicated ingest graph (`<agent-base>graph/ingested-{src}`) tagged with `prov:wasAttributedTo` and `dg:ingestedAt`. The store is an `rdflib.ConjunctiveGraph` quad store; the policy graph is **structurally isolated** from the data store (`_store is not _policy`), and the isolation is itself an asserted invariant.

Cross-agent sharing is declared as RDF policy objects (`grantee_uri`, `source_graph_uri`, `include_types`, `exclude_nodes`) and compiled at export time to **SPARQL `CONSTRUCT`** queries scoped to the source agent's named graph via an explicit `GRAPH <source>` clause. After each export the package asserts three invariants — excluded nodes absent, all discourse edges endpoint-bounded inside the permitted set, policy graph not exported — and refuses to release the subgraph if any fails. Push (`alice.export_policy(...) → bob.ingest(...)`) and pull (`bob.pull_from(alice, "policy-name")`) converge on the same ingest pipeline.

## 2. Why this is the right prior art for the federated approach

Three properties of `multi-agent-dg` map directly onto commitments [[Federated Audit and Composition]] makes, and the mapping is sharper than any comparable external reference (LD Patch, Solid pods, RDF Dataset Canonicalization in isolation):

- **Each owner gets a named graph.** The discourse-graph quad store partitions content by `<agent-base>graph/local` exactly as the polycentric ASOT model ([[ADR-030 Polycentric ASOT Authority Model]]) partitions content by `rtm:Scope` IRI. The "patchwork of named graphs" framing is not aspirational — it is already the working substrate of a sibling DSG package, with multi-graph SPARQL exercised end-to-end in tests.
- **Sharing is declared as RDF and compiled to SPARQL.** Policies are first-class graph instances, not procedural code. The same data substrate carries the policy and the data it governs. This is the discipline [[Identity Boundaries and Policy Projections]] requires for `rtm:Policy` instances: "policy IS RDF + SPARQL," no parallel XACML / OPA / Cedar engine, no second authority surface to audit.
- **Boundaries are asserted post-export.** The discourse-graph package treats "no excluded node leaked" and "no edge crosses the permitted-set boundary" as **structural invariants checked after every export**, not as documentation. This is the same engineering posture `flexo-rtm`'s SHACL bottleneck takes for policy enforcement (`rtm:AttestationAuthorizationShape` in [[Identity Boundaries and Policy Projections]]) and that the federated-audit profiles take for composition-scale adequacy and sufficiency.

The three properties together mean: a working DSG codebase already enforces the load-bearing claim — *that you can structurally guarantee a multi-graph patchwork's sharing semantics in RDF without inventing a new policy engine*. `flexo-rtm`'s federated-audit primitive inherits that conviction with empirical backing rather than only theoretical argument.

## 3. Patterns that carry forward

Six concrete patterns lift from `multi-agent-dg` into `flexo-rtm` with light adaptation:

- **Owner-per-named-graph addressing.** `<agent-base>graph/local` for own content, `<agent-base>graph/ingested-{src}` for content received from another agent. `flexo-rtm`'s scope IRIs follow the same shape: `rtm:scope/<scope-name>` for the canonical scope, with attestations layered on top carrying `rtm:atCommit` to pin the version. Inbound federated-audit attestations from a third-party auditor are the moral equivalent of an "ingested" subgraph — content from another agent, attributed via `rtm:approverOrganization` and `prov:wasAttributedTo`.
- **Policy graph structurally isolated from data store.** The `_store is not _policy` invariant in `multi-agent-dg` parallels [[Storage Layer Flexo Conventions]]' commitment to keep the `<rtm:policies>` named graph separable from content graphs. Policy lives in the same dataset for `default_union=True` SPARQL evaluation but is addressable as its own graph for audit and rollback.
- **Declared policies, compiled to SPARQL at evaluation time.** `multi-agent-dg`'s `export_policy` compiles a policy RDF object into a `CONSTRUCT` query at runtime; `flexo-rtm`'s `rtm:Policy` instances drive the SPARQL pattern inside `rtm:AttestationAuthorizationShape` ([[Identity Boundaries and Policy Projections]]) and the composition-scale SPARQL in `composition-adequacy` / `composition-sufficiency` ([[Federated Audit and Composition]]). The compilation step is the same idea — declarative RDF policy, dynamically materialized as the query language the engine speaks.
- **Post-export / post-validation boundary invariants.** Where `multi-agent-dg` enforces P1/P2/P3 after every export, `flexo-rtm` enforces the named-approver SHACL shape after every attestation write and the federated-audit profile SHACL after every cert run. The pattern — invariants asserted at the trust boundary, not assumed — is the same.
- **PROV-O attribution on ingested or cross-boundary content.** Every node ingested across an agent boundary gets `prov:wasAttributedTo <source-agent>` and a timestamp. `flexo-rtm`'s `rtm:ScopeCertificationAttestation` ([[Federated Audit and Composition]] §"Three new attestation subjects") carries `rtm:approverOrganization` plus `prov:atTime` for the same reason: a consumer of the composed cert artifact can always trace any third-party signature to the org that produced it and the moment it was produced.
- **Join points between graphs.** `multi-agent-dg` identifies `dg:Question` as "the only term referenced by both ontologies … the intentional and natural seam." `flexo-rtm` has the analogous seam at `rtm:Scope`: scope-algebra operators (`rtm:union`, `rtm:intersectsWith`, `rtm:extends`, [[Analysis Layer Scope Algebra]]) compose named graphs without flattening them, and `rtm:appliesToSystemOfInterest` is the join point where constituent scopes attach to a composed model.

## 4. Where `flexo-rtm` extends beyond `multi-agent-dg`

The discourse-graph package solves the **isolation half** of the problem well. `flexo-rtm` must additionally solve the **accountability half**, the **reproducibility half**, and the **institutional-identity half** — none of which are in `multi-agent-dg`'s scope.

- **Named approvers on every attestation.** `multi-agent-dg` records `prov:wasAttributedTo` on ingested nodes; it does not require a named human approver behind every claim. `flexo-rtm`'s `rtm:approvedBy` SHACL bottleneck ([[Attestation Infrastructure in v0.1]], [[Identity Boundaries and Policy Projections]] I1) is the load-bearing addition. Federated-audit attestations inherit it automatically because `sh:targetClass rtm:Attestation` matches the parent class ([[Federated Audit and Composition]] §"Three new attestation subjects").
- **Qualified-role org-level identities.** Discourse-graph agents are URIs without a role schema; flexo-rtm's `foaf:Organization` projection with `rtm:hasQualifiedRole` ([[Identity Boundaries and Policy Projections]] §"Org-level identities") is what makes "every safety-critical scope has ≥ 1 attestation from an org bearing `rtm:role/accredited-reproducibility-auditor`" enforceable.
- **Bit-exact reproducibility and transcript replay.** `multi-agent-dg` does not commit to RDFC-1.0 canonicalization or transcript replay. `flexo-rtm` does, because the federated-audit Level 2 (reproducibility audit) requires it — an auditor re-fetches external URIs, re-executes recorded activities, and compares hashes ([[External URI References]], [[Transcript Replay Semantics]], [[RDFC-1.0 Canonicalization]]).
- **Signed envelopes via established standards.** `multi-agent-dg`'s policy guarantees end at "no excluded node leaked." `flexo-rtm` additionally requires that attestations are signed via W3C VC-DI / DSSE / Sigstore / signed git commits ([[Signed Envelopes and Established Standards]]), and that the signatures themselves are auditable.
- **OSLC interoperability and SysMLv2 anchoring.** `flexo-rtm`'s adapter contracts ([[OSLC RM Adapter Contract]], [[OSLC QM Adapter Contract]]) and the model-vocabulary anchor in [[OMG SysMLv2]] are out of scope for discourse-graph and required for the requirements-traceability use case.

These are additions, not contradictions. The discourse-graph isolation model is the substrate `flexo-rtm`'s additional accountability and reproducibility surface rides on.

## 5. Where the two systems compose

The compositional path is concrete enough to design against, even though no v0.1 deliverable depends on it:

- **A discourse graph as a rationale source feeding `flexo-rtm`.** A team's discourse-graph captures the Q/C/E/Decision rationale behind a requirement or an attestation. The relevant `eng:Decision` nodes (with their supporting `dg:Claim` / `dg:Evidence` chains, governed by the same sharing policies that protect them inside the team) can be projected as GSN `Justification` nodes attached to a `rtm:AdequacyAttestation` or `rtm:SufficiencyAttestation` — see [[GSN Integration]] for the GSN shape that already lives in v0.1. The discourse-graph's per-node provenance becomes the GSN justification's provenance.
- **`eng:Assumption` with `scope` field parallels `rtm:scopedTo`.** `multi-agent-dg`'s `eng:Assumption` requires an explicit scope declaration ("the analysis scope within which this assumption is accepted"). `flexo-rtm`'s `rtm:scopedTo` and `rtm:withinScope` ([[Identity Boundaries and Policy Projections]], [[Analysis Layer Scope Algebra]]) carry the same epistemic discipline at the policy and attestation level: nothing is admitted without an explicit scope binding.
- **Pull semantics parallel federated-audit ingest.** `multi-agent-dg`'s `pull_from(source, "policy-name")` is the right operational shape for a federated-audit consumer: a system-of-systems certifier "pulls" the scope-certification attestations of each constituent scope under a sharing policy declared by each owner. The composed audit report ([[Federated Audit and Composition]] §"Worked example") is the materialized union.
- **Refresh-policy projection-at-time parallels P3.** `multi-agent-dg` enforces that the policy graph itself is never exported. `flexo-rtm`'s [[Identity Boundaries and Policy Projections]] §"Refresh policy" records the projection-as-of-cert-time in the transcript so that an audit re-run reproduces the SHACL outcome regardless of what the live identity provider currently says. Both rest on the same principle: the artifact carries the rule it was evaluated under at the moment of evaluation, separable from live state.

## 6. What this precedent does **not** decide

`multi-agent-dg` validates the substrate, not the federated-audit-specific decisions. Several questions remain open within `flexo-rtm`'s scope and are not answered by the precedent:

- **Trust transitivity across organizations.** `multi-agent-dg` policies are pairwise (Alice → Bob). `flexo-rtm` v0.1 also declines transitivity ([[Federated Audit and Composition]] §"What v0.1 ships vs. what's deferred"): each adopter declares its own qualified-role set; org A trusting B trusting C is not yet modeled. Discourse-graph offers no precedent here.
- **Community-curated qualified-auditor registry.** Discourse-graph has no notion of "accredited" agents; agents are just URIs. The deferred registry of qualified-auditor orgs and roles (similar in spirit to the topological framework's pre-approved-types registry) is `flexo-rtm`-specific work.
- **Bit-exact reproducibility under partial sharing.** A discourse-graph sharing policy can structurally exclude evidence behind a claim (the package's worked "claim-only" example). `flexo-rtm`'s reproducibility audits require the auditor to re-execute the recorded activities, which presumes access to the inputs. The interaction between scope-level sharing policies and reproducibility-audit permissions is a `flexo-rtm`-side design problem — see also [[External URI References]] for the access-boundary story.
- **Numerical-tolerance regimes.** Discourse-graph does not engage with the bit-exact vs. numerical-tolerance distinction ([[ADR-027 Bit-Exactness vs Numerical Tolerances Are Both First-Class]]); both regimes are first-class in `flexo-rtm` and orthogonal to the sharing-policy substrate.

These are not gaps in the precedent — they are out of scope for it. Naming them keeps the borrowing honest.

## 7. Bottom line

`multi-agent-dg` does for design rationale what `flexo-rtm`'s federated audit does for requirements traceability: it treats a multi-owner system as a patchwork of named graphs, declares sharing policies as RDF, compiles them to SPARQL at the boundary, and asserts structural invariants after every export. The two systems are not the same system, and the discourse-graph precedent does not absolve `flexo-rtm` of the accountability, reproducibility, and qualified-role surface its certification use case requires. But the precedent **does** demonstrate, in a working DSG codebase on the same OWL/SHACL/SPARQL/PROV-O stack, that the scoped-to-named-graph approach is implementable, that structural invariants at the trust boundary are enforceable, and that "policy is RDF + SPARQL" is sufficient without a parallel policy engine. That demonstration is the contribution this internal research item makes to the case for [[Federated Audit and Composition]] and [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]].

## Cross-references

- [[Federated Audit and Composition]] — the composition-scale primitive this precedent supports.
- [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]] — the locked decision.
- [[ADR-007 Scope as First-Class RDF Resource]] — scope as queryable named-graph IRI.
- [[ADR-030 Polycentric ASOT Authority Model]] — multi-owner institutional topology the patchwork-of-graphs framing serves.
- [[Identity Boundaries and Policy Projections]] — "policy IS RDF + SPARQL"; org-level identity projection.
- [[Storage Layer Flexo Conventions]] — named-graph layout `flexo-rtm` adopts.
- [[Analysis Layer Scope Algebra]] — `rtm:union` / `rtm:intersectsWith` / `rtm:extends` as the join-point analogue of `dg:Question`.
- [[Attestation Infrastructure in v0.1]] — the named-approver SHACL bottleneck the precedent does not provide.
- [[GSN Integration]] — the projection target for discourse-graph rationale.
- [[External URI References]] — the reproducibility access boundary where partial-sharing policies and reproducibility audits interact.
- [[PROV EARL GSN P-PLAN]] — the W3C/community vocabulary stack shared with `multi-agent-dg`.
- [[ADCS Prototype Lessons]] — sibling internal-research item; named-graph partitioning at the single-team scale.
- [`DynamicalSystemsGroup/multi-agent-dg`](https://github.com/DynamicalSystemsGroup/multi-agent-dg) — the package itself; README, `docs/ARCHITECTURE.md`, `docs/DESIGN.md`, `notebooks/discourse_graph_demo.py`.
- [discoursegraphs.com](https://discoursegraphs.com) — the upstream information model the package implements.
