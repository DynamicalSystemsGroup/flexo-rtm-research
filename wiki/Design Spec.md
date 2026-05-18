<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# `flexo-rtm` — Design Spec

> **Status:** Canonical design spec. The single source of truth from which all wiki pages derive. **§6 Acceptance Criteria are normative**; everything else is explanatory. Detailed interface contracts are broken out into companion pages cross-linked from §6.

**Date:** 2026-05-18 (rev)
**Author:** Michael Zargham
**Reviewer:** Michael Zargham

---

## 1. Mission

A verifiable self-certification protocol for bidirectional requirements traceability of SysMLv2 models, anchored in open source and self-hostable on Flexo MMS, with lossless I/O paths to OSLC-based RM systems (Doors, Jama, Polarion, others). The oracle proves that a model satisfies forward + backward traceability — or pinpoints the gaps from graph structure — and emits a layered, replayable certification artifact (transcript → attestation graph → audit report).

**`flexo-rtm` is bidirectional traceability + named-signer accountability.** That is the settled engineering it ships. It is methodology-neutral with respect to downstream-analysis paths (SLSA, GSN, ARP4754A, in-house, or others); it neither requires nor privileges any of them. See [[ADR-032 Methodology Agnosticism as Foundational Axiom]].

**Polycentric institutional topology.** `flexo-rtm` reflects the reality of mission- and safety-critical systems engineering: multiple organizations (engineering teams, prime contractors, subsystem suppliers, regulatory authorities, qualified auditors) hold **scoped authorities** over different parts of the system. Each [`rtm:Scope`](#53-analysis-layer-composable-scopes) is a named graph functioning as an **Authoritative Source of Truth (ASOT)** for its content, with versioning, change control, and named-approver accountability. Scopes compose into higher-order scopes and may overlap; the arrangement is **polycentric**, not centralized. This follows [MOSA](https://www.cto.mil/sea/mosa/) ([10 U.S.C. §4401](https://www.law.cornell.edu/uscode/text/10/4401); [DoD MOSA Guidebook 2025](https://www.cto.mil/wp-content/uploads/2025/03/MOSA-Implementation-Guidebook-27Feb2025-Cleared.pdf)) and [DAU's ASOT](https://www.dau.edu/glossary/authoritative-source-truth) terminology. See [[ADR-030 Polycentric ASOT Authority Model]].

**Generalized ASOT principle.** The polycentric ASOT framing for scopes is one application of a foundational design axiom: **every identified thing referenced in `flexo-rtm` data has an Authoritative Source of Truth held by an external entity** — typically the organization that produces, maintains, hosts, or issues credentials for it. `flexo-rtm` carries thin, dereferenceable references; it does not own the authoritative content. This applies uniformly to persons (identity provider holds the credential), organizations, code / files / directories / datasets (git hosts, content-addressed stores), execution environments (OCI registries, cloud platforms), activities and their outputs (the organization that ran them), scopes themselves, policies / roles / attributes (the identity provider that issued them), and cryptographic keys + signed envelopes (the PKI / KMS / OIDC / cosign / Rekor / VC-DI issuer). Each kind of identity is **dereferenceable by anyone qualified to do so under the ASOT's own access policy** — `flexo-rtm` does not authenticate, gatekeep, proxy, cache, or bypass dereferencing. The full per-kind ASOT mapping and the security corollary it implies are specified in §4 (ASOT principle) and recorded in [[ADR-033 Generalized ASOT Principle for All Identified Things]].

**What `flexo-rtm` adds to today's stacks.** Incumbent RM tools (Doors, Jama, Polarion) deliver authoring and storage of requirements; they do not yet deliver these three properties natively:

1. **Verifiable certification-by-construction** — canonical hashes + replayable transcripts (§4.7).
2. **Open data portability** — RDF + lossless OSLC roundtrip (§6.2).
3. **Federable verification across scoped ASOTs** — any party with adequate permissions can re-check facts in their scope without proprietary access (§4.8).

These properties benefit adopters whether they keep their existing RM tool, run `flexo-rtm` standalone, or use a hosting partner. Incumbents themselves can serve as credible-counterparty auditors and hosts atop the open standard; the intended posture is **cooperation across ASOTs, not displacement of any one of them**.

**Four interface boundaries are the design constraints.** The mission above is the **objective function**; the binary acceptance criteria at §6 (Flexo storage F1–F7, OSLC interop O1–O7, identity-for-actors I1–I8, artifact URIs U1–U6, signed envelopes S1–S5, cross-cutting X1–X8) are the **constraints**. Each criterion is testable. Detailed contracts are in the companion pages cross-linked from §6.

## 2. Two-repo strategy

| Repo | Purpose | Status |
|---|---|---|
| `flexo-rtm-research` | Companion wiki: design spec, ADRs, research synthesis, decision rationale. | Built first; this spec is published in its wiki. |
| `flexo-rtm` | Standards + software. Ontology, oracle code, conformance suite, OSLC adapters, regression corpus. | Built after this spec is reviewed and locked. |

Both repos start in `dynamicalsystemsgroup/`; transfer to OpenMBEE at MVP service milestone.

## 3. Scope-reducing assumption

**The modeled system is a SysMLv2 model conformant with OMG specifications**, represented as RDF via the openCAESAR `omg-sysml:` OWL rendering. Requirements, evidence, and attestations are structured around SysMLv2 elements. The full ingestion contract — accepted serializations, conformance profile, mapping rules — is normative in [[SysMLv2 Ingestion Contract]].

## 4. Certification model

`flexo-rtm` v0.1 ships **traditional bidirectional traceability** (§4.1) plus **named-approver attestation infrastructure** with three attestation subclasses for v0.1 work (§4.2) and three additional subclasses for federated audit composition (§4.8). Identity boundaries (§4.3), external URIs (§4.4), signed envelopes (§4.5), gap reporting (§4.6), and reproducibility (§4.7) operationalize the certification artifact. The entire model rests on one foundational principle, §4.0 below.

### 4.0 ASOT principle (foundational)

Every identified thing referenced in `flexo-rtm` data has an **Authoritative Source of Truth (ASOT) held by an external entity** — typically the organization that produces, maintains, hosts, or issues credentials for it. `flexo-rtm` carries thin, dereferenceable references; it does not own the authoritative content. This single principle unifies §4.3 (identity for actors), §4.4 (identity for artifacts), §4.5 (signed envelopes), and §5.3 (scope authority). See [[ADR-033 Generalized ASOT Principle for All Identified Things]].

**ASOT for each kind of identified thing:**

| Thing | ASOT | Reference vocabulary |
|---|---|---|
| Persons | identity provider (SSO / OIDC / SAML / LDAP / GitHub / GitLab / custom) | `foaf:Person` + `rtm:hasExternalIdentity` |
| Organizations | registry, hosting provider, or accreditation body issuing the org IRI | `org:Organization` + `rtm:hasExternalIdentity` |
| Roles / attributes / policies | identity provider that issued them | `rtm:Policy` referencing `rtm:role/...`, `rtm:Attribute` |
| Cryptographic keys | PKI / KMS / OIDC issuer | `rtm:hasPublicKey` with fingerprint |
| Code, files, directories | git host or content-addressed store | `rtm:hasGitRepo + rtm:hasGitCommit + rtm:hasGitPath`, or `rtm:hasContentHash` |
| Datasets | data publisher or content-addressed store | `rtm:hasContentHash` (often `ipfs:` / `cid:` for archives) |
| Execution environments | OCI registry, cloud platform | `rtm:hasOCIImage` |
| Activities (simulations, builds, tests) | the organization that ran the activity | `prov:Activity` + `prov:wasAssociatedWith` |
| Activity outputs | the organization that produced them | `prov:Entity` + `prov:wasGeneratedBy` |
| Scopes | the organization the scope's content concerns | `rtm:Scope` + `rtm:asotHeldBy` (per [[ADR-030 Polycentric ASOT Authority Model]]) |
| Signed envelopes | cosign / Rekor / VC-DI / DSSE issuer | `sec:proof`, `rtm:dsseEnvelope`, `rtm:cosignBundle`, `rtm:rekorLogEntry` |

If a new kind of identified thing enters the design, the question is not "should `flexo-rtm` own this?" but "**which external entity is its ASOT, and what reference vocabulary points to it?**"

**Dereferencing corollary.** Each kind of identity is dereferenceable by anyone qualified to do so **under the ASOT's own access policy**. `flexo-rtm` does NOT:

- authenticate or gatekeep dereferencing (the ASOT does this natively — git access tokens, OCI registry auth, IdP login, KMS key policies, …)
- proxy or cache content from ASOTs (references are direct; resolution is the verifier's responsibility)
- arbitrate disputes between ASOTs (single ASOT per identified thing; conflicts resolve upstream)
- bypass an ASOT's access policy under any condition

This gives `flexo-rtm` a useful security property: **a cert artifact can be shared widely without leaking ASOT content** — the references are just identifiers. Sensitive content remains behind whichever ASOT owns it; a verifier without dereference permission can still confirm **structural completeness** of the references (per acceptance criterion X8 of §6.6) without ever fetching.

### 4.1 Traditional bidirectional traceability

**Minimal vocabulary:**

- `rtm:Requirement` — a stated requirement
- `rtm:Artifact` — evidence (a SysMLv2 model element, proof script, simulation result, test report, …)
- `rtm:satisfies` (Artifact → Requirement) — verification edge

**Analyses.** Forward: for each $r \in R$, enumerate $\{a \in A : a \texttt{ rtm:satisfies } r\}$; a requirement is *forward-covered* if non-empty. Backward: symmetric for $a \in A$.

**Coverage statistics.** Forward coverage $\% = |\{r : r \text{ forward-covered}\}| / |R|$; backward similarly.

**Basic predicate.** Pass at scope S iff forward $\% \geq \theta_\text{forward}$ AND backward $\% \geq \theta_\text{backward}$ (default both 100%; configurable).

This is the analysis Doors/Jama/Polarion/OSLC users recognize; it works directly against the OSLC adapter's output. The reports look like the RTM tables they already use, plus the transcript adds replayable provenance. Acceptance criteria gates this analysis at §6.6 X1–X3.

### 4.2 Attestation infrastructure (named-approver accountability)

`flexo-rtm` ships structurally enforced named-approver accountability for six attestation kinds across two tiers:

**Per-claim attestations (v0.1 primary):**

| Class | Subject | Asserts |
|---|---|---|
| `rtm:SatisfactionAttestation` | an `rtm:satisfies` triple | "this artifact satisfies this requirement" |
| `rtm:AdequacyAttestation` | an (artifact, requirement) pair | "the model representation is adequate for the claim" |
| `rtm:SufficiencyAttestation` | an (artifact, requirement) pair | "the evidence is sufficient to support the claim" |

The ADCS regression corpus uses adequacy and sufficiency attestations; v0.1 must support them. See [[ADR-021 Three Attestation Subclasses Ship in v0.1]] and [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]].

**Composition attestations (v0.1, for federated audit; see §4.8):**

| Class | Subject | Asserts |
|---|---|---|
| `rtm:ScopeCertificationAttestation` | an `rtm:Scope` IRI | "the scope's content meets the certification predicate at $\theta$" |
| `rtm:CompositionCoverageAttestation` | a composition of scopes | "the composed scopes cover the system-of-interest" |
| `rtm:CompositionSufficiencyAttestation` | a composition of scopes | "the qualified-role signers across the composed scopes are sufficient" |

See [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]].

