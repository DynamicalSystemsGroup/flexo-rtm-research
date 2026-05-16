<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Attestation Infrastructure in v0.1

> The named-approver attestation discipline that ships in v0.1 — three typed attestation subclasses (`rtm:SatisfactionAttestation`, `rtm:AdequacyAttestation`, `rtm:SufficiencyAttestation`), each a `rdfs:subClassOf rtm:Attestation`, each governed by a single SHACL shape that rejects any attestation lacking a named human approver IRI. This is the accountability mechanism that is "by construction" rather than "by policy." It is independent of the deferred topological framework and ships in v0.1 because the [[ADCS Prototype Lessons]] regression corpus already depends on adequacy and sufficiency attestations today. Normative source: [[Design Spec]] §4.3. Acceptance criteria: §9.A.3 **I1** (schema-enforced approver) and §9.A.3 **I7** (git approver binding under `signed-commits` profile).

## Purpose and scope

`flexo-rtm` v0.1 ships three kinds of attestation as first-class typed RDF assertions. Each is an independent claim by a named human about a single subject, and each is rejected at write time if no approver is named. The discipline is narrower than the full topological audit Zargham (2026) describes — there is no closed-triangle gate, no recursive completeness check on guidance, and no V−F invariant computation. Those are deferred. **The typed attestations are well-defined as individual assertions; aggregating them into closed assurance faces is what waits.**

This page specifies what v0.1 ships, the SHACL shape that makes the discipline structural, the composable profiles, and the boundary against the deferred framework. Normative source: [[Design Spec]] §4.3. Gap codes: [[Gap Taxonomy]] (§4.7). Git side: [[Approver Binding via Git]]. Accountability motivation: [[Human-AI Accountability]].

## Why this ships in v0.1 (and not in the deferred framework)

Two arguments converge.

**Regression need.** The [[ADCS Prototype Lessons]] corpus — the ground-truth dataset against which `flexo-rtm` regressions run — already records adequacy and sufficiency attestations as `rtm:Attestation` instances with `earl:result` outcomes and `prov:` provenance. v0.1 has to read and round-trip those graphs without semantic loss; the three subclasses with a named-approver SHACL shape are the minimum satisfying the regression contract.

**Independent value.** Named-approver accountability is independently useful before any topological aggregation. A claim that "this artifact satisfies this requirement" is well-typed regardless of whether the surrounding triangle has closed. The adopter who turns on `attested-satisfies` today gets the "by construction" property — they cannot persist an unsigned attestation — without waiting for the registry-dependent recursive audit. Structural accountability is achieved by making the schema reject the unaccountable case, not by trusting reviewers to enforce a recommendation.

## The three attestation subclasses

All three are `rdfs:subClassOf rtm:Attestation` and share the parent's properties. They differ in what they take as subject and what they assert.

| Class | Subject | Asserts |
|---|---|---|
| `rtm:SatisfactionAttestation` | an `rtm:satisfies` triple (artifact → requirement) | "this artifact satisfies this requirement" — named human approves |
| `rtm:AdequacyAttestation` | an artifact + requirement pair (typically tied to coupling via `rtm:AdequacyCriteria` guidance) | "the model representation is adequate for the kind of claim made about this requirement" — named human approves |
| `rtm:SufficiencyAttestation` | an artifact + requirement pair (typically tied to coupling via `rtm:SufficiencyCriteria` guidance) | "the evidence is sufficient to support the claim about this requirement" — named human approves |

A satisfaction attestation answers "did this artifact meet this requirement?" An adequacy attestation answers "is the model we used adequate for the kind of claim being made?" A sufficiency attestation answers "is the evidence enough to support the claim?" The three are separable judgments, potentially made by different approvers under different aspects, each an independent named-approver assertion. The prototype flow at `ADCS-lifecycle-demo/traceability/attestation.py` already follows this triple split — the CLI presents evidence, the engineer makes adequacy and sufficiency judgments, and the records are written with `earl:result` outcomes and `prov:` provenance.

### Parent class `rtm:Attestation` — shared properties

All three subclasses inherit:

- `rtm:approvedBy` (IRI) — **REQUIRED**; points to a `foaf:Person` or `org:Membership`. This is the SHACL-enforced field.
- `rtm:attests` — points to the asserted triple (via RDF-star) or to the reified (artifact, requirement) pair.
- `earl:result` — one of `earl:passed`, `earl:failed`, `earl:cantTell`, `earl:inapplicable`.
- `rtm:hasAspect` (optional) — aspect tag for per-aspect attestation; used by the `aspect-coverage` profile.
- `prov:wasGeneratedBy`, `prov:atTime`, `prov:wasAssociatedWith` — full PROV provenance.

