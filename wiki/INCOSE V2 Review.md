<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# INCOSE V2 Review

The INCOSE Systems Engineering Handbook is the established practitioner reference for systems engineering work; `flexo-rtm` grounds in the SE concepts that handbook articulates (traceability, verification vs. validation, lifecycle, RTM artifact structure, named-authority review gates). The `Incose-Extraction-V2-Experimental` repository is one digitization of the v5.1 handbook into a knowledge-complex structure (vertices / edges / faces stored as markdown plus a compiled JSON cache); it is the most thorough INCOSE-aligned ontology asset the project has access to. This page covers both the **SE content** `flexo-rtm` adopts from INCOSE and the **extraction-format material** that is worth noting for adopters who want to dereference into a structured rendering. Both form and content are useful contributions; the SE content is the page's center of gravity.

See [[Design Spec]] §6 for the ontology architecture that consumes the alignment, [[Alignment Strategy]] for the parsimony discipline, [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]] for the lifecycle decision (lifecycle is one SE contribution among many, optional, methodology-neutral), and [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] for the methodology-neutrality framing this page operates under.

## What INCOSE contributes to `flexo-rtm`

The INCOSE handbook articulates a small set of foundational SE concepts that `flexo-rtm` grounds in. The mapping is one-way: INCOSE is the descriptive source, `flexo-rtm`'s vocabulary and SHACL shapes are the prescriptive enforcement that adds machine-checkable structure to those concepts. Adoption is via `skos:closeMatch` alignment (per [[Alignment Strategy]]) — INCOSE concept IRIs become anchor vocabulary for `flexo-rtm`'s terms without committing to the handbook's specific encoding or the extraction's specific format.

### Traceability as the core concern

INCOSE's `00_vertices/concept-traceability.md` defines traceability as "the ability to relate items in the system development to their sources and to items derived from them" and articulates the standard directionality table (backward / forward / horizontal) along with four subtypes (requirements, design, verification, change). The benefits the handbook names — supports change impact analysis, ensures completeness, enables coverage assessment, documents rationale, supports audits — are the operational outcomes `flexo-rtm` exists to deliver.

`flexo-rtm`'s structural form for traceability is the `rtm:satisfies` predicate connecting requirements and artifacts, plus the per-claim attestation infrastructure ([[Attestation Infrastructure in v0.1]]) that records named-human accountability for each trace edge. The bidirectional directionality the handbook articulates is what [[Traditional Forward and Backward Analysis]] mechanizes: forward analysis enumerates orphan requirements (T1 in [[Gap Taxonomy]]); backward analysis enumerates dangling evidence (T2). The structural form is `flexo-rtm`'s contribution; the conceptual framing is INCOSE's.

The alignment ships as `rtm:traceability skos:closeMatch v:concept:traceability` and analogous closeMatches for the four subtypes. Adopters reading a `flexo-rtm` requirement can dereference back to the handbook articulation for full context; `flexo-rtm`'s SHACL shapes give them machine-checkable assurance the handbook itself does not.

### Verification vs. validation as judgment kinds

INCOSE's `00_vertices/concept-verification.md` and `concept-validation.md` define verification as "confirmation through objective evidence that specified requirements have been fulfilled" — answering "did we build it right?" — and validation as "confirmation through objective evidence that the system fulfills its intended use in its intended operational environment" — answering "did we build the right thing?" The handbook articulates this distinction with a clear contrast table: verification references requirements, runs in a controlled environment, involves engineers; validation references stakeholder needs, runs in an operational environment, involves stakeholders.

`flexo-rtm`'s named-approver discipline (per [[Attestation Infrastructure in v0.1]]) refines this distinction structurally through **three attestation subclasses** (locked in [[ADR-021 Three Attestation Subclasses Ship in v0.1]]):

- **Satisfaction** — a named human attests that an artifact satisfies a requirement. This is the trace-edge approval, closest to the operational form of verification.
- **Adequacy** — a named human attests that the model representation is adequate for the kind of claim being made. This addresses the "does this evidence reference the right thing in the right way" judgment.
- **Sufficiency** — a named human attests that the evidence is sufficient to support the claim. This addresses the "is there enough evidence, of the right kinds" judgment.

The three subclasses are not a re-labelling of INCOSE's V&V distinction; they are an orthogonal refinement of the judgment kinds the handbook discusses. A given satisfaction attestation may have separate adequacy and sufficiency attestations on the same trace edge, each by a different named approver. The handbook's V&V distinction is preserved as `skos:closeMatch` alignment for vocabulary; the operational dispatch is `flexo-rtm`'s.

