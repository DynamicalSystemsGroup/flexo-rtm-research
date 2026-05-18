<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Certification Predicate

## Purpose

`flexo-rtm` ships **one** formal certification predicate — the **basic predicate** — and documents a **full-assurance predicate** as one possible downstream-analysis composition adopters may choose to apply on top. The basic predicate is what `flexo-rtm` IS. The full-assurance predicate is what an adopter would compute by composing the basic predicate with a topological downstream audit (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]] and [[Topological Framework Future Work]]); it is not a `flexo-rtm` feature and is not on `flexo-rtm`'s roadmap. Both predicates take the same inputs — a canonicalized RDF dataset $D$ and a scope $S$ — and return a single Boolean. The full-assurance predicate **entails** the basic predicate: any graph satisfying full-assurance at $S$ also satisfies basic at $S$, but not vice versa.

This page gives the formal definition of each predicate, the SPARQL/SHACL machinery that decides them, the entailment relationship, and the rationale. See [[Design Spec]] §4.1 for the basic predicate, §4.10 for the topological research line, and §9.A.5 for the cross-cutting acceptance criteria (X1, X3) that constrain the basic predicate.

## Basic (v0.1) predicate

The basic predicate is the certification surface every Doors / Jama / OSLC-RM practitioner already recognizes as "the RTM is complete." It is defined entirely over the `rtm:satisfies` verification edge and the two coverage statistics from [[Traditional Forward and Backward Analysis]].

**Definition.** Given a canonical dataset $D$ and a scope $S$:

$$\text{Basic}(D, S) \iff \text{forward\%}(D, S) \geq \theta_\text{forward} \;\wedge\; \text{backward\%}(D, S) \geq \theta_\text{backward}$$

where the per-dimension coverage statistics, computed over the scope's induced subgraph, are:

- $\text{forward\%}(D, S) = \dfrac{|\{r \in R(D) \cap S : \exists a \;.\; a \texttt{ rtm:satisfies } r\}|}{|R(D) \cap S|}$
- $\text{backward\%}(D, S) = \dfrac{|\{a \in A(D) \cap S \setminus A_\text{foundational} : \exists r \;.\; a \texttt{ rtm:satisfies } r\}|}{|A(D) \cap S \setminus A_\text{foundational}|}$

**Default thresholds.** $\theta_\text{forward} = \theta_\text{backward} = 100\%$. Projects MAY relax these thresholds locally; the chosen values are written into the transcript so the predicate evaluation is reproducible (per [[Design Spec]] §9.A.5 X2 replay).

**SPARQL implementation.** The basic predicate decomposes into two parameterized aggregate queries — one per direction — both wrapped in deterministic ordering so transcripts are byte-identical across runs (X1):

```sparql
PREFIX rtm: <https://flexo-rtm.org/ns/core#>

# Forward coverage over scope ?S
SELECT (COUNT(?req) AS ?reqTotal)
       (COUNT(?covered) AS ?reqCovered) WHERE {
  ?req a rtm:Requirement ; rtm:withinScope ?S .
  OPTIONAL {
    ?art rtm:satisfies ?req ; rtm:withinScope ?S .
    BIND(?req AS ?covered)
  }
}
ORDER BY ?S
```

```sparql
PREFIX rtm: <https://flexo-rtm.org/ns/core#>

# Backward coverage over scope ?S
SELECT (COUNT(?art) AS ?artTotal)
       (COUNT(?traced) AS ?artTraced) WHERE {
  ?art a rtm:Artifact ; rtm:withinScope ?S .
  FILTER NOT EXISTS { ?art a rtm:FoundationalArtifact . }
  OPTIONAL {
    ?art rtm:satisfies ?req .
    BIND(?art AS ?traced)
  }
}
ORDER BY ?S
```

The oracle records both queries and both result sets in the transcript, computes the two percentages, compares to the configured thresholds, and emits the Boolean. The full per-row enumeration is also persisted so consumers can independently re-derive the predicate from the recorded coverage statistics (X3 forbids rolling these dimensions into a single headline number — the predicate is the *threshold-applied conjunction*, not a smoothed grade).

**What this predicate proves.** Every requirement in scope has at least one satisfying artifact (no orphan requirements, gap `T1`), and every non-foundational artifact in scope contributes to at least one requirement (no dangling evidence, gap `T2`). This is the predicate a Doors or Jama team recognizes as "the RTM is complete." It runs directly against the OSLC-RM adapter's output with no additional vocabulary, no guidance vertices, no attestations, no profile composition. The oracle's `certify --level=basic` evaluates this predicate and nothing else.