**Shared structure.** All six subclass `rdfs:subClassOf rtm:Attestation` and share:

- `rtm:approvedBy` (IRI) — REQUIRED (SHACL-enforced)
- `rtm:status` — `pass | fail | deferred | deprecated` (four-state; see [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]])
- `prov:wasGeneratedBy`, `prov:atTime`, `prov:wasAssociatedWith` — provenance
- `prov:wasInvalidatedBy` — set on `deprecated` to point to the invalidating event
- Optional `rtm:hasAspect` for per-aspect attestation

**Status semantics:**

- `pass` — the named approver attests the claim under the active SHACL profile
- `fail` — the named approver attests the claim is unsupported under the active SHACL profile
- `deferred` — judgment moment surfaced; approver explicitly defers (a first-class "I don't know yet" state, not silent absence)
- `deprecated` — the attestation has been invalidated by an upstream change; `prov:wasInvalidatedBy` records the cause; regression handling is local per [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] (no scope state machine; see §5.3 and [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]])

**Schema-enforced approver:**

```turtle
rtm:AttestationShape a sh:NodeShape ;
    sh:targetClass rtm:Attestation ;
    sh:property [
        sh:path rtm:approvedBy ;
        sh:minCount 1 ;
        sh:nodeKind sh:IRI ;
        sh:message "Every attestation requires a named human approver IRI"
    ] .
```

Applies to the parent class and all six subclasses.

**Composable profiles** (off by default):

