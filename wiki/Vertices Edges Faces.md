<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Vertices Edges Faces

> Detailed type catalog for the assurance complex — the vertex classes, edge properties, and derived faces that the deferred topological framework will operate over. **This page documents future-framework content.** The RDF vocabulary it specifies (`rtm:Guidance`, `rtm:AdequacyCriteria`, `rtm:SufficiencyCriteria`, `rtm:Aspect`, `rtm:DeferredJudgment`, and the three direct-property edges) ships in `flexo-rtm` v0.1 per [[Design Spec]] §4.2 so adopters can begin tagging now. The closed-triangle audit that *consumes* this vocabulary is deferred per [[Design Spec]] §9.A.6 D1, along with the V−F-style invariant per §9.A.6 D4. The deferral discussion lives at [[Topological Framework Future Work]].

## v0.1 vs. future scope at a glance

| Element | v0.1 | Deferred |
|---|---|---|
| Vertex classes (`Requirement`, `Guidance`, `AdequacyCriteria`, `SufficiencyCriteria`, `Artifact`) | Vocabulary ships; instances MAY be present (§4.2) | Closure of triangles against these vertices |
| Edge properties (`rtm:satisfies`, `rtm:coupledTo`, `rtm:fitsFor`) | Vocabulary ships; SHACL well-formedness only | Triangle-closure audit gate |
| `rtm:Attestation` + `rtm:approvedBy` | Schema-enforced named approver (§4.3) | Recursive completeness check on the approver's guidance |
| Faces (`rtm:AssuranceFace`) | None — derived view only (no v0.1 audit) | SPARQL CONSTRUCT projection in `knowledgecomplex`, triangle-closure audit |
| `rtm:hasAspect` tagging | Vocabulary ships | Per-aspect face closure |
| `rtm:DeferredJudgment` state | First-class RDF state, recorded (§4.2 vocabulary) | Surfacing/reporting under topological audit |
| Boundary complex | Defined via the type-definitions themselves | Formalized as part of the future framework |
| V−F invariant (or alternative) | Not computed | Future criterion (§9.A.6 D4, pending research) |

The through-line: v0.1 captures every typed fact the future framework will consume, but does not aggregate those facts into a topological audit. Per [[Design Spec]] §4.2 the oracle **MUST** parse these terms and accept attestations referencing them, and **MUST NOT** validate that guidance content is itself fit-for-purpose — that recursive completeness check is deferred to §4.10. The vocabulary accumulates forward-compatibly under v0.1; when the framework lands, no migration of the historical graph is required.

## Vertices (0-simplices)

The assurance complex has three top-level vertex kinds. Each is an RDF class with a stable IRI in the `rtm:` namespace, and each is independently meaningful in v0.1 even though the topological audit that consumes them is future work.

### `rtm:Requirement` — specification vertex

A statement of what the system must do, at any layer of an institutional spec stack. Instances may be `rtm:Requirement` proper or `sysml:RequirementUsage` carried through alignment (see [[OMG SysMLv2]]); both are acceptable, and alignment shapes handle the mapping so downstream queries see a uniform vertex type.

In v0.1 the requirement vertex participates in traditional forward/backward bidirectional analysis (see [[Traditional Forward and Backward Analysis]]). It does not yet participate in triangle closure; it is simply the requirement endpoint of an `rtm:satisfies` triple.

### `rtm:Guidance` (abstract) — judgment-checkpoint vertex

A rubric or acceptance-criteria vertex that names a specific judgment the engineer is being asked to make. `rtm:Guidance` is abstract — instances are always one of its two subtypes.

- **`rtm:AdequacyCriteria`** — concerns the **model representation**. "Is the SysMLv2 (or other) representation fit for the *kind* of claim being made?" An adequacy criterion against a structural requirement might say: "the part-property decomposition must reach component-level for any safety claim against this requirement."
- **`rtm:SufficiencyCriteria`** — concerns the **evidence**. "Does the evidence support the claim strongly enough?" A sufficiency criterion against a performance requirement might say: "test data must cover the full operating envelope at three standard deviations."

The adequacy/sufficiency split is exactly the GSN Solution + Justification pattern; [[GSN Integration]] documents the alignment in detail. Shipping `rtm:Guidance` and its subtypes in v0.1 vocabulary is the substantive forward step: adopters begin tagging which criteria apply to which (requirement, artifact) pair today; the topological framework later audits whether those criteria were attested against. Per [[Design Spec]] §4.2 the oracle parses these terms and accepts attestations that reference them but does not validate guidance content itself.

