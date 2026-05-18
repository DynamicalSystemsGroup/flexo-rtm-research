<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Topological Framework Future Work

> **Status — Related research line; not `flexo-rtm`'s planned destination.** This page documents the **topological framework** articulated in Zargham (2026), *Formalizing Document Assurance: A Topological Framework for Verification, Validation, and Human Accountability* (typed simplicial complexes, assurance triangles, recursive completeness, named-approver-enforced validation edges, V−F-type invariants, persistent homology over commit-sequence filtration). The framework is a **separate line of inquiry**, philosophically aligned with `flexo-rtm`'s accountability discipline but not yet reduced to practice and **not required by `flexo-rtm`**. Per [[ADR-032 Methodology Agnosticism as Foundational Axiom]], `flexo-rtm` is methodology-agnostic; the topological framework is one example of an assurance methodology that an adopter may choose to run as **downstream analysis** on data `flexo-rtm` produces. The normative scope is in [[Design Spec]] §4.10; the optional analysis acceptance criteria, if the framework matures, are listed in [[Design Spec]] §9.A.6 (D1–D4). What `flexo-rtm` v0.1 ships — and what `flexo-rtm` IS — is documented in [[Traditional Forward and Backward Analysis]] and [[Attestation Infrastructure in v0.1]].

This document exists because the research repo records research-adjacent work alongside the v0.1 specification: "documentation about how we imagine building this extended capability as well as the open questions and extra work that lead us to defer it." `flexo-rtm` does not depend on this framework, and the framework does not depend on `flexo-rtm`; the two share philosophical kinship (named-approver discipline, structural accountability, V&V distinction) and an aligned vocabulary (per [[ADR-020 Vocabulary Alignment with Zargham 2026]]), but they are different artifacts on different timelines.

## 1. What `flexo-rtm`'s relationship to this framework actually is

`flexo-rtm` v0.1 is a working tool for **bidirectional requirements traceability reduced to practice** plus **a record of human signers where judgment is rendered** ([[ADR-032 Methodology Agnosticism as Foundational Axiom]]). The two halves are settled engineering: forward/backward traces with coverage statistics (decades of RTM practice — Doors, Jama, Polarion, OSLC-RM); structural enforcement of named approvers via SHACL (W3C VC Data Integrity, SLSA in-toto, Sigstore + Fulcio, git GPG/SSH commit signing, NIST SP 800-63, W3C SHACL). `flexo-rtm`'s contribution is composing these into RDF + named graphs for SysMLv2 requirements traceability under a methodology-neutral substrate. None of this requires the topological framework.

The topological framework, if it matures, is **downstream analysis by definition**: an audit mode that takes the traceability + attestation graph as input and computes additional structural properties (face closure, V−F-type invariants, persistent-homology barcodes) over it. `flexo-rtm` produces the substrate; the framework would consume the substrate. The framework's vocabulary already aligns with `flexo-rtm`'s ontology (per [[ADR-020 Vocabulary Alignment with Zargham 2026]]) so adopters who later choose to run downstream topological analysis can do so without translation — and adopters who never do are unaffected.

That alignment is the same forward-compatibility treatment `flexo-rtm` gives any related research line. SLSA supply-chain audits, GSN assurance-case construction, ARP4754A airborne-systems audits, and custom in-house analysis layers all benefit from the same substrate. The topological framework is one downstream analysis path among several plausible ones; `flexo-rtm` privileges none.

## 2. Open questions in the topological research line

Two questions remain open in the framework's own research line — independent of `flexo-rtm`'s release schedule and independent of whether any specific adopter chooses to run topological analysis:

1. **Recursive completeness termination.** For an `Artifact` to count as evidence for a `Requirement` under a topological audit, its assurance triangle must close. The triangle closes only if its `Guidance` is fit-for-purpose. "Fit for purpose" means the `Guidance` itself is assured — i.e., the Guidance vertex has its own assurance triangle, whose Guidance must in turn be assured, and so on. In Zargham (2026) the recursion is terminated by a small **boundary complex** (four self-referential vertices SS, SG, GS, GG plus an axiomatic root `b0`). For an applied audit, the recursion terminates only via a **community-curated registry** of pre-approved artifact types, specifications, and guidance. Without such a registry, the audit either never terminates or terminates on hand-waving. The registry conversation — governance, versioning, domain coverage, community uptake — is a substantial commitment that belongs to the research line, not to `flexo-rtm`.