The four verification methods INCOSE names (Test, Analysis, Inspection, Demonstration — "TAID") become candidate values for the evidence-type field on satisfaction attestations. They are illustrative vocabulary, not a privileged enumeration; programs that use other terms (e.g., Modelling, Simulation, Walkthroughs) declare their own SKOS concepts and tag accordingly.

### Lifecycle stages as one organizational vocabulary

INCOSE / ISO/IEC/IEEE 15288 defines a canonical six-stage lifecycle: Concept, Development, Production, Utilization, Support, Retirement. The `00_vertices/stage-*` files in the extraction articulate each stage with entry/exit criteria, key processes, key reviews, and typical artifacts. The Concept stage explicitly includes activities programs sometimes describe as "exploratory" or "requirements-specification" — stakeholder needs definition, concept-of-operations, preliminary requirements specification all happen at Concept stage.

**`flexo-rtm` makes lifecycle stages OPTIONAL** organizational-convenience metadata. This is the locked decision in the revised [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]]. The framework provides the `rtm:lifecycleStage` property (range `skos:Concept`); the optional `ontology/lifecycle/incose.ttl` module ships the six INCOSE-aligned stage IRIs; adopters using INCOSE / ISO 15288 tag scopes with them. Adopters using other vocabularies — DO-178C DAL gates, NASA Phase A–F, ISO 9001 process gates, Agile sprint cycles, MIL-STD-498 phasing, customer-program milestones, or no lifecycle vocabulary at all — declare their own SKOS concept schemes and tag scopes with those. **No translation through INCOSE is required.** The framework is methodology-neutral; INCOSE is one example among many ([[Engineering Lifecycle Stages]] enumerates the alternatives).

The earlier framing made lifecycle stages first-class scope metadata with a v0.2 state machine. That framing violated the methodology-neutrality axiom — privileging INCOSE / ISO 15288 over equally legitimate alternatives — and is removed. Regression handling moves to the attestation level via [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]: an attestation invalidated by upstream change is marked `rtm:status/deprecated` with `prov:wasInvalidatedBy` provenance, surfaced as a T9 gap. This mechanism is local to the attestation and works for any adopter regardless of which lifecycle vocabulary (if any) they use.

`flexo-rtm`'s contribution here is the methodology-neutral substrate. INCOSE's contribution is one well-articulated example vocabulary, useful for adopters working in INCOSE-aligned programs, ignored without cost by adopters working in any other tradition.

### RTM artifact structure with orphan detection and coverage criteria

INCOSE's `00_vertices/artifact-requirements-traceability-matrix.md` describes the Requirements Traceability Matrix as an artifact produced by the System Requirements Definition and System Architecture Definition processes, consumed by Verification, Validation, and Configuration Management. The handbook articulates explicit quality criteria the RTM must meet: all requirements traced bidirectionally; **no orphan requirements** (without parent); no gold-plating (design without requirement); all requirements have verification; rationale captured for relationships. The structural fields the handbook names — requirement ID, parent, child, allocated design element, verification method, verification status, associated test cases — are the descriptive picture `flexo-rtm`'s vocabulary refines.

`flexo-rtm`'s **T1 (orphan-requirement)** and **T2 (dangling-evidence)** gap codes in [[Gap Taxonomy]] are exactly the machine-checkable predicates the handbook's quality criteria call for. INCOSE articulates the criteria in prose; `flexo-rtm` ships SPARQL queries (`SELECT ?req WHERE { ?req a rtm:Requirement . FILTER NOT EXISTS { ?art rtm:satisfies ?req } }`) that detect violations deterministically against the graph. The audit report enumerates every gap; the certification predicate ([[Certification Predicate]]) decides whether a given set of gaps is acceptable for a PASS grade.

INCOSE describes; `flexo-rtm` enforces. T1 and T2 are the operationalization of INCOSE's "no orphan requirements" and "all requirements have verification" criteria as machine-checkable predicates that surface in every audit report. The handbook's "rationale captured for relationships" criterion is addressed by the attestation provenance discipline ([[Attestation Infrastructure in v0.1]]): every `rtm:satisfies` edge under the `attested-satisfies` profile carries a named-approver IRI and PROV provenance, structurally guaranteeing rationale is captured.

### Named-authority review gates