- `attested-satisfies` — every `rtm:satisfies` requires a `rtm:SatisfactionAttestation`
- `attested-adequacy` — same with `rtm:AdequacyAttestation`
- `attested-sufficiency` — same with `rtm:SufficiencyAttestation`
- `composition-adequacy` / `composition-sufficiency` / `qualified-audit-per-scope` — composition-level (see §4.8)

**Vocabulary for adequacy / sufficiency criteria.** `rtm:Guidance` (abstract), `rtm:AdequacyCriteria`, `rtm:SufficiencyCriteria`, `rtm:Aspect` ship in the core ontology because the per-claim attestations reference them. SHACL well-formedness shapes apply; no triangle-closure or recursive completeness audit runs over them. See [[ADR-021 Three Attestation Subclasses Ship in v0.1]].

### 4.3 Identity boundaries — thin projections of external authoritative sources

`flexo-rtm` does not own identity. Named approvers are IRIs referencing identities owned by external systems (institutional SSO via OIDC/SAML, LDAP/AD, GitHub/GitLab). The system carries thin RDF projections of identities and policies; SHACL is the single bottleneck where authority is checked at attestation-write time. See [[ADR-024 Identity by Thin Projection of External Sources]] and [[Identity Adapter Contract]] for the full normative contract.

**Vocabulary:**

- Persons: `foaf:Person` + `rtm:hasExternalIdentity` (e.g., `"github:zargham"`, `"oidc:https://idp.example/sub"`)
- Memberships: `org:Membership` with `org:role`, `org:organization`, `rtm:scopedTo`
- Attributes: `rtm:Attribute` with `rtm:attributeKey`, `rtm:attributeValue`
- Organizations: `org:Organization` with `rtm:hasQualifiedRole` for org-level identity (per [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]])
- Policies: `rtm:Policy` with `rtm:appliesToRole`, `rtm:requiresAttribute`, `rtm:permitsAttestationType`, `rtm:permitsAspect`, `rtm:withinScope`

**Policy primitives** (combinable; configurable):

| Kind | Example |
|---|---|
| Role-based (RBAC) | `rtm:role/safety-engineer` may attest `rtm:SufficiencyAttestation` for `rtm:safety` aspect |
| Attribute-based (ABAC) | `security-clearance ≥ SECRET` to attest classified-data sufficiency |
| Scope-based | Approver authorized only for `rtm:scope/adcs-attitude-control` and its sub-scopes |

All three are SPARQL-evaluable against the identity projection. Policies are RDF resources — versioned, scoped, queryable, certifiable.

**SHACL bottleneck.** When a new attestation is written, a SHACL constraint evaluates the applicable policies via SPARQL. The constraint rejects attestations whose approver does not match any authorizing policy. The pseudocode shape is normative in [[Identity Adapter Contract]].

**Reference adapters (v0.1):** GitHub, generic OIDC, GitHub Actions OIDC. Adopters extend for SAML / LDAP / AD / Okta / Auth0 / Keycloak via the thin adapter pattern; the input/output schema and conformance criteria are normative in [[Identity Adapter Contract]].

**Refresh policy.** Projections are point-in-time. Adopters choose: every cert run, on commit, scheduled, or static. The transcript records the projection-as-of-cert-time so audit re-runs evaluate against the recorded projection, not the live identity provider — identity changes do not invalidate past attestations. Refresh policy and reproducibility are complementary, not in tension. See [[ADR-025 Reproducibility is Structural and Local]].

**Out of scope:** authentication (no login, no session, no credentials stored); proprietary policy engines (no XACML / OPA / Cedar — SPARQL evaluation against RDF is the policy engine).

### 4.4 External URI references — the git+RDF foundation

Evidence, models, and activities are RDF entities that reference concepts outside the graph via URI: git repositories + commit hashes, content-addressed data (sha256 / IPFS), OCI image digests. These references — not the RDF metadata in isolation — are the source of true open-source interoperability, portability, auditability, and reproducibility. See [[ADR-022 External URI References as Open-Source Foundation]] and [[External URI Rules]] for the normative contract.

**Entity classes:**

- `rtm:Activity` (subclass of `prov:Activity`) — a process: simulation run, model build, test execution, proof check, data import
- `rtm:Artifact` (subclass of `prov:Entity`) — an addressable artifact: model file, evidence file, simulation result, dataset

**Vocabulary:**

| Property | Range | Purpose |
|---|---|---|
| `rtm:hasGitRepo` | xsd:anyURI | Git repository URL |
| `rtm:hasGitCommit` | xsd:string | Full commit SHA |
| `rtm:hasGitPath` | xsd:string | Optional path within repo |
| `rtm:hasContentHash` | xsd:string | Content hash with algorithm prefix (e.g., `sha256:abc...`); algorithm is suite-derived per [[ADR-026 Cryptographic Agility via Algorithm Profiles]] |
| `rtm:hasOCIImage` | xsd:string | OCI image reference with digest |
| `dcat:downloadURL` | xsd:anyURI | Optional mirror / fetch URL |

Plus standard PROV-O: `prov:wasDerivedFrom`, `prov:used`, `prov:wasGeneratedBy`, `prov:atLocation`, `prov:hadPlan`, `prov:startedAtTime`, `prov:wasAssociatedWith`.

**SHACL discipline.** `rtm:Activity` SHOULD carry at least one of `rtm:hasGitCommit` / `rtm:hasOCIImage` (warning by default; error under `--profile=strict-provenance`). Full required/optional rules per artifact type, URI format validation, audit-mode fetch behavior, and the reproducibility manifest format are in [[External URI Rules]].

### 4.5 Signed envelopes — composing battle-tested cryptographic standards

`flexo-rtm` does not invent cryptography. Where signing matters, the system composes established standards. See [[ADR-023 Cryptography by Composition of Battle-Tested Standards]] and [[Signed Envelope Shapes]] for the normative SHACL shapes and verification flow.

**Cryptographic agility.** Algorithm choice (SHA-256, P-256, Ed25519, …) is **suite-derived**, not hardcoded in the data model. The active cryptographic suite (W3C VC-DI cryptosuite, cosign suite, DSSE suite, OCI signature suite) supplies the algorithm. v0.1 default: SHA-256 for content hashes; signing-suite default per W3C VC-DI 2.0. See [[ADR-026 Cryptographic Agility via Algorithm Profiles]].

**Integration surfaces:**

