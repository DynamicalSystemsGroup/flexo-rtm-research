<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Human-AI Accountability

> How `flexo-rtm` integrates LLM-assisted authoring with structurally enforced human accountability. Applies Zargham (2026)'s typed-simplicial-complex framing of "named human approver as a schema constraint" to the v0.1 attestation infrastructure described in [[Design Spec]] §4.3, and grounds the AI's operational role in the judgment-surfacing UX described in [[Operational Layer UX Discipline]].

## Why this matters

LLMs are now routine in how systems engineering artifacts get written. The 2024 DORA report records 76% of developers using AI tools daily; the same machinery — Claude Code, Cursor, Copilot, retrieval-augmented assistants — is increasingly used to draft requirements, populate traceability matrices, generate verification rationale, and synthesize evidence summaries. INCOSE IS 2026 introduced mandatory AI-assistance disclosure requirements because AI-generated content has entered the certification pipeline whether standards bodies sanctioned it or not.

The problem is not that AI is being used. The problem is that **existing institutional frameworks lack mechanisms to integrate AI assistance with accountability for the outputs**. IEEE 1012, ISO/IEC/IEEE 15288, and the INCOSE Systems Engineering Handbook assume the author of a V&V claim is a person; they predate the situation where a credentialed engineer signs off on text an LLM drafted. The standards recommend named human responsibility; they do not enforce it. `flexo-rtm` provides the enforcement mechanism.

## The accountability gap

Zargham (2026), "Formalizing Document Assurance: A Topological Framework for Verification, Validation, and Human Accountability," names the gap precisely. Two observations are load-bearing.

**Verification can be automated; validation cannot.** Verification asks "are we building the product right?" — a structural question: required sections present, types conform, references resolve. A deterministic script answers it. Validation asks "are we building the right product?" — is the model adequate to the kind of claim being made? is the evidence sufficient to support it? Those are qualitative judgments — the kind cognitive systems engineering (Hollnagel & Woods 2005; Boy et al. 2015) identifies as inherently human. Automation should support, not replace, this judgment.

**LLMs cannot bear responsibility.** Zargham: "When AI assists in generating content, who is responsible for judging its fitness? The answer cannot be 'the AI' because language models cannot bear accountability. There must be a named human responsible for review, evaluation, and approval." Accountability presupposes a subject who can be held to account, and an LLM is not that subject. The model vendor is not the engineer who approved the claim; the operator who ran the prompt is not necessarily the credentialed authority for the aspect attested.

**Existing frameworks recommend accountability rather than structurally enforce it.** Floridi & Cowls (2019), UNESCO's 2021 Recommendation on the Ethics of Artificial Intelligence (adopted by all 194 member states), and the UN High-Level Advisory Body on AI's 2024 governance framework all call for "accountability anchored in human responsibility." But these are principles, not schemas. What is missing is a mechanism that **requires** accountability attribution at the level of individual claims, **enforces** human review, and **audits** for gaps — not as a policy norm honored by disciplined teams, but as a precondition for the data existing at all.

## Zargham (2026)'s contribution: structural enforcement

Zargham's framework closes the gap by lifting accountability from a recommendation to a **schema constraint**. In the typed simplicial complex formalism documents are vertices, verification and validation are edges, and an assurance triangle (a 2-simplex) closes when verification, validation, and the coupling between specification and guidance are all present. The validation edge is typed such that **it cannot exist without a named human approver field**. Schema validation rejects an unaccountable claim before it enters the graph.

Ghrist's "The Forge" methodology (Ghrist 2025, *The Geometry of Heaven & Hell*, Appendix C) demonstrates how disciplined practice can achieve AI-assisted scholarly writing with explicit human accountability — "every sentence in this book passed through my judgment; every connection earned my conviction; every claim bears my responsibility." Ghrist's work is procedural; Zargham's contribution is to make accountability **enforceable** rather than aspirational — the schema rejects what the procedure would have refused.

## Translation to `flexo-rtm`

`flexo-rtm` v0.1 carries Zargham's structural move into a working RDF/SHACL stack. The mechanism is the named-approver field on `rtm:Attestation`, gated by SHACL at write time, bound to a signed git commit, and authorized via the thin identity projection. See [[Attestation Infrastructure in v0.1]] for the normative specification.