INCOSE's handbook articulates a set of formal review gates — System Requirements Review (SRR), Preliminary Design Review (PDR), Critical Design Review (CDR), Test Readiness Review (TRR), Production Readiness Review (PRR), Operational Readiness Review (ORR), and others — each with explicit purposes, entry/exit criteria, key activities, and named human responsibility. The `00_vertices/review-gate-*` files in the extraction articulate each gate; the handbook's posture is that review gates are named human responsibilities, conducted by identifiable people with authority over the gate.

`flexo-rtm` enforces named-human responsibility **structurally** via the SHACL `AttestationShape` (per [[Attestation Infrastructure in v0.1]] §9.A.3 I1): every `rtm:Attestation` MUST carry an `rtm:approvedBy` IRI pointing at a specific human identity. An attestation without a named approver is rejected at write time; the gap code **T7 (unapproved-attestation)** is "structurally absent" — it cannot exist in stored data because the SHACL gate prevents it. This is the "by construction" mechanism in [[Mission and Thesis]]: accountability is not a post-hoc audit check, it is a precondition for the data existing at all.

INCOSE recommends named human responsibility; `flexo-rtm` structurally enforces it. Adopters working with INCOSE review gates (SRR, PDR, CDR, etc.) can model each gate as an `rtm:Attestation` subclass or as an attestation tagged with the gate concept; the named-approver SHACL applies regardless. The framework does not ship the specific review-gate vocabulary as core (an adopter-specific profile can if needed), but the named-authority discipline INCOSE recommends is the framework's foundational constraint.

### Configuration management and baselines

INCOSE's `00_vertices/process-configuration-management.md` articulates configuration management as managing and controlling system elements and configurations over the lifecycle, with three canonical baselines (functional, allocated, product) and activities for identification, change management, status accounting, evaluation, and release control. `flexo-rtm`'s commit DAG (per [[Storage Layer Flexo Conventions]]) and reproducibility chain (per [[Verifiable Self-Certification]]) are the storage-layer mechanization of configuration management discipline. The handbook articulates the criteria; `flexo-rtm` provides the substrate where every certification is bound to a specific commit, the commit DAG records change history, and per-commit transcripts make every certification reproducible. The handbook's "release control" activity is the `cert/<run-id>` branch convention (immutable post-publish) per [[Storage Layer Flexo Conventions]].

## What `flexo-rtm` adopts (informative, via `skos:closeMatch`)

The adoption mechanism is uniform: `flexo-rtm`'s `rtm:` terms carry `skos:closeMatch` to dereferenceable INCOSE concept IRIs minted from the extraction's stable `id:` slugs. The full extraction never enters the runtime closure; a parsimony-extracted alignment file under `ontology/alignment/incose.ttl` records just the IRIs and labels for terms `flexo-rtm` cites.

- **Traceability concept** (and its forward / backward / horizontal subdivisions, and four subtypes) → `v:concept:traceability` and the four subtype vertices.
- **Verification and validation** as judgment-kind concepts → `v:concept:verification`, `v:concept:validation`.
- **Lifecycle stages** (when an adopter uses INCOSE stages) → the six `v:stage:*` vertices.
- **RTM artifact structure** as a descriptive informant → `v:artifact:requirements-traceability-matrix`.
- **Configuration management** as the discipline `flexo-rtm`'s storage layer mechanizes → `v:process:configuration-management`.
- **Named-authority review gates** (when an adopter uses INCOSE gates) → the `v:review-gate:*` vertices.

Adopters reading a `flexo-rtm` requirement definition can dereference each INCOSE IRI back to the extraction's markdown body for full context. The extraction repository functions as the human-readable expansion of the alignment vocabulary; `flexo-rtm`'s SHACL shapes give what the handbook itself does not — machine-checkable predicates.

## What `flexo-rtm` does not adopt

The boundary between the two projects is sharp.

