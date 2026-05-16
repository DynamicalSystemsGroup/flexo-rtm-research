<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# GSN Integration

> **Purpose.** Document how `flexo-rtm` adopts the **Goal Structuring Notation** (GSN) — via the published OntoGSN vocabulary — as the substrate for adequacy and sufficiency attestations. The integration is the locked decision **D15 / ADR-015**: keep GSN as the assurance-case backbone, parsimony-extract ~8 classes and ~6 properties, and subclass two `rtm:` attestation types from `gsn:Solution` so external assurance-case tooling reads them natively. See [[Design Spec]] §6.3 for the headline decision, [[PROV EARL GSN P-PLAN]] for the broader four-vocabulary substrate, and [[Aspect Coverage with Adequacy and Sufficiency]] for the epistemic split this encoding serves.

## Why GSN

The Goal Structuring Notation is the **canonical assurance-case vocabulary**. It originated in UK rail safety (Kelly's thesis, late 1990s) and is now standard practice across **rail** (CENELEC EN 50129), **aerospace** (UK MoD Def Stan 00-56, NASA assurance-case work), **medical devices** (FDA assurance-case submissions), and **automotive** (ISO 26262 Part 10, SOTIF). The notation has a graphical convention and a corresponding ontology — **OntoGSN** — that gives every node and link a stable IRI under `https://w3id.org/OntoGSN/ontology#`.

`flexo-rtm` is not in the business of writing full assurance cases. It records **adequacy** and **sufficiency** attestations against requirements. Those attestations are exactly the kind of structured judgment GSN was built to encode: a claim, supported by evidence, qualified by context and justification. Reusing GSN at the leaf level lets a downstream assurance-case author lift `flexo-rtm` attestations into a larger GSN argument without translation.

## What we use from GSN

Per the [[Parsimony Policy]], we extract a minimal subset — not the whole vocabulary. The classes:

- `gsn:Goal` — a claim to be supported. (Used by downstream assurance-case authors; `flexo-rtm` does not mint goals itself but preserves the term for round-tripping.)
- `gsn:Strategy` — an argumentation step decomposing a goal into sub-claims. (Already used by `rtm:Attestation` in the prototype, multi-typed as `earl:Assertion , gsn:Strategy , prov:Activity`.)
- `gsn:Solution` — a leaf evidence node supporting a claim.
- `gsn:Justification` — rationale for an inference step (the "why this argument is valid").
- `gsn:Assumption` — a claim taken without supporting evidence within the case.
- `gsn:Context` — applicable scope, conditions, or definitions framing a claim.

The properties:

- `gsn:supports` — links a supporting node (Solution, sub-Goal) to what it supports.
- `gsn:supportedBy` — inverse of the above.
- `gsn:byJustification` — links an argumentation step to its justification node.
- `gsn:inContextOf` — links a node to a Context, Assumption, or Justification that frames it.
- `gsn:statement` — datatype property carrying the textual content of a node.

Total: **6 classes + 5 properties** (well inside the ~8 + ~6 parsimony budget). These are the OntoGSN identifiers; the build-time extractor pulls them via SPARQL `CONSTRUCT` or ROBOT MIREOT into the assembled `rtm.ttl`, with provenance recorded in `manifest.yaml`. See [[PROV EARL GSN P-PLAN]] for the assembly mechanics.

## `flexo-rtm` class extensions (D15 / ADR-015)

The locked decision is to **subclass** rather than reuse `gsn:` identifiers directly for the two attestation flavours that `flexo-rtm` cares about:

```turtle
@prefix rtm:   <https://flexo-rtm.org/ontology#> .
@prefix gsn:   <https://w3id.org/OntoGSN/ontology#> .
@prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#> .

rtm:AdequacyAttestation
    rdfs:subClassOf gsn:Solution ;
    rdfs:label "Adequacy Attestation" ;
    rdfs:comment "A leaf node asserting that the model used to produce evidence is adequate for the requirement it addresses." .

rtm:SufficiencyAttestation
    rdfs:subClassOf gsn:Solution ;
    rdfs:label "Sufficiency Attestation" ;
    rdfs:comment "A leaf node asserting that the body of evidence is sufficient to support the requirement's satisfaction claim." .

rtm:Justification
    rdfs:subClassOf gsn:Justification ;
    rdfs:label "Justification" ;
    rdfs:comment "Rationale node accompanying an adequacy or sufficiency attestation." .
```

The semantics are inherited: every `rtm:AdequacyAttestation` *is* a `gsn:Solution`, every `rtm:Justification` *is* a `gsn:Justification`. External readers see the standard view; internal readers see the rtm-specific view.

## Worked example — adequacy attestation

A requirement `adcs:req-pointing-accuracy` is the subject. An engineer attests that the linearized rigid-body model used to simulate pointing error is adequate for the requirement, in the context that the spacecraft remains in the small-angle regime:

```turtle
@prefix rtm:   <https://flexo-rtm.org/ontology#> .
@prefix gsn:   <https://w3id.org/OntoGSN/ontology#> .
@prefix adcs:  <https://example.org/adcs#> .

adcs:adequacy-2026-05-16-a3f1 a rtm:AdequacyAttestation ;
    gsn:supports          adcs:req-pointing-accuracy ;
    gsn:byJustification   adcs:rationale-linearization ;
    gsn:inContextOf       adcs:context-small-angle .

adcs:rationale-linearization a rtm:Justification ;
    gsn:statement "Linearized rigid-body dynamics are adequate because operational pointing offsets remain below 5 degrees, where the small-angle approximation introduces error below the 0.1% threshold required for pointing-accuracy verification." .

adcs:context-small-angle a gsn:Context ;
    gsn:statement "Spacecraft pointing offsets remain within ±5 degrees during the imaging mission phase." .
```

The triple `gsn:supports adcs:req-pointing-accuracy` is the load-bearing link: a downstream assurance-case tool walking the GSN graph reaches the requirement directly. The justification carries the *reason* the engineer accepted model adequacy; the context carries the *envelope* within which that reason holds.

## Worked example — sufficiency attestation

Same structure, different class. The engineer attests that the body of evidence (proof artifact + simulation result) is sufficient for the same requirement:

```turtle
adcs:sufficiency-2026-05-16-b7c2 a rtm:SufficiencyAttestation ;
    gsn:supports          adcs:req-pointing-accuracy ;
    gsn:byJustification   adcs:rationale-evidence-coverage ;
    gsn:inContextOf       adcs:context-evidence-set .

adcs:rationale-evidence-coverage a rtm:Justification ;
    gsn:statement "The symbolic proof bounds steady-state pointing error analytically; the numerical simulation confirms the bound under the operational disturbance profile. Together these cover the requirement's verification objective with no remaining open analytic gap." .

adcs:context-evidence-set a gsn:Context ;
    gsn:statement "Evidence set: proof artifact rtm:proof-stab-2026-05-10 and simulation result rtm:sim-pointing-2026-05-12." .
```

The two attestation types compose: the SHACL closure rule in [[Attestation Infrastructure in v0.1]] requires both an `rtm:AdequacyAttestation` *and* an `rtm:SufficiencyAttestation` for a requirement before the certification predicate ([[Certification Predicate]]) can fire.

## Why subclass rather than reuse `gsn:Solution` directly

Three reasons:

1. **`rtm:` prefix discipline.** All `flexo-rtm`-specific classes live in `rtm:`. An adopter scanning for `?x a rtm:?` sees the full surface of attestation events; bare `gsn:Solution` instances would be invisible to that query and mix with imported assurance-case data.
2. **Constraint scope.** SHACL shapes constraining adequacy attestations (e.g., "must reference adequacy guidance" — see [[Vertices Edges Faces]]) need a class to target. Constraining `gsn:Solution` directly would also bind unrelated solution nodes a downstream user might import.
3. **Future evolution.** When the closed-triangle audit and V−F invariant ([[Topological Framework Future Work]]) land, they will hang properties off `rtm:AdequacyAttestation` and `rtm:SufficiencyAttestation` that have no general meaning for `gsn:Solution`. Subclassing keeps that path open without polluting the upstream vocabulary.

The cost is one extra class declaration per attestation flavour. The benefit is a clean namespace boundary and an evolution slot.

## Interop with assurance-case tooling

Tools that read GSN — **AdvoCATE** (NASA Ames), **Astah System Safety** (Change Vision), **ACME** (Adelard), and the various academic GSN readers — recognise nodes by their `rdf:type` chain. Because every `rtm:AdequacyAttestation` is also a `gsn:Solution`, those tools see `flexo-rtm` attestations as leaf evidence nodes and can splice them under any larger assurance-case argument the adopter authors externally. No translation, no export shim.

`flexo-rtm` itself **does not author full assurance cases** — there is no `rtm:` machinery for top-level goals, strategies decomposing a system-safety claim, or argument patterns. That is out of scope ([[Mission and Thesis]]). The integration goes one way: `flexo-rtm` produces GSN-compatible leaves; downstream tooling assembles the argument. This keeps `flexo-rtm` parsimonious while preserving the interop story that justified picking GSN in the first place.

## Comparison to the lean alternative

A flatter design would declare `rtm:AdequacyAttestation` and `rtm:SufficiencyAttestation` as standalone classes with no GSN parent, and define `rtm:supports`, `rtm:byJustification`, `rtm:inContextOf` as `rtm:`-namespaced properties. That shaves ~6 imported terms from `rtm.ttl` — a real parsimony win — but loses the **interop dividend**. Engineers reading a `flexo-rtm` graph who know GSN immediately recognise the pattern, and any tool in the GSN ecosystem reads the graph without configuration. Inventing `rtm:supports` forces everyone to learn a local vocabulary that names exactly the thing GSN already names. The decision: **GSN as substrate, subclass for namespace discipline, extraction held to ~6+5 terms.** The ADCS prototype's `rtm-edit.ttl` already follows this pattern (multi-typing `rtm:Attestation` as `gsn:Strategy`, `rtm:Evidence` as `gsn:Solution`); v0.1 generalises and locks it as ADR-015.

## See also

- [[Aspect Coverage with Adequacy and Sufficiency]] — the epistemic split (Hawkins–Habli ACP categorization) this encoding serves
- [[PROV EARL GSN P-PLAN]] — the four-vocabulary substrate and parsimony budget
- [[Vertices Edges Faces]] — guidance / criteria vocabulary that adequacy and sufficiency attestations point into
- [[Parsimony Policy]] — the ≤ 2k-triple ceiling and the extraction discipline
- [[Attestation Infrastructure in v0.1]] — SHACL closure rules that require paired adequacy + sufficiency
- [[Design Spec]] §6.3 — the headline GSN-adoption decision
