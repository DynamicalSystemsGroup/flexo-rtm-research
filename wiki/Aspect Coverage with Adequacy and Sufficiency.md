<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Aspect Coverage with Adequacy and Sufficiency

> The per-aspect rollup of typed attestations that ships in v0.1. Two orthogonal axes — **aspect** (functional, performance, safety, security, …) and **judgment kind** (satisfaction, adequacy, sufficiency) — form a coverage matrix that audit reports surface directly. The `aspect-coverage` profile turns the matrix into an enforced obligation via gap code `T8.aspect-uncovered`. **Status: ships in v0.1.** The [[ADCS Prototype Lessons]] regression corpus already records adequacy and sufficiency attestations with aspect tags via `ADCS-lifecycle-demo/traceability/attestation.py`; v0.1 must preserve that vocabulary to pass regression. Normative source: [[Design Spec]] §4.3 (three attestation subclasses). Gap code: [[Design Spec]] §4.7 **T8**. Acceptance criteria: §9.A.3 **I1** (schema-enforced approver) and §9.A.5 **X3** (per-dimension quantitative outcomes — never a single rolled-up %).

## Two orthogonal axes

The vocabulary that makes per-aspect attestation expressible cleanly separates two questions a reviewer asks. Confusing them is the failure mode the typing prevents.

**Axis 1 — Aspect.** What *concern* of the requirement is being attested? A real safety-critical requirement carries multiple aspects simultaneously: a slew-maneuver controller satisfies a functional behaviour, a performance envelope, *and* a safety constraint, with possibly distinct security and dependability concerns layered on. Aspects are first-class instances of `rtm:Aspect` (abstract), with `rtm:functional`, `rtm:performance`, `rtm:safety`, `rtm:security`, `rtm:dependability` shipped as initial members. The taxonomy is extensible — programs add `rtm:cybersecurity`, `rtm:radiation-tolerance`, `rtm:thermal`, whatever the domain requires.

**Axis 2 — Judgment kind.** What *kind of claim* is being made? Three typed subclasses of `rtm:Attestation` (per [[Design Spec]] §4.3):

| Class | Asserts | Example |
|---|---|---|
| `rtm:SatisfactionAttestation` | "this artifact satisfies this requirement" | "The simulation output meets the slew-rate envelope." |
| `rtm:AdequacyAttestation` | "the model representation is adequate for this claim" | "Is the rigid-body assumption adequate for this slew-maneuver analysis?" |
| `rtm:SufficiencyAttestation` | "the evidence is sufficient to support this claim" | "Is one Monte Carlo run sufficient for a 6σ claim?" |

The two axes are independent. A safety-aspect claim can have adequacy attested but sufficiency open; a performance-aspect claim can have satisfaction attested but adequacy open under a new model. v0.1 collects each cell of (aspect × judgment kind) as a separate, named-approver-bearing assertion.

## Why three judgment kinds, not one

A satisfaction attestation says nothing about whether the underlying model is a fair representation of the system, nor whether the evidence run is statistically adequate. Collapsing all three into a single "approved" stamp loses the information a reviewer needs to take responsibility for one judgment without implicitly endorsing the others. The split is the Hawkins–Habli Assurance Claim Point pattern (`gsn:Assumption` for adequacy; `gsn:Justification` for sufficiency) instantiated against requirements — see [[GSN Integration]]. Adequacy and sufficiency are *backward-analysis* judgments ("given the claim, is the model/evidence fit?"); satisfaction is the *forward-analysis* judgment ("does this artifact meet this requirement?"). The mapping is in [[Traditional Forward and Backward Analysis]].

## Aspect tagging on the wire

Both requirements and attestations carry the aspect predicate. A multi-aspect requirement declares its aspects up front:

```turtle
:req-slew-maneuver a rtm:Requirement ;
    rtm:hasAspect rtm:functional, rtm:performance, rtm:safety .
```

Each attestation that claims to attest *for* a particular aspect tags itself accordingly:

```turtle
:att-slew-safety-adequacy a rtm:AdequacyAttestation ;
    rtm:attests :req-slew-maneuver ;
    rtm:hasAspect rtm:safety ;
    rtm:approvedBy <https://example.org/approver/jdoe> ;
    earl:result earl:passed ;
    gsn:byJustification "Rigid-body model is adequate under the slew-rate regime; flexible modes are bounded by the safety envelope and do not change the conclusion." ;
    gsn:inContextOf :ctx-rigid-body-assumption .
```

Per [[Attestation Infrastructure in v0.1]], every attestation regardless of aspect tag is rejected at write time if `rtm:approvedBy` is absent — the SHACL shape from [[Design Spec]] §9.A.3 **I1** binds on the parent class and propagates to all three subclasses. The aspect tag is an additional discriminator, not a replacement for the named-approver discipline.

## Coverage as a matrix view

The audit report's primary view for aspect coverage is a two-dimensional table — aspect on the rows, judgment kind on the columns, coverage percentage in the cells:

