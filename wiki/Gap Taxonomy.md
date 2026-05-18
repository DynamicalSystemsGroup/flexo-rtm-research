<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Gap Taxonomy

> The canonical enumeration of gap codes that a `flexo-rtm` v0.1 audit report can produce, plus the gap codes documented as topology-line material (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — only meaningful if an adopter runs the optional topological audit as a downstream-analysis mode). The taxonomy is the lingua franca between the certification predicate, the audit report, the SHACL profiles, and adopters' workflow tooling. Normative source: [[Design Spec]] §4.7. Topology-line codes referenced against §9.A.6 (D1, D2).

## What a "gap" is

A gap is a structural or attestation-level deficiency that a deterministic SPARQL or SHACL check can detect against the graph in scope. Gaps are not opinions; each is the absence (or, in the case of $T6$, presence) of a specific triple pattern, and each has a published detection query. The certification predicate decides, given the profiles in force, whether a particular set of gaps is acceptable for a PASS grade. Gap enumeration in the audit report is independent of grade — a v0.1 audit report lists every gap it finds, even when the predicate grants PASS, because adopters need the per-row detail for triage. See [[Certification Predicate]] for how gaps feed the grade.

Two crosscutting properties hold for every gap code:

- **Scope-relativity.** All gap codes are evaluated against the graph subset selected by the active [[Analysis Layer Scope Algebra]] policy. The same triple may be in scope for one cert run and out of scope for another, so the same data can produce different gap enumerations under different scopes. Scope is itself a deterministic input recorded in the transcript; a gap enumeration is reproducible given the scope and the data snapshot.
- **Profile-gating.** Several gap codes only surface when a specific composable profile is active (see [[Attestation Infrastructure in v0.1]]). Adopters compose profiles as their workflow matures; gap detection rigor scales with profile selection.

## v0.1 ship list: T1–T10

The ten `T`-prefixed codes are what v0.1 reports. They cover traditional forward/backward analysis ($T1$, $T2$), per-claim attestation gaps under the named-approver discipline ($T3$–$T8$), and per-attestation status gaps under the four-state attestation status vocabulary ($T9$, $T10$ — see [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]). Normative source: [[Design Spec]] §4.7.

### T1.orphan-requirement — forward gap

**Definition.** A requirement in scope with no incoming `rtm:satisfies` edge — no artifact claims to satisfy it.

**Detection (SPARQL).**

```sparql
SELECT ?req WHERE {
  ?req a rtm:Requirement .
  FILTER NOT EXISTS { ?art rtm:satisfies ?req }
}
```

**Profile-gating.** Always reported. This is part of [[Traditional Forward and Backward Analysis]] and surfaces without any optional profile.

**Resolution.** Link an artifact that satisfies the requirement, or move the requirement out of scope by amending the scope policy. This is the typical Doors/Jama "uncovered requirement" workflow.

### T2.dangling-evidence — backward gap

**Definition.** An artifact in scope with no outgoing `rtm:satisfies` edge — the artifact participates in the trace graph but is not used to satisfy any requirement.

**Detection (SPARQL).**

```sparql
SELECT ?art WHERE {
  ?art a rtm:Artifact .
  FILTER NOT EXISTS { ?art rtm:satisfies ?req }
}
```

**Profile-gating.** Always reported, with one nuance: foundational artifacts (axioms, immutable inputs the project takes as given) are excluded from the backward denominator by scope policy. See [[Traditional Forward and Backward Analysis]] for the foundational-artifact discipline.

**Resolution.** Link the artifact to the requirements it addresses, mark it as foundational under the scope policy, or remove it from scope.

### T3.unattested-satisfaction

**Definition.** An `rtm:satisfies` triple in scope without any associated `rtm:SatisfactionAttestation` — the claim exists, but no named human has approved it.

**Detection (SPARQL).**

```sparql
SELECT ?art ?req WHERE {
  ?art rtm:satisfies ?req .
  FILTER NOT EXISTS {
    ?att a rtm:SatisfactionAttestation ;
         rtm:subject [ rtm:source ?art ; rtm:target ?req ] .
  }
}
```

**Profile-gating.** Active only with `--profile=attested-satisfies`. With the profile off, satisfaction triples can stand alone and $T3$ is silent. See [[Attestation Infrastructure in v0.1]] for the profile semantics.

**Resolution.** Add an `rtm:SatisfactionAttestation` whose subject is the offending triple, signed by a named approver IRI. The SHACL `AttestationShape` rejects the attestation if `rtm:approvedBy` is missing — that branch is what makes $T7$ structurally absent.

### T4.unattested-adequacy

