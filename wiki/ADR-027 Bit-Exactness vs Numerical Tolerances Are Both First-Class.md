<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-027: Bit-Exactness vs Numerical Tolerances Are Both First-Class

**Status:** Accepted
**Date:** 2026-05-17
**Deciders:** Michael Zargham
**Related:** [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]]; [[ADR-015 GSN Adoption for Adequacy and Sufficiency]]; [[ADR-021 Three Attestation Subclasses Ship in v0.1]]; [[ADR-025 Reproducibility is Structural and Local]]; [[Verifiable Self-Certification]]; [[Aspect Coverage with Adequacy and Sufficiency]]; [[Transcript Replay Semantics]]; [[Design Spec]]

## Context

The v0.1 design speaks consistently about **deterministic, byte-exact reproduction** — same canonical input, byte-identical hash, every time. That language is correct for the **RDF-internal** layer: RDFC-1.0 canonicalization, SPARQL solution-set ordering, and SHACL evaluation are deliberately constructed to produce byte-identical canonical bytes across runs, libraries, and platforms (acceptance criteria X1+X2 in [[Design Spec]] §9.A.5). Bit-exactness here is mandatory and mechanically enforced — the transcript's `inputs_hash → result_hash` chain replays cleanly or it does not.

The same language is **incorrect** if read as a universal commitment for **delegated, numerical computation**. A Monte Carlo simulation, a finite-element analysis, a regression fit, a numerical ODE/PDE solver, or a symbolic proof with a numerical fallback step typically cannot be reproduced bit-for-bit across runs and platforms: floating-point operations are non-associative, BLAS/LAPACK kernels select different code paths depending on CPU features, parallel reductions reorder additions, and library minor-version changes alter rounding in edge cases. Demanding bit-exact reproduction for these activities is physically unrealistic; demanding nothing leaves the regime opaque to audit. The principle the wiki uses for adequacy and sufficiency criteria ([[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]], [[Aspect Coverage with Adequacy and Sufficiency]]) is exactly the right one for this gap: the **tolerance** that defines acceptable reproduction is a property of the **kind of evidence**, captured in the sufficiency criteria for that evidence type, with the adequacy criteria specifying what the tolerance means. This ADR makes the two regimes — bit-exact for RDF-internal, tolerance-aware for delegated numerical — both first-class in the certification artifact. See [[Design Spec]] §4.3 (the three attestation subclasses) and §9.A.5 X1.

## Decision

`flexo-rtm` v0.1 carries **two reproducibility regimes**, both first-class:

1. **RDF-internal computation is bit-exact and mandatory.** RDFC-1.0 + canonical SPARQL solution ordering + SHACL evaluation produces byte-identical canonical bytes for the same canonical input across runs, libraries, and platforms. The `inputs_hash → result_hash` chain in [[Transcript Replay Semantics]] enforces this. This is the X1+X2 acceptance gate; replay either matches or names the divergence step.
2. **Delegated / numerical computation is tolerance-aware, evidence-type-defined.** When the activity that produces an artifact is numerical (Monte Carlo, FEA, time-series simulation, regression fit, ODE/PDE solve, symbolic proof with numerical fallback), bit-identical reproduction across runs is often physically impossible. The **tolerance** that defines acceptable reproduction is part of the **sufficiency criteria** for that kind of evidence (e.g., "Monte Carlo with N ≥ 10⁵ trials, sample-mean within ±0.5% of the recorded value"). The **adequacy criteria** specify what the tolerance must mean (e.g., "rigid-body assumption is adequate if numerical residual < 1e-6"). Both criteria are first-class RDF (per [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]] and [[GSN Integration]]); tolerance values live in the criteria data, not in code.

**Bit-exactness is the default.** Tolerance is an explicit, evidence-type-specific opt-in declared in the sufficiency criteria for a specific kind of evidence. A claim without an explicit tolerance is verified bit-exact.

## Consequences

### Positive

- The certification artifact stays honest about what it can promise: bit-exact where it can, tolerance-bounded where physics or numerics make bit-exactness impossible
- Numerical evidence — the bulk of real engineering analysis — becomes auditable through the same `rtm:Attestation` / sufficiency-criteria / adequacy-criteria machinery the wiki already uses, with no new vocabulary
- The audit pipeline gets a clean dispatch: every TranscriptStep that operates on RDF replays bit-exact; every TranscriptStep that records a delegated numerical computation replays against the sufficiency criteria's recorded tolerance
- Adopters running numerical workflows (FEA, simulation, statistical model fitting) can certify those workflows under v0.1 without inventing a parallel tolerance vocabulary outside the cert artifact
- Aligns with the cross-cutting **structural and local** reproducibility property ([[ADR-025 Reproducibility is Structural and Local]]): each numerical fact carries its own tolerance, locally, in its sufficiency criteria

### Negative / Tradeoffs

- Tolerance criteria add expressive surface to the sufficiency-criteria vocabulary; mitigated by the criteria already being typed RDF instances with `rtm:appliesToAspect` and external-reference predicates ([[Aspect Coverage with Adequacy and Sufficiency]]) — tolerances are additional fields, not a new sub-system
- A reviewer attesting sufficiency for a numerical claim now must explicitly think about the tolerance; this is a feature, not a bug, but it does require operational-layer prompts to surface the question
- Audit-time verification requires the verifier to fetch the activity outputs (per [[External URI References]] **U2**) and run the tolerance check, which costs slightly more than a bit-exact hash compare; mitigated by the check still being mechanically definable and reproducible

