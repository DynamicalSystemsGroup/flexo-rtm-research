<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# INCOSE V2 Review

The `Incose-Extraction-V2-Experimental` repository is a parallel research effort that ingests the INCOSE Systems Engineering Handbook v5.1 and reconstructs its content as a **knowledge complex** — a vertex/edge/face structure stored as markdown files plus a compiled JSON cache. It is the most thorough INCOSE-aligned ontology asset the project has access to, and `flexo-rtm` will consume parts of it as an alignment vocabulary. This page records what the extraction is, what `flexo-rtm` adopts from it, what it deliberately does not adopt, and how the two projects relate going forward. See [[Design Spec]] §6 for the ontology architecture that consumes it, and [[Topological Framework Future Work]] for the prescriptively-typed simplicial framing that is deferred to v0.2+.

## 1. What the extraction is

The extraction is a **simplicial-complex-shaped knowledge base** of the INCOSE handbook, stored as one markdown file per element with a YAML frontmatter type tag, plus a compiled `outputs/incose_complex.json` that holds the full graph metadata for tooling. From the current build of that JSON:

- **1,627 vertices** (one per concept, process, artifact, section, term, figure, table, role, quality, method, principle, etc.)
- **11,555 edges** (typed binary relations — `defined-in`, `produces`, `consumes`, `is-a`, `enables`, `precedes`, `achieves`, `operationalizes`, and others)
- **846 faces** (higher-order groupings — artifact-evolution chains, process IPO units, concept webs, assurance triangles, lifecycle stage clusters)

These counts are the actual figures from `outputs/incose_complex.json` at the time of this review, not estimates. The top vertex-type populations are `artifact` (434), `concept` (155), `content-unit` (143), `section` (137), `lecture` (132), `slide-deck` (131), `figure` (104), `term` (71), `method` (42), `quality` (41), `role` (41), `process` (34), `principle` (31), `process-detail` (30), and `table` (28). The edge layer is dominated by provenance (`defined-in` / `discussed-in`), flow (`produces` / `consumes`), and bridging (`operationalizes` / `grounds`) types. Faces include `artifact-evolution-*`, `process-unit-*`, `concept-web-*`, and `assurance-*` patterns.

The repository is explicitly **not** a formal OWL ontology. It is a learning-system knowledge graph, optimized for an educational frontend ("a Young Systems Engineer's Illustrated Primer"), with markdown bodies for human reading and JSON metadata for navigation. The README and CLAUDE.md describe it as a primer-shaped extraction, and the directory layout (`00_vertices/`, `01_edges/`, `02_faces/`, `templates/`, `scripts/`) reflects that orientation: build artifacts for a tutoring system, not a SHACL-validated ontology.

## 2. Type hierarchy

The reconciliation document `ontology/session5_framework_reconciliation.md` lays out the vertex type hierarchy that the extraction (mostly) conforms to. The abstract spine is:

- `doc` → `vertex` → one of:
  - **content-vertex** — `handbook-section`, `content-unit` (source material from the handbook)
  - **conceptual-vertex** — `concept`, `principle`, `intellectual-tradition` (the theoretical layer, Ch1)
  - **operational-vertex** — `process`, `stage`, `artifact`, `life-cycle-model`, `measure`, `review-gate` (operational layer, Ch2)
  - **bridging-vertex** — `life-cycle-concept`, `quality` (connects theory and practice)
  - **methodological-vertex** — `method` (how SE work is done, Ch3)
  - **contextual-vertex** — `system-type`, `domain` (application context, Ch4)
  - **actor-vertex** — `role`, `related-discipline` (who does SE, Ch5)
  - **governance-vertex** — `spec`, `guidance` (assurance / quality criteria)
  - **exemplar-vertex** — `case-study` (Ch6 learning resources)

An analogous abstract grouping exists for edges (assurance, taxonomic, causal, temporal, flow, governance, bridging, contextual, learning, provenance) and for faces (assurance, conceptual, operational, bridging, quality, contextual, provenance). The `extends` chain in each markdown frontmatter is what carries the type assertion; nothing currently enforces it as RDF/OWL semantics.

## 3. Concepts of immediate interest to `flexo-rtm`

Three families of vertices and faces from the extraction are directly relevant to `flexo-rtm` v0.1.