```
                  Satisfaction  Adequacy  Sufficiency
    Functional       100%         85%        90%
    Performance      100%         70%       100%
    Safety           100%        100%        60%
    Security          75%         80%        80%
```

Each row is the per-aspect rollup across all requirements declaring that aspect; each column is the per-judgment-kind rollup across all aspects. Each cell answers: "of the requirements declaring this aspect, what fraction have an attestation of this judgment kind tagged to this aspect?" Per [[Design Spec]] §9.A.5 **X3**, no audit report rolls these cells into a single "% certified" number — quantitative outcomes are always reported per-dimension (forward, backward, per-claim-type, per-aspect). The matrix view is the canonical surface; [[Quantitative Outcomes]] details the report shape.

A cell at 60% does not fail the audit by itself. PASS/FAIL is decoupled from gap presence per §4.7 — a cert can pass at the certification-predicate level while still listing gaps in $T3$–$T8$ that future iterations should close. The matrix tells the reviewer *where* attestation effort is concentrated and where it is thin.

## Where adequacy and sufficiency criteria come from

A reviewer cannot attest adequacy or sufficiency without knowing what the bar is in this domain. v0.1 admits four sources, all captured as `rtm:AdequacyCriteria` / `rtm:SufficiencyCriteria` ontology instances:

1. **Project-specific rubrics** — an organization authors its own criteria in `ontology/rubrics/<program>.ttl`.
2. **INCOSE-derived** — acceptance criteria extracted from the INCOSE Handbook (see [[INCOSE V2 Review]]); a starter set.
3. **Domain-specific** — aerospace, automotive, medical. `rtm:appliesToAspect` scopes a rubric to a particular aspect.
4. **External standards alignment** — `rtm:hasExternalReference` binds a criterion to a standards clause; the reproducibility manifest (per [[Design Spec]] §9.A.4 **U5**) enumerates these.

Criteria are referenceable from `gsn:byJustification` rationale on the attestation: "I attest adequacy *per criteria* `:rubric-slew-rigid-body-v2`." This is the named-criterion handle the reviewer takes responsibility against. v0.1 does **not** audit whether the criteria are themselves fit-for-purpose — that recursive completeness check is deferred (see below).

## Judgment surfacing in the operational layer

The matrix is populated by the operational layer prompting an attesting engineer when new evidence arrives. The skill asks per (artifact, requirement, aspect, judgment-kind) tuple — three prompts per relevant aspect — with three responses available for each:

- **Attest yes** — creates the corresponding typed attestation, tagged with `rtm:hasAspect`, signed by the operator's IRI, `earl:result earl:passed`, rationale bound as `gsn:byJustification`.
- **Refine** — returns the workflow to edit mode (evidence, model, or requirement is modified before re-presenting). No attestation triple yet.
- **Defer** — emits an `rtm:DeferredJudgment` (`earl:result earl:cantTell`); still a named-approver assertion, still bearing aspect and judgment-kind tags. Deferral is itself a recorded act: the graph never silently lacks the judgment.

Prompts are aspect-scoped: "Is the rigid-body model adequate for this slew-maneuver claim *for the safety aspect*?" The reviewer answers per aspect; the operational layer does not collapse multi-aspect judgments. Where one reviewer holds authority over only some aspects (a safety engineer with `rtm:permitsAspect rtm:safety` per [[Identity Boundaries and Policy Projections]]), the workflow surfaces only those prompts and routes the rest.

## The ADCS prototype's existing pattern

`ADCS-lifecycle-demo/traceability/attestation.py` already implements the adequacy/sufficiency split with named-approver provenance. The prototype's CLI flow presents evidence for a requirement, asks the engineer for model adequacy (declining yields `earl:failed`), then asks for evidence sufficiency (declining yields `earl:cantTell`); triples are written with `gsn:Assumption` carrying the adequacy statement, `gsn:Justification` carrying the sufficiency statement, `prov:qualifiedAssociation` recording the engineer and role, and (in a git workspace) the head commit SHA bound via `rtm:gitCommit`. Writes go to the `<adcs:attestations>` named graph. v0.1 reads and round-trips this graph without semantic loss — the three subclasses (with `rtm:hasAspect`) are the minimum vocabulary needed to type the prototype's existing assertions explicitly. Programs running the prototype today already accumulate the data the v0.1 matrix view surfaces; the rollout is additive. See [[ADCS Prototype Lessons]] for the broader provenance contract v0.1 preserves.

## GSN integration (per ADR-015)

Per [[GSN Integration]], adequacy and sufficiency attestations align to Goal Structuring Notation as terminal solutions in an assurance argument:

- `rtm:AdequacyAttestation` `rdfs:subClassOf` `gsn:Solution`
- `rtm:SufficiencyAttestation` `rdfs:subClassOf` `gsn:Solution`