The `earl:result` channel is what makes a "failed" attestation expressible without losing the named-approver discipline: a `T6.failed-attestation` (see [[Gap Taxonomy]]) is a *recorded* judgment, not a missing one. The attestation exists, has an approver, and asserts `earl:failed`. That is structurally different from $T3$/$T4$/$T5$ which surface as "no attestation present at all (for this claim type, under the active profile)."

## Schema-enforced named-approver requirement (§9.A.3 **I1**)

The single SHACL shape that gives this discipline its structural character:

```turtle
rtm:AttestationShape a sh:NodeShape ;
    sh:targetClass rtm:Attestation ;  # applies to parent and all subclasses
    sh:property [
        sh:path rtm:approvedBy ;
        sh:minCount 1 ;
        sh:nodeKind sh:IRI ;
        sh:message "Every attestation requires a named human approver IRI"
    ] .
```

Because `sh:targetClass rtm:Attestation` matches the parent, RDFS subclass entailment ensures the shape also targets all three subclasses. SHACL rejects any attestation instance of any kind that lacks an approver IRI at write time. This is what [[Design Spec]] §9.A.3 **I1** specifies as the acceptance criterion: every `rtm:Attestation` instance MUST have `rtm:approvedBy <IRI>` with `sh:minCount 1` and `sh:nodeKind sh:IRI`; writes without this fail at the SHACL gate. The test is `tests/conformance/test_attestation_shape.py`. Gap code $T7.unapproved-attestation$ is listed in [[Gap Taxonomy]] as **cannot exist** — the schema does not admit such triples.

This is the "by construction" mechanism. The conventional approach asks reviewers to enter their name into a field; `flexo-rtm`'s approach makes the absence of that name a write-time validation failure. The two look similar in policy text; they differ enormously in the data that ends up in the graph.

## Composable optional profiles

The named-approver shape is on by default and unconditional. Four additional profiles are off by default and composable — adopters opt in as their workflow matures:

- **`attested-satisfies`** — every `rtm:satisfies` triple in the graph requires a corresponding `rtm:SatisfactionAttestation` whose subject is that triple. When this profile is off, satisfaction triples can exist without attestations; gap code $T3.unattested-satisfaction$ only surfaces when the profile is on.
- **`attested-adequacy`** — every `rtm:satisfies` triple requires a corresponding `rtm:AdequacyAttestation` for the artifact. Surfaces gap $T4.unattested-adequacy$.
- **`attested-sufficiency`** — every `rtm:satisfies` triple requires a corresponding `rtm:SufficiencyAttestation` for the artifact. Surfaces gap $T5.unattested-sufficiency$.
- **`aspect-coverage`** — for multi-aspect requirements, each declared aspect requires its own attestation per claim type. Surfaces gap $T8.aspect-uncovered$.

An adopter typically starts with just the unconditional named-approver shape, then enables `attested-satisfies`, then layers `attested-adequacy` and `attested-sufficiency` as practice matures, and finally `aspect-coverage` for programs with multi-aspect requirements (safety, security, performance, dependability). Composability is the point: the discipline scales to the rigor the program is ready for, and audit reports show exactly where the gaps are at each stage. See [[Aspect Coverage with Adequacy and Sufficiency]] for the per-aspect rollup and [[Quantitative Outcomes]] for reporting.

## Per-aspect attestation

A multi-aspect requirement (one that declares aspects like `rtm:safety`, `rtm:security`, `rtm:performance`) can have its claims attested per-aspect: an attestation carries `rtm:hasAspect <aspect-iri>` to mark which aspect it covers. When `aspect-coverage` is on, the audit checks that each declared aspect has the required attestations per claim type. This composes with `attested-adequacy` and `attested-sufficiency` — a safety-aspect requirement may need adequacy and sufficiency attestations *for the safety aspect* in addition to (or in lieu of) program-wide ones. The per-aspect rollup is described in [[Aspect Coverage with Adequacy and Sufficiency]].

## Git binding chain (§9.A.3 **I7**)

The named-approver IRI is enforced at the SHACL gate; the binding between that IRI and a real human action is enforced at the git layer. The full chain is documented in [[Approver Binding via Git]]. The relevant guarantee here is §9.A.3 **I7**: when the `signed-commits` profile is active, any git commit that introduces an attestation triple MUST be GPG- or SSH-signed by a key whose fingerprint matches the `rtm:approvedBy` IRI's published key. A pre-commit hook and a GitHub Actions check both verify this, applied uniformly to all three subclasses. The test is `tests/integration/git/test_approver_binding.py`. Together, **I1** (SHACL-enforced approver IRI) and **I7** (cryptographic binding from IRI to commit signer) compose into the end-to-end guarantee: an attestation exists in the graph only if a named approver signed for it, and a signed commit introducing one only verifies if the signer matches the named approver.