**Definition.** An `rtm:satisfies` triple in scope without an `rtm:AdequacyAttestation` for the artifact — no named human has approved that the model representation is adequate for the kind of claim being made.

**Detection (SPARQL).**

```sparql
SELECT ?art ?req WHERE {
  ?art rtm:satisfies ?req .
  FILTER NOT EXISTS {
    ?att a rtm:AdequacyAttestation ;
         rtm:subject [ rtm:source ?art ; rtm:target ?req ] .
  }
}
```

**Profile-gating.** Active only with `--profile=attested-adequacy`. Adequacy is conceptually independent of satisfaction (see [[Aspect Coverage with Adequacy and Sufficiency]]), so adopters typically turn this on after `attested-satisfies` has stabilized.

**Resolution.** Add an `rtm:AdequacyAttestation` — a named human confirms the model is adequate for the claim. The criterion is usually tied to a coupling-level `rtm:AdequacyCriteria` guidance vertex; v0.1 does not check that guidance recursively (recursive guidance checking is a problem in the topological research line, not part of `flexo-rtm` — see [[Topological Framework Future Work]]) but does require a named approver on the adequacy claim itself.

### T5.unattested-sufficiency

**Definition.** An `rtm:satisfies` triple in scope without an `rtm:SufficiencyAttestation` for the artifact — no named human has approved that the evidence is sufficient to support the claim.

**Detection (SPARQL).**

```sparql
SELECT ?art ?req WHERE {
  ?art rtm:satisfies ?req .
  FILTER NOT EXISTS {
    ?att a rtm:SufficiencyAttestation ;
         rtm:subject [ rtm:source ?art ; rtm:target ?req ] .
  }
}
```

**Profile-gating.** Active only with `--profile=attested-sufficiency`. Same composability story as $T4$.

**Resolution.** Add an `rtm:SufficiencyAttestation` — a named human confirms the evidence is sufficient. The accompanying guidance vertex would be `rtm:SufficiencyCriteria`; the v0.1 check requires the approver IRI but does not audit the criteria recursively.

### T6.failed-attestation

**Definition.** Any `rtm:Attestation` (of any subclass) with `rtm:attestationStatus rtm:status/fail`. The `earl:result earl:failed` predicate remains SKOS-aligned via `skos:exactMatch` and is still accepted as an equivalent assertion for EARL-tooling interop; the canonical vocabulary in `flexo-rtm` is the four-state status property (see [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]).

**Detection (SPARQL).**

```sparql
SELECT ?att WHERE {
  ?att a rtm:Attestation ;
       rtm:attestationStatus rtm:status/fail .
}
```

**Profile-gating.** Always reported. $T6$ lets a named human assert "I looked at this claim and it does not hold" without losing the named-approver discipline — the attestation exists, has an approver IRI, carries provenance, and asserts failure. That is structurally different from $T3$/$T4$/$T5$, which are about the absence of an attestation.

**Resolution.** Triage the failure: revise the artifact, amend the attestation, or accept the negative judgment as the program's recorded position. The audit report shows $T6$ entries alongside the attestation IRI so reviewers can follow the chain.

### T7.unapproved-attestation — structurally absent

**Definition.** An `rtm:Attestation` (of any subclass) without an `rtm:approvedBy` IRI.

**Profile-gating.** Reserved in the enumeration but **cannot exist in stored data**. The v0.1 SHACL `AttestationShape` (see [[Attestation Infrastructure in v0.1]] and [[Design Spec]] §4.3) rejects any attestation lacking `rtm:approvedBy` at write time. This is the "by construction" mechanism for named-approver accountability: engineers encounter the constraint as a write-time error from the SHACL gate, never as a gap in an audit report.

**Why the code still exists.** $T7$ is reserved for diagnostic completeness — if a future tool or external import path were ever to bypass SHACL, the audit would still have a code to surface the deficiency. Under normal v0.1 operation the audit report will never list a $T7$ row.

**Resolution.** The resolution happens at the write boundary, not in the audit: the SHACL violation message tells the user to add `rtm:approvedBy` before the attestation is accepted into the graph.

### T8.aspect-uncovered

**Definition.** A multi-aspect requirement (one declaring `rtm:hasAspect` values such as `rtm:safety`, `rtm:security`, `rtm:performance`, `rtm:dependability`) has at least one satisfaction attestation but is missing the required attestations for one or more of its declared aspects.

**Detection (informal).** For each requirement with declared aspects, for each aspect, check the per-aspect rollup defined in [[Aspect Coverage with Adequacy and Sufficiency]] and flag aspects whose required attestation set (under the active profiles) is incomplete. The SPARQL is parameterized over the aspect declaration; the precise query is in the conformance suite.