The core SHACL shape (from [[Design Spec]] §4.3):

```turtle
rtm:AttestationShape a sh:NodeShape ;
    sh:targetClass rtm:Attestation ;
    sh:property [
        sh:path rtm:approvedBy ;
        sh:nodeKind sh:IRI ;
        sh:minCount 1 ;
    ] .
```

`sh:minCount 1` rejects an attestation with no approver. `sh:nodeKind sh:IRI` rejects a string, blank node, or literal where an IRI is required. The shape applies to the parent class and to all three v0.1 subclasses:

- `rtm:SatisfactionAttestation` — "this artifact satisfies this requirement," approved by a named human
- `rtm:AdequacyAttestation` — "the model representation is adequate for the kind of claim being made," approved by a named human (typically a domain authority for the aspect)
- `rtm:SufficiencyAttestation` — "the evidence is sufficient to support the claim," approved by a named human (typically a credentialed authority for the assurance level required)

Three subclasses, one SHACL discipline. An attestation of any kind without an approver IRI is structurally impossible to write. See [[Aspect Coverage with Adequacy and Sufficiency]] for how the three claim types decompose practitioner judgment.

**Git commit binding.** The `rtm:approvedBy` IRI is bound to the act of committing. A pre-commit hook verifies that the committer's identity (resolved from the GPG or SSH signature) matches the `rtm:approvedBy` IRI for any new attestation triple in the diff. GitHub Actions re-checks at PR time, server-side. See [[Approver Binding via Git]]. The effect: "this person, at this time, attested this claim" is verifiable through public-key infrastructure the institution already trusts.

**Identity bottleneck.** The `rtm:approvedBy` IRI resolves through a thin RDF projection of the institution's external identity provider — OIDC, SAML, LDAP/AD, GitHub, GitLab, Okta, Keycloak. `flexo-rtm` does not own identity. The projection carries just enough of identity, role, attribute, and scope to support SPARQL-evaluable policies — role-based (RBAC), attribute-based (ABAC), and scope-based — that authorize a given approver to emit a given attestation type for a given aspect within a given scope. See [[Identity Boundaries and Policy Projections]] for the contract and policy primitives.

The bottleneck composes with the SHACL gate. When an attestation is written, one shape rejects the unsigned case (no IRI); a second shape rejects the unauthorized case (the named approver matches no authorizing policy). Both rejections happen at write time, before the triple enters the graph.

## What the AI does in this model

The division of labor is explicit and asymmetric.

**The AI constructs candidate triples.** An LLM-assisted skill — the Claude Code skill that ships with `flexo-rtm`, an institutionally hosted equivalent, or any other oracle wired to the operational layer — reads the model, drafts proposed `rtm:satisfies` triples, suggests verification rationale, surfaces evidence candidates, and proposes coupling edges. This is the work that benefits most from LLM assistance.

**The AI prompts the engineer at judgment moments.** When a draft `rtm:satisfies` triple is about to be written, the skill surfaces the three questions Zargham's framework names: is the model adequate? is the evidence sufficient? who is approving? This is what [[Operational Layer UX Discipline]] calls *judgment surfacing*. The AI may draft answers as candidates but cannot supply approval.

**The engineer reviews, attests, or refines/defers.** The human reads the candidate, the surfaced judgment questions, and the proposed approver identity, then takes one of three actions: attest yes (write the attestation, sign the commit), refine (edit the triple, the rationale, or the approver), or defer with an explicit gap marker (`rtm:DeferredJudgment`).

**The AI never authors the validation/attestation edge.** This is the structural floor. The skill may draft attestation *content*, including a placeholder approver IRI it reads from local git config. It is not permitted to commit the attestation. The commit signature binds the human at the moment of attestation; the AI holds no signing key, has no identity in the institutional projection, and cannot satisfy the SHACL authorization shape. If a malfunctioning automation tried to bypass the human, the SHACL gate and the commit-signature verification would both reject the attempt, independently.

## What "judgment surfacing" means

