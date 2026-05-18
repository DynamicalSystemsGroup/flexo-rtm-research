<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Human-AI Accountability

> How `flexo-rtm` integrates LLM-assisted authoring with structurally enforced human accountability. The mechanism — named-approver IRI required as a schema constraint at write time — is established engineering practice grounded in W3C Verifiable Credentials Data Integrity, SLSA in-toto attestations, git GPG/SSH commit signing, and the broader security tradition recorded in NIST SP 800-63 and W3C SHACL. v0.1's contribution is composing that practice into a working RDF stack for SysMLv2 requirements traceability; see [[Attestation Infrastructure in v0.1]] for the normative specification and [[Operational Layer UX Discipline]] for the judgment-surfacing UX the AI participates in. Zargham (2026) provides one topological articulation of why structural accountability matters at the framework level; the v0.1 mechanism itself does not depend on the topological framework.

## Why this matters

LLMs are now routine in how systems engineering artifacts get written. The 2024 DORA report records 76% of developers using AI tools daily; the same machinery — Claude Code, Cursor, Copilot, retrieval-augmented assistants — is increasingly used to draft requirements, populate traceability matrices, generate verification rationale, and synthesize evidence summaries. INCOSE IS 2026 introduced mandatory AI-assistance disclosure requirements because AI-generated content has entered the certification pipeline whether standards bodies sanctioned it or not.

The problem is not that AI is being used. The problem is that **existing institutional frameworks lack mechanisms to integrate AI assistance with accountability for the outputs**. IEEE 1012, ISO/IEC/IEEE 15288, and the INCOSE Systems Engineering Handbook assume the author of a V&V claim is a person; they predate the situation where a credentialed engineer signs off on text an LLM drafted. The standards recommend named human responsibility; they do not enforce it. `flexo-rtm` provides the enforcement mechanism.

## The accountability gap

Three observations frame the gap that established SE practice + AI-assisted authoring together produce. None of the three is novel; what is new is the requirement that they hold together structurally.

**Verification can be automated; validation cannot.** Verification asks "are we building the product right?" — a structural question: required sections present, types conform, references resolve. A deterministic script answers it. Validation asks "are we building the right product?" — is the model adequate to the kind of claim being made? is the evidence sufficient to support it? Those are qualitative judgments — the kind cognitive systems engineering (Hollnagel & Woods 2005; Boy et al. 2015) identifies as inherently human. Automation should support, not replace, this judgment. The INCOSE Systems Engineering Handbook and ISO/IEC/IEEE 15288 codify the V&V distinction; the cognitive-systems-engineering literature explains why validation resists automation.

**LLMs cannot bear responsibility.** Accountability presupposes a subject who can be held to account, and an LLM is not that subject. The model vendor is not the engineer who approved the claim; the operator who ran the prompt is not necessarily the credentialed authority for the aspect attested. This point is articulated across the AI-ethics literature — Floridi & Cowls (2019), UNESCO (2021), the UN High-Level Advisory Body on AI (2024) — and named explicitly in Zargham (2026): "There must be a named human responsible for review, evaluation, and approval."

**Existing frameworks recommend accountability rather than structurally enforce it.** Floridi & Cowls (2019), UNESCO's 2021 Recommendation on the Ethics of Artificial Intelligence (adopted by all 194 member states), and the UN High-Level Advisory Body on AI's 2024 governance framework all call for "accountability anchored in human responsibility." But these are principles, not schemas. The same is true of the SE handbooks (INCOSE, ISO 15288): they recommend named-human review at named gates without making the absence of a name a write-time rejection. What is missing in the recommendations is a mechanism that **requires** accountability attribution at the level of individual claims, **enforces** human review, and **audits** for gaps — not as a policy norm honored by disciplined teams, but as a precondition for the data existing at all. That mechanism is settled engineering — see the next section.

## Structural enforcement: making accountability a schema constraint

Lifting accountability from a recommendation to a **schema constraint** is settled engineering, not a 2026 innovation. The pattern shows up across the security, identity, and supply-chain stack `flexo-rtm` composes:

- **W3C Verifiable Credentials Data Integrity 2.0** — every credential has an issuer; cryptographic proofs are bound to that named identity. Unsigned credentials are not credentials.
- **SLSA in-toto attestations** — every attestation has a named signer (a producer identity); the supply-chain frameworks (SLSA, OpenSSF Scorecard, Sigstore Rekor) treat unsigned predicates as non-attestations.
- **Sigstore + Fulcio** — keyless signing binds an OIDC identity to every signature event; the signature does not exist without a named human (or named workload identity) at attestation time.
- **git GPG/SSH commit signing** — every commit can be signed by a named author; integrators routinely require signatures on protected branches via established practice.
- **NIST SP 800-63 (Digital Identity Guidelines)** — codifies the named-identity discipline in security: every authoritative act has a named, authenticated actor.
- **W3C SHACL** — the `sh:minCount 1` + `sh:nodeKind sh:IRI` constraint pattern is the canonical way to make a property required-and-IRI-typed at write time.