**Traceability concept.** `00_vertices/concept-traceability.md` records INCOSE's definition verbatim — "the ability to relate items in the system development to their sources and to items derived from them" — together with the standard backward / forward / horizontal directionality table and the four subtypes (requirements, design, verification, change). This is the canonical handbook articulation of the term `flexo-rtm` builds its certification model around.

**Requirements Traceability Matrix artifact.** `00_vertices/artifact-requirements-traceability-matrix.md` describes the RTM as a traceability artifact produced by the System Requirements Definition and System Architecture Definition processes, consumed by Verification, Validation, and Configuration Management, with explicit orphan-detection and verification-coverage quality criteria (no requirement without a parent, no design without a requirement, all requirements have verification, rationale captured). This is the structural picture `flexo-rtm`'s `rtm:` vocabulary is the machine-checkable refinement of.

**Lifecycle phase content.** The `stage-*` vertices (concept, development, production, utilization, support, retirement) and the `life-cycle-concept-*` vertices (OpsCon, ConOps, etc.) give a stable handbook-anchored set of phase tags suitable for use as aspect candidates in `flexo-rtm`'s SHACL aspect-coverage shape.

## 4. What `flexo-rtm` adopts (informative, via `skos:closeMatch`)

`flexo-rtm` adopts a narrow, informative slice of the extraction, anchored at the alignment layer described in [[Alignment Strategy]]. The adoptions are:

- **Traceability concept definitions** as anchor vocabulary. The `rtm:traceability` term (and its forward / backward / horizontal subdivisions) carries `skos:closeMatch` to the INCOSE vertex `v:concept:traceability` and to the four subtype vertices. This anchors `flexo-rtm`'s informal vocabulary to the handbook articulation without committing to the extraction's encoding.
- **RTM artifact structure** as a vocabulary informant for the certification model. The INCOSE RTM artifact's structural fields — requirement ID, parent, child, allocated design element, verification method, verification status, associated test cases — map onto `flexo-rtm`'s `rtm:Requirement`, `rtm:Evidence`, `rtm:Attestation`, and the GSN-based adequacy/sufficiency pattern. The mapping is one-way: INCOSE is the descriptive source, `flexo-rtm`'s SHACL shapes are the prescriptive enforcement.
- **Lifecycle phase tags as aspect candidates.** The six handbook stages become candidate values for the `rtm:aspect` predicate used by the aspect-coverage shape, alongside the OSLC-RM and SysMLv2 phase tags. This is a vocabulary contribution only; the actual aspect set is profile-configurable.

In all three cases the adoption mechanism is `skos:closeMatch` from the `rtm:` term to a dereferenceable INCOSE concept IRI minted from the extraction's stable `id:` slugs (e.g. `v:concept:traceability` → an INCOSE IRI namespace `flexo-rtm` resolves via the imports layer). The extraction's JSON output is treated as a build-time dependency: a parsimony-extracted alignment file under `ontology/alignment/incose.ttl` records just the IRIs and labels for terms we cite, and the full extraction never enters the runtime closure.

## 5. What `flexo-rtm` does not adopt

The boundary between the two projects is sharp.

- **The simplicial complex extraction format itself is not adopted.** The vertices/edges/faces encoding in `Incose-Extraction-V2-Experimental` is a **descriptive** knowledge structure — it reconstructs the handbook's conceptual topology for navigation and learning. The Zargham 2026 framework that `flexo-rtm` looks toward (see [[Topological Framework Future Work]]) is a **prescriptive** structural-assurance framework that uses simplicial complex language but for a different purpose: enforcing closure properties on certification artifacts, not modeling a corpus. Both encodings can coexist conceptually, but the prescriptive use is deferred from v0.1.
- **The markdown-and-JSON encoding is not adopted.** `flexo-rtm` is an OWL/SHACL/RDF artifact native to Flexo MMS and Apache Jena Fuseki. Markdown frontmatter is not a substrate `flexo-rtm` ingests; the JSON output is consumed only as a build-time IRI map, not as runtime data.
- **The educational primer scaffolding is not adopted.** Lecture vertices, slide-deck vertices, flashcard outputs, learning paths, and assessment artifacts are out of scope. `flexo-rtm` is a certification framework, not a tutoring system.
- **The full vertex population is not adopted.** Of the 1,627 vertices in the extraction, only a small handful (the traceability concept, the RTM artifact, the six lifecycle stages, possibly a few more for OSLC-RM/QM alignment) become citation targets. The rest stay in the extraction repository.

