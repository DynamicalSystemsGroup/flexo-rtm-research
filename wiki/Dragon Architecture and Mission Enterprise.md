<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Dragon Architecture and Mission Enterprise

> External-research record of the **Dragon Architecture** — the openMBEE-community vision for a Mission Enterprise for Digital Thread approaches. Source: [Dragon Architecture - DRAFT](https://openmbee.atlassian.net/wiki/spaces/OPENMBEE/pages/704708609/Dragon+Architecture+-+DRAFT) on the openMBEE Confluence space, mirrored locally for citation stability at [`_assets/dragon-architecture/dragon-architecture-DRAFT-2026-05-18.pdf`](_assets/dragon-architecture/dragon-architecture-DRAFT-2026-05-18.pdf). Authors are openMBEE community contributors; the document is marked DRAFT and may evolve. This page records the alignment without restating, extending, or constraining Dragon's commitments.

`flexo-rtm` and the Dragon Architecture operate at **different layers of the engineering stack** and they share a methodological posture. Dragon is the vision for *how engineers do model-based engineering work* in a Mission Enterprise — Quantitative Engineering, Software Defined Systems, Engineering Information Science, Formal Explicit Qualification — methodology-neutral, RDF-compatible, refusing to mandate a central model. `flexo-rtm` is the **certification-evidence layer**: it captures bidirectional requirements traceability as the engineering team works, producing institutional-grade evidence that requirements have been satisfied. Like Dragon, `flexo-rtm` is methodology-neutral. It mirrors the engineers' methodology rather than dictating one, and records their decisions and justifications as they happen.

This page records the upstream vision, why it is the right vision for `flexo-rtm` to serve, and the specific commitments Dragon makes that `flexo-rtm` must respect.

## What Dragon is (in the authors' framing)

The Dragon Architecture is "the Architecture of a Mission Enterprise for Digital Thread approaches. It leverages concepts like Quantitative Engineering, Software Defined Systems and Engineering Information Science built on COTS platforms that emphasize Internet-based standards and protocols for User Experience, Scale and Interoperability."

Three foundational concepts compose:

- **Quantitative Engineering** — "the transformation of traditional engineering practices into formalized executable representations such that the engineering work being done can now be performed in an entirely quantitative manner."
- **Software Defined Systems** — "an extension of Quantitative Engineering where by the engineering models are cohesive enough to be used to represent the complete product or system of products. This representation becomes the embodiment of requirements and design of the system or product."
- **Engineering Information Science** — the COTS-platform layer, Internet-based standards, and protocol composition that supports User Experience, Scale, and Interoperability.

Both Quantitative Engineering and Software Defined Systems are grounded in the **Executable Systems Engineering Methodology (ESEM)**.

The Architecture itself "centers around the concept of **Formal Explicit Qualification**, which is rooted in the utilization of the Change Package framework and Digital Threads." The Dragon notional functional flow figure spans **Capture → Requirements/Design → Analysis → Publication** for Systems and **Design → Development → Testing → Operation** for Software, with Change Package as the configuration-management surface, Global Traceability as the cross-flow surface, and a tool ecosystem (JAMA/DNG, Teamwork Cloud/MMS, GitHub, Jenkins, Coverity, TestRail, Collaborator, Artifactory, etc.) intentionally shown as **interchangeable** rather than prescriptive. A Digital Twin Pipelines figure shows the same vision applied through Architecture Definition → System Design → Behavior Model + Testbed Model → Mission System Execution Environment → Hardware Testbed, with multi-physics composition (Python, FMU/FMI, Modelica). A NASA NPR 7120.5E life-cycle figure shows the mission-lifecycle phases the architecture supports.

The cited references are ESEM, the IEEEAC 2023 paper "Towards a Model-Based Product Development Process from Early Concepts to Engineering Implementation," and the NASA Systems Engineering Handbook (NPR 7120.5E). The languages and standards table enumerates SysML v2, Python v3, Modelica, SysML v1, BPMN v2, UAF, and FMU/FMI — composed, not dictated.

## Three commitments Dragon makes

Three commitments in the source document are load-bearing for how `flexo-rtm` relates to Dragon:

1. **Methodology-neutral.** "Dragon Architecture maintains a complete neutrality towards the specifics of the modeling methodology adopted. Its sole purpose is to elucidate the manner in which models can be seamlessly integrated with both documents and software systems."
2. **No mandated central model.** "Dragon doesn't mandate the existence of a centralized model. Rather, it hinges on the ability to harness models for establishing connections with code. It remains incumbent upon individual projects to determine the approach, if any, they wish to adopt in this regard."
3. **RDF-compatible, representation-agnostic.** "The entirety of Dragon adheres to RDF compatibility, making it adaptable to any Model-Based representation. The framework refrains from imposing any requirements specific to representation, be it in relation to models, documents, or any other aspect."

The contribution of Dragon, in the authors' words, "lies in delineating the precise process through which these models undergo unequivocal traceability within the qualification trajectory" — and explicitly, "the decision to model scenarios and the methodologies employed therein is distinctly a project-specific prerogative, separate from the framework set forth by Dragon."

## Where `flexo-rtm` sits relative to Dragon

`flexo-rtm` is a different layer of the same stack. Dragon describes how the engineering work flows — what gets captured, what gets analyzed, what gets published, where the systems-engineering and software-engineering threads meet, how Formal Explicit Qualification rides on the Change Package framework and Digital Threads. `flexo-rtm` does not redefine any of this. It provides the **certification-evidence layer**: as the engineering team works inside their chosen flow (Dragon-conformant or otherwise), `flexo-rtm` captures the bidirectional requirements traceability as named-graph attestations under named approvers, produces a structurally-local replayable cert artifact, and supports federated audit at composition scale.

The posture is mirror, not dictate. `flexo-rtm`'s data substrate is RDF and SPARQL — the same RDF-compatibility commitment Dragon makes. `flexo-rtm`'s scope model is polycentric (multiple organizations, multiple scopes, no single central runtime — see [[Mission and Thesis]] and [[ADR-030 Polycentric ASOT Authority Model]]) — the same "no mandated central model" commitment. `flexo-rtm`'s adapters and SHACL profiles are composable and opt-in — the same composition-of-standards posture. The certification surface engages with the work as it happens; decisions and justifications are captured atomically alongside model evolution, not extracted retroactively.

## What `flexo-rtm` does not do

Three explicit non-claims, in service of fidelity to the authors' intent:

- `flexo-rtm` does not implement Dragon, extend Dragon, or claim conformance to a Dragon specification. The Dragon page is DRAFT and methodology-neutral by design; conformance is not a meaningful claim against a methodology-neutral vision.
- `flexo-rtm` does not require Dragon. Projects that adopt `flexo-rtm` need not adopt Dragon, ESEM, or any specific modeling methodology. The certification-evidence layer is methodology-neutral itself.
- `flexo-rtm` does not own the engineering flow. Where Dragon enumerates Capture, Requirements/Design, Analysis, Publication, Development, Testing, and Operation as the surface where engineering work happens, `flexo-rtm` attaches at that surface to record traceability and attestations — it does not define what the surface looks like.

These non-claims are not hedges. They are the operating constraint: Dragon's value is its neutrality, and `flexo-rtm`'s value is that it can serve that neutrality without compromising it.

## Vocabulary alignment

A small set of mappings between Dragon's vocabulary and `flexo-rtm`'s vocabulary, offered as a reading aid only:

| Dragon | `flexo-rtm` |
|---|---|
| Change Package framework | `rtm:Scope` + atomic commit pairing git working-tree state with Flexo named-graph state ([[Storage Layer Flexo Conventions]], [[Flexo Git Coexistence]]) |
| Digital Thread | Structurally-local replayable facts in the cert artifact; external URI references ([[External URI References]]) |
| Formal Explicit Qualification | Verifiable Self-Certification + named-approver attestations ([[Verifiable Self-Certification]]) |
| Global Traceability | Bidirectional traceability oracle + composition-scale federated audit ([[Federated Audit and Composition]]) |
| Mission Enterprise (multi-organization scope) | Polycentric ASOT model ([[ADR-030 Polycentric ASOT Authority Model]]) |

These are mappings, not equivalences. Dragon's framing is broader (the Mission Enterprise as a whole); `flexo-rtm`'s framing is narrower (the certification-evidence layer of one part of that enterprise).

## References

- [Dragon Architecture - DRAFT](https://openmbee.atlassian.net/wiki/spaces/OPENMBEE/pages/704708609/Dragon+Architecture+-+DRAFT) — canonical source on the openMBEE Confluence space (authentication required).
- [Mirrored PDF (2026-05-18 snapshot)](_assets/dragon-architecture/dragon-architecture-DRAFT-2026-05-18.pdf) — local copy for citation stability; refresh from the canonical source if Dragon advances past DRAFT.
- **ESEM** (Executable Systems Engineering Methodology) — the methodology Dragon cites as the basis for Quantitative Engineering and Software Defined Systems. Linked from the Dragon page.
- **IEEEAC 2023** — "Towards a Model-Based Product Development Process from Early Concepts to Engineering Implementation." Cited from the Dragon page.
- [NASA Systems Engineering Handbook (NPR 7120.5E)](https://www.nasa.gov/sites/default/files/atoms/files/nasa_systems_engineering_handbook_0.pdf) — life-cycle process the Dragon Architecture supports.
- **OpenMBEE** — the open-source modeling environment community where Dragon is authored. `flexo-rtm`'s planned home at the MVP service milestone (see [[Mission and Thesis]] "OpenMBEE positioning").
