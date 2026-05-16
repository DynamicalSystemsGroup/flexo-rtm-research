<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Topological Framework Future Work

> **Status — Deferred from v0.1.** This page documents the topological framework (typed simplicial complexes, assurance triangles, recursive completeness, named-approver-enforced validation edges, V−F-type invariants, persistent homology over commit-sequence filtration) as **future capability**: the vision, the mechanics, the open questions, and the additional work required before implementation. The normative scope of this deferral is recorded in [[Design Spec]] §4.10; the future acceptance criteria are listed in [[Design Spec]] §9.A.6 (D1–D4). What `flexo-rtm` v0.1 ships in lieu of this framework is documented in [[Traditional Forward and Backward Analysis]] and [[Attestation Infrastructure in v0.1]].

This document exists because the user directed the research repo to include, alongside the v0.1 specification, "documentation about how we imagine building this extended capability as well as the open questions and extra work that lead us to defer it." The decision to ship v0.1 without the topological framework was not a decision to abandon it — it was a decision to ship a working, accountable, traditional traceability tool first, and to do the framework justice on its own timeline. This page is the receipt.

## 1. Why this is future work, not v0.1

The original aspiration — drawn from Zargham 2026 (*Formalizing Document Assurance*) — was to make the typed simplicial complex of assurance triangles the **primary** audit primitive of `flexo-rtm`. Forward and backward analysis would become corollaries; the load-bearing certification check would be the closure of every (Artifact, Requirement, Guidance) face under (Verification, Coupling, Validation) edges, with named approvers on the validation edges and a community-curated registry terminating the recursion of "is this evidence itself assured?"

That aspiration survived contact with two realities:

1. **Recursive completeness is real and unbounded without a registry.** For an `Artifact` to count as evidence for a `Requirement`, its assurance triangle must close. The triangle closes only if its `Guidance` is fit-for-purpose. "Fit for purpose" means the `Guidance` itself is assured — i.e., the Guidance vertex has its own assurance triangle, whose Guidance must in turn be assured, and so on. In Zargham 2026 the recursion is terminated by a small **boundary complex** (four self-referential vertices SS, SG, GS, GG plus an axiomatic root `b0`). In a working RTM, the recursion terminates only via a **community-curated registry** of pre-approved artifact types, specifications, and guidance. Without such a registry, the audit either never terminates or terminates on hand-waving.

2. **Purely numerical invariants are necessary but not sufficient.** The widely-cited check V − F ≤ 1 (where V is the count of non-foundational vertices in scope and F is the count of closed assurance faces) is a **necessary** condition for a properly closed complex; it catches certain structural defects (orphan documents, faces sharing too many vertices). It is **not sufficient** — a complex can satisfy V − F ≤ 1 without enforcing recursive completeness, because the invariant counts faces but does not interrogate whether each face's Guidance is itself in a closed face. The right invariants for the assurance complex are a research question, not a settled answer.