## Why per-claim attestations are not deferred (the boundary)

An attestation is an independent assertion by a named human about a single claim. Its semantics do not depend on whether the surrounding assurance triangle is closed, whether the guidance it implicitly invokes has itself been attested, or whether the V−F invariant balances. Those are properties of an *aggregation* of attestations, not of any individual one. Adequacy and sufficiency, as individual judgments, are well-defined; the [[ADCS Prototype Lessons]] corpus demonstrates them in operation. What is deferred is the *aggregation step* — building closed assurance faces, auditing that every coupling has guidance, checking that guidance is recursively assured. Those steps require the guidance registry (deferred), the closed-triangle gate (deferred), and the recursive completeness audit (deferred).

The corollary is forward compatibility. The triples written under v0.1 carry exactly the fields the future framework needs: named approver, typed subject, aspect tag, EARL result, PROV provenance. When the topological framework lands, aggregation builds on top of this data without retro-fitting. Adopters running v0.1 today are accumulating compliant evidence for the future audit.

## What v0.1 does NOT do

The boundary against the future framework, stated plainly:

- **Does not enforce closed assurance triangles.** The 2-simplex closure (verification + validation + spec/guidance coupling all present) is the topological gate Zargham (2026) describes; v0.1 does not check it.
- **Does not check "is this guidance itself fit-for-purpose?"** That is the recursive completeness check on the guidance dimension. It requires the registry of guidance documents and an audit pass over the guidance graph. Deferred.
- **Does not run recursive completeness audits.** Reaching guidance-of-guidance-of-guidance until a self-attesting base case is found is part of the topological audit, not part of v0.1.
- **Does not compute V−F invariants.** The Euler-style invariant the framework uses to detect coverage gaps is a property of the closed complex; v0.1 has no such complex.
- **Does not verify aspect coverage as a closure property.** The `aspect-coverage` profile checks declared aspects, not topologically derived ones.

All of these live in the future topological framework; see [[Topological Framework Future Work]] for the deferred-features roadmap.

## Coverage and audit reporting

v0.1 audit reports include, per [[Quantitative Outcomes]] and [[Gap Taxonomy]]:

- Coverage statistics per attestation subclass — satisfaction %, adequacy %, sufficiency %.
- Per-aspect breakdown when multi-aspect requirements are present.
- Gap-code enumeration: $T3.unattested-satisfaction$, $T4.unattested-adequacy$, $T5.unattested-sufficiency$, $T6.failed-attestation$, $T8.aspect-uncovered$. ($T7.unapproved-attestation$ is structurally absent.)
- A reproducibility manifest enumerating every external URI (approver identity provider, signed-commit reference, evidence URI) the cert depends on.

Audit failure is decoupled from gap presence — a report can succeed at the predicate level while still listing gaps in $T3$–$T8$, depending on which profiles are active and what the certification predicate requires.

## Relationship to traditional V&V analysis

The three subclasses map cleanly to the forward/backward primitives in [[Traditional Forward and Backward Analysis]]. Forward analysis (requirement → artifact) corresponds to satisfaction attestation; backward analysis ("is the model adequate / is the evidence sufficient?") corresponds to adequacy and sufficiency attestations. The novelty in v0.1 is not the analysis taxonomy — it is schema enforcement of named approvers on the resulting assertions.

## Cross-references

- [[Design Spec]] §4.3 — normative source for the three subclasses and the SHACL shape; §4.7 — gap taxonomy ($T3$, $T4$, $T5$, $T6$, $T7$, $T8$); §9.A.3 — acceptance criteria **I1** and **I7**.
- [[Approver Binding via Git]] — the git-side of the binding chain that satisfies **I7**.
- [[Traditional Forward and Backward Analysis]] — V&V analysis primitives mapped onto the three subclasses.
- [[Aspect Coverage with Adequacy and Sufficiency]] — per-aspect attestation rollup and the `aspect-coverage` profile.
- [[Gap Taxonomy]] — full enumeration of T-codes the audit surfaces.
- [[Quantitative Outcomes]] — how coverage % and gap counts appear in audit reports.
- [[Topological Framework Future Work]] — the deferred aggregation and closure features.
- [[Human-AI Accountability]] — why named-approver accountability matters in the LLM-assisted authoring era.
- [[ADCS Prototype Lessons]] — the regression corpus that exercises the three subclasses today.