- **The simplicial-complex extraction format itself is not adopted.** The vertices/edges/faces encoding in `Incose-Extraction-V2-Experimental` is a **descriptive** knowledge structure — it reconstructs the handbook's conceptual topology for navigation and learning. The Zargham 2026 framework that `flexo-rtm` looks toward (see [[Topological Framework Future Work]]) is a **prescriptive** structural-assurance framework that uses simplicial-complex language for a different purpose: enforcing closure properties on certification artifacts, not modelling a corpus. Both encodings can coexist conceptually; the prescriptive use is deferred from v0.1.
- **The markdown-and-JSON encoding is not adopted.** `flexo-rtm` is an OWL/SHACL/RDF artifact native to Flexo MMS and Apache Jena Fuseki. Markdown frontmatter is not a substrate `flexo-rtm` ingests; the extraction's JSON output is consumed only as a build-time IRI map, not as runtime data.
- **The educational primer scaffolding is not adopted.** Lecture vertices, slide-deck vertices, flashcard outputs, learning paths, and assessment artifacts are out of scope. `flexo-rtm` is a certification framework, not a tutoring system.
- **INCOSE as the privileged lifecycle vocabulary is not adopted.** Per methodology-neutrality (locked in the revised [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]] and [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]), INCOSE / ISO 15288 lifecycle stages are **one example** among many. Programs using DO-178C, NASA, ISO 9001, Agile, MIL-STD-498, or custom phasing participate on the same footing. The framework does not privilege INCOSE.
- **The full vertex population is not adopted.** Of the ~1,627 vertices in the extraction, only a small handful become citation targets in `flexo-rtm`'s alignment vocabulary. The rest stay in the extraction repository.

## About the V2 extraction format

This section retains the digitization details for adopters who want to dereference into a structured rendering of the handbook. The extraction is interesting work in its own right; it is not the page's center of gravity, and `flexo-rtm` does not depend on its specific encoding choices for any operational purpose.

The extraction is a **simplicial-complex-shaped knowledge base** of the INCOSE handbook v5.1, stored as one markdown file per element with YAML frontmatter type tags, plus a compiled `outputs/incose_complex.json` for tooling. From a recent build of that JSON:

- ~1,627 vertices (one per concept, process, artifact, section, term, figure, table, role, quality, method, principle, etc.)
- ~11,555 edges (typed binary relations — `defined-in`, `produces`, `consumes`, `is-a`, `enables`, `precedes`, `achieves`, `operationalizes`, and others)
- ~846 faces (higher-order groupings — artifact-evolution chains, process IPO units, concept webs, assurance triangles, lifecycle stage clusters)

The top vertex-type populations are `artifact` (~434), `concept` (~155), `content-unit` (~143), `section` (~137), `figure` (~104), `term` (~71), `method` (~42), `quality` (~41), `role` (~41), `process` (~34), `principle` (~31). The edge layer is dominated by provenance (`defined-in` / `discussed-in`), flow (`produces` / `consumes`), and bridging (`operationalizes` / `grounds`) types.

The repository is explicitly **not** a formal OWL ontology. It is a learning-system knowledge graph, optimized for an educational frontend, with markdown bodies for human reading and JSON metadata for navigation. The vertex type hierarchy (from `ontology/session5_framework_reconciliation.md`) groups vertices abstractly into content-vertex, conceptual-vertex, operational-vertex, bridging-vertex, methodological-vertex, contextual-vertex, actor-vertex, governance-vertex, and exemplar-vertex categories. The `extends` chain in each markdown frontmatter carries the type assertion; nothing currently enforces it as RDF/OWL semantics.

For `flexo-rtm`, the format is informative but not load-bearing. What matters operationally is that the extraction provides stable, dereferenceable IRIs for the small set of SE concepts `flexo-rtm` aligns to.

## How to consume the V2 JSON output as a dependency

`flexo-rtm` treats `outputs/incose_complex.json` as an external vocabulary source, handled exactly like OSLC-RM, OSLC-QM, SysMLv2, GSN, PROV, EARL, and P-PLAN under [[Design Spec]] §6.1–6.2:

1. A build-time script reads the JSON, extracts the vertex `id:` slugs and human-readable labels for the small set of cited terms, and writes them to `ontology/imports/incose.ttl` as `skos:Concept` instances with `rdfs:label`.
2. The alignment file `ontology/alignment/incose.ttl` adds `skos:closeMatch` triples from `rtm:` terms to those IRIs.
3. The parsimony manifest `ontology/parsimony/manifest.yaml` lists every kept IRI so the audit trail is complete and the assembled `rtm.ttl` stays well under the ~2k-triple budget per [[Parsimony Policy]].
4. Engineers reading a `flexo-rtm` requirement definition can dereference the INCOSE IRI back to the extraction's markdown body for full context. The extraction repository acts as the human-readable expansion of the alignment vocabulary.

The dependency direction is one-way: `flexo-rtm` cites INCOSE; INCOSE does not cite `flexo-rtm`. Changes to the extraction that do not affect cited IRIs do not affect `flexo-rtm`. Changes that rename or remove a cited IRI trigger a parsimony review and an alignment update, treated identically to a renamed OSLC-RM term.