2. **Sufficient topological invariants.** The widely-cited check V − F ≤ 1 (where V is the count of non-foundational vertices in scope and F is the count of closed assurance faces) is a **necessary** condition for a properly closed complex; it catches certain structural defects (orphan documents, faces sharing too many vertices). It is **not sufficient** — a complex can satisfy V − F ≤ 1 without enforcing recursive completeness, because the invariant counts faces but does not interrogate whether each face's Guidance is itself in a closed face. The right invariants for the assurance complex are a research question, not a settled answer.

Neither question blocks `flexo-rtm` v0.1: the ADCS regression corpus and the v0.1 acceptance criteria require forward/backward coverage, T1/T2 gap enumeration, and named-approver attestations on adequacy/sufficiency claims — none of which require a topological audit. Both questions belong to the framework's own research timeline.

## 3. The vision (what an applied topological audit would look like)

If the research line matures into an applied audit, the surface looks like this — as a **downstream-analysis mode over `flexo-rtm`'s data, not as `flexo-rtm`'s default audit**. The framework reads the v0.1 traceability + attestation graph as input and computes additional structural properties over it. Adopters who choose to run this analysis enable it explicitly; adopters who do not are unaffected (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]).

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

where `V_boundary` is the registry-rooted boundary complex (see §5), `F` is the set of closed assurance triangles, and `∂f` is the boundary operator returning the three vertices of face `f`.

**Aspect-typed extension.** Each face is parameterized by an `rtm:Aspect` (functional, performance, safety, security, ethical, regulatory, environmental). A requirement is *fully covered* when every aspect declared by the requirement has at least one closed face with both adequacy- and sufficiency-flavored Guidance. The aspect taxonomy is extensible per [[Aspect Coverage with Adequacy and Sufficiency]]; v0.1 ships the vocabulary and the per-aspect attestation rollup, but does not run the aspect-tagged face-closure audit.