### `rtm:Artifact` — document vertex

An evidence-bearing artifact. Two subtype families ship in v0.1: **SysMLv2 model elements** via alignment (`omg-sysml:Part`, `omg-sysml:Action`, `omg-sysml:Constraint`, etc.) playing the evidence role for structural, behavioral, or constraint-based requirements; and **external evidence artifacts** (proof scripts, simulation results, test reports) which carry external URI references (`rtm:hasGitRepo`, `rtm:hasGitCommit`, `rtm:hasContentHash`, `rtm:hasOCIImage`) per [[External URI References]] so verifiers can re-fetch the underlying content. The artifact vertex is independently meaningful in v0.1 — it is the artifact endpoint of `rtm:satisfies` triples that traditional bidirectional analysis audits today.

## Edges (1-simplices, stored as direct properties)

Per locked decision D12 ([[Design Spec]] §11), edges are **stored as direct RDF properties, not reified statements**. The leaner data model is the engineering choice; SHACL still enforces well-formedness structurally, and attestations bind to the asserted triple via RDF-star or reified-statement wrappers when accountability requires it. Three edge properties carry the load.

### `rtm:satisfies` — verification edge (Artifact → Requirement)

The classical bidirectional-traceability edge: *artifact X satisfies requirement R*. This is the workhorse of v0.1 — the oracle audits coverage and orphan-presence over these triples per [[Traditional Forward and Backward Analysis]], and `T1`–`T8` gap codes are computed against this edge directly. Under the optional `attested-satisfies` profile a `rtm:SatisfactionAttestation` must accompany every triple, binding it to a named approver IRI.

### `rtm:coupledTo` — coupling edge (Requirement → Guidance)

States that a particular guidance vertex is the appropriate judgment-checkpoint for a given requirement. *Requirement R is coupled to adequacy criterion A* means "if you are claiming an artifact satisfies R, your representation must satisfy A." A requirement is typically coupled to at least one adequacy criterion and at least one sufficiency criterion. The coupling edge is content-typed but not yet attestation-required in v0.1.

### `rtm:fitsFor` — validation edge (Artifact → Guidance)

States that a particular artifact fits the named guidance. *Artifact X fits-for adequacy criterion A* is the named-human assertion that the model representation in X meets A. Per [[Attestation Infrastructure in v0.1]], the validation edge requires an accompanying `rtm:Attestation` (an `rtm:AdequacyAttestation` or `rtm:SufficiencyAttestation` depending on the guidance subtype), and the SHACL approver shape applies.

## Attestation — carrier of accountability

`rtm:Attestation` is the class that carries named-human accountability around individual claims. It is **not a vertex of the assurance complex** — it is a carrier annotation that attaches accountability to a specific asserted triple. The complete v0.1 specification lives at [[Attestation Infrastructure in v0.1]]; normative source [[Design Spec]] §4.3.

Required properties (SHACL-enforced under `rtm:AttestationShape`):

- `rtm:approvedBy` — IRI of a named human (`sh:minCount 1`, `sh:nodeKind sh:IRI`). The schema rejects any attestation lacking this field at write time.
- `rtm:certifies` — pointer to the asserted triple, via RDF-star or a reified-statement wrapper.

Standard provenance: `earl:result` (`passed` / `failed` / `cantTell` / `inapplicable`), `prov:wasGeneratedBy`, `prov:atTime`, `prov:wasAssociatedWith`, and optional `rtm:hasAspect` for per-aspect attestation under the `aspect-coverage` profile.

The three `rdfs:subClassOf rtm:Attestation` subtypes — `rtm:SatisfactionAttestation`, `rtm:AdequacyAttestation`, `rtm:SufficiencyAttestation` — share the parent shape; SHACL rejects any of them without an approver IRI. Adequacy and sufficiency attestations are exactly the named-approver inputs the future framework needs to construct closed assurance triangles: v0.1 captures them, the future framework aggregates them into faces.

## Faces (2-simplices, derived view)

A **face** in the assurance complex is the closed triangle ⟨Artifact, Requirement, Guidance⟩ bounded by one of each of the three edge types: a verification edge (`rtm:satisfies`), a coupling edge (`rtm:coupledTo`), and a validation edge (`rtm:fitsFor`). A face is, by Zargham 2026's definition, the unit of fully-typed assurance: every component of the claim is named, every edge of the triangle has an attestation, and the supporting guidance is itself fit-for-purpose against its own assurance face (the recursive completeness condition).

