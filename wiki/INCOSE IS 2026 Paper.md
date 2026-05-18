<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# INCOSE IS 2026 Paper

> **Status:** Pointer / stub. The paper articulates the **topological framework** — a related research line, not `flexo-rtm`'s destination (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]). The paper's named-approver accountability principle is part of what `flexo-rtm` IS, shipped in v0.1 ontology and SHACL. The paper's typed-simplicial-complex framework articulates the related research line; if it matures into an applied audit, adopters may choose to run it as one optional downstream-analysis mode on top of `flexo-rtm`'s data (alongside SLSA, GSN, ARP4754A, in-house). See [[Topological Framework Future Work]] for the research-line documentation.

## Paper details

- **Title:** *Formalizing Document Assurance: A Topological Framework for Verification, Validation, and Human Accountability*
- **Author:** Michael Zargham
- **Venue:** INCOSE International Symposium 2026
- **Submission status:** Submitted (2026); publication URL TBD post-acceptance.
- **Working PDF:** `/Users/z/Downloads/Formalizing_Document_Assurance_Submission.pdf` (local working copy used during the design phase; replace with the published DOI once available).

## Why this paper is relevant to `flexo-rtm`

The paper introduces a **typed simplicial complex framework** for engineering assurance — vertices, edges, and faces (2-simplices) with discipline-specific types — and argues that **structural enforcement** of named-human approval on validation edges is what distinguishes assurance from mere process compliance. The first idea is the topological research line; the second is settled engineering that `flexo-rtm` ships.

Three contributions cross-reference `flexo-rtm`:

1. **Typed simplicial complex framework** — articulated as one possible downstream-analysis methodology (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]); not adopted as `flexo-rtm`'s certification model. v0.1 ships the vocabulary terms (Specification / Guidance / Document; Verification / Coupling / Validation; Aspect; DeferredJudgment) as forward-compatible interop, so adopters who later run topological analysis as a downstream-analysis mode read the data natively. See [[Vertices Edges Faces]].
2. **Structural accountability enforcement** — validation edges *cannot exist* without a named approver field. `flexo-rtm` v0.1 ships this discipline for the three attestation subclasses (Satisfaction / Adequacy / Sufficiency) via SHACL `sh:minCount 1 ; sh:nodeKind sh:IRI` on `rtm:approvedBy`. Per [[ADR-032 Methodology Agnosticism as Foundational Axiom]], named-signer accountability is part of what `flexo-rtm` IS — settled engineering, independent of any specific downstream-analysis methodology. See [[Attestation Infrastructure in v0.1]] and [[Human-AI Accountability]].
3. **Boundary complex termination of recursive completeness** — every artifact's assurance triangle would require its guidance's own assurance triangle; termination requires a community-curated registry of pre-approved artifact types. The registry is a major scope commitment internal to the topological research line, not part of `flexo-rtm`. See [[Topological Framework Future Work]] for the research-line documentation.

## Vocabulary `flexo-rtm` adopts verbatim from the paper

- **Assurance complex** — the typed simplicial complex of vertices/edges/faces over which the assurance argument is built
- **Assurance face** — a closed 2-simplex (Artifact, Requirement, Guidance) with all three boundary edges present and the validation edge attested by a named approver
- **Assurance triple** — the three vertices of an assurance face
- **Boundary complex** — the self-referential primitives that terminate the recursive completeness check at the framework axioms (SS / SG / GS / GG plus root `b0`)

These terms appear in the `rtm:` vocabulary (`rtm:AssuranceFace`, `rtm:AssuranceTriple` as forward-compatible interop with the topological research line; `rtm:Guidance`, `rtm:AdequacyCriteria`, `rtm:SufficiencyCriteria` ship in v0.1 as `flexo-rtm`'s own concepts). See [[ADR-020 Vocabulary Alignment with Zargham 2026]].

## Where the paper applies directly to `flexo-rtm`

| Paper section | `flexo-rtm` correspondent |
|---|---|
| §3 Framework Intuition (constraint-optimization framing) | [[Mission and Thesis]] objective function + §9.A acceptance criteria as constraints |
| §4 Framework Architecture (Conceptual / Functional / Logical / Physical layers) | [[Three-Layer Architecture]] (operational / storage / analysis) + [[Layered Ontology]] (core / alignment / profiles / shapes / imports / parsimony) |
| §4.3 Logical Layer (typed simplicial complex) | [[Vertices Edges Faces]] (topological research line vocabulary) + v0.1 vocabulary in [[Design Spec]] §4.2 as forward-compatible interop |
| §4.4 Accountability Model (SHACL-enforced approver field) | [[Attestation Infrastructure in v0.1]] (three subclasses with named-approver SHACL) + [[Approver Binding via Git]] |
| §6 Self-Demonstration (the paper's own assurance complex) | not yet implemented; demonstrates the framework's reflexive applicability |

## Citation

> Zargham, M. (2026). *Formalizing Document Assurance: A Topological Framework for Verification, Validation, and Human Accountability.* INCOSE International Symposium 2026, Yokohama, Japan.

(BibTeX entry and final DOI to be added once publication is finalized.)

## Related wiki pages

- [[Mission and Thesis]] — the load-bearing propositions that cite the paper
- [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — names the topological framework as one related research line, not `flexo-rtm`'s destination
- [[Human-AI Accountability]] — named-signer accountability as settled engineering (W3C VC-DI / SLSA / SHACL / NIST SP 800-63), independent of any specific downstream-analysis methodology
- [[Topological Framework Future Work]] — the research line documentation with registry / recursion / V−F discussion (where the paper IS load-bearing)
- [[Vertices Edges Faces]] — the topological research line's type catalog
- [[INCOSE V2 Review]] — INCOSE handbook SE content `flexo-rtm` grounds in
- [[ADR-020 Vocabulary Alignment with Zargham 2026]] — vocabulary alignment as forward-compatible interop
- [[Design Spec]] §4.10 (topological framework as related research line)