## Full-assurance predicate (topological downstream-analysis composition; not a `flexo-rtm` feature)

The full-assurance predicate is the certification surface an adopter who chooses to run **topological analysis as a downstream-analysis mode** would compose on top of `flexo-rtm`. It conjoins the basic predicate (which `flexo-rtm` IS) with a topological condition $\Phi_\text{topo}$ that audits the assurance-triangle structure articulated by the topological research line ([[Design Spec]] §4.10 and [[Topological Framework Future Work]]). It is **not** part of `flexo-rtm`; the shapes that decide $\Phi_\text{topo}$ are the topology-line acceptance criteria D1 and D2 in [[Design Spec]] §9.A.6 — meaningful only if an adopter runs that downstream analysis. Per [[ADR-032 Methodology Agnosticism as Foundational Axiom]], the topological audit is one possible downstream-analysis path among several (SLSA, GSN, ARP4754A, in-house); the same `Basic` predicate can be composed with any of them.

**Definition.**

$$\text{FullAssurance}(D, S) \iff \text{Basic}(D, S) \;\wedge\; \Phi_\text{topo}(D, S)$$

**The topological conjunction.** $\Phi_\text{topo}(D, S)$ is the conjunction of four clauses:

1. **Closed assurance faces.** Every non-foundational vertex in scope belongs to at least one closed assurance face: $\forall v \in (V(D) \cap S) \setminus V_\text{boundary} : \exists f \in F(D) \cap S, v \in \partial f$. See [[Vertices Edges Faces]] for the simplicial-complex semantics.
2. **Named approvers on validation edges.** Every Validation edge in scope carries an `rtm:approvedBy` IRI satisfying the v0.1 SHACL shape (`sh:nodeKind sh:IRI`, `sh:minCount 1`). This clause's SHACL shape is the same shape v0.1 already enforces on attestations ([[Design Spec]] §4.3); a topological downstream audit would extend the same discipline to every Validation edge in scope.
3. **Topological invariant.** $V - F \leq 1$, or an alternative formulation pending the research recorded in [[Design Spec]] §9.A.6 D4. This is a purely numerical check; it is necessary but not sufficient for recursive completeness, which is why clause 4 is required.
4. **No stale attestations.** Every face's recorded input hash matches the current canonical hash of the inputs the face attests over: $\forall f \in F(D) \cap S : \text{hash}_\text{recorded}(f) = \text{hash}_\text{canonical}(\text{inputs}(f))$. Attestations whose subject inputs have mutated since the attestation was signed are stale and cause $\Phi_\text{topo}$ to fail. This clause is what makes the topological composition sensitive to commit-sequence evolution.

**Downstream-analysis decision machinery.** Clauses 1, 3, and 4 are decided by SPARQL over the assurance-complex view ([[Vertices Edges Faces]]); clause 2 is a SHACL shape on `rtm:ValidationEdge` that mirrors the v0.1 `rtm:AttestationShape`. None of this machinery runs in `flexo-rtm`. The topology-line acceptance criteria that would admit it are D1 (closed assurance triangle audit) and D2 (recursive completeness against the registry) in [[Design Spec]] §9.A.6 — meaningful only if an adopter runs the topological audit as a downstream-analysis mode.

## Entailment relationship

$\text{FullAssurance}(D, S) \Rightarrow \text{Basic}(D, S)$ — the full-assurance predicate **entails** the basic predicate.

The argument is direct: `rtm:satisfies` is the same edge in both predicates, and every closed assurance face presupposes an `rtm:satisfies` edge between its Artifact and Requirement vertices. If every non-foundational vertex in scope sits on at least one closed face (clause 1 of $\Phi_\text{topo}$), then every Requirement is satisfied by at least one Artifact (forward = 100%) and every non-foundational Artifact satisfies at least one Requirement (backward = 100%). At the default thresholds, basic certification is entailed; a 100%-covered scope trivially exceeds any threshold $\leq 100\%$, so the entailment holds even under relaxed thresholds.

The converse does **not** hold. $\text{Basic}(D, S) \not\Rightarrow \text{FullAssurance}(D, S)$ — a graph with full forward and backward coverage can fail $\Phi_\text{topo}$ on any clause: no Guidance vertices, no closed faces, missing approver IRIs, $V - F$ out of bounds, or stale attestation hashes. **A user can stop at the basic predicate and hold a valid certification.** Full-assurance is opt-in, not a hidden requirement.

