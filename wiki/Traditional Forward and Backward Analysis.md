<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Traditional Forward and Backward Analysis

## Why this page comes first

`flexo-rtm`'s primary surface is traditional Requirements Traceability Matrix (RTM) analysis, in the form that Doors, Jama, Polarion, and OSLC-RM users already recognize. Practitioners can adopt this analysis on day one to produce familiar requirements traceability reports — without committing to any specific downstream-analysis methodology. The topological framework articulated in Zargham (2026) (assurance triangles, V−F invariants, recursive completeness) is one related research line that, if it matures, would consume `flexo-rtm`'s traditional traceability + attestation data as input — it is **not `flexo-rtm`'s destination** (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]); it is one possible downstream-analysis path among several (SLSA, GSN, ARP4754A, in-house).

This page specifies the **v0.1 primary surface**. Everything described here ships in v0.1 and is governed by the §9.A acceptance criteria in [[Design Spec]] — specifically X1 (determinism), X2 (replay), X3 (quantitative outcomes only), and X8 (structural completeness without dereferencing). The bidirectional analysis is exactly what those criteria anchor as the v0.1 release gate.

## Historical context

Gotel and Finkelstein, in their 1994 paper *An Analysis of the Requirements Traceability Problem*, gave the foundational definition that has shaped the field for three decades: requirements traceability is "the ability to describe and follow the life of a requirement, in both forwards and backwards direction." They distinguished **pre-RS** traceability (the origins of a requirement — stakeholders, rationale, environmental constraints) from **post-RS** traceability (a requirement's life through design, implementation, and verification). The traditional RTM is the post-RS surface, and it is what virtually every industrial requirements tool ships today.

`ISO/IEC/IEEE 29148:2018` codifies bidirectional traceability as a requirements engineering best practice. The standard articulates two complementary purposes: **impact analysis** when a requirement changes (which downstream artifacts are affected?) and **completeness demonstration** that every stated requirement has been addressed and every produced artifact ties back to a stated need. v0.1's bidirectional analysis serves both purposes directly.

The OSLC-RM 2.1 specification carries this lineage into the linked-data era. Its `oslc_rm:tracedTo` predicate is the canonical machine-readable form of the post-RS verification edge. v0.1 maps directly onto this predicate (see *Mapping to OSLC-RM* below).

## Minimal vocabulary

v0.1 traditional analysis runs against a deliberately bare RTM kernel:

- `rtm:Requirement` — a stated requirement
- `rtm:Artifact` — evidence (a SysMLv2 model element, a proof script, a simulation result, a test report, an inspection record, …)
- `rtm:satisfies` (Artifact → Requirement) — the verification edge: "this artifact claims to satisfy this requirement"

That is the entire vocabulary needed for bidirectional analysis. Adopters MAY also populate the richer vocabulary described in [[Design Spec]] §4.2 (guidance, attestations, aspects), but v0.1 does not require it for forward and backward analysis to produce a valid report.

## Forward traceability analysis

**Definition.** For each requirement $r \in R$, enumerate the artifacts that claim to satisfy it: $\{a \in A : a \texttt{ rtm:satisfies } r\}$. A requirement is **forward-covered** if this set is non-empty.

**SPARQL pattern** (illustrative):

```sparql
PREFIX rtm: <https://flexo-rtm.org/ns/core#>

SELECT ?req (COUNT(?art) AS ?evidenceCount) WHERE {
  ?req a rtm:Requirement .
  OPTIONAL { ?art rtm:satisfies ?req . }
}
GROUP BY ?req
ORDER BY ?req
```

The `ORDER BY` clause is load-bearing for the determinism criterion X1: deterministic SPARQL solution ordering is what makes transcripts byte-identical across runs. The oracle wraps every query with stable ordering before recording it in the audit transcript.

A requirement is forward-covered iff `evidenceCount > 0`. Requirements with `evidenceCount = 0` are forward gaps and surface as `T1.orphan-requirement` (below).

## Backward traceability analysis

**Definition.** For each artifact $a \in A$, enumerate the requirements it claims to satisfy: $\{r \in R : a \texttt{ rtm:satisfies } r\}$. An artifact is **backward-traced** if this set is non-empty.

**SPARQL pattern** (illustrative):

```sparql
PREFIX rtm: <https://flexo-rtm.org/ns/core#>

SELECT ?art (COUNT(?req) AS ?requirementCount) WHERE {
  ?art a rtm:Artifact .
  OPTIONAL { ?art rtm:satisfies ?req . }
}
GROUP BY ?art
ORDER BY ?art
```

An artifact is backward-traced iff `requirementCount > 0`. Artifacts with `requirementCount = 0` are backward gaps and surface as `T2.dangling-evidence` (below). Foundational artifacts (axioms, immutable inputs the project takes as given) are excluded from the backward denominator by scope policy; the scope definition is itself a deterministic input recorded in the transcript.

## Coverage statistics

Per the X3 criterion, coverage is **always reported per dimension** — never rolled into a single "% certified" headline number.

- **Forward coverage** $\% = \dfrac{|\{r \in R : r \text{ forward-covered}\}|}{|R|}$
- **Backward coverage** $\% = \dfrac{|\{a \in A : a \text{ backward-traced}\}|}{|A_\text{non-foundational}|}$

A v0.1 audit report carries both percentages, both raw counts, and the full per-row enumeration. It does not synthesize them into a single grade. Practitioners reading the report see exactly which requirements are uncovered and exactly which artifacts are dangling.

## Traditional gap codes

v0.1's traditional analysis surfaces two gap codes drawn from the canonical gap taxonomy (see [[Gap Taxonomy]]):

| Code | Meaning | Direction |
|---|---|---|
| `T1.orphan-requirement` | a requirement $r \in R$ with no incoming `rtm:satisfies` edge | forward |
| `T2.dangling-evidence` | an artifact $a \in A_\text{non-foundational}$ with no outgoing `rtm:satisfies` edge | backward |

`T1` and `T2` are the only gap codes the v0.1 traditional analysis can produce. The remaining gap codes (`T3`–`T8` for structural issues, `G3`–`G9` for guidance-mediated and topological issues) require the additional vocabulary and the deferred framework respectively; see [[Gap Taxonomy]].

## Basic certification predicate

A graph **passes basic certification at scope S** iff (subject to configurable thresholds):

$$\text{Forward coverage } \% \geq \theta_\text{forward} \quad \wedge \quad \text{Backward coverage } \% \geq \theta_\text{backward}$$

Defaults: $\theta_\text{forward} = \theta_\text{backward} = 100\%$. Thresholds are configurable per project; the chosen values are recorded in the transcript so the certification predicate is reproducible.

This predicate matches exactly what Doors/Jama practitioners call "RTM is complete." The oracle's `certify --level=basic` runs only this analysis: SPARQL-driven, fast, familiar, no commitment to guidance vertices or attestation structure.

## Reports in familiar form

v0.1 produces the report views Doors/Jama users immediately recognize:

- **Tabular RTM view** — rows = requirements, columns = artifacts (or transposed); each cell indicates the presence or absence of an `rtm:satisfies` edge.
- **Coverage summary** — forward %, backward %, T1 count, T2 count, per-row enumeration of which requirements are orphaned and which artifacts dangle.
- **Per-aspect breakdown** — if aspect tags are present (functional, performance, safety, …), the same statistics are reported per aspect, consistent with X3.

Every report is generated from the recorded SPARQL transcript, so any consumer can replay the query and verify the report against the source graph (X2). Reports include the canonical input hash and the transcript hash so structural completeness (X8) can be confirmed without dereferencing external URIs.

## Mapping to OSLC-RM

v0.1's traditional analysis maps directly onto OSLC-RM 2.1 core. The predicate equivalence is:

$$\texttt{oslc\_rm:tracedTo} \equiv \texttt{rtm:satisfies}$$

with the verification direction preserved (artifact → requirement). A graph imported through the OSLC-RM adapter is immediately analyzable at the traditional level — no additional guidance vertices, no attestations, no profile composition required. This is by design: a team running Doors today can stand up a `flexo-rtm` instance, point it at their existing OSLC-RM endpoint, and produce a coverage report in minutes. See [[OSLC RM and QM Review]] for the full adapter mapping and roundtrip semantics.

## What v0.1 does NOT do

The traditional bidirectional analysis is what `flexo-rtm` IS. It is intentionally narrow. The following capabilities belong to the **topological research line** ([[Topological Framework Future Work]]) — one possible downstream-analysis path adopters may choose to run on top of `flexo-rtm`'s data, per [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — and are NOT part of `flexo-rtm`:

- **No guidance vertices required.** v0.1 does not require an `rtm:Guidance` node mediating each verification edge. (Adopters MAY add guidance — see [[Design Spec]] §4.2 — but bidirectional analysis runs without it.)
- **No assurance triangle closure.** `flexo-rtm` does not check that an artifact, a requirement, and a guidance vertex form a closed triangle with the required attestations on each face. Triangle closure is a problem in the topological research line — see [[Topological Framework Future Work]] — not part of `flexo-rtm`.
- **No V−F invariant computation.** `flexo-rtm` does not compute the vertex-minus-face topological invariant. The invariant's research belongs to the topological line, not `flexo-rtm`'s roadmap.
- **No adequacy/sufficiency judgment in bidirectional analysis.** v0.1 records `rtm:AdequacyAttestation` and `rtm:SufficiencyAttestation` when present (as part of `flexo-rtm`'s named-signer discipline), but bidirectional analysis does not surface adequacy or sufficiency findings; those are guidance-mediated gap codes (`G3`–`G9`) — topology-line, meaningful only if an adopter runs a topological downstream audit.
- **No recursive guidance completeness.** `flexo-rtm` does not check whether the guidance itself is fit-for-purpose. Recursive completeness is an unresolved problem in the topological research line, internal to that line.
- **No rolled-up grade.** Per X3, no audit report contains a single "% certified" headline. Quantitative outcomes are always reported per dimension.

These capabilities live in the topological research line. `flexo-rtm` v0.1 ontology carries the aligned vocabulary as forward-compatible interop (see [[Design Spec]] §4.2 and [[ADR-020 Vocabulary Alignment with Zargham 2026]]); adopters who later run any downstream analysis (topological or otherwise) read it natively.

## How the traditional analysis composes with downstream-analysis paths

The traditional bidirectional analysis is **what `flexo-rtm` IS**; it is not a stepping stone toward a topological audit. Per [[ADR-032 Methodology Agnosticism as Foundational Axiom]], `flexo-rtm` is methodology-agnostic, and the topological framework is one possible downstream-analysis path among several (SLSA, GSN, ARP4754A, in-house). Composition properties:

- Any downstream-analysis audit that includes verification semantics rests on `rtm:satisfies` as common substrate. A topological closed-triangle pass would imply a traditional bidirectional pass; SLSA, GSN, and ARP4754A read `rtm:satisfies` the same way.
- A traditional pass does NOT imply a downstream-analysis pass: topological adds requirements (closed triangles, named attestations on each face, V−F invariant); SLSA adds supply-chain attestation requirements; GSN adds argument-structure requirements; each downstream path adds its own conditions.
- Adopters compose incrementally as needed for their context. A team that never adopts any downstream analysis still gets an open-source, OSLC-RM-roundtrip-capable, transcript-replayable RTM with reproducible certification artifacts — a meaningful complement to whatever RM tooling they already use.

## Reference implementation lineage

The ADCS prototype's `traceability/audit.py` module implements forward and backward analysis as independent checks today, and has done so since the project's early commits. The traditional analysis is well-trodden ground. What `flexo-rtm` adds is the explicit formalization as the v0.1 primary surface, with SPARQL-driven SPARQL/SHACL transcript replay (X1, X2), per-dimension quantitative outcomes (X3), and structural completeness verifiable without dereferencing external URIs (X8). See [[ADCS Prototype Lessons]] for the full carry-forward analysis.

## Why this matters for adoption

Institutional requirements management today is well-served by Doors, Jama, Polarion, and similar incumbents — but their certification artifacts are proprietary and their data is locked behind commercial agreements. `flexo-rtm` adds three properties the existing ecosystem doesn't yet supply natively: **open data portability** (RDF graphs with OSLC-RM roundtrip), **reproducible certification** (canonical hashes + replayable transcripts), and **federable verification** (third parties can re-check without proprietary access; see [[Federated Audit and Composition]]). These are properties an organization gains regardless of whether it keeps using its existing RM tool or transitions; they are also properties incumbent vendors and their hosting partners can offer their customers atop the open standard.

Adopters can pick whichever path suits their context: pair `flexo-rtm` with existing RM tooling via OSLC roundtrip, run `flexo-rtm` standalone, or work through a vendor or hosting provider that supports the open standard. Each path produces the same artifact: a deterministic, replayable, lossless RTM with reproducible provenance. Adopters who later want a deeper assurance audit can compose any downstream-analysis path on top — topological (if the research line matures), SLSA, GSN, ARP4754A, or in-house — without abandoning the traditional analysis they already trust. Per [[ADR-032 Methodology Agnosticism as Foundational Axiom]], `flexo-rtm` does not privilege one downstream-analysis target over another. See [[Mission and Thesis]] and [[Verifiable Self-Certification]] for the framing context, and [[Quantitative Outcomes]] for how the per-dimension reporting contract enforces X3.

## See also

- [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — names traditional bidirectional analysis as part of what `flexo-rtm` IS; the topological framework is one related research line, not `flexo-rtm`'s destination
- [[Design Spec]] §4.1 (normative definitions), §9.A.5 (acceptance criteria X1–X3, X8), §4.10 (topological research line)
- [[Topological Framework Future Work]] — the related research line as one possible downstream-analysis path
- [[Certification Predicate]]
- [[Gap Taxonomy]]
- [[Quantitative Outcomes]]
- [[OSLC RM and QM Review]]
- [[ADCS Prototype Lessons]]