| Concern | Standard | Vocabulary |
|---|---|---|
| Approver binding to git commit | Git GPG / SSH signing | committer-key fingerprint vs. `rtm:approvedBy` identity-projection-published key |
| RDF integrity of attestation | W3C Verifiable Credentials + Data Integrity (RDFC-1.0 + signature) | `sec:proof` |
| Activity attestation envelope | DSSE + in-toto attestation predicate | `rtm:dsseEnvelope` |
| Container image trust | Sigstore cosign / OCI image signatures | `rtm:cosignBundle` |
| Transparency / non-repudiation | Sigstore Rekor transparency log | `rtm:rekorLogEntry` |
| Keyless CI signing | Sigstore keyless (Fulcio OIDC-bound ephemeral keys) | implicit; produces the same `sec:proof` / `rtm:dsseEnvelope` artifacts |

**Composable profiles** (off by default): `signed-commits`, `data-integrity-attestations`, `dsse-activities`, `cosign-images`, `rekor-transparency`.

**Boundary discipline.** No custom crypto schemes; no custom envelope formats (DSSE wraps payloads, VC-DI wraps RDF); no custom transparency logs (Rekor when wanted); no custom key management (gnupg / ssh-agent / cosign / GitHub OIDC / cloud KMS — adopter's choice).

### 4.6 Gap taxonomy

v0.1 reports these gap codes:

| Code | Meaning | Detection |
|---|---|---|
| `T1.orphan-requirement` | `r ∈ R` with no incoming `rtm:satisfies` | forward analysis |
| `T2.dangling-evidence` | `a ∈ A` with no outgoing `rtm:satisfies` | backward analysis |
| `T3.unattested-satisfaction` | `rtm:satisfies` without `SatisfactionAttestation` (when `attested-satisfies` active) | attestation profile |
| `T4.unattested-adequacy` | same with `AdequacyAttestation` (when `attested-adequacy` active) | attestation profile |
| `T5.unattested-sufficiency` | same with `SufficiencyAttestation` (when `attested-sufficiency` active) | attestation profile |
| `T6.failed-attestation` | any attestation with `rtm:status = fail` | attestation review |
| `T7.unapproved-attestation` | attestation without `rtm:approvedBy` IRI | **structurally absent** — SHACL rejects at write |
| `T8.aspect-uncovered` | multi-aspect requirement missing attestation for one or more declared aspects | per-aspect rollup |
| `T9.deferred-attestation` | attestation with `rtm:status = deferred` — judgment surfaced but unresolved | attestation review (per [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]) |
| `T10.deprecated-attestation` | attestation with `rtm:status = deprecated` and no superseding live attestation | attestation review |

`T7` is structurally absent (the "by construction" mechanism). `T3`–`T5`, `T8` surface only when the corresponding profile is active. Adopters enable profiles as their workflow matures.

### 4.7 Reproducibility chain — structural completeness enables local, federated verification

**The principle.** Reproducibility is **structural and local**, not global. The cert artifact carries everything a verifying party needs to reproduce a specific fact — without re-dereferencing the whole graph or holding universal permissions. Reproduction federates: multiple parties verify different subsets, composing to a complete audit without any single party owning everything. See [[ADR-025 Reproducibility is Structural and Local]].

**Two regimes, both first-class** (per [[ADR-027 Bit-Exactness vs Numerical Tolerances Are Both First-Class]]):

1. **Bit-exact** — for RDF-internal computation: RDFC-1.0 canonical form + SPARQL/SHACL results are byte-identical across runs. The transcript records input/result hashes; any verifier with read access re-executes and confirms.
2. **Tolerance-aware** — for delegated numerical computation (Monte Carlo, FEA, regression, simulation): tolerances are **evidence-type-specific** and declared in `rtm:SufficiencyCriteria`. The transcript records tolerance plus the recorded result; a verifier re-running the underlying activity (via external URIs per §4.4) compares within tolerance.

**Dimensions, each locally verifiable:**

- **RDF-internal** — canonical inputs + replayable transcript steps (bit-exact regime)
- **External URI** — re-execute the underlying activity (tolerance-aware regime for numerics; bit-exact otherwise)
- **Identity projection** — projection-as-of-cert-time is in the transcript; re-evaluate authorization against recorded projection
- **Signed envelopes** — independently checkable against published keys; no live service required
- **Git approver binding** — GPG/SSH-signed commit + `rtm:approvedBy` IRI confirm "this human attested this fact at this time"

No proprietary dependencies anywhere in the chain.

### 4.8 Federated audit and composition

Four levels of certification compose on top of the per-claim attestations of §4.2. Each level inherits the named-approver SHACL bottleneck. See [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]] and [[Federated Audit and Composition]].

| Level | What it certifies | Attestation class |
|---|---|---|
| 1. Self-cert | Adopter's own scope passes the certification predicate at $\theta$ | `rtm:ScopeCertificationAttestation` |
| 2. Reproducibility audit | An external party with adequate permissions re-runs the transcript and confirms | `rtm:ScopeCertificationAttestation` (by the reproducing party) |
| 3. Qualified-role audit | A party with a qualified role (regulator, accredited auditor) attests the scope under their role's profile | `rtm:ScopeCertificationAttestation` (with qualified `rtm:approvedBy`) |
| 4. Composition certification | A composition of scopes meets coverage + sufficiency thresholds at the system-of-interest level | `rtm:CompositionCoverageAttestation` + `rtm:CompositionSufficiencyAttestation` |

**Composition adequacy** = the composed scopes cover the system-of-interest. **Composition sufficiency** = the number and roles of signing organizations across the composed scopes meet a configurable threshold. Profiles `composition-adequacy`, `composition-sufficiency`, `qualified-audit-per-scope` enforce these at SHACL.

**Out of v0.1:** community-curated qualified-auditor registry (adopters define role sets locally in v0.1).

## 5. Architecture & Scope

### 5.1 Three-layer architecture

```
┌──────────────────────────────────────────────────────────────┐
│  OPERATIONAL — fast, in-memory, model-state-induced          │
│  Pydantic authoring + SHACL gate on every write              │
│  Batch commit to Flexo with model/sim/data co-versioned      │
└────────────────────────┬─────────────────────────────────────┘
                         │ atomic transaction
┌────────────────────────▼─────────────────────────────────────┐
│  STORAGE — Flexo MMS                                          │
│  Authoritative named graphs (branched, versioned)             │
│  See: [[Flexo REST Binding]] for the normative contract       │
└────────────────────────┬─────────────────────────────────────┘
                         │ scoped read
┌────────────────────────▼─────────────────────────────────────┐
│  ANALYSIS — scoped certification, reporting                   │
│  Input = Scope IRI → graph union + filter                     │
│  Emits transcript / attestation / audit                       │
└──────────────────────────────────────────────────────────────┘
```