Each carries `gsn:byJustification` (the rationale text the approver supplies) and may carry `gsn:inContextOf` to attach assumptions or contextual constraints (e.g., "this adequacy assertion is in the context of the rigid-body assumption holding"). The GSN binding makes the attestations participate in any external GSN-aware tool's assurance graph — they are not bespoke RDF artifacts disconnected from the assurance-case ecosystem. Per ADR-015, the project introduces no novel epistemic vocabulary; it composes established standards.

## The `aspect-coverage` profile

`aspect-coverage` is one of the four composable optional profiles documented in [[Attestation Infrastructure in v0.1]]. When active, SHACL enforces a per-aspect attestation obligation: for every multi-aspect requirement (declaring two or more aspects via `rtm:hasAspect`), each declared aspect MUST have its own attestation per active claim type. The shape composes with `attested-satisfies` / `attested-adequacy` / `attested-sufficiency` — a safety-aspect requirement under `aspect-coverage` + `attested-adequacy` needs an adequacy attestation tagged `rtm:hasAspect rtm:safety` for the artifact making the safety claim.

Missing per-aspect attestations are reported as gap code **T8.aspect-uncovered** per [[Design Spec]] §4.7: "A multi-aspect requirement has satisfaction attestation but is missing attestation for one or more declared aspects." The audit surfaces T8 per (requirement, aspect, judgment-kind) — not as a single rolled-up count, again per §9.A.5 **X3**. See [[Gap Taxonomy]] for the full T-code enumeration; T8 is the per-aspect-aware extension of $T3$–$T5$, surfaced only when `aspect-coverage` is active.

An adopter typically enables `aspect-coverage` after their attestation discipline has matured under the unconditional named-approver shape plus one or more of `attested-satisfies` / `attested-adequacy` / `attested-sufficiency`. The composability scales the rigor to the program's readiness.

## What v0.1 does NOT do for aspect coverage

The boundary against the deferred topological framework is sharper here than elsewhere in v0.1, because adequacy and sufficiency attestations are exactly the inputs the future framework will aggregate. v0.1 collects, types, tags, and audits whether they are present and approved. It does **not**:

- **Check that `rtm:AdequacyCriteria` / `rtm:SufficiencyCriteria` are themselves assured.** The recursive completeness check — "is the guidance fit-for-purpose, given its own coupling to a parent rubric or standards clause?" — is the topological framework's job. v0.1 accepts criteria as ontology individuals; it does not audit their genealogy.
- **Aggregate per-aspect attestations into closed assurance triangles.** The 2-simplex closure (specification + verification + validation coupled with attested guidance) is the future-framework gate. v0.1 reports per-aspect coverage as a matrix; it does not enforce that safety-aspect verification, validation, and coupling-to-guidance are all simultaneously present.
- **Require the guidance to be registry-pre-approved.** The guidance registry — canonical store of fit-for-purpose criteria with their own attestation chains — is deferred.
- **Compute V−F invariants.** The Euler-style invariant the future framework uses to detect aspect-coverage closure gaps is a property of a closed complex; v0.1 has no such complex.

Per [[Design Spec]] §4.2 / D22, the per-claim attestations are first-class v0.1 features; the recursive completeness audit is what's deferred. See [[Topological Framework Future Work]].

## Forward compatibility with the topological framework

The matrix-view audit display, the typed subclasses, and the aspect tags are precisely the named-approver-bearing inputs the future framework will aggregate into closed assurance triangles. Each cell of v0.1's matrix corresponds to a future-framework face — when the topological audit lands, the gate becomes "for each aspect declared on a requirement, the matching (satisfaction, adequacy, sufficiency) triple must close a 2-simplex with the guidance coupling." Per-aspect coverage stats (v0.1) and per-aspect assurance-face closure (future) operate on the same attestation data. Adopters running v0.1 with `aspect-coverage` active accumulate compliant evidence for the future audit without retro-fit.

## Cross-references

- [[Design Spec]] §4.3 — normative source for the three attestation subclasses and SHACL shape; §4.7 **T8** — `aspect-uncovered` gap code; §9.A.3 **I1** — schema-enforced approver IRI; §9.A.5 **X3** — per-dimension quantitative outcomes.
- [[Attestation Infrastructure in v0.1]] — named-approver discipline and composable profiles this page builds on.
- [[Gap Taxonomy]] — full T-code enumeration including T8.
- [[Quantitative Outcomes]] — audit report shape; per-aspect matrix view.
- [[ADCS Prototype Lessons]] — regression corpus exercising adequacy/sufficiency attestations today.
- [[GSN Integration]] — `gsn:Solution` binding for adequacy/sufficiency attestations.
- [[Traditional Forward and Backward Analysis]] — V&V primitives the three judgment kinds correspond to.
- [[Identity Boundaries and Policy Projections]] — `rtm:permitsAspect` scoping for per-aspect approver authority.
- [[Topological Framework Future Work]] — deferred recursive completeness audit over criteria themselves.
- [[Human-AI Accountability]] — why typed, aspect-tagged attestations matter in the LLM-assisted era.