## 6. Notable convergence — and the divergence inside it

INCOSE-Extraction-V2 and the Zargham 2026 framework that motivates [[Topological Framework Future Work]] **both use simplicial complex language**. That is the convergence worth naming. The divergence inside that convergence is equally worth naming:

- **INCOSE's vertices/edges/faces are descriptive.** They model the knowledge structure of the handbook — what concepts exist, how the handbook relates them, which sections define which terms. The complex is a map of an existing body of text.
- **Zargham's vertices/edges/faces are prescriptive.** They model the structural requirements a certification artifact must satisfy — what faces must close, what aspect coverage must hold, what V − E + F invariants must be preserved. The complex is a constraint surface on what counts as a well-formed RTM.

Both views can coexist in `flexo-rtm` as separate alignment layers — the descriptive INCOSE view in v0.1 (via `skos:closeMatch`), the prescriptive Zargham view deferred to v0.2+ behind an opt-in profile. v0.1 only ships the descriptive alignment.

## 7. How to consume the JSON output as a dependency

`flexo-rtm` treats `outputs/incose_complex.json` as an external vocabulary source, handled exactly like OSLC-RM, OSLC-QM, SysMLv2, GSN, PROV, EARL, and P-PLAN under [[Design Spec]] §6.1–6.2:

1. A build-time script reads the JSON, extracts the vertex `id:` slugs and human-readable labels for the small set of cited terms (currently: `v:concept:traceability` and its four subtypes, `v:artifact:requirements-traceability-matrix`, the six `v:stage:*` vertices), and writes them to `ontology/imports/incose.ttl` as `skos:Concept` instances with `rdfs:label`.
2. The alignment file `ontology/alignment/incose.ttl` adds `skos:closeMatch` triples from `rtm:` terms to those IRIs.
3. The parsimony manifest `ontology/parsimony/manifest.yaml` lists every kept IRI so the audit trail is complete and the assembled `rtm.ttl` stays well under the ~2k-triple budget.
4. Engineers reading a `flexo-rtm` requirement definition can dereference the INCOSE IRI back to the extraction's markdown body for full context. The extraction repository acts as the human-readable expansion of the alignment vocabulary.

The dependency direction is one-way: `flexo-rtm` cites INCOSE; INCOSE does not cite `flexo-rtm`.

## 8. What INCOSE-Extraction-V2 does not give us

For completeness, the gaps are worth naming. The extraction provides handbook content, type hierarchy, and a vertex/edge/face structure for navigation. It does **not** provide:

- **No SHACL constraints.** The closure rules, orphan-detection, aspect-coverage, and approver-required shapes that `flexo-rtm` v0.1 enforces are not in the extraction.
- **No OWL axioms.** Subclass and equivalence are recorded only in markdown frontmatter `extends:` fields; nothing is asserted as OWL.
- **No machine-checkable rules.** The "quality criteria" listed on the RTM artifact page ("no orphan requirements", "all requirements have verification") are prose, not predicates.
- **No certification predicate.** The extraction has no notion of a signed attestation, an EARL outcome, a GSN solution, or a PROV activity.

These are exactly the things `flexo-rtm` adds. INCOSE is the descriptive ground; `flexo-rtm` is the prescriptive enforcement built on top.

## 9. Operational status and pointer

The extraction repository is at `/Users/z/Documents/GitHub/Incose-Extraction-V2-Experimental/`. It is an experimental research artifact with its own roadmap and is not under `flexo-rtm`'s versioning. For `flexo-rtm` v0.1, the contract surface is exactly the small set of IRIs cited in `ontology/imports/incose.ttl` and the `skos:closeMatch` triples in `ontology/alignment/incose.ttl`. Changes to the extraction that do not affect those IRIs do not affect `flexo-rtm`. Changes that rename or remove a cited IRI trigger a parsimony review and an alignment update, treated identically to a renamed OSLC-RM term.

See also [[Vertices Edges Faces]] for the `flexo-rtm`-internal use of simplicial-complex vocabulary, [[Alignment Strategy]] for the general parsimony / `skos:closeMatch` discipline, and [[Topological Framework Future Work]] for the deferred prescriptive simplicial-complex audit.