### Neutral

- The decision composes with [[ADR-015 GSN Adoption for Adequacy and Sufficiency]]: tolerance values appear as part of the `gsn:byJustification` or `gsn:inContextOf` payload on a sufficiency attestation; the GSN binding is unchanged
- Forward-compatible with downstream-analysis paths (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]): tolerance-typed sufficiency attestations are readable by any downstream analysis adopters may choose (topological, SLSA, GSN, ARP4754A, in-house); no rework required if any of those research lines mature

## Alternatives Considered

- **Require bit-exact reproduction for every step including delegated numerical:** Rejected. Floating-point non-associativity, BLAS code-path divergence on different CPU microarchitectures, parallel reductions, and library minor-version differences make bit-identical reproduction physically impossible for many numerical evidence types. Forcing the claim would invalidate certifications for the bulk of real engineering analysis or force adopters into byte-identical-VM pinning that does not scale.
- **Ignore numerical reproducibility entirely (treat numerical activities as opaque black boxes):** Rejected. That posture would leave numerical evidence — the dominant evidence type in safety- and performance-critical engineering — opaque to audit, defeating the verifiable-self-certification thesis ([[Verifiable Self-Certification]]). A verifier seeing only "the engineer ran a simulation; here's the output hash" gets no machine-checkable handle on whether the output is the right kind of output.
- **Carry tolerance globally as a single config knob (e.g., `flexo-rtm.tolerance = 1e-6`):** Rejected. Tolerance is **evidence-type-specific**: a Monte Carlo sample-mean tolerance is structurally different from an FEA residual threshold from a time-series RMSE bound from a sufficient-trial-count threshold. A single global setting either over-constrains (rejecting tolerable claims) or under-constrains (accepting claims that should fail) for any given evidence type. Per-evidence-type tolerances in the sufficiency criteria are the only honest framing.
- **Define a new `rtm:NumericalAttestation` subclass parallel to the three existing subclasses:** Rejected. The three subclasses ([[ADR-021 Three Attestation Subclasses Ship in v0.1]]) are oriented around the **judgment kind** (satisfaction / adequacy / sufficiency), not the evidence type. Tolerance lives correctly in the sufficiency criteria, not in a parallel attestation subclass — a numerical Monte-Carlo result still gets the same trio of satisfaction / adequacy / sufficiency attestations; the sufficiency one happens to carry a tolerance.

## Implementation Notes

- TranscriptStep `rtm:stepKind` values gain `"delegated-numerical"` alongside the existing `sparql`, `shacl`, `canonicalize`, `kc-operation` (see [[Transcript Replay Semantics]]). A `delegated-numerical` step records the activity's recorded numerical result alongside its sufficiency-criteria IRI; replay fetches the activity output (per [[External URI References]]) and checks the recorded result is within the criteria's tolerance of the recorded expected outcome
- The sufficiency-criteria vocabulary (already shipped per [[Aspect Coverage with Adequacy and Sufficiency]]) gains tolerance-bearing predicates: a sufficiency criterion for "Monte Carlo" carries `rtm:hasNumericalTolerance` (or analogous) with the relative or absolute bound; the criteria are RDF instances in `ontology/rubrics/` and external standards alignments
- The adequacy criteria for a numerical evidence type specify what the tolerance means — for example, "the rigid-body assumption is adequate if the recorded numerical residual is < 1e-6 in the slew-rate regime"
- Bit-exact remains the default for every step kind not explicitly declared `delegated-numerical`. A claim made without explicit tolerance declarations is verified bit-exact; tolerance is opt-in per evidence type
- Gap codes: a delegated-numerical step missing its tolerance criteria is reportable as a sufficiency-criteria gap, consistent with the existing T-series enumeration ([[Gap Taxonomy]])
- The audit pipeline dispatches: RDF-internal steps go through the bit-exact replay loop in [[Transcript Replay Semantics]] §3; delegated-numerical steps go through a tolerance-conformance check against the sufficiency criteria's recorded tolerance

## References

- [[Design Spec]] §4.3 (three attestation subclasses), §9.A.5 X1 (Determinism), §4.9 (Reproducibility chain)
- [[Verifiable Self-Certification]] — new "Two regimes of reproducibility" section governed by this ADR
- [[Aspect Coverage with Adequacy and Sufficiency]] — adequacy/sufficiency criteria vocabulary tolerance fields ride on
- [[Transcript Replay Semantics]] — `delegated-numerical` step kind and its replay path
- [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]] — guidance subtype framing the criteria use
- [[ADR-015 GSN Adoption for Adequacy and Sufficiency]] — GSN binding tolerances inherit
- [[ADR-021 Three Attestation Subclasses Ship in v0.1]] — judgment-kind subclasses unchanged
- [[ADR-025 Reproducibility is Structural and Local]] — locality principle the per-evidence tolerance honours
- Closes flexo-rtm-research issue #2 (Clarification on Bit-exactness requirements)