**Profile-gating.** Active only with `--profile=aspect-coverage`. Composes with `attested-adequacy` and `attested-sufficiency` — for a safety-aspect requirement under all three profiles, the audit checks that the safety aspect has both adequacy and sufficiency attestations in addition to satisfaction.

**Resolution.** Add per-aspect attestations. The specific subclass(es) needed depend on which profile triggered the gap — it may be `rtm:SatisfactionAttestation`, `rtm:AdequacyAttestation`, `rtm:SufficiencyAttestation`, or some combination — each tagged with `rtm:hasAspect <aspect-iri>`.

### T9.deprecated-attestation

**Definition.** An `rtm:Attestation` (of any subclass) with `rtm:attestationStatus rtm:status/deprecated` and no replacement attestation in scope. The attestation existed and was valid; upstream changes have invalidated it; a new attestation is required. This is the methodology-neutral regression-handling mechanism locked in [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] — it replaces the earlier scope-level lifecycle state machine.

**Detection (SPARQL).**

```sparql
SELECT ?att ?cause WHERE {
  ?att a rtm:Attestation ;
       rtm:attestationStatus rtm:status/deprecated .
  OPTIONAL { ?att prov:wasInvalidatedBy ?cause . }
}
```

The audit-report rendering enumerates each deprecated attestation with its `prov:wasInvalidatedBy` cause so the team knows what to re-attest. Under the strict profile `--profile=deprecated-requires-provenance`, the absence of `prov:wasInvalidatedBy` on a deprecated attestation is a separate gap (the provenance is required, not merely recommended); under default profile, the provenance is recommended and its absence is informational.

**Profile-gating.** Always reported. Under `--profile=accept-deprecated` the gap is informational; otherwise it is cert-blocking (a deprecated attestation needs replacement before certification passes).

**Resolution.** Write a new attestation (with appropriate named approver) that re-establishes the claim under the current state. The new attestation replaces the deprecated one for cert purposes; the deprecated attestation remains in the audit graph as a record of the prior state. The v0.2 **deprecation cascade detection** ([[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]) automates marking downstream attestations as deprecated when upstream changes invalidate them; v0.1 surfaces existing deprecated attestations and relies on the engineer (or external tooling) to set the status.

### T10.deferred-attestation

**Definition.** An `rtm:Attestation` (of any subclass) with `rtm:attestationStatus rtm:status/deferred`. The engineer surfaced the judgment moment but has not yet resolved it. Subsumes the prior `rtm:DeferredJudgment` concept — which becomes a special case of $T10$ — per [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]].

**Detection (SPARQL).**

```sparql
SELECT ?att WHERE {
  ?att a rtm:Attestation ;
       rtm:attestationStatus rtm:status/deferred .
}
```

**Profile-gating.** Always reported as informational by default. Under `--profile=no-deferred`, $T10$ becomes cert-blocking — appropriate for production cert runs where every attestation must be resolved.

**Resolution.** Resolve the deferred judgment by transitioning the attestation to `rtm:status/pass` or `rtm:status/fail` with appropriate evidence and provenance. The deferred state is intentional surfacing of the judgment moment, not a defect; the gap code exists so the audit report can enumerate pending judgments cleanly.

## Why $T3$–$T5$ and $T8$ are profile-gated

A v0.1 adopter chooses the level of attestation discipline appropriate to the program's maturity. With no optional profiles active, the audit reports $T1$, $T2$, $T6$, $T9$, and $T10$ (informational) — traditional bidirectional analysis plus failed-, deprecated-, and deferred-attestation surfacing. As programs mature, they add `attested-satisfies`, then `attested-adequacy`, then `attested-sufficiency`, and finally `aspect-coverage`; each profile activates a new gap code with a deterministic SHACL/SPARQL check. Programs running production certifications add `--profile=no-deferred` to make deferred attestations cert-blocking. Tightening the audit does not require rewriting the data, only switching on the next profile. See [[Attestation Infrastructure in v0.1]] for the profile catalogue and [[Operational Layer UX Discipline]] for how adoption is sequenced.

## G3–G9: topology-line gap codes

The `G`-prefixed codes are gap codes that would be meaningful **only if an adopter runs the topological audit as a downstream-analysis mode** (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]). They depend on the topological research line maturing into an applied audit, on a registry of pre-approved guidance/artifact types existing, and on the adopter choosing to run that audit; they are NOT reported by v0.1, and `flexo-rtm` does not commit to ever producing them. Normative source: [[Design Spec]] §4.7 and §9.A.6 (topology-line acceptance criteria D1 and D2). The research line itself is described in [[Topological Framework Future Work]].