A registry is a major scope commitment. It demands governance (who curates?), versioning (how do entries evolve?), domain coverage (aerospace vs. biotech vs. software-only adopters?), and community engagement (without uptake, the registry is one organization's opinion in OWL). Bundling that commitment with a v0.1 release that needs to ship and certify the ADCS regression corpus would have meant shipping neither well. The decision was made to ship the traditional capability cleanly in v0.1, document the topological framework comprehensively as future work, and let the registry conversation happen on its own honest timeline.

A second reality reinforced the decision: `flexo-rtm` v0.1 must successfully certify the ADCS prototype corpus end-to-end, and that corpus does not require the topological audit. It requires forward/backward coverage, T1/T2 gap enumeration, and named-approver attestations on adequacy/sufficiency claims — all of which v0.1 ships and tests. The framework's absence from v0.1 is not a gap in the user-visible product; it is a deferral of an audit-mode that the product is not yet ready to underwrite.

## 2. The vision (what the framework looks like fully implemented)

When the topological framework eventually lands, the `flexo-rtm` certification surface looks like this:

**Vertices** (0-simplices). Three primary types, each with stable IRIs in the v0.1 vocabulary:
- `rtm:Specification` (also known as `rtm:Requirement`) — a statement of what the system must do or be.
- `rtm:Guidance` — a statement of *how to judge* whether a `Specification` is met by a particular `Document`. Decomposes into `rtm:AdequacyCriteria` (the model represents the intended thing well enough) and `rtm:SufficiencyCriteria` (the evidence supports the claim well enough).
- `rtm:Document` (also known as `rtm:Artifact`) — a piece of evidence: a proof script, a test report, a simulation log, a CAD drawing, a Monte Carlo run, a peer-reviewed analysis. Carries external URI references (git+commit, content-hash, OCI digest — see [[External URI References]]).

**Edges** (1-simplices). Three types, each linking exactly two vertices:
- `rtm:Verification` — `Artifact → Requirement`. Asserts that the artifact, considered against the requirement, would satisfy the requirement if the artifact were itself adequate evidence.
- `rtm:Coupling` — `Requirement → Guidance`. Asserts that the requirement is judged using these adequacy / sufficiency criteria.
- `rtm:Validation` — `Artifact → Guidance`. Asserts that the artifact meets the guidance's criteria. **SHACL-gated**: a `Validation` edge MUST carry an `rtm:approvedBy` IRI; SHACL rejects writes without it. This is the named-human-on-the-hook edge.

**Faces** (2-simplices, the *assurance triangles*). A `rtm:Face` of type `rtm:AssuranceTriangle` is a triple `{Artifact, Requirement, Guidance}` whose boundary is exactly the three matching edges `{Verification(A→R), Coupling(R→G), Validation(A→G)}`. The face's existence is the unit of assurance: "this artifact, against this requirement, satisfies this guidance, attested by this named approver."

**Closure (the certification predicate).** A model in scope is *fully assured* when every non-foundational vertex appears in at least one closed assurance face:

$$\forall v \in V \setminus V_\text{boundary}, \exists f \in F : v \in \partial f$$

where `V_boundary` is the registry-rooted boundary complex (see §3), `F` is the set of closed assurance triangles, and `∂f` is the boundary operator returning the three vertices of face `f`.

**Aspect-typed extension.** Each face is parameterized by an `rtm:Aspect` (functional, performance, safety, security, ethical, regulatory, environmental). A requirement is *fully covered* when every aspect declared by the requirement has at least one closed face with both adequacy- and sufficiency-flavored Guidance. The aspect taxonomy is extensible per [[Aspect Coverage with Adequacy and Sufficiency]]; v0.1 ships the vocabulary and the per-aspect attestation rollup, but does not run the aspect-tagged face-closure audit.

**Derivation, not storage.** The complex is not a parallel data structure — it is a **derived view** computed from the underlying RDF triples via SPARQL `CONSTRUCT` and materialized for analysis by [`knowledgecomplex` library](https://github.com/DynamicalSystemsGroup/knowledgecomplex)'s typed-simplicial-complex machinery. The 2×2 responsibility map of that library (Topological × Ontological crossed with OWL × SHACL) provides the type discipline. SHACL closure rules enforce face-cardinality (`Face` has exactly 3 `boundedBy` edges) and closed-triangle constraints at write time.

In implementation terms: the v0.1 vocabulary already carries every term this section names. What v0.1 omits is the audit pass that interprets those terms as a typed simplicial complex and checks closure.

## 3. The recursion challenge

The single most important reason the framework is future work — not just polish or scope-trimming — is **recursive completeness**. The argument:

1. For a `Verification` edge `Artifact → Requirement` to count as evidence in a certification, the artifact must be adequate-and-sufficient evidence.
2. "Adequate-and-sufficient" is exactly what the `Validation` edge `Artifact → Guidance` attests. So we need the assurance triangle `{Artifact, Requirement, Guidance}` to close.
3. The triangle closes only if its `Guidance` is **fit-for-purpose** — i.e., the right criteria for *this* requirement, in *this* domain, under *these* organizational standards.
4. "Fit-for-purpose" is itself an assurance claim. So the `Guidance` vertex needs *its own* closed assurance triangle: a different artifact (e.g., a standards document, a peer-reviewed handbook, a regulator's adopted methodology) verifying the guidance against a higher-order specification (e.g., "the criterion shall be measurable and reproducible"), under a higher-order guidance ("acceptable forms of measurability and reproducibility for this aspect").
5. Recurse.

In Zargham 2026, the recursion is terminated formally by the **boundary complex** — four self-referential vertices (`SS` Specification-of-Specifications, `SG` Specification-of-Guidance, `GS` Guidance-of-Specifications, `GG` Guidance-of-Guidance) and an axiomatic root `b0`. The boundary complex is treated as foundational; recursion stops there by fiat.

For a working `flexo-rtm` deployment in a real engineering organization, "by fiat" is not enough. The boundary has to be **operational**: a set of pre-approved artifact types, specification templates, and guidance criteria that the community (or the organization, or the domain) has agreed *count as foundational*. That is the **registry**.

## 4. The registry concept

A registry, in this framework, is a curated set of entries each of the form:

```turtle
rtm-reg:entry/proof-script-with-sympy a rtm-reg:RegistryEntry ;
    rtm-reg:artifactType rtm:ProofScript ;
    rtm-reg:acceptedSpecificationTemplate <iri/analytical-claim> ;
    rtm-reg:acceptedGuidanceCriteria <iri/sympy-assumptions-reviewable> ;
    rtm-reg:curator <https://openmbee.org/working-groups/assurance> ;
    rtm-reg:status "active" ;
    rtm-reg:version "1.2" ;
    rtm-reg:effectiveFrom "2026-01-01"^^xsd:date ;
    rtm-reg:supersededBy rtm-reg:entry/proof-script-with-sympy-v1.3 .
```

The semantics: when the framework's audit reaches a Guidance vertex whose own assurance recursion would not otherwise terminate, it checks the registry. If the (artifact-type, specification-template, guidance-criteria) tuple matches an active entry, the recursion bottoms out — that vertex is treated as registry-rooted and the audit moves on. If the tuple has no matching entry, the audit raises `G9.registry-unknown-type` and surfaces the gap to a human.

### Illustrative entries (not normative)

- "A proof script using SymPy with documented assumptions is acceptable evidence for analytical-claim requirements when the assumptions are independently reviewable."
- "A Monte Carlo simulation report with N ≥ 10⁵ trials and a documented sampling distribution is acceptable evidence for stochastic-claim requirements."
- "A peer-reviewed paper in a venue with documented review process is acceptable evidence for a literature-supported design choice."
- "A regulatory-authority-issued type certificate is acceptable evidence for regulatory-conformance requirements within the scope of that authority."

These are illustrative because the registry's *content* is exactly what the community has not yet built. v0.1 ships the substrate for it; v0.2+ is where the conversation begins.

### Governance questions

Building the registry is the substantial scope commitment. The open questions:

- **Who curates?** Options include an OpenMBEE-hosted community registry, domain-specific working groups (aerospace, biotech, automotive), regulator-issued registries, and organization-internal registries. The likely answer is *all of the above*, federated, with explicit precedence rules.
- **How are entries added, revised, retired?** A registry without a change process is a dead document. The process must address proposal, review, ratification, versioning, sunset, and appeals.
- **What's the appeals mechanism for entries an adopter disputes?** An adopter may believe an entry is over-permissive (e.g., the SymPy proof entry should require formal verification, not assumptions review) or under-permissive (e.g., it should accept Lean 4 outputs too). The governance must accommodate these disputes without paralyzing the registry.
- **How do versioned entries propagate to in-flight certifications?** When entry v1.2 is superseded by v1.3, what happens to certifications produced against v1.2? Are they grandfathered? Re-validated? Marked stale?
- **Recursive registries.** Can a registry entry itself be assured by another registry? If yes, what prevents cycles? If no, what is the global root of the registry graph?
- **Cross-registry composition.** What happens when an artifact type appears in two registries — the OpenMBEE community registry and an organization-internal extension — with different acceptance criteria? Precedence? Intersection? Most-restrictive-wins?

None of these questions has a single right answer; each has to be answered by the community that adopts the framework. That conversation is the precondition to shipping the framework — not something the framework can ship without.

## 5. V − F invariant: necessary, not sufficient

The numerical invariant most often discussed in the topological framework literature is:

$$V - F \le 1$$

where `V` is the count of non-foundational vertices in scope and `F` is the count of closed assurance faces. Equality (`V − F = 1`) holds when each non-boundary vertex appears in exactly one assurance face plus one foundational root contributes the `+1`. The inequality variant tolerates faces that share vertices (the same artifact serving as evidence for multiple requirements is normal).

The invariant is **necessary**: a properly closed complex cannot violate it. A scope with `V − F > 1` has more vertices than faces can account for, meaning at least one vertex is not in any face — an orphan or dangling element.

The invariant is **not sufficient**: a scope can satisfy `V − F ≤ 1` while violating recursive completeness, because the invariant counts faces but does not interrogate each face's Guidance for *its own* face-membership. A pathological example: a scope with one requirement, one artifact, and one guidance, forming exactly one face. `V = 3, F = 1, V − F = 2` — fails the invariant. Now add a "guidance-of-guidance" vertex and a face for it. `V = 4, F = 2, V − F = 2` — still fails. Keep adding "guidance of the guidance of the guidance" — the count never converges unless the recursion terminates in the registry-rooted boundary. The numerical check alone never asks the question "did the recursion terminate properly?"

The deferral is therefore double: the framework as a whole is deferred, and within it the invariant is deferred *as a sufficient check*. What replaces (or supplements) V − F is an open research question:

- Euler characteristic of the typed complex modulo the boundary
- Betti numbers (β₀ = connected components; β₁ = unclosed cycles; higher orders for higher-dimensional simplices the framework may eventually carry)
- Persistence-based invariants (see §6)
- Type-aware invariants that count vertices and faces per aspect, per registry-status, per attestation-freshness

This is genuine open territory. The framework can and probably will ship with a candidate invariant (likely V − F augmented by a registry-termination check), but the *right* invariant is still being looked for.

## 6. Persistent homology and TDA

When the framework lands, the assurance complex becomes the substrate for topological data analysis (TDA) over the **commit-sequence filtration**: at each commit on the model branch, the complex's current closure is one snapshot in a filtration ordered by commit time. **Persistent homology** over that filtration yields barcodes per scope showing:

- Which assurance triangles persist across commits (durable claims)
- Which collapse and rebuild (claims that are actively re-evaluated)
- Which never close (claims with chronic gaps)
- Which appear, close, and then become stale (claims overtaken by evolving guidance)

The barcodes are the rigorous answer to "how mature is the certification, longitudinally?" — a question the current state-of-the-art in RTM tools can only answer impressionistically.

TDA capability sits **on top of** the framework: it cannot ship without the framework, and so is deferred along with it. The v0.2+ roadmap entry "persistent homology" in [[Design Spec]] §11 is contingent on the framework landing in §10's "future work" column first.

## 7. Future certification predicate

When the framework ships, the v0.1 certification predicate (the `Basic` predicate from [[Verifiable Self-Certification]] and [[Traditional Forward and Backward Analysis]]) is extended:

$$\text{FullAssurance}(D, S) \iff \text{Basic}(D, S) \land \Phi_\text{topo}(D, S)$$

where `D` is the model, `S` is the scope, and `Φ_topo` encodes:

- **Closed-face coverage.** Every non-foundational vertex in scope is in at least one closed assurance face (the existence-of-face condition, §2).
- **Named-approver SHACL on validation edges.** Every `Validation` edge in scope carries an `rtm:approvedBy` IRI. (This SHACL gate already exists in v0.1 for attestations; the framework extends it to validation edges.)
- **Recursive completeness via registry lookup.** Every face's Guidance vertex is either itself in a closed face *or* matches an active registry entry.
- **No stale attestations.** Every attestation supporting a closed face is fresh under the project's staleness policy (e.g., not invalidated by a downstream commit that changes the artifact hash without re-attestation).

`Basic` is `Traditional Forward and Backward Analysis` plus the v0.1 attestation infrastructure. `FullAssurance` is `Basic` plus topological audit. v0.1 ships `Basic`; future work delivers the conjunction.

## 8. G3–G9 future gap codes

Documented for forward planning; **not in v0.1** (only T1–T8 in [[Design Spec]] §4.7 are). These codes are reserved in the diagnostic enumeration and surface only when the framework's audit runs.

| Code | Meaning |
|---|---|
| `G3.uncoupled` | A `Requirement` in scope has no `Coupling` edge to any `Guidance` — the requirement is uncoupled from any judgment criteria. |
| `G4.unvalidated` | An `Artifact` in scope verifies a `Requirement` (via `Verification` edge) but has no `Validation` edge to the requirement's `Guidance` — the artifact is unvalidated against the criteria. |
| `G5.unapproved-validation-edge` | A `Validation` edge exists without an `rtm:approvedBy` IRI. *Structurally absent under the framework's SHACL gate — reserved in the enumeration for diagnostic completeness if SHACL is somehow bypassed.* |
| `G6.assurance-triangle-incomplete` | The three vertices of a candidate face exist with two of the three edges present, but the third edge is missing — the face does not close. |
| `G7.stale-recursive-attestation` | A face is closed at the surface, but a Guidance vertex in its boundary has no recursively-complete attestation chain (e.g., the registry entry that grounded the recursion has been superseded). |
| `G8.dangling-sysml-ref` | A vertex references a SysMLv2 element by IRI that does not resolve in the storage layer at certification time. |
| `G9.registry-unknown-type` | The registry-termination check encountered a Guidance vertex whose (artifact-type, specification-template, guidance-criteria) tuple has no matching active entry. |

These codes interlock: a single face with a missing validation edge is `G4`; the same face with the edge present but no approver is `G5` (which SHACL prevents); a face that closes but whose Guidance was never coupled to a higher-order spec is `G7` or `G9` depending on whether the registry knew about it.

## 9. The seven open questions

The deferral is honest: these are the questions that the user, the research project, and the community do not yet have settled answers for. Each is a precondition to shipping the framework in any production-grade form.

1. **Registry curation governance.** Who maintains the registry? How are entries vetted? What is the relationship between OpenMBEE-community-curated entries, domain-specific working-group entries, regulator-issued entries, and organization-internal extensions? Federation rules? Conflict resolution?
2. **Recursion termination semantics.** Is the registry a single global root, or can registries themselves be assured (recursive registries)? Are there cycles, and if so, how are they detected and resolved? What is the formal status of the boundary complex `{SS, SG, GS, GG, b0}` from Zargham 2026 in the operational system?
3. **Versioning.** Pre-approved types evolve. How do existing certifications relate to retired registry entries? Sunset policies, grandfathering rules, forced re-validation triggers?
4. **Cross-registry composition.** When an artifact type appears in multiple registries with different acceptance criteria, what wins? Precedence orderings, intersection semantics, most-restrictive-wins, explicit adopter declarations?
5. **Right topological invariants.** V − F is one candidate but insufficient alone. What other invariants — Euler characteristic, Betti numbers, persistent-homology features — should the framework check? What are the necessary-and-sufficient invariants for a properly closed, recursively-complete assurance complex?
6. **Performance.** A full topological audit is expensive — graph traversal, SHACL evaluation, registry lookups, and persistence computation, possibly over hundreds of thousands of triples. What caching, incremental computation, and lazy evaluation strategies make the audit tolerable in CI pipelines?
7. **Authority verification.** The named-approver IRI on validation edges is asserted. Should the framework verify that the approver had *institutional authority* at attestation time (not merely was-a-person)? How does this integrate with [[Identity Boundaries and Policy Projections]] and the projected policy snapshots already recorded in v0.1?

These are not blockers in the sense of "we know what to do but haven't done it." They are open in the sense of "the community has to converge on answers before the framework can ship without doing harm." That is exactly why v0.1 ships without it.

## 10. Roadmap to eventual implementation

A four-phase roadmap, deliberately unaggressive on dates:

**Phase A — Research.** Registry governance design (drafted as a discussion document, not code). Pilot a domain-specific registry (e.g., for aerospace artifact types) in collaboration with one or two willing adopters. Refine the invariants — publish candidate formulations, run them against the ADCS regression corpus and any pilot corpora, iterate. Engage with the OpenMBEE assurance working group (or its successor) on the governance shape. Outputs: a registry schema, a candidate invariant set, and a small population of validated example entries.

**Phase B — Prototype.** Implement the assurance triangle audit in code, against a fixed registry frozen at Phase A's end. Test on the ADCS lifecycle demo corpus. Build the future test suite per [[Design Spec]] §9.A.6 (D1–D4): `tests/future/test_triangle_closure.py`, `tests/future/test_recursive_completeness.py`, `tests/future/test_tda_barcodes.py`, `tests/future/test_topological_invariants.py`. Validate against the pilot domain registry. Outputs: a working prototype certification mode (`flexo-rtm certify --profile=full-assurance`) on a feature branch, with limited test coverage but real end-to-end execution.

**Phase C — Community engagement.** Publish the registry schema, the prototype audit, and the pilot registry's contents. Solicit feedback from prospective adopters. Iterate on the schema and on the governance model in response. Conduct one or two structured workshops with the broader assurance / RTM community. Outputs: a v0.1 registry schema with documented governance, public draft entries for at least one domain, and a written record of community input.

**Phase D — Production.** Merge the framework into `flexo-rtm` as an opt-in `--profile=full-assurance` certification mode. Maintain v0.1 traditional analysis as the default; users who want the topological audit enable the profile explicitly. Update [[Design Spec]] §4.10 to normative status; update §9.A.6 D1–D4 to gating criteria for a future major release. Outputs: a `flexo-rtm` release with the framework available as an opt-in profile, full test coverage, and a documented adoption pathway.

There is no calendar attached to these phases. The right pace is determined by community uptake and the resolution of the seven open questions, not by a sprint plan. The research project will report progress in [[Map of Content]] as phases complete.

## 11. What v0.1 carries forward (so future work has somewhere to land)

The single most important property of v0.1 is that it is **forward-compatible** with the framework. The vocabulary, the attestation infrastructure, and the external URI references already speak the language the framework will eventually audit.

**Vocabulary terms.** `rtm:Guidance`, `rtm:AdequacyCriteria`, `rtm:SufficiencyCriteria`, `rtm:Aspect` (and its taxonomy), `rtm:Specification`, `rtm:Document` are all in the v0.1 ontology. Adopters who tag adequacy and sufficiency criteria on satisfaction claims, and who classify by aspect, are populating exactly the graph the future framework operates on.

**Attestation infrastructure.** The three `rtm:Attestation` subtypes (`SatisfactionAttestation`, `AdequacyAttestation`, `SufficiencyAttestation`) ship in v0.1 with SHACL-enforced `rtm:approvedBy` IRIs. These attestations are the precursors to the framework's named-approver validation edges; the same human-on-the-hook discipline that v0.1 enforces on attestations will extend in future work to validation edges.

**Aspect tagging.** Per-aspect attestation is supported in v0.1 via `rtm:hasAspect`. When the framework lands, per-aspect face closure becomes the per-aspect audit pass — the data structure is already populated.

**External URI references.** Per [[External URI References]], every artifact carries `rtm:hasGitRepo`, `rtm:hasGitCommit`, `rtm:hasContentHash`, `rtm:hasOCIImage`. Every assurance triangle's vertices already carry the provenance handles the framework's reproducibility audit will check.

**Identity boundaries.** Per [[Identity Boundaries and Policy Projections]], every attestation is evaluated against a projected policy snapshot — the same projection the framework's authority-verification check (open question §9.7) will use.

The boundary between v0.1 and future work is therefore explicit at the artifact level: v0.1 ships *every input the framework will need*, and defers *only the audit pass that interprets those inputs as a typed simplicial complex and runs closure*. An adopter who runs v0.1 correctly today is building a graph the framework will read tomorrow.

## 12. What adopters should do today

Concrete recommendations for organizations adopting `flexo-rtm` v0.1 who want their certifications to age well into the topological framework:

- **Use [[Traditional Forward and Backward Analysis]] as the primary certification mode.** It is what v0.1 ships, it is what the ADCS regression corpus runs under, and it is what shows up to OSLC-RM and Doors-shaped tooling without surprise.
- **Tag adequacy and sufficiency criteria as you go.** Every time an engineer writes "this artifact satisfies this requirement," prompt them (via the skill, the CLI, or a review checklist) to record the adequacy criterion ("the model represents the right thing") and the sufficiency criterion ("the evidence supports the claim") as Guidance vertices. These accumulate the Guidance population the framework will eventually audit.
- **Record named-approver attestations on satisfaction claims.** The `rtm:SatisfactionAttestation`, `rtm:AdequacyAttestation`, and `rtm:SufficiencyAttestation` records (per [[Attestation Infrastructure in v0.1]] and [[Human-AI Accountability]]) are the accountability primitive shipped in v0.1. They are independently meaningful for traditional traceability *and* are the validation-edge precursors for the future framework.
- **Classify by aspect.** Use `rtm:hasAspect` on requirements and attestations. The aspect taxonomy is extensible; per [[Aspect Coverage with Adequacy and Sufficiency]], even partial tagging composes naturally with future per-aspect face-closure audits.
- **Anchor artifacts to external URIs.** Per [[External URI References]], every artifact should carry `rtm:hasGitCommit` (or `rtm:hasContentHash`, or `rtm:hasOCIImage`) so it is reproducible. The framework's reproducibility chain will compose on top of this.
- **Do not invent a local registry.** Resist the temptation to roll your own pre-approved-artifact-types registry inside your organization before the community converges. A premature registry will likely diverge from the eventual community schema, and the divergence is more expensive to repair than the absence is.

These practices position the project to adopt the topological framework when it ships — without locking in to any particular framework decision the community has not yet made.

## 13. Future acceptance criteria (D1–D4)

Per [[Design Spec]] §9.A.6, the framework's eventual release is gated by four future test gates, **not in v0.1's release gate**:

| ID | Future criterion | Future test |
|---|---|---|
| D1 | Closed assurance triangle audit | `tests/future/test_triangle_closure.py` |
| D2 | Recursive completeness check against registry | `tests/future/test_recursive_completeness.py` |
| D3 | Persistent homology over commit-sequence filtration | `tests/future/test_tda_barcodes.py` |
| D4 | V − F invariant (alternative formulation pending research) | `tests/future/test_topological_invariants.py` |

These tests do not exist in v0.1; the file paths are reserved as placeholders so the future work has a known landing site. They will be authored in Phase B of the roadmap (§10).

## 14. The library that materializes the complex

When the framework lands, the in-memory representation of the assurance complex is materialized by the [`knowledgecomplex` library](https://github.com/DynamicalSystemsGroup/knowledgecomplex) (the `knowledgecomplex` Python package). That library's 2×2 responsibility map — Topological × Ontological crossed with OWL × SHACL — exactly matches the discipline the framework needs:

- **Topological / OWL.** `kc:Element`, `kc:Vertex`, `kc:Edge`, `kc:Face` hierarchy with boundary-cardinality axioms.
- **Topological / SHACL.** Closed-triangle constraints and boundary-closure rules (these require `sh:sparql` because OWL-DL cannot express the closed-triangle constraint).
- **Ontological / OWL.** Concrete subclasses — `rtm:Specification`, `rtm:Guidance`, `rtm:Document` — and their allowed attributes.
- **Ontological / SHACL.** Controlled-vocabulary enforcement (e.g., `rtm:Aspect` values), approver-required gates, attestation co-occurrence rules.

The library is independently maintained; its README and ARCHITECTURE specify the contract `flexo-rtm` will consume when the framework lands. v0.1 does not depend on it; future work will.

## 15. Closing position

The topological framework is the most ambitious capability in the `flexo-rtm` future-work surface. It is also the one where shipping prematurely would do the most harm — a half-built registry, an under-specified invariant, or an audit that produces false greens would damage trust in the framework long before the community has reason to trust it. The deferral is therefore not a retreat from the original vision; it is a commitment to do the framework justice.

v0.1 ships the foundation. v0.2+ ships the OpenAPI surface, the SysMLv2 I/O, the Claude skill, and the live OSLC connectors. The framework ships when the registry conversation has happened, the invariants have settled, the recursion is genuinely terminable, and the community is ready to consume the result. The artifacts, the vocabulary, and the attestation infrastructure that v0.1 carries forward make sure that when the framework lands, it lands on populated, accountable, reproducible data.

## See also

- [[Design Spec]] §4.10 (normative deferral statement) and §9.A.6 (D1–D4 future criteria)
- [[Traditional Forward and Backward Analysis]] — what v0.1 ships in lieu of the framework
- [[Attestation Infrastructure in v0.1]] — the named-approver discipline that survives forward into the framework
- [[Vertices Edges Faces]] — the type discipline of the complex
- [[Aspect Coverage with Adequacy and Sufficiency]] — per-aspect closure as a future-framework audit dimension
- [[Analysis Layer Scope Algebra]] — scope as the input to any audit, traditional or topological
- [[External URI References]] — the provenance handles every vertex carries
- [[Identity Boundaries and Policy Projections]] — the policy snapshots the framework's authority check will use
- [`knowledgecomplex` library](https://github.com/DynamicalSystemsGroup/knowledgecomplex) — the library that materializes the complex
- [[Human-AI Accountability]] — the accountability discipline that motivates the named-approver-on-validation-edge design
- [[INCOSE IS 2026 Paper]] — the paper that describes the framework and from which this future-work agenda derives
- [[Map of Content]] — orientation
