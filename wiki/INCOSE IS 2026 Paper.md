<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# INCOSE IS 2026 Paper

> **Status:** Pointer / stub. The paper is the substrate that `flexo-rtm`'s **future topological framework** builds on; the paper's vocabulary and accountability principles ship in `flexo-rtm` v0.1 even though the topological audit itself is deferred. See [[Topological Framework Future Work]] for the deferral analysis.

## Paper details

- **Title:** *Formalizing Document Assurance: A Topological Framework for Verification, Validation, and Human Accountability*
- **Author:** Michael Zargham
- **Venue:** INCOSE International Symposium 2026
- **Submission status:** Submitted (2026); publication URL TBD post-acceptance.
- **Working PDF:** `/Users/z/Downloads/Formalizing_Document_Assurance_Submission.pdf` (local working copy used during the design phase; replace with the published DOI once available).

## Why this paper is the substrate for `flexo-rtm`

The paper introduces a **typed simplicial complex framework** for engineering assurance — vertices, edges, and faces (2-simplices) with discipline-specific types — and proves that **structural enforcement** of named-human approval on validation edges is what distinguishes assurance from mere process compliance.

Three contributions carry directly into `flexo-rtm`:

1. **Typed simplicial complex framework** — adopted as the future topological framework's certification model. v0.1 ships the vocabulary terms (Specification / Guidance / Document; Verification / Coupling / Validation; Aspect; DeferredJudgment) so adopters accumulate data the future framework will operate on. See [[Vertices Edges Faces]].
2. **Structural accountability enforcement** — validation edges *cannot exist* without a named approver field. `flexo-rtm` v0.1 implements this **today** for the three attestation subclasses (Satisfaction / Adequacy / Sufficiency) via SHACL `sh:minCount 1 ; sh:nodeKind sh:IRI` on `rtm:approvedBy`. The accountability mechanism does not require the topological audit gate. See [[Attestation Infrastructure in v0.1]] and [[Human-AI Accountability]].
3. **Boundary complex termination of recursive completeness** — every artifact's assurance triangle requires its guidance's own assurance triangle; termination requires a community-curated registry of pre-approved artifact types. This recursive completeness check is what makes `flexo-rtm` defer the full topological audit — the registry is a major scope commitment. See [[Topological Framework Future Work]] for the deferral rationale.

## Vocabulary `flexo-rtm` adopts verbatim from the paper

- **Assurance complex** — the typed simplicial complex of vertices/edges/faces over which the assurance argument is built
- **Assurance face** — a closed 2-simplex (Artifact, Requirement, Guidance) with all three boundary edges present and the validation edge attested by a named approver
- **Assurance triple** — the three vertices of an assurance face
- **Boundary complex** — the self-referential primitives that terminate the recursive completeness check at the framework axioms (SS / SG / GS / GG plus root `b0`)

These terms appear in the `rtm:` vocabulary (`rtm:AssuranceFace`, `rtm:AssuranceTriple` planned for the future framework; `rtm:Guidance`, `rtm:AdequacyCriteria`, `rtm:SufficiencyCriteria` ship in v0.1). See [[ADR-020 Vocabulary Alignment with Zargham 2026]].

## Where the paper applies directly to `flexo-rtm`

| Paper section | `flexo-rtm` correspondent |
|---|---|
| §3 Framework Intuition (constraint-optimization framing) | [[Mission and Thesis]] objective function + §9.A acceptance criteria as constraints |
| §4 Framework Architecture (Conceptual / Functional / Logical / Physical layers) | [[Three-Layer Architecture]] (operational / storage / analysis) + [[Layered Ontology]] (core / alignment / profiles / shapes / imports / parsimony) |
| §4.3 Logical Layer (typed simplicial complex) | [[Vertices Edges Faces]] (future framework) + v0.1 vocabulary in [[Design Spec]] §4.2 |
| §4.4 Accountability Model (SHACL-enforced approver field) | [[Attestation Infrastructure in v0.1]] (three subclasses with named-approver SHACL) + [[Approver Binding via Git]] |
| §6 Self-Demonstration (the paper's own assurance complex) | not yet implemented; demonstrates the framework's reflexive applicability |

## Citation

> Zargham, M. (2026). *Formalizing Document Assurance: A Topological Framework for Verification, Validation, and Human Accountability.* INCOSE International Symposium 2026, Yokohama, Japan.

(BibTeX entry and final DOI to be added once publication is finalized.)

## Related wiki pages

- [[Mission and Thesis]] — the load-bearing propositions that quote the paper
- [[Human-AI Accountability]] — the paper restated for RTM context
- [[Topological Framework Future Work]] — the deferral analysis with registry / recursion / V−F discussion
- [[Vertices Edges Faces]] — the future-framework type catalog
- [[ADR-020 Vocabulary Alignment with Zargham 2026]] — the locked-decision ADR
- [[Design Spec]] §4.10 (Future work: Topological framework)