## Why two predicates (not one with a threshold)

A single tunable predicate would be cleaner in the abstract, but two predicates are the correct shape for three reasons.

First, **the basic predicate matches existing RTM tooling.** Doors, Jama, OSLC-RM, and three decades of practice have settled on bidirectional traceability as "the RTM is complete." Adopters get a familiar surface from their existing data, with no commitment to new vocabulary, on day one.

Second, **the full-assurance predicate makes a structurally stronger claim with different vocabulary requirements.** It depends on Guidance vertices, Validation edges, closed assurance faces, and a named-approver registry that is internal to the topological research line, not part of `flexo-rtm`. Collapsing the two into a single graded predicate would force adopters to commit to one specific downstream-analysis methodology, against [[ADR-032 Methodology Agnosticism as Foundational Axiom]].

Third, **the predicates are layered, not competing.** The entailment $\text{FullAssurance} \Rightarrow \text{Basic}$ means a project can adopt the basic predicate today as what `flexo-rtm` IS, accumulate the aligned vocabulary opportunistically per [[Design Spec]] §4.2, and optionally compose any downstream-analysis predicate (topological, SLSA, GSN, ARP4754A, in-house) on top — without rewriting data. Two predicates with a clean entailment relationship encode this composition pattern explicitly; a single predicate with a knob does not.

## Why "predicate" and not "metric"

A predicate is binary; a metric is quantitative. The certification outcome at scope $S$ is binary by design (per [[Design Spec]] §9.A.5 X1 — determinism makes the outcome a function of canonical input, and the threshold comparison produces a single Boolean). The coverage **metrics** — forward %, backward %, per-aspect, per-claim-type — are reported separately, per dimension, and never collapsed into a single rolled-up "% certified" headline (per [[Design Spec]] §9.A.5 X3). The predicate is the threshold-applied outcome over those metrics; the metrics themselves remain visible in the transcript and report. See [[Quantitative Outcomes]] for the metrics surface.

The split matters because audit reports must support both deterministic pass/fail and rich per-dimension diagnostics. The predicate answers "did this scope certify?"; the metrics answer "where are the gaps?". Conflating the two into one headline grade would lose the gap information practitioners need.

## Scope-relativity

Both predicates are evaluated **at a scope** $S$, not over the whole graph. The same dataset $D$ admits many scopes, and `Basic` (or `FullAssurance`) can pass at one and fail at another. Typical pattern: a subsystem scope certifies cleanly while the full-system scope does not, because integration evidence has not yet landed.

Scopes form an algebra (see [[Analysis Layer Scope Algebra]]); the predicate is a function of the $(D, S)$ pair, and the result for `Basic(D, S_1)` says nothing about `Basic(D, S_2)`. The scope IRI is recorded in the transcript so the evaluation is reproducible (X2). Scope-relativity is what makes incremental certification possible: a project can certify subsystems independently as they mature, without waiting for the full model to clear.

## Cross-links

- [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — frames the basic predicate as what `flexo-rtm` IS and the full-assurance predicate as one optional downstream-analysis composition among several.
- [[Traditional Forward and Backward Analysis]] — the SPARQL implementations of forward% and backward%, and the gap codes T1 / T2 the basic predicate falsifies.
- [[Vertices Edges Faces]] — the simplicial-complex vocabulary $V$, $F$, $\partial f$ that $\Phi_\text{topo}$ ranges over (topology-line research, not `flexo-rtm`).
- [[Quantitative Outcomes]] — the per-dimension metrics surface and the X3 criterion that forbids a single rolled-up grade.
- [[Gap Taxonomy]] — the gap codes (T1–T8 for `flexo-rtm`'s basic surface, G3–G9 for topology-line downstream-analysis only) that the predicates falsify when they fail.
- [[Analysis Layer Scope Algebra]] — the scope formalism the predicates are evaluated against.
- [[Verifiable Self-Certification]] — the certification artifact the predicate evaluation produces.
- [[Design Spec]] §4.1 (basic predicate), §4.10 (topological research line), §9.A.5 (X1 determinism, X3 quantitative outcomes), §9.A.6 (D1 triangle closure, D2 recursive completeness — topology-line acceptance criteria).