- **`G3.uncoupled`** — a requirement is not paired with the Guidance vertices a topological audit would expect (`rtm:AdequacyCriteria`, `rtm:SufficiencyCriteria`, etc.). Surfaces only if coupling edges are populated and a registry-rooted audit is run.
- **`G4.assurance-triangle-incomplete`** — an assurance triangle (the closed face a topological audit reads) is missing one or more edges. Requires the closed-triangle audit pass (D1).
- **`G5`** — **structurally absent under the topological audit's SHACL gate, just as $T7$ is in v0.1.** The audit's SHACL gate on validation edges would reject any without an approver IRI. The code is reserved in the enumeration for diagnostic completeness only.
- **`G6.assurance-triangle-stale`** — a triangle is structurally closed but the content hashes of its constituents have diverged since closure; the closure no longer reflects current state.
- **`G7.recursive-incompleteness`** — guidance referenced by an attestation is itself not assured. Catching this requires the registry-driven recursive completeness audit (D2).
- **`G8.dangling-sysml-ref`** — an edge points to an `omg-sysml:` IRI not in scope. This can surface descriptively in v0.1 audit reports under [[External URI References]], but only a topological audit gives it semantic weight as an audit failure.
- **`G9.registry-unknown-type`** — an artifact or guidance type is not in the pre-approved registry. The registry is internal to the topological research line.

The G-codes are tracked in the codebase enumeration alongside the T-codes so any downstream-analysis tooling that materializes has stable identifiers. A v0.1 audit report MUST NOT emit G-code rows; the certification predicate MUST NOT depend on them. Adopters interested in the topological audit as a downstream-analysis path can follow [[Topological Framework Future Work]] and the D1/D2 topology-line tests in [[Design Spec]] §9.A.6.

## Scope-relativity recap

Every gap code above is evaluated against the graph subset chosen by the active [[Analysis Layer Scope Algebra]] policy. The audit report records the scope IRI and scope hash alongside the gap enumeration. Two consequences follow: (1) a triple may produce a gap under one scope and no gap under another — different cert runs ask different questions; (2) reproducing a gap enumeration requires reproducing the scope, the data snapshot, and the active profiles. All three are recorded in the transcript per [[Design Spec]] §4.8.

## Where each code lives in the spec

| Code | Spec section | Profile |
|---|---|---|
| $T1$ | §4.7, §4.1 | always on |
| $T2$ | §4.7, §4.1 | always on (foundational-artifact exclusion via scope) |
| $T3$ | §4.7, §4.3 | `attested-satisfies` |
| $T4$ | §4.7, §4.3 | `attested-adequacy` |
| $T5$ | §4.7, §4.3 | `attested-sufficiency` |
| $T6$ | §4.7, §4.3 | always on |
| $T7$ | §4.7, §4.3 | structurally absent — SHACL rejects at write |
| $T8$ | §4.7, §4.3 | `aspect-coverage` |
| $T9$ | §4.7, §4.3, ADR-031 | always on (cert-blocking by default; informational under `accept-deprecated`) |
| $T10$ | §4.7, §4.3, ADR-031 | always on as informational; cert-blocking under `no-deferred` |
| $G3$–$G9$ | §4.7, §9.A.6 (D1, D2) | topology-line only (downstream-analysis mode) |

## Cross-links

- [[ADR-032 Methodology Agnosticism as Foundational Axiom]] — names the topological framework as one related research line; the G-codes are downstream-analysis gap codes, not deferred `flexo-rtm` features.
- [[Design Spec]] — §4.7 normative source for the gap taxonomy; §4.3 attestation subclasses that generate $T3$–$T10$; §9.A.6 (D1, D2) for the topology-line capabilities that the G-codes depend on.
- [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] — locked decision introducing the four-state attestation status vocabulary that generates $T9$ and $T10$ and refines $T6$.
- [[Certification Predicate]] — how gap enumeration composes into the PASS/FAIL grade.
- [[Aspect Coverage with Adequacy and Sufficiency]] — the per-aspect rollup that $T8$ checks.
- [[Operational Layer UX Discipline]] — how the audit report surfaces gaps to practitioners.
- [[Traditional Forward and Backward Analysis]] — $T1$ and $T2$ in their forward/backward context.
- [[Attestation Infrastructure in v0.1]] — the SHACL discipline and composable profiles that produce $T3$–$T8$.
- [[Topological Framework Future Work]] — the topological research line that the G-codes are meaningful under.