What `flexo-rtm` does is compose this established pattern into RDF for SysMLv2 requirements traceability: the `rtm:approvedBy` property on `rtm:Attestation` is required (`sh:minCount 1`), IRI-typed (`sh:nodeKind sh:IRI`), bound to a signed git commit, and authorized via a thin projection of the institutional identity provider. The discipline is not novel; the composition into the RTM use case is what v0.1 contributes. Ghrist's "The Forge" methodology (Ghrist 2025, *The Geometry of Heaven & Hell*, Appendix C) demonstrates procedural accountability in AI-assisted scholarly writing — "every sentence in this book passed through my judgment; every connection earned my conviction; every claim bears my responsibility." `flexo-rtm` makes the same accountability **schema-enforced** rather than procedural — the SHACL gate rejects what the procedure would have refused. Zargham (2026) articulates why this structural move matters at the framework level via a topological framing (see [[Topological Framework Future Work]]); the v0.1 SHACL mechanism stands on the established practice listed above and does not require the topological framework.

## Translation to `flexo-rtm`

`flexo-rtm` v0.1 implements the established named-approver SHACL pattern for RTM attestations. The mechanism is the named-approver field on `rtm:Attestation`, gated by SHACL at write time, bound to a signed git commit, and authorized via the thin identity projection. See [[Attestation Infrastructure in v0.1]] for the normative specification.

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

**Settled engineering practice `flexo-rtm`'s mechanism composes:**

- **W3C Verifiable Credentials Data Integrity 2.0** — required issuer identity and cryptographic proof binding; the foundational pattern for named-attribution at write time.
- **W3C SHACL** — `sh:minCount 1` + `sh:nodeKind sh:IRI` as the canonical schema-constraint pattern for required IRI-typed properties.
- **SLSA + in-toto** — supply-chain attestations with required named signer; the broader "every claim has an accountable signer" discipline `flexo-rtm` joins.
- **Sigstore (Fulcio + Rekor)** — keyless signing bound to OIDC identity; named-human-at-attestation-time enforced at the cryptographic layer.
- **NIST SP 800-63** — Digital Identity Guidelines codifying named-identity discipline across authoritative acts.

**Accountability literature `flexo-rtm`'s framing draws from:**

- **Floridi & Cowls (2019)** — five principles for AI in society; explicability comprises intelligibility plus accountability. `flexo-rtm` operationalizes the accountability half through SHACL enforcement.
- **UNESCO (2021), Recommendation on the Ethics of AI** — global standards for transparency, human oversight, and accountability. `flexo-rtm` is a concrete mechanism for the accountability principle in systems engineering.
- **UN High-Level Advisory Body on AI (2024)** — "accountability anchored in human responsibility." The named-approver field is the anchor.
- **Ghrist (2025), *The Geometry of Heaven & Hell*, Appendix C** — procedural accountability in AI-assisted scholarly writing. `flexo-rtm` adds structural enforcement to what Ghrist demonstrates procedurally.
- **Zargham (2026)** — one topological articulation of why structural accountability matters at the framework level; see [[INCOSE IS 2026 Paper]] and [[Topological Framework Future Work]]. The v0.1 mechanism does not depend on the topological framework; the framework is future work.

## Limitations and open questions

Honest accounting of what v0.1 does *not* enforce:

- **Approver authority depends on projection freshness.** If an engineer's role changes in the institutional identity provider but the projection has not yet been refreshed, an attestation might be authorized under stale data. The projection-as-of-cert-time is recorded in the transcript ([[Design Spec]] §4.4), so staleness is forensically visible, but real-time authority is not guaranteed. Adopters configure the refresh interval against their risk tolerance.
- **PROV captures association but does not track LLM versions or prompts.** The audit graph records that an AI was involved in producing a candidate triple, but v0.1 does not standardize how to record *which* model, prompt, or retrieval context. Treating LLM versions as first-class PROV entities — content-addressed by the model card hash — is on the future-work shortlist.
- **Defeaters and revocation are not in v0.1.** SACM and Goal Structuring Notation include *defeaters* — explicit counter-claims that revoke or weaken an attestation. v0.1 supports `rtm:DeferredJudgment` but not a "rescinded" state with structured rationale. Additive in a future minor version.
- **The framework does not prevent rubber-stamping.** It records, audits, names, and binds, but a careless approver can still attest without review. The structural floor is "every claim names someone who can be held to account," not "every claim was carefully considered." Organizational discipline, sampling audits, and peer review remain necessary.

The posture: v0.1 raises the floor — unaccountable claims are structurally impossible — without claiming to ceiling out the problem of careful human judgment. That problem is older than AI and will outlast it. See [[Mission and Thesis]] Proposition 2 (named-approver attestation is structurally enforced) for how this page sits in the eight-proposition framing.