At each new claim, the skill produces a structured prompt with three questions, each tied to a specific RDF entity:

- **Adequacy:** is the model representation adequate for the kind of claim being made? (`rtm:AdequacyAttestation`, optionally guided by `rtm:AdequacyCriteria`.)
- **Sufficiency:** is the evidence sufficient to support the claim? (`rtm:SufficiencyAttestation`, optionally guided by `rtm:SufficiencyCriteria`.)
- **Approver:** who is approving this attestation? (`rtm:approvedBy`. The skill may default to the engineer's projected identity but cannot finalize without explicit confirmation.)

Three responses: **attest yes** (write the attestation, sign the commit, SHACL gates pass), **refine** (edit candidate fields, re-surface), or **defer** with an explicit `rtm:DeferredJudgment` marker recording which question was deferred and why. Deferral is first-class — "I don't know yet" is a state the system represents, not a silent skip. The audit graph counts deferrals as gaps alongside coverage statistics; the engineer is accountable for the deferral itself, even if not yet for the underlying judgment.

## What this enables

Two things at once:

- **AI assistance with auditable chains of human responsibility.** LLM-assisted drafting productivity is captured, but every claim names the human who approved it. PROV provenance records the AI's contribution as `prov:Association` — the AI is acknowledged as a tool, not as an attestor.
- **Institutional adoption without the accountability cliff.** Organizations that would otherwise choose between "ban AI assistance" and "trust AI output" can have both: engineers use the AI as a productivity tool, the attestation graph names the humans who approved each claim, and the audit artifact carries the chain of responsibility to the credentialed authorities. See [[Verifiable Self-Certification]] for how the three-layer cert artifact carries this chain to an external verifier.

## Related work

- **Floridi & Cowls (2019)** — five principles for AI in society; explicability comprises intelligibility plus accountability. `flexo-rtm` operationalizes the accountability half through SHACL enforcement.
- **UNESCO (2021), Recommendation on the Ethics of AI** — global standards for transparency, human oversight, and accountability. `flexo-rtm` is a concrete mechanism for the accountability principle in systems engineering.
- **UN High-Level Advisory Body on AI (2024)** — "accountability anchored in human responsibility." The named-approver field is the anchor.
- **Ghrist (2025), *The Geometry of Heaven & Hell*, Appendix C** — procedural accountability in AI-assisted scholarly writing. `flexo-rtm` adds structural enforcement.
- **Zargham (2026)** — the topological framework whose accountability move v0.1 carries into RDF/SHACL. See [[INCOSE IS 2026 Paper]].

## Limitations and open questions

Honest accounting of what v0.1 does *not* enforce:

- **Approver authority depends on projection freshness.** If an engineer's role changes in the institutional identity provider but the projection has not yet been refreshed, an attestation might be authorized under stale data. The projection-as-of-cert-time is recorded in the transcript ([[Design Spec]] §4.4), so staleness is forensically visible, but real-time authority is not guaranteed. Adopters configure the refresh interval against their risk tolerance.
- **PROV captures association but does not track LLM versions or prompts.** The audit graph records that an AI was involved in producing a candidate triple, but v0.1 does not standardize how to record *which* model, prompt, or retrieval context. Treating LLM versions as first-class PROV entities — content-addressed by the model card hash — is on the future-work shortlist.
- **Defeaters and revocation are not in v0.1.** SACM and Goal Structuring Notation include *defeaters* — explicit counter-claims that revoke or weaken an attestation. v0.1 supports `rtm:DeferredJudgment` but not a "rescinded" state with structured rationale. Additive in a future minor version.
- **The framework does not prevent rubber-stamping.** It records, audits, names, and binds, but a careless approver can still attest without review. The structural floor is "every claim names someone who can be held to account," not "every claim was carefully considered." Organizational discipline, sampling audits, and peer review remain necessary.

The posture: v0.1 raises the floor — unaccountable claims are structurally impossible — without claiming to ceiling out the problem of careful human judgment. That problem is older than AI and will outlast it. See [[Mission and Thesis]] Proposition 2 (named-approver attestation is structurally enforced) for how this page sits in the eight-proposition framing.