### 5.2 Operational layer

Materializes only the working set induced by what's checked out (~hundreds of triples). SHACL gates on every write — fast because the graph is small. The skill prompts at judgment moments (adequacy / sufficiency / approver). Batch commit to Flexo is atomic — model triples + evidence refs + attestation triples land together; model evolution and traceability evolution version together.

### 5.3 Scope semantics — composable scopes, ASOTs, optional lifecycle metadata

`rtm:Scope` is a first-class RDF resource (per [[ADR-007 Scope as First-Class RDF Resource]]). Each scope is an ASOT (per [[ADR-030 Polycentric ASOT Authority Model]]). Scopes compose via union / intersection / extension.

```turtle
rtm:scope/adcs-attitude-control a rtm:Scope ;
    rtm:asotHeldBy <https://example.org/orgs/adcs-team> ;
    rtm:includesGraph <adcs:structural>, <adcs:requirements/attitude> ;
    rtm:scopeFilter "FILTER(?aspect IN (rtm:functional, rtm:performance))" .

rtm:scope/adcs-safety a rtm:Scope ;
    rtm:asotHeldBy <https://example.org/orgs/safety-board> ;
    rtm:extends rtm:scope/adcs-attitude-control ;
    rtm:intersectsWith rtm:scope/safety-critical .
```

**Optional lifecycle metadata.** Scopes MAY carry `rtm:lifecycleStage` (range `skos:Concept`) for organizational metadata. The vocabulary is methodology-neutral: INCOSE / ISO 15288, DO-178C DAL gates, NASA Phase A–F, Agile sprints, ISO 9001 process gates, or program-specific milestones all participate equally. `flexo-rtm` ships an INCOSE module (`ontology/lifecycle/incose.ttl`) as one example; adopters declare others. No state machine; no required SHACL shape on stage transitions. Regression handling is local via attestation deprecation (§4.6 T10). See [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]] and [[Engineering Lifecycle Stages]].

### 5.4 Storage layer (Flexo)

Authoritative named graphs in Flexo MMS. One named graph per logical partition (model, requirements, attestations, guidance, transcripts, audit). Per-resource source graphs for imported content (e.g., `<oslc-rm:source/{id}>`). Branches isolate concurrent engineering streams; conflict resolution per `flexo-conflict-resolution-policy-research` (verification-scope automated via SHACL/SPARQL ASK; validation-scope escalated). Per-commit metadata records the active `rtm:Scope` IRI.

Full normative contract — REST API binding, named-graph IRI scheme, transaction semantics, merge policy details — in [[Flexo REST Binding]].

## 6. Acceptance Criteria — Interface Contracts as Design Constraints

This section enumerates the **binary acceptance criteria** for each constraint family. Every criterion is testable. Detailed normative contracts are in companion pages.

### 6.1 Flexo storage — F1–F7

Companion contract: [[Flexo REST Binding]].