Faces are **not stored as RDF resources in v0.1 or any planned release.** Per locked decision D13 ([[Design Spec]] §11), the simplicial complex is a **derived view materialized via SPARQL CONSTRUCT** when needed, into the analysis layer (`knowledgecomplex`, shipping as a future `[analysis]` optional extra per D17). The SPARQL pattern is sketched below.

```sparql
CONSTRUCT {
    ?face a rtm:AssuranceFace ;
        rtm:hasArtifact  ?art ;
        rtm:hasRequirement  ?req ;
        rtm:hasGuidance  ?gui ;
        rtm:hasAspect  ?aspect .
} WHERE {
    ?art  rtm:satisfies  ?req .
    ?req  rtm:coupledTo  ?gui .
    ?art  rtm:fitsFor  ?gui .
    ?att  a  rtm:Attestation ;
        rtm:certifies  << ?art rtm:fitsFor ?gui >> ;
        rtm:approvedBy  ?approver .
    OPTIONAL { ?req rtm:hasAspect ?aspect . }
    BIND( IRI(CONCAT("urn:face/", ...)) AS ?face )
}
```

A face exists in the materialized view iff **all three edges are present and the validation edge carries a valid attestation** — the **closed assurance triangle** of Zargham 2026.

The audit gate is itself future work. [[Design Spec]] §9.A.6 **D1** ("Closed assurance triangle audit") names the future test (`tests/future/test_triangle_closure.py`). In v0.1 the oracle does not run this audit; the data accumulates and the audit waits. The deferred V−F-style invariant — Zargham 2026's |V| − |F| ≤ 1 sanity check — is named in §9.A.6 **D4** ("V−F invariant (alternative formulation pending research)"). Per locked decision D18, further research determined purely numerical invariants are insufficient; a proper topological audit requires recursive completeness against a registry of pre-approved types. An alternative formulation is pending — see [[Topological Framework Future Work]].

## Aspect parameterization

Real systems engineering does not produce uniform assurance — a requirement may need to be argued under several aspects (functional, performance, safety, security, usability), each of which can warrant its own face. The vocabulary handles this via `rtm:hasAspect` on Requirement, Guidance, and Artifact. Aspect is an open extensibility point: the core ontology ships `rtm:functional`, `rtm:performance`, `rtm:safety`, and adopters add their own (`rtm:security`, `rtm:reliability`, `rtm:cost`, …) by minting IRIs.

A face has an **implicit aspect** via the consistent aspect tag across its three vertices. A multi-aspect requirement induces a multi-face closure obligation: "R is closed for aspect *safety*" is independent of "R is closed for aspect *performance*." Per-aspect coverage is the reporting unit institutional adopters care about ([[Design Spec]] §9 audit dimensions). In v0.1, aspect tags accumulate but the per-aspect closure audit is deferred along with the rest of the topological framework.

## DeferredJudgment — first-class judgment state

`rtm:DeferredJudgment` is a first-class RDF state representing "the engineer surfaced this judgment moment but is not ready to attest yet." It is the substantive contribution of the assurance complex to engineering UX: rather than letting unresolved judgments stay invisible, the schema lets the engineer record them with `rtm:deferralReason`, `rtm:deferredAtTime`, and optional `rtm:expectedResolutionBy`, and resume later.

The audit treats a `rtm:DeferredJudgment` as a **gap that has been recognized** — categorically different from an *unrecognized* gap. In future-framework reporting, deferred judgments appear on their own line of the gap taxonomy ([[Gap Taxonomy]] G-series codes) and the report distinguishes "engineer hasn't noticed the missing attestation" (worse) from "engineer noticed and explicitly deferred" (better, with audit trail). The vocabulary ships in v0.1 even though the audit semantics that consume it are future work.

## Boundary complex