**Derivation, not storage.** The complex is not a parallel data structure — it is a **derived view** computed from the underlying RDF triples via SPARQL `CONSTRUCT` and materialized for analysis by [`knowledgecomplex` library](https://github.com/DynamicalSystemsGroup/knowledgecomplex)'s typed-simplicial-complex machinery. The 2×2 responsibility map of that library (Topological × Ontological crossed with OWL × SHACL) provides the type discipline. SHACL closure rules enforce face-cardinality (`Face` has exactly 3 `boundedBy` edges) and closed-triangle constraints at write time.

In implementation terms: the v0.1 vocabulary aligns with every term this section names (per [[ADR-020 Vocabulary Alignment with Zargham 2026]]). What v0.1 deliberately omits — and what is not on `flexo-rtm`'s critical path — is the audit pass that interprets those terms as a typed simplicial complex and checks closure. That audit, if it ever exists, is downstream analysis over `flexo-rtm`'s data, not `flexo-rtm`'s built-in certification surface.

## 4. The recursion challenge

The single most substantial open problem in the topological research line — not just polish or scope-trimming — is **recursive completeness**. This is one of the reasons the framework is not reduced to practice yet, and it is independent of any specific `flexo-rtm` release schedule. The argument:

1. For a `Verification` edge `Artifact → Requirement` to count as evidence in a certification, the artifact must be adequate-and-sufficient evidence.
2. "Adequate-and-sufficient" is exactly what the `Validation` edge `Artifact → Guidance` attests. So we need the assurance triangle `{Artifact, Requirement, Guidance}` to close.
3. The triangle closes only if its `Guidance` is **fit-for-purpose** — i.e., the right criteria for *this* requirement, in *this* domain, under *these* organizational standards.
4. "Fit-for-purpose" is itself an assurance claim. So the `Guidance` vertex needs *its own* closed assurance triangle: a different artifact (e.g., a standards document, a peer-reviewed handbook, a regulator's adopted methodology) verifying the guidance against a higher-order specification (e.g., "the criterion shall be measurable and reproducible"), under a higher-order guidance ("acceptable forms of measurability and reproducibility for this aspect").
5. Recurse.

In Zargham 2026, the recursion is terminated formally by the **boundary complex** — four self-referential vertices (`SS` Specification-of-Specifications, `SG` Specification-of-Guidance, `GS` Guidance-of-Specifications, `GG` Guidance-of-Guidance) and an axiomatic root `b0`. The boundary complex is treated as foundational; recursion stops there by fiat.

For an applied topological audit in a real engineering organization, "by fiat" is not enough. The boundary has to be **operational**: a set of pre-approved artifact types, specification templates, and guidance criteria that the community (or the organization, or the domain) has agreed *count as foundational*. That is the **registry**. Note that `flexo-rtm` itself does not require any such registry — the registry is internal to the topological research line.

## 5. The registry concept

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

The semantics: when an adopter running the topological audit reaches a Guidance vertex whose own assurance recursion would not otherwise terminate, the audit checks the registry. If the (artifact-type, specification-template, guidance-criteria) tuple matches an active entry, the recursion bottoms out — that vertex is treated as registry-rooted and the audit moves on. If the tuple has no matching entry, the audit raises `G9.registry-unknown-type` and surfaces the gap to a human. None of this affects adopters who do not run the topological audit.

### Illustrative entries (not normative)

- "A proof script using SymPy with documented assumptions is acceptable evidence for analytical-claim requirements when the assumptions are independently reviewable."
- "A Monte Carlo simulation report with N ≥ 10⁵ trials and a documented sampling distribution is acceptable evidence for stochastic-claim requirements."
- "A peer-reviewed paper in a venue with documented review process is acceptable evidence for a literature-supported design choice."
- "A regulatory-authority-issued type certificate is acceptable evidence for regulatory-conformance requirements within the scope of that authority."

These are illustrative because the registry's *content* is exactly what the community has not yet built. The registry conversation belongs to the topological research line, and it is a precondition for that line to mature into an applied audit; it is not on `flexo-rtm`'s critical path.

### Governance questions

Building the registry is the substantial scope commitment. The open questions:

- **Who curates?** Options include an OpenMBEE-hosted community registry, domain-specific working groups (aerospace, biotech, automotive), regulator-issued registries, and organization-internal registries. The likely answer is *all of the above*, federated, with explicit precedence rules.
- **How are entries added, revised, retired?** A registry without a change process is a dead document. The process must address proposal, review, ratification, versioning, sunset, and appeals.
- **What's the appeals mechanism for entries an adopter disputes?** An adopter may believe an entry is over-permissive (e.g., the SymPy proof entry should require formal verification, not assumptions review) or under-permissive (e.g., it should accept Lean 4 outputs too). The governance must accommodate these disputes without paralyzing the registry.
- **How do versioned entries propagate to in-flight certifications?** When entry v1.2 is superseded by v1.3, what happens to certifications produced against v1.2? Are they grandfathered? Re-validated? Marked stale?
- **Recursive registries.** Can a registry entry itself be assured by another registry? If yes, what prevents cycles? If no, what is the global root of the registry graph?
- **Cross-registry composition.** What happens when an artifact type appears in two registries — the OpenMBEE community registry and an organization-internal extension — with different acceptance criteria? Precedence? Intersection? Most-restrictive-wins?

None of these questions has a single right answer; each has to be answered by the community choosing to adopt the topological audit as a downstream-analysis mode. That conversation is the precondition to the research line maturing — not something the topological audit can be shipped without. `flexo-rtm` does not block on this resolution.

## 6. V − F invariant: necessary, not sufficient

The numerical invariant most often discussed in the topological framework literature is:

$$V - F \le 1$$

where `V` is the count of non-foundational vertices in scope and `F` is the count of closed assurance faces. Equality (`V − F = 1`) holds when each non-boundary vertex appears in exactly one assurance face plus one foundational root contributes the `+1`. The inequality variant tolerates faces that share vertices (the same artifact serving as evidence for multiple requirements is normal).

The invariant is **necessary**: a properly closed complex cannot violate it. A scope with `V − F > 1` has more vertices than faces can account for, meaning at least one vertex is not in any face — an orphan or dangling element.

The invariant is **not sufficient**: a scope can satisfy `V − F ≤ 1` while violating recursive completeness, because the invariant counts faces but does not interrogate each face's Guidance for *its own* face-membership. A pathological example: a scope with one requirement, one artifact, and one guidance, forming exactly one face. `V = 3, F = 1, V − F = 2` — fails the invariant. Now add a "guidance-of-guidance" vertex and a face for it. `V = 4, F = 2, V − F = 2` — still fails. Keep adding "guidance of the guidance of the guidance" — the count never converges unless the recursion terminates in the registry-rooted boundary. The numerical check alone never asks the question "did the recursion terminate properly?"

The research-line gap is therefore double: the topological audit as a whole is unresolved, and within it the invariant is open *as a sufficient check*. What replaces (or supplements) V − F is an open research question:

- Euler characteristic of the typed complex modulo the boundary
- Betti numbers (β₀ = connected components; β₁ = unclosed cycles; higher orders for higher-dimensional simplices the framework may eventually carry)
- Persistence-based invariants (see §7)
- Type-aware invariants that count vertices and faces per aspect, per registry-status, per attestation-freshness

This is genuine open territory. If the topological audit matures into an applied artifact, it will likely do so with a candidate invariant (likely V − F augmented by a registry-termination check), but the *right* invariant is still being looked for.

## 7. Persistent homology and TDA

If an adopter runs topological analysis as a downstream audit mode, the assurance complex becomes the substrate for topological data analysis (TDA) over the **commit-sequence filtration**: at each commit on the model branch, the complex's current closure is one snapshot in a filtration ordered by commit time. **Persistent homology** over that filtration yields barcodes per scope showing:

- Which assurance triangles persist across commits (durable claims)
- Which collapse and rebuild (claims that are actively re-evaluated)
- Which never close (claims with chronic gaps)
- Which appear, close, and then become stale (claims overtaken by evolving guidance)

The barcodes are the rigorous answer to "how mature is the certification, longitudinally?" — a question the current state-of-the-art in RTM tools can only answer impressionistically.

TDA capability sits **on top of** the topological audit: it cannot run without that audit existing as an applied artifact, and so its availability tracks the research line, not `flexo-rtm`'s roadmap. The "persistent homology" entry in [[Design Spec]] §11 is contingent on the topological research line maturing — it is not a planned `flexo-rtm` feature.

## 8. Downstream-analysis certification predicate

An adopter who runs topological analysis as a downstream audit mode would compose the v0.1 certification predicate (the `Basic` predicate from [[Verifiable Self-Certification]] and [[Traditional Forward and Backward Analysis]]) with an additional topological predicate:

$$\text{FullAssurance}(D, S) \iff \text{Basic}(D, S) \land \Phi_\text{topo}(D, S)$$

where `D` is the model, `S` is the scope, and `Φ_topo` encodes:

- **Closed-face coverage.** Every non-foundational vertex in scope is in at least one closed assurance face (the existence-of-face condition).
- **Named-approver SHACL on validation edges.** Every `Validation` edge in scope carries an `rtm:approvedBy` IRI. (This SHACL gate already exists in v0.1 for attestations; the topological audit, if run, extends the same discipline to validation edges.)
- **Recursive completeness via registry lookup.** Every face's Guidance vertex is either itself in a closed face *or* matches an active registry entry.
- **No stale attestations.** Every attestation supporting a closed face is fresh under the project's staleness policy (e.g., not invalidated by a downstream commit that changes the artifact hash without re-attestation).

`Basic` is `Traditional Forward and Backward Analysis` plus the v0.1 attestation infrastructure — that is what `flexo-rtm` IS. `FullAssurance` is `Basic` plus an optional downstream topological audit. v0.1 ships `Basic`; the conjunction is available only to adopters who choose to run the topological analysis as a downstream mode, and only if and when that research line matures into an applied artifact.

## 9. G3–G9 topology-line gap codes

Documented for forward planning; **not in v0.1** (only T1–T8 in [[Design Spec]] §4.7 are). These codes are reserved in the diagnostic enumeration; they are meaningful only to adopters who run the topological audit as a downstream-analysis mode.

| Code | Meaning |
|---|---|
| `G3.uncoupled` | A `Requirement` in scope has no `Coupling` edge to any `Guidance` — the requirement is uncoupled from any judgment criteria. |
| `G4.unvalidated` | An `Artifact` in scope verifies a `Requirement` (via `Verification` edge) but has no `Validation` edge to the requirement's `Guidance` — the artifact is unvalidated against the criteria. |
| `G5.unapproved-validation-edge` | A `Validation` edge exists without an `rtm:approvedBy` IRI. *Structurally absent under the topological audit's SHACL gate — reserved in the enumeration for diagnostic completeness if SHACL is somehow bypassed.* |
| `G6.assurance-triangle-incomplete` | The three vertices of a candidate face exist with two of the three edges present, but the third edge is missing — the face does not close. |
| `G7.stale-recursive-attestation` | A face is closed at the surface, but a Guidance vertex in its boundary has no recursively-complete attestation chain (e.g., the registry entry that grounded the recursion has been superseded). |
| `G8.dangling-sysml-ref` | A vertex references a SysMLv2 element by IRI that does not resolve in the storage layer at certification time. |
| `G9.registry-unknown-type` | The registry-termination check encountered a Guidance vertex whose (artifact-type, specification-template, guidance-criteria) tuple has no matching active entry. |

These codes interlock: a single face with a missing validation edge is `G4`; the same face with the edge present but no approver is `G5` (which SHACL prevents); a face that closes but whose Guidance was never coupled to a higher-order spec is `G7` or `G9` depending on whether the registry knew about it.

## 10. The seven open questions

These are the questions that the research project and the broader assurance community do not yet have settled answers for. Each is a precondition to the topological research line maturing into a production-grade applied audit. None of them block `flexo-rtm` v0.1, which by design does not depend on any of these resolutions.

1. **Registry curation governance.** Who maintains the registry? How are entries vetted? What is the relationship between OpenMBEE-community-curated entries, domain-specific working-group entries, regulator-issued entries, and organization-internal extensions? Federation rules? Conflict resolution?
2. **Recursion termination semantics.** Is the registry a single global root, or can registries themselves be assured (recursive registries)? Are there cycles, and if so, how are they detected and resolved? What is the formal status of the boundary complex `{SS, SG, GS, GG, b0}` from Zargham 2026 in the operational system?
3. **Versioning.** Pre-approved types evolve. How do existing certifications relate to retired registry entries? Sunset policies, grandfathering rules, forced re-validation triggers?
4. **Cross-registry composition.** When an artifact type appears in multiple registries with different acceptance criteria, what wins? Precedence orderings, intersection semantics, most-restrictive-wins, explicit adopter declarations?
5. **Right topological invariants.** V − F is one candidate but insufficient alone. What other invariants — Euler characteristic, Betti numbers, persistent-homology features — should the framework check? What are the necessary-and-sufficient invariants for a properly closed, recursively-complete assurance complex?
6. **Performance.** A full topological audit is expensive — graph traversal, SHACL evaluation, registry lookups, and persistence computation, possibly over hundreds of thousands of triples. What caching, incremental computation, and lazy evaluation strategies make the audit tolerable in CI pipelines?
7. **Authority verification.** The named-approver IRI on validation edges is asserted. Should the framework verify that the approver had *institutional authority* at attestation time (not merely was-a-person)? How does this integrate with [[Identity Boundaries and Policy Projections]] and the projected policy snapshots already recorded in v0.1?

These are not blockers in the sense of "we know what to do but haven't done it." They are open in the sense of "the community has to converge on answers before the topological audit can be reduced to practice without doing harm." That is also why `flexo-rtm` v0.1 does not commit to it — `flexo-rtm` IS settled engineering on bidirectional traceability plus named signers, and that floor is independent of how the topological research line resolves.

## 11. Roadmap for the topological research line

This is the **research line's own roadmap**, not `flexo-rtm`'s roadmap. `flexo-rtm` v0.1 does not depend on any phase below; the framework's research progresses on its own honest timeline. A four-phase shape, deliberately unaggressive on dates:

**Phase A — Research.** Registry governance design (drafted as a discussion document, not code). Pilot a domain-specific registry (e.g., for aerospace artifact types) in collaboration with one or two willing adopters. Refine the invariants — publish candidate formulations, run them against the ADCS regression corpus and any pilot corpora, iterate. Engage with the OpenMBEE assurance working group (or its successor) on the governance shape. Outputs: a registry schema, a candidate invariant set, and a small population of validated example entries.

**Phase B — Prototype.** Implement the assurance triangle audit in code as a separate downstream-analysis tool, against a fixed registry frozen at Phase A's end. Test on the ADCS lifecycle demo corpus. Build the topology-line test suite per [[Design Spec]] §9.A.6 (D1–D4): `tests/future/test_triangle_closure.py`, `tests/future/test_recursive_completeness.py`, `tests/future/test_tda_barcodes.py`, `tests/future/test_topological_invariants.py`. Validate against the pilot domain registry. Outputs: a working prototype audit mode that reads `flexo-rtm` data and applies the topological analysis on top, with limited test coverage but real end-to-end execution.

**Phase C — Community engagement.** Publish the registry schema, the prototype audit, and the pilot registry's contents. Solicit feedback from prospective adopters. Iterate on the schema and on the governance model in response. Conduct one or two structured workshops with the broader assurance / RTM community. Outputs: a registry schema with documented governance, public draft entries for at least one domain, and a written record of community input.

**Phase D — Applied.** Make the topological audit available as an **optional downstream-analysis mode** that adopters can run over their `flexo-rtm` data. The default `flexo-rtm` certification surface remains the traditional bidirectional analysis from v0.1; adopters who want the topological audit invoke it explicitly as a separate analysis pass. The topological audit is one of several plausible downstream-analysis paths (SLSA, GSN, ARP4754A, custom in-house analysis layers) — not a privileged successor to v0.1. Outputs: an applied topological audit available as an opt-in downstream-analysis target, full test coverage on the topology-line tests, and a documented adoption pathway.

There is no calendar attached to these phases. The right pace is determined by community uptake and the resolution of the seven open questions, not by `flexo-rtm`'s release schedule. The research project will report progress in [[Map of Content]] as phases complete.

## 12. What v0.1 vocabulary aligns with this research line

v0.1 ontology is **forward-compatible** with the topological research line per [[ADR-020 Vocabulary Alignment with Zargham 2026]]. This is interop alignment for one optional downstream-analysis target among several, not a commitment that the topological audit is `flexo-rtm`'s eventual destination. Adopters who later choose to run topological analysis as a downstream mode benefit from the alignment; adopters who never do are unaffected.

**Vocabulary terms.** `rtm:Guidance`, `rtm:AdequacyCriteria`, `rtm:SufficiencyCriteria`, `rtm:Aspect` (and its taxonomy), `rtm:Specification`, `rtm:Document` are in the v0.1 ontology. Adopters who tag adequacy and sufficiency criteria on satisfaction claims, and who classify by aspect, accumulate data that a topological downstream audit can read directly. The same data is also readable by other downstream analyses (SLSA, GSN, ARP4754A, in-house) — the vocabulary is not topology-specific.

**Attestation infrastructure.** The three `rtm:Attestation` subtypes (`SatisfactionAttestation`, `AdequacyAttestation`, `SufficiencyAttestation`) ship in v0.1 with SHACL-enforced `rtm:approvedBy` IRIs. These are the named-signer accountability primitive of `flexo-rtm` ([[ADR-032 Methodology Agnosticism as Foundational Axiom]]). A downstream topological audit would interpret these attestations as the named-approver discipline on validation edges; they are equally meaningful to any other downstream analysis that needs named human signers.

**Aspect tagging.** Per-aspect attestation is supported in v0.1 via `rtm:hasAspect`. A topological downstream audit could compute per-aspect face closure over already-populated aspect tags.

**External URI references.** Per [[External URI References]], every artifact carries `rtm:hasGitRepo`, `rtm:hasGitCommit`, `rtm:hasContentHash`, `rtm:hasOCIImage`. Any downstream-analysis pass that wants to do reproducibility checks — topological or otherwise — has the provenance handles to do so.

**Identity boundaries.** Per [[Identity Boundaries and Policy Projections]], every attestation is evaluated against a projected policy snapshot. A topological audit's authority-verification check (open question §10.7) would consume the same projection.

The boundary between v0.1 and the topological research line is therefore explicit: v0.1 captures the substrate (traceability, attestations, provenance, projected policy) any downstream analysis would consume; the topological audit, if and when it matures, runs as one of several plausible downstream-analysis modes over that substrate. An adopter who runs v0.1 correctly today is building a graph that any downstream analysis — topological or otherwise — can read.

## 13. What adopters should do today

Concrete recommendations for organizations adopting `flexo-rtm` v0.1. Note that these recommendations are good `flexo-rtm` practice in their own right — they are not "preparation for the topological framework." Each is independently valuable; the side effect is that any downstream-analysis path an adopter later chooses to run (topological, SLSA, GSN, ARP4754A, in-house) has well-shaped data to consume:

- **Use [[Traditional Forward and Backward Analysis]] as the primary certification mode.** It is what v0.1 ships, what the ADCS regression corpus runs under, and the analytical surface that incumbent RM tools (Doors, Jama, Polarion) and OSLC-RM tooling already recognize and interoperate with cleanly.
- **Tag adequacy and sufficiency criteria as you go.** Every time an engineer writes "this artifact satisfies this requirement," prompt them (via the skill, the CLI, or a review checklist) to record the adequacy criterion ("the model represents the right thing") and the sufficiency criterion ("the evidence supports the claim") as Guidance vertices. This is good traceability hygiene independent of any downstream analysis.
- **Record named-approver attestations on satisfaction claims.** The `rtm:SatisfactionAttestation`, `rtm:AdequacyAttestation`, and `rtm:SufficiencyAttestation` records (per [[Attestation Infrastructure in v0.1]] and [[Human-AI Accountability]]) are the named-signer accountability primitive shipped in v0.1. They are independently meaningful for traditional traceability and consumable by any downstream analysis that needs human signers.
- **Classify by aspect.** Use `rtm:hasAspect` on requirements and attestations. The aspect taxonomy is extensible; per [[Aspect Coverage with Adequacy and Sufficiency]], even partial tagging composes naturally with per-aspect downstream analyses.
- **Anchor artifacts to external URIs.** Per [[External URI References]], every artifact should carry `rtm:hasGitCommit` (or `rtm:hasContentHash`, or `rtm:hasOCIImage`) so it is reproducible. Any reproducibility check — topological, SLSA, or otherwise — composes on top of this.
- **Do not invent a local registry of pre-approved artifact types.** Resist the temptation to roll your own registry inside your organization before any community converges on one. The registry conversation belongs to the topological research line; until that line resolves (or until you commit to a different downstream-analysis methodology that needs its own registry), a premature registry will likely diverge from whatever the community settles on.

These practices position the project to consume any downstream analysis whose research line matures — without privileging the topological framework over alternative downstream-analysis paths the adopter may choose instead.

## 14. Topology-line acceptance criteria (D1–D4)

Per [[Design Spec]] §9.A.6, if the topological research line matures into an applied downstream audit, that audit's acceptance is gated by four test gates **separate from `flexo-rtm`'s v0.1 release gate**:

| ID | Topology-line criterion | Topology-line test |
|---|---|---|
| D1 | Closed assurance triangle audit | `tests/future/test_triangle_closure.py` |
| D2 | Recursive completeness check against registry | `tests/future/test_recursive_completeness.py` |
| D3 | Persistent homology over commit-sequence filtration | `tests/future/test_tda_barcodes.py` |
| D4 | V − F invariant (alternative formulation pending research) | `tests/future/test_topological_invariants.py` |

These tests do not exist in v0.1; the file paths are reserved as placeholders so the topological research line has a known landing site if it matures. They would be authored in Phase B of the research-line roadmap (§11). They are not on `flexo-rtm`'s release path.

## 15. The library that would materialize the complex

If an adopter runs topological analysis as a downstream mode, the in-memory representation of the assurance complex would be materialized by the [`knowledgecomplex` library](https://github.com/DynamicalSystemsGroup/knowledgecomplex) (the `knowledgecomplex` Python package). That library's 2×2 responsibility map — Topological × Ontological crossed with OWL × SHACL — matches the discipline a topological audit would need:

- **Topological / OWL.** `kc:Element`, `kc:Vertex`, `kc:Edge`, `kc:Face` hierarchy with boundary-cardinality axioms.
- **Topological / SHACL.** Closed-triangle constraints and boundary-closure rules (these require `sh:sparql` because OWL-DL cannot express the closed-triangle constraint).
- **Ontological / OWL.** Concrete subclasses — `rtm:Specification`, `rtm:Guidance`, `rtm:Document` — and their allowed attributes.
- **Ontological / SHACL.** Controlled-vocabulary enforcement (e.g., `rtm:Aspect` values), approver-required gates, attestation co-occurrence rules.

The library is independently maintained; its README and ARCHITECTURE specify the contract a topological downstream audit would consume. `flexo-rtm` v0.1 does not depend on it; the topological audit, if it ever exists as an applied artifact, would.

## 16. Closing position

The topological framework is the most ambitious of the downstream-analysis paths discussed in this research repo. It is also the one where being reduced to practice prematurely would do the most harm — a half-built registry, an under-specified invariant, or an audit that produces false greens would damage trust in the research line long before the community has reason to trust it. The fact that `flexo-rtm` does not commit to it is not a retreat from anything; it is a commitment to keep `flexo-rtm`'s scope honest (bidirectional traceability plus named signers, reduced to practice) while letting the research line resolve on its own honest timeline.

`flexo-rtm` v0.1 ships the substrate it has always been designed to ship: traceability, attestations, provenance, projected policy. v0.2+ ships the OpenAPI surface, the SysMLv2 I/O, the Claude skill, and the live OSLC connectors — `flexo-rtm`'s own roadmap, not the topological framework's. Whether the topological research line ever matures into an applied downstream audit, and whether any specific adopter chooses to run that audit if it does, is independent of `flexo-rtm`'s release path. The vocabulary alignment (per [[ADR-020 Vocabulary Alignment with Zargham 2026]]) ensures interop with that research line if and when it lands — and equally with other downstream-analysis paths (SLSA, GSN, ARP4754A, custom in-house analysis) on equal footing. Per [[ADR-032 Methodology Agnosticism as Foundational Axiom]], `flexo-rtm` does not privilege one downstream-analysis target over another.

## See also

- [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — the locked decision that names this framework as one related research line, not `flexo-rtm`'s destination
- [[Design Spec]] §4.10 (normative positioning) and §9.A.6 (D1–D4 topology-line criteria)
- [[Traditional Forward and Backward Analysis]] — what `flexo-rtm` v0.1 actually IS
- [[Attestation Infrastructure in v0.1]] — the named-approver discipline; settled engineering in its own right
- [[Vertices Edges Faces]] — the type catalog for the topological research line's vocabulary
- [[Aspect Coverage with Adequacy and Sufficiency]] — per-aspect tagging that any downstream analysis can consume
- [[Analysis Layer Scope Algebra]] — scope as the input to any audit, traditional or otherwise
- [[External URI References]] — the provenance handles every artifact carries
- [[Identity Boundaries and Policy Projections]] — projected policy snapshots, consumable by any downstream-analysis pass
- [`knowledgecomplex` library](https://github.com/DynamicalSystemsGroup/knowledgecomplex) — the library that would materialize the complex if a topological audit is run
- [[Human-AI Accountability]] — the accountability discipline that grounds the named-approver design
- [[INCOSE IS 2026 Paper]] — the paper that describes the topological research line
- [[ADR-020 Vocabulary Alignment with Zargham 2026]] — vocabulary alignment as forward-compatible interop for this research line
- [[Map of Content]] — orientation