| ID | Acceptance criterion | Test |
|---|---|---|
| F1 | `flexo-rtm commit` writes model + evidence + attestation + transcript-fragment triples in a single Flexo transaction. Partial commits forbidden. | `tests/integration/flexo/test_atomic_commit.py` |
| F2 | All triples from a commit reference a single `prov:Activity` IRI (the commit's `flexo:Commit` resource). | `tests/integration/flexo/test_commit_provenance.py` |
| F3 | Named-graph layout: one graph per logical partition (`<model>`, `<requirements>`, `<attestations>`, `<transcripts>`, `<audit>`); per-resource source graphs for imports. IRI scheme normative in [[Flexo REST Binding]]. | `tests/integration/flexo/test_named_graph_layout.py` |
| F4 | Commit metadata captures the active `rtm:Scope` IRI; round-trip: read a commit, recover the scope. | `tests/integration/flexo/test_scope_metadata.py` |
| F5 | Merge policy: constraint-aware synthesis; verification-scope auto-resolved via SHACL ASK; validation-scope escalated to named approver. | `tests/integration/flexo/test_merge_policy.py` |
| F6 | Branch model: `main` for published baselines; `engineering/<team>` for concurrent streams; `cert/<run-id>` for immutable certification artifacts. | `tests/integration/flexo/test_branch_conventions.py` |
| F7 | Live Flexo tests marked `@pytest.mark.live`; auto-skip without `FLEXO_TOKEN`. Test suite runnable end-to-end without a live Flexo. | `tests/conftest.py` |

### 6.2 OSLC-RM / OSLC-QM lossless roundtrip — O1–O7

Companion contract: [[OSLC Roundtrip Acceptance]] (enumerated core class mapping, link-type table, carry-through registry schema). See also [[ADR-010 OSLC-RM and OSLC-QM in v0.1]] and [[ADR-011 Lossless Criterion A plus C]].

| ID | Acceptance criterion | Test |
|---|---|---|
| O1 | **Layer A (core)**: for the enumerated OSLC-RM/QM core class set (see [[OSLC Roundtrip Acceptance]]), $\text{RDFC-1.0}(\text{parse}(\text{emit}(\text{parse}(input)))) = \text{RDFC-1.0}(input)$. | `tests/integration/oslc-roundtrip/test_layer_a_rm.py`, `test_layer_a_qm.py` |
| O2 | **Layer C (vendor extensions)**: triples outside core are stored verbatim in `<oslc-rm:source/{id}>` and re-emitted verbatim; structural triple count per resource preserved. | `tests/integration/oslc-roundtrip/test_layer_c_carrythrough.py` |
| O3 | Enumerated core class set + link-type table are normative in [[OSLC Roundtrip Acceptance]]. Any new core mapping requires updating that companion page. | `tests/conformance/test_mapping_table.py` |
| O4 | Canonical fixtures (W3C/OASIS OSLC spec examples) in `examples/oslc-fixtures/canonical/` roundtrip losslessly (Layer A). | `tests/integration/oslc-roundtrip/test_canonical_fixtures.py` |
| O5 | Vendor sample fixtures (Doors, Jama, sanitized exports) in `examples/oslc-fixtures/vendor/` roundtrip with Layer A on core + Layer C on extensions. | `tests/integration/oslc-roundtrip/test_vendor_fixtures.py` |
| O6 | SHACL profile gate: `--profile=oslc-rm-roundtrip` PASSes only when all profile shapes pass. | `tests/conformance/test_oslc_profile.py` |
| O7 | Vendor extension registry at `examples/oslc-fixtures/vendor-registry.yaml` (schema in [[OSLC Roundtrip Acceptance]]); adding a new vendor requires only a registry entry, no code changes. | `tests/conformance/test_registry_completeness.py` |

### 6.3 Identity & authority for actors — I1–I8

Companion contract: [[Identity Adapter Contract]] (adapter input/output schema, reference adapter specifications, SHACL projection shape).

| ID | Acceptance criterion | Test |
|---|---|---|
| I1 | Schema-enforced approver: every `rtm:Attestation` requires `rtm:approvedBy <IRI>` (`sh:minCount 1`, `sh:nodeKind sh:IRI`). | `tests/conformance/test_attestation_shape.py` |
| I2 | Policy positive case: approver with role R, attribute K=V, scoped to S, IS authorized to emit `rtm:SatisfactionAttestation` for aspect X iff there exists `rtm:Policy` P matching all five. | `tests/conformance/test_policy_positive.py` |
| I3 | Policy negative case (attribute): same approver without attribute K MUST FAIL even if role matches. | `tests/conformance/test_policy_negative_attribute.py` |
| I4 | Policy negative case (scope): approver scoped to `rtm:scope/adcs-attitude-control` authorized for sub-scopes; NOT for sibling scopes. | `tests/conformance/test_policy_scope_hierarchy.py` |
| I5 | Reference adapters (GitHub, generic OIDC, GitHub Actions OIDC) take sample claim payloads and produce conforming projection triples; conformance per [[Identity Adapter Contract]]. | `tests/conformance/test_identity_adapters.py` |
| I6 | New-provider adapter: writing a new adapter (e.g., SAML) requires only conforming to the input/output schema in [[Identity Adapter Contract]]. No core code changes. | manual review + `test_adapter_contract_schema.py` |
| I7 | Git approver binding (when `signed-commits` profile active): commit GPG/SSH key fingerprint must match the `rtm:approvedBy` IRI's published key. Pre-commit hook + GitHub Actions verify. | `tests/integration/git/test_approver_binding.py` |
| I8 | Local & federated reproducibility of identity facts: a verifier with read access to the recorded projection-at-cert-time re-evaluates authorization for any specific attestation locally. Identity changes after cert do NOT invalidate past attestations. | `tests/conformance/test_projection_local_reproducibility.py` |

### 6.4 Identity for artifacts (dereferenceable URIs) — U1–U6

Companion contract: [[External URI Rules]] (required/optional per artifact type, URI format validation, audit-mode fetch behavior, manifest format).

| ID | Acceptance criterion | Test |
|---|---|---|
| U1 | Vocabulary: any `rtm:Activity` SHOULD carry at least one of `rtm:hasGitCommit` or `rtm:hasOCIImage`; `--profile=strict-provenance` upgrades to MUST. | `tests/conformance/test_activity_provenance.py` |
| U2 | Content-hash verification (audit mode): if given network access, the oracle MAY fetch the URI for any `rtm:hasContentHash` and compute the hash; computed hash MUST equal recorded hash. | `tests/integration/dereferenceable/test_content_hash_verify.py` |
| U3 | Git commit existence: in audit mode, fetching `rtm:hasGitRepo + rtm:hasGitCommit` MUST succeed. | `tests/integration/dereferenceable/test_git_commit_resolves.py` |
| U4 | OCI image digest existence: in audit mode, fetching `rtm:hasOCIImage` digest MUST succeed; cosign-verifiable when `--profile=cosign-images` is active. | `tests/integration/dereferenceable/test_oci_digest_resolves.py` |
| U5 | Reproducibility manifest: every audit report MUST include the manifest enumerating every external URI the cert depends on. Format normative in [[External URI Rules]]. | `tests/conformance/test_audit_manifest_completeness.py` |
| U6 | Source-preserving references: an activity's URI references persist verbatim through Flexo round-trips (no normalization). | `tests/integration/flexo/test_uri_preservation.py` |

### 6.5 Signed envelopes — S1–S5

Companion contract: [[Signed Envelope Shapes]] (SHACL shapes for VC-DI / DSSE / cosign verification; cryptosuite identifiers; dependency posture).

| ID | Acceptance criterion | Test |
|---|---|---|
| S1 | When `signed-commits` profile active: every attestation triple originates from a GPG/SSH-signed git commit; signature key fingerprint matches the `rtm:approvedBy` IRI's published key. | `tests/integration/sign/test_signed_commits.py` |
| S2 | When `data-integrity-attestations` profile active: every `rtm:Attestation` carries a valid `sec:proof`; verification via the cryptosuite ID, no live service required. | `tests/integration/sign/test_data_integrity.py` |
| S3 | When `dsse-activities` profile active: every `rtm:Activity` emitting an attestation references a DSSE-enveloped in-toto attestation via `rtm:dsseEnvelope`; envelope verifies under the recorded suite. | `tests/integration/sign/test_dsse_activities.py` |
| S4 | When `cosign-images` profile active: every `rtm:hasOCIImage` reference carries a verifying `rtm:cosignBundle`. | `tests/integration/sign/test_cosign_images.py` |
| S5 | When `rekor-transparency` profile active: every attestation has a corresponding Rekor log entry IRI via `rtm:rekorLogEntry`; Merkle inclusion proof verifies. | `tests/integration/sign/test_rekor_transparency.py` |

### 6.6 Cross-cutting — X1–X8

| ID | Acceptance criterion | Test |
|---|---|---|
| X1 | Bit-exact determinism (RDF-internal): same canonical input → byte-identical transcript across runs (machines, process IDs, times). | `tests/determinism/test_byte_identical_transcripts.py` |
| X2 | Tolerance-aware reproducibility (numerics): re-executed numerical activity within recorded tolerance per evidence-type-specific `rtm:SufficiencyCriteria`. | `tests/determinism/test_tolerance_aware_replay.py` |
| X3 | Replay: anyone with canonical input-hash + transcript re-executes recorded SPARQL/SHACL steps and produces byte-identical result hashes. | `tests/conformance/test_transcript_replay.py` |
| X4 | Quantitative outcomes only: no audit report contains a single "% certified" rolled-up number; coverage reported per-dimension. | `tests/conformance/test_audit_report_shape.py` |
| X5 | No proprietary deps in default install: `pip install flexo-rtm` works with PyPI + system `git`. Cosign, OCI tooling, identity adapters are optional extras. | `tests/conformance/test_minimal_install.py` |
| X6 | Parsimony: assembled `rtm.ttl` ≤ 2000 triples; build fails if exceeded. Terms extracted enumerated in [[Parsimony Manifest]]. | `tests/conformance/test_ontology_parsimony.py` |
| X7 | Local reproducibility of any fact: a verifier with read access to that fact's local neighborhood + dereference access to its external URIs re-executes the recorded steps and confirms hashes. | `tests/conformance/test_local_fact_reproducibility.py` |
| X8 | Federated reproducibility composes: multiple parties with non-overlapping permission subsets each reproduce their permitted fact-set; union of per-fact PASSes = global PASS over the union. | `tests/conformance/test_federated_reproducibility.py` |

## 7. Ontology + Oracle architecture

### 7.1 Ontology layers

| Layer | Path | Content |
|---|---|---|
| Core | `ontology/core/` | TBox: requirement, artifact, attestation (+ 6 subclasses), scope, identity projection, policy, transcript, gap |
| Alignment | `ontology/alignment/` | `owl:equivalentClass` / `skos:closeMatch` to OSLC-RM, OSLC-QM, SysMLv2 (openCAESAR), INCOSE, GSN, PROV, EARL, ORG, FOAF |
| Profiles | `ontology/profiles/` | Composable SHACL contracts (per §4 listings + §6 profile gates) |
| Shapes | `ontology/shapes/` | Always-active structural enforcement (approver-required, profile-gate dispatch) |
| Lifecycle | `ontology/lifecycle/` | INCOSE example module (`incose.ttl`); adopters add others (DO-178C, NASA, Agile, …) |
| Parsimony | `ontology/parsimony/` | Build-time MIREOT/SLME extracts; `manifest.yaml` declares every kept term. See [[Parsimony Manifest]]. |

### 7.2 Oracle sub-packages

```
oracle/src/oracle/
├── models/             # Pydantic: Scope, Attestation, Transcript, Audit, ...
├── canonicalize/       # RDFC-1.0 + cryptosuite-derived hashing
├── operational/        # workspace, checkout, author, batch, commit
├── storage/            # Flexo adapter (see [[Flexo REST Binding]])
├── analysis/           # scope.py, materialize.py, coverage.py, emit/, verify/
├── identity/           # adapter contract + reference adapters (see [[Identity Adapter Contract]])
├── adapters/oslc/      # RM + QM (see [[OSLC Roundtrip Acceptance]])
├── adapters/sysmlv2/   # ingestion (see [[SysMLv2 Ingestion Contract]])
└── cli.py              # Typer entry
```

### 7.3 Dependency policy

| Layer | Required | Optional extras |
|---|---|---|
| Hot path (operational + storage + analysis) | `rdflib`, `pyshacl`, `pydantic` | — |
| OSLC adapters | `rdflib`, `pydantic-xml` | — |
| Signed envelopes (verify) | `cryptography` | optional: `sigstore`, `in-toto-attestation` |
| Build / parsimony | `rdflib` | `robot` CLI |
| Visualization | — | `[viz]`: `matplotlib`, `networkx`, `graphviz` |

Default `pip install flexo-rtm` is the lean hot path + adapters. Signing-verification extras lazy-loaded only when a signed-envelope profile is active.

### 7.4 Pydantic surface (preview of v0.2 OpenAPI)

```python
class Scope(BaseModel):
    iri: AnyUrl
    label: str
    asot_held_by: AnyUrl | None              # ADR-030 polycentric ASOT
    includes_graphs: list[AnyUrl]
    scope_filter: str | None
    extends: AnyUrl | None
    intersects_with: list[AnyUrl] = []
    lifecycle_stage: AnyUrl | None           # ADR-029 optional

class TranscriptStep(BaseModel):
    seq: int
    step_kind: Literal["sparql", "shacl", "canonicalize", "fetch", "verify-signature"]
    query_text: str | None
    shape_iri: AnyUrl | None
    inputs_hash: str
    result_hash: str
    cryptosuite: str | None                  # ADR-027 suite-derived algorithm
    prov_activity: AnyUrl

class GapRecord(BaseModel):
    code: Literal["T1","T2","T3","T4","T5","T6","T7","T8","T9","T10"]
    vertex_iri: AnyUrl | None
    aspect: AnyUrl | None
    detail: str

class AttestationRecord(BaseModel):
    iri: AnyUrl
    approved_by: AnyUrl
    subject: tuple[AnyUrl, AnyUrl, AnyUrl] | AnyUrl   # triple or scope IRI
    attestation_class: Literal[
        "SatisfactionAttestation", "AdequacyAttestation", "SufficiencyAttestation",
        "ScopeCertificationAttestation", "CompositionCoverageAttestation", "CompositionSufficiencyAttestation",
    ]
    status: Literal["pass", "fail", "deferred", "deprecated"]
    invalidated_by: AnyUrl | None
    timestamp: AwareDatetime
    transcript_ref: AnyUrl | None

class AuditReport(BaseModel):
    run_id: UUID
    scope: AnyUrl
    profile: list[AnyUrl] = []
    input_hash: str
    transcript_iri: AnyUrl
    attestation_graph_iri: AnyUrl
    coverage: CoverageStats                  # forward / backward / per-claim / per-aspect / composition
    gaps: list[GapRecord]
    reproducibility_manifest_iri: AnyUrl
    certified: bool                          # derived from coverage + thresholds
```

These models become FastAPI request/response schemas in v0.2 with zero rework.

## 8. v0.1 scope + roadmap + testing

### 8.1 v0.1 in scope

| Capability | Source contract |
|---|---|
| Traditional bidirectional traceability + coverage stats | §4.1 + §6.1, §6.6 |
| Six attestation subclasses (3 per-claim + 3 composition) with four-state status | §4.2 + §4.8 |
| Identity boundaries + thin projections + reference adapters | §4.3 + §6.3 + [[Identity Adapter Contract]] |
| External URI references + reproducibility manifest | §4.4 + §6.4 + [[External URI Rules]] |
| Signed envelopes (5 composable profiles, all off-by-default) | §4.5 + §6.5 + [[Signed Envelope Shapes]] |
| OSLC-RM + OSLC-QM full read/write adapters with lossless roundtrip tests | §6.2 + [[OSLC Roundtrip Acceptance]] |
| `rtm:Scope` as first-class RDF resource; composition algebra; ASOT model | §5.3 |
| Optional `rtm:lifecycleStage` (methodology-neutral); INCOSE module ships as example | §5.3 + [[Engineering Lifecycle Stages]] |
| Federated audit ladder (self → reproducibility → qualified-role → composition) | §4.8 + [[Federated Audit and Composition]] |
| Ontology: core + alignment + profiles + shapes + lifecycle + parsimony extracts | §7.1 + [[Parsimony Manifest]] |
| Oracle: operational + storage + analysis + identity + adapters | §7.2 |
| Conformance suite: SHACL + SPARQL + fixtures | §8.3 |
| Regression corpus: ADCS prototype graphs certify under v0.1 | §8.3 |

### 8.2 v0.2+ roadmap

| Capability | v0.2+ work | Triggers |
|---|---|---|
| OpenAPI service | Pydantic → FastAPI | MVP service → transfer to OpenMBEE org |
| Claude skill + CLI (MVC) | RIME pattern; role-scoped skills | Operational layer is the substrate |
| SysMLv2 bidirectional I/O (`.kerml` / `.sysml.json` write) | Round-trip writer; v0.1 covers read | New work; v0.1 reads via [[SysMLv2 Ingestion Contract]] |
| Live OSLC connectors | Doors / Jama / Polarion runtime adapters | v0.1 adapter contract is the hedge |
| Community-curated qualified-auditor registry | Per [[Federated Audit and Composition]] §4.8 L3 | Adopter feedback + governance design |
| Deprecation cascade detection | Per [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] | v0.1 ships the status vocabulary; cascade reasoning is v0.2 |

### 8.3 Testing strategy

| Category | Path | Asserts |
|---|---|---|
| Unit | `tests/unit/` | Pydantic models, canonicalization, SHACL pass/fail per fixture |
| Conformance | `tests/conformance/` | Reference implementation passes the full conformance suite (§6.1–6.6) |
| Regression | `tests/regression/adcs/` | ADCS prototype corpus certifies identically (catches ontology drift) |
| OSLC roundtrip | `tests/integration/oslc-roundtrip/` | Lossless roundtrip against reference + vendor fixtures (§6.2) |
| Flexo integration | `tests/integration/flexo/` | Live Flexo transaction tests (`@pytest.mark.live`; auto-skip without `FLEXO_TOKEN`) |
| Signing | `tests/integration/sign/` | Signed-envelope profile gates (S1–S5) |
| Dereferenceable | `tests/integration/dereferenceable/` | External URI fetch + verify (U2–U4) |
| Property | `tests/property/` | Hypothesis-style: arbitrary valid graph → certify → re-verify → identical |
| Determinism | `tests/determinism/` | Bit-exact + tolerance-aware regimes (X1, X2) |

## 9. Locked decisions log

| # | Decision | ADR |
|---|---|---|
| D1 | Foundations-first approach | [[ADR-001 Foundations First Approach]] |
| D2 | SysMLv2 anchoring (OMG conformant; openCAESAR rendering) | [[ADR-002 SysMLv2 Anchoring]] |
| D4 | Quantitative certification outcome (coverage % per dimension) | [[ADR-004 Quantitative Certification Outcome]] |
| D5 | Adequacy + sufficiency as explicit `rtm:Guidance` subtypes | [[ADR-005 Adequacy and Sufficiency as Guidance Subtypes]] |
| D6 | Three-layer architecture (operational / storage / analysis) | [[ADR-006 Three-Layer Architecture]] |
| D7 | `rtm:Scope` as first-class RDF resource with composition algebra | [[ADR-007 Scope as First-Class RDF Resource]] |
| D8 | `flexo-rtm` name; org → OpenMBEE transfer at MVP service | [[ADR-008 Repo Name and Org Transfer Plan]] |
| D9 | Two-repo strategy: research wiki built first; software repo after | [[ADR-009 Two-Repo Strategy]] |
| D10 | OSLC-RM + OSLC-QM full adapters in v0.1 with lossless roundtrip tests | [[ADR-010 OSLC-RM and OSLC-QM in v0.1]] |
| D11 | Lossless criterion = A (RDFC-1.0 equivalence) + C (carry-through for vendor extensions) | [[ADR-011 Lossless Criterion A plus C]] |
| D12 | Direct RDF properties for edges (not reified); approver enforcement on Attestation | [[ADR-012 Direct RDF Properties over Reified Edges]] |
| D14 | Parsimony layer: MIREOT/SLME extracts at build time; ≤ 2000-triple target | [[ADR-014 Parsimony Layer Build-Time Extraction]] |
| D15 | GSN adoption (parsimony-extracted) for adequacy / sufficiency claims | [[ADR-015 GSN Adoption for Adequacy and Sufficiency]] |
| D16 | Profile mechanism = composable SHACL contracts | [[ADR-016 Composable SHACL Profiles]] |
| D17 | `knowledgecomplex` as `[analysis]` optional extras | [[ADR-017 knowledgecomplex as Optional Extras]] |
| D19 | Binary certification view derived from quantitative metrics (configurable threshold) | [[ADR-019 Derived Binary View from Quantitative Metrics]] |
| D22 | Three per-claim attestation subclasses ship in v0.1 (Satisfaction, Adequacy, Sufficiency) | [[ADR-021 Three Attestation Subclasses Ship in v0.1]] |
| D23 | External URI references (git+commit, content addresses, OCI digests) foundational | [[ADR-022 External URI References as Open-Source Foundation]] |
| D24 | Cryptography by composition of battle-tested standards, never invention | [[ADR-023 Cryptography by Composition of Battle-Tested Standards]] |
| D25 | Identity by thin projection of external authoritative sources, never ownership | [[ADR-024 Identity by Thin Projection of External Sources]] |
| D26 | Reproducibility is structural and local; verification federates | [[ADR-025 Reproducibility is Structural and Local]] |
| D27 | Cryptographic agility via algorithm profiles (suite-derived, not hardcoded) | [[ADR-026 Cryptographic Agility via Algorithm Profiles]] |
| D28 | Bit-exactness vs numerical tolerances are both first-class | [[ADR-027 Bit-Exactness vs Numerical Tolerances Are Both First-Class]] |
| D29 | Scope-level adequacy + sufficiency for federated audit; 3 composition attestation subclasses | [[ADR-028 Scope-Level Adequacy and Sufficiency for Federated Audit]] |
| D30 | Engineering lifecycle stages = optional scope metadata; methodology-neutral; no state machine | [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]] |
| D31 | Polycentric ASOT authority model | [[ADR-030 Polycentric ASOT Authority Model]] |
| D32 | Four-state attestation status (pass / fail / deferred / deprecated) | [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] |
| D33 | Methodology agnosticism as foundational axiom | [[ADR-032 Methodology Agnosticism as Foundational Axiom]] |
| D34 | Generalized ASOT principle — every identified thing has an ASOT held by an external entity; `flexo-rtm` never owns, authenticates, gatekeeps, proxies, caches, or bypasses dereferencing | [[ADR-033 Generalized ASOT Principle for All Identified Things]] |