Adopters using INCOSE benefit from the V2 IRIs being dereferenceable — they can follow the alignment from a `flexo-rtm` term to a structured handbook rendering. Adopters using other methodologies are unaffected; the alignment is an opt-in convenience, not a runtime requirement.

## Notable convergence — and the divergence inside it

INCOSE-Extraction-V2 and the Zargham 2026 framework that motivates [[Topological Framework Future Work]] **both use simplicial-complex language**. That convergence is worth naming. The divergence inside it is equally worth naming:

- **INCOSE's vertices/edges/faces are descriptive.** They model the knowledge structure of the handbook — what concepts exist, how the handbook relates them, which sections define which terms. The complex is a map of an existing body of text.
- **Zargham's vertices/edges/faces are prescriptive.** They model the structural requirements a certification artifact must satisfy — what faces must close, what aspect coverage must hold, what invariants must be preserved. The complex is a constraint surface on what counts as a well-formed RTM.

Both views can coexist in `flexo-rtm` as separate alignment layers — the descriptive INCOSE view in v0.1 (via `skos:closeMatch`), the prescriptive Zargham view deferred to v0.2+ behind an opt-in profile. v0.1 only ships the descriptive alignment.

## What INCOSE-Extraction-V2 does not give us

For completeness, the gaps are worth naming. The extraction provides handbook content, type hierarchy, and a vertex/edge/face structure for navigation. It does **not** provide:

- **No SHACL constraints.** The closure rules, orphan-detection, aspect-coverage, named-approver shapes, and four-state attestation status shape that `flexo-rtm` v0.1 enforces are not in the extraction.
- **No OWL axioms.** Subclass and equivalence are recorded only in markdown frontmatter `extends:` fields; nothing is asserted as OWL.
- **No machine-checkable rules.** The "quality criteria" listed on the RTM artifact page ("no orphan requirements", "all requirements have verification") are prose, not predicates.
- **No certification predicate.** The extraction has no notion of a signed attestation, an EARL outcome, a four-state status, a GSN solution, or a PROV activity.

These are exactly the things `flexo-rtm` adds. INCOSE is the descriptive ground; `flexo-rtm` is the prescriptive enforcement built on top.

## Operational status and pointer

The extraction repository is at `/Users/z/Documents/GitHub/Incose-Extraction-V2-Experimental/`. It is an experimental research artifact with its own roadmap and is not under `flexo-rtm`'s versioning. For `flexo-rtm` v0.1, the contract surface is exactly the small set of IRIs cited in `ontology/imports/incose.ttl` and the `skos:closeMatch` triples in `ontology/alignment/incose.ttl`.

## Cross-references

- [[Design Spec]] §6 — ontology architecture (Core / Alignment / Profiles / Shapes / Imports / Parsimony).
- [[Alignment Strategy]] — the `skos:closeMatch` and `owl:equivalentClass` discipline used to bring INCOSE concept IRIs in as anchor vocabulary.
- [[Vertices Edges Faces]] — `flexo-rtm`-internal use of simplicial-complex vocabulary; distinct from the descriptive extraction.
- [[Topological Framework Future Work]] — the deferred prescriptive simplicial-complex audit; uses the same vocabulary as the extraction but for a different purpose.
- [[Attestation Infrastructure in v0.1]] — the three attestation subclasses (satisfaction / adequacy / sufficiency) that refine INCOSE's V&V distinction with named-approver structure; the four-state attestation status vocabulary.
- [[Gap Taxonomy]] — T1 (orphan-requirement), T2 (dangling-evidence), T9 (deprecated-attestation), T10 (deferred-attestation), and the rest of the v0.1 gap codes that mechanize the criteria INCOSE articulates in prose.
- [[Engineering Lifecycle Stages]] — the optional lifecycle pattern with INCOSE / ISO 15288 as one example among many.
- [[Traditional Forward and Backward Analysis]] — the bidirectional traceability analysis that operationalizes INCOSE's directionality table.
- [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]] — revised decision making lifecycle optional and methodology-neutral; INCOSE is one example.
- [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] — the methodology-neutrality framing this page operates under; regression handling at the attestation level, not via a scope-level state machine.
- [[ADR-030 Polycentric ASOT Authority Model]] — the polycentric framing that motivates methodology-neutrality across cooperating orgs.
- [[Design Spec]] — referenced throughout for normative architecture decisions.