Zargham 2026 §4 identifies a foundational problem with simplicial-complex assurance frameworks: four self-referential vertices — the (S, S), (S, G), (G, S), (G, G) pairings of *specification* and *guidance* over themselves — appear at the boundary of any non-trivial complex. These are claims one makes *about the framework itself* ("the way we specify requirements is itself adequately specified," etc.). Left unresolved they generate an infinite regress. Zargham 2026 resolves this by introducing an **axiomatic root vertex `b0`** — the framework's foundational commitment, asserted but not further decomposed within the framework. For `flexo-rtm`, the boundary complex is realized by the `rtm:Requirement` / `rtm:Guidance` / `rtm:Artifact` type definitions themselves, plus the SHACL shapes that govern them: the type catalog is the axiomatic root from which the rest of the assurance complex is grown. This is not a v0.1 *audit* feature — it is the conceptual underpinning that this page's type catalog provides.

## RDF representation summary

A worked example pulling every construct into one coherent graph:

```turtle
@prefix rtm: <https://w3id.org/flexo-rtm/rtm#> .
@prefix earl: <http://www.w3.org/ns/earl#> .
@prefix prov: <http://www.w3.org/ns/prov#> .
@prefix ex: <https://example.org/> .

# Vertices
ex:req-17  a  rtm:Requirement ; rtm:hasAspect rtm:safety .
ex:adq-3   a  rtm:AdequacyCriteria .
ex:suf-7   a  rtm:SufficiencyCriteria .
ex:art-42  a  rtm:Artifact ; rtm:hasGitCommit "a3f1c…" ; rtm:hasAspect rtm:safety .

# Edges (direct properties per D12)
ex:req-17  rtm:coupledTo  ex:adq-3 , ex:suf-7 .
ex:art-42  rtm:satisfies  ex:req-17 .
ex:art-42  rtm:fitsFor    ex:adq-3 , ex:suf-7 .

# Attestations (named-approver accountability)
ex:att-S a rtm:SatisfactionAttestation ;
    rtm:certifies << ex:art-42 rtm:satisfies ex:req-17 >> ;
    rtm:approvedBy ex:alice ; earl:result earl:passed ;
    prov:atTime "2026-05-15T10:00:00Z"^^xsd:dateTime .

ex:att-A a rtm:AdequacyAttestation ;
    rtm:certifies << ex:art-42 rtm:fitsFor ex:adq-3 >> ;
    rtm:approvedBy ex:bob ; earl:result earl:passed .

ex:att-U a rtm:SufficiencyAttestation ;
    rtm:certifies << ex:art-42 rtm:fitsFor ex:suf-7 >> ;
    rtm:approvedBy ex:bob ; earl:result earl:cantTell .

# A deferred judgment — first-class state
ex:judge-22 a rtm:DeferredJudgment ;
    rtm:deferredOnEdge << ex:art-42 rtm:fitsFor ex:suf-7 >> ;
    rtm:deferralReason "awaiting fatigue-test data" ;
    rtm:deferredAtTime "2026-05-14T16:00:00Z"^^xsd:dateTime .
```

The above is valid v0.1 RDF, will round-trip through the storage layer, and will be accepted by the v0.1 SHACL gate. The face audit it *enables* — "is the safety-aspect (Artifact, Requirement, Guidance) triangle closed for `ex:req-17`?" — is the future-framework audit deferred per [[Design Spec]] §9.A.6 D1. The vocabulary is ready; the audit will follow.

## Cross-references

- [[Design Spec]] §4.1 (traditional bidirectional traceability; v0.1 primary), §4.2 (vocabulary carried in v0.1), §4.3 (attestation infrastructure), §4.10 (topological framework future work), §9.A.6 D1/D4 (deferred acceptance criteria), §11 D12/D13 (direct-property edges and derived-view simplicial complex).
- [[Topological Framework Future Work]] — deferral discussion, registry concept, recursion challenge, open questions.
- [[Typed Simplicial Complex for RTM]] — companion page on the simplicial-complex framing.
- [[Certification Predicate]] — the predicate the closed-face audit will compute.
- [[Gap Taxonomy]] — T1–T8 (v0.1) versus G3–G9 (future framework) gap codes.
- [[GSN Integration]] — adequacy/sufficiency as Solution + Justification mapping.
- [[Layered Ontology]] — where `rtm:` sits among upstream ontologies (BFO, IOF Core, SysMLv2, PROV-O, EARL, SHACL).
- [[Attestation Infrastructure in v0.1]] — the v0.1 named-approver discipline the validation edge requires.
- [[External URI References]] — how artifact vertices carry git+commit / content-hash / OCI digest URIs.
- [[Traditional Forward and Backward Analysis]] — the v0.1 audit that runs over `rtm:satisfies` today.
