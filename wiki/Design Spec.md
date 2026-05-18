<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# `flexo-rtm` — Design Spec

> **Status:** Canonical design spec for `flexo-rtm`. This is the single source of truth from which all other wiki pages are derived or which they elaborate. Updates land here first; downstream pages reference back via [[Design Spec]]. **The spec's §9.A defines binary acceptance criteria — those criteria are normative; everything else in this wiki is explanatory.**

**Date:** 2026-05-16
**Status:** Design (pre-implementation)
**Author:** Michael Zargham
**Reviewer:** Michael Zargham
**Brainstorming session:** Claude Code (this spec is its terminal artifact)

---

## 1. Mission

A verifiable self-certification protocol for bidirectional requirements traceability of SysMLv2 models, anchored in open source, self-hostable on Flexo, with explicit lossless I/O paths to OSLC-based RM systems (Doors, Jama, Polarion, and others). The oracle proves that a model satisfies forward + backward traceability — or pinpoints the gaps from graph structure — and emits a layered, replayable certification artifact (transcript → attestation graph → audit report).

**Polycentric institutional topology.** `flexo-rtm` is designed around the institutional reality of mission- and safety-critical systems engineering: multiple organizations (engineering teams, prime contractors, subsystem suppliers, regulatory authorities, qualified auditors) hold **scoped authorities** over different parts of the system. The data model reflects this directly — each [`rtm:Scope`](§5.3) is a named graph functioning as an **Authoritative Source of Truth (ASOT)** for its content, with traceability, versioning, and accountable change control. Scopes compose into higher-order scopes and may overlap; the institutional arrangement is **polycentric**, not centralized. This follows the [Modular Open Systems Approach (MOSA)](https://www.cto.mil/sea/mosa/) principle of modular, loosely-coupled authorities with well-defined interfaces ([10 U.S.C. §4401](https://www.law.cornell.edu/uscode/text/10/4401); [DoD MOSA Implementation Guidebook, 2025](https://www.cto.mil/wp-content/uploads/2025/03/MOSA-Implementation-Guidebook-27Feb2025-Cleared.pdf); see also [DAU Glossary: Authoritative Source of Truth](https://www.dau.edu/glossary/authoritative-source-truth) and [OMG MBSE Wiki: ASOT](https://www.omgwiki.org/MBSE/doku.php?id=mbse:authoritative_source_of_truth)).

`flexo-rtm` complements today's incumbent RM tools rather than competing with them. It supplies three properties their proprietary stacks don't yet deliver natively — **verifiable certification-by-construction** (canonical hashes + replayable transcripts), **open data portability** (RDF + lossless OSLC roundtrip), and **federable verification across scoped ASOTs** (any party with adequate permissions can re-check the facts in their scope without proprietary access; see §4.4 and §4.9). These properties benefit adopters whether they keep using their existing tools, run `flexo-rtm` standalone, or rely on a vendor or hosting partner that supports the open standard. The incumbents themselves can serve as credible-counterparty auditors and hosts atop the standard, holding their own scoped authorities in the composition; cooperation across multiple ASOTs, not displacement of any one of them, is the intended posture.

**Scope discipline.** `flexo-rtm` v0.1 ships **traditional bidirectional traceability** as the primary analysis (forward and backward structural traces with coverage statistics, in the form Doors/Jama/OSLC practitioners recognize) plus **named-approver attestation infrastructure for three claim types** (satisfaction, adequacy, sufficiency). The ADCS regression corpus already uses adequacy and sufficiency attestations; v0.1 supports them as first-class.

**The git+RDF foundation (foundational, not cosmetic).** Evidence, models, and activities in `flexo-rtm` are RDF entities that **reference concepts outside the RDF graph via URI** — git repositories + commit hashes, content-addressed data (sha256 / IPFS), OCI image digests for infrastructure-as-code. These external URIs are the source of true open-source interoperability, portability, auditability, and reproducibility. The RDF graph is not a closed world; it anchors to immutable external references that anyone can fetch, hash-verify, and re-execute without depending on any proprietary system. v0.1 specifies the vocabulary and SHACL discipline for these references; the ADCS prototype already operates this way.

**Cryptography by composition, not invention.** Where signing matters — approver binding to commits, attestation integrity, activity provenance, transcript signing, container trust — `flexo-rtm` composes **battle-tested standardized tools**: git GPG/SSH commit signing, W3C Verifiable Credentials + Data Integrity proofs, DSSE / in-toto attestation envelopes, Sigstore (cosign) for keyless signing and transparency logs, and OCI image signature standards. v0.1 ships vocabulary support for these signing artifacts and profile-gated requirements for them; we do **not** roll our own crypto. The ADCS prototype flagged signed envelopes as deferred — `flexo-rtm` v0.1 closes that gap by specifying the integration surfaces (§4.6).

**Identity by thin projection, not ownership.** Named approvers (§4.3) are IRIs referencing identities owned by external authoritative systems — institutional SSO (OIDC, SAML), LDAP/Active Directory, GitHub/GitLab, etc. `flexo-rtm` does **not** authenticate users or store credentials. Instead, it carries thin RDF projections of identities and their attached policies (role-based, attribute-based, scope-based primitives — configurable). These projections exist at a single bottlenecked boundary so SPARQL/SHACL can enforce policies and certify that enforcement happened. The ADCS prototype hard-coded GitHub IDs; v0.1 specifies the integration surface so adopters wire their institutional identity provider (§4.4).

**Local reproducibility, federated verification.** The cert artifact is **structurally complete** — every fact in it carries the local references (RDF neighborhood, external URIs, projection-at-time, signatures) needed to reproduce that fact in isolation. Verification is **local** in the traceability graph: a reviewer with permissions for safety-aspect facts can re-execute safety-aspect claims without access to confidential-design data; an external regulator can verify structural integrity without dereferencing classified payloads. Reproduction **federates** — computationally (compute distributes across reproducing parties) and organizationally (different parties verify different permission slices, composing to a complete audit). No single party requires universal access for the audit to be complete. This is what makes the certification verifiable in open multi-party institutional contexts.

The **topological framework** — closed assurance triangles as audit gate, recursive completeness checks, V−F-type invariants, TDA — is a **related research line, not `flexo-rtm`'s destination** (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]). Further research determined that purely numerical invariants like V−F ≤ 1 are not sufficient for a rigorous topological audit. A proper topological audit requires that every artifact used as evidence have its own assurance triangle, with the supporting guidance and specifications themselves fit-for-purpose. This creates a recursion that terminates only via a community-curated registry of pre-approved artifact types, specifications, and guidance — a major scope commitment internal to the topological research line. `flexo-rtm` is methodology-agnostic and does not commit to that resolution; if the research line matures, the resulting audit operates as one optional downstream-analysis mode on top of `flexo-rtm`'s data (among several plausible ones: SLSA, GSN, ARP4754A, in-house).

The distinction: v0.1 captures named-approver attestations of all three kinds (satisfaction, adequacy, sufficiency), reports coverage and gaps for each, and uses SHACL to enforce accountability. v0.1 does **not** check triangle closure or run recursive completeness audits over those attestations — those are problems in the topological research line, not `flexo-rtm` features deferred from v0.1.

`flexo-rtm-research/` documents the topological framework as a related research line: the vision, the recursive completeness condition, the registry concept, open questions, and the substantial additional work required to reduce it to practice. The attestations that v0.1 collects are independently meaningful as `flexo-rtm`'s named-approver discipline; they are also forward-compatible as named-approver-bearing inputs to any downstream analysis (topological or otherwise) an adopter may choose to run.

## 2. Two-repo strategy

| Repo | Purpose | Status | Built from |
|---|---|---|---|
| `flexo-rtm-research` | Obsidian-style markdown vault. Full design documentation, decision justifications, internal/external research synthesis, INCOSE IS 2026 alignment, conflict-resolution policy mapping. Reviewable artifact. | Built **first** | This design spec |
| `flexo-rtm` | Standards + software repo. Ontology, formal spec, oracle code, conformance suite, OSLC adapters, regression corpus. | Built **second** | `flexo-rtm-research` after in-depth review |

Both repos start in user's org; transfer to OpenMBEE at MVP service milestone.

`flexo-rtm-research` is modeled structurally after `flexo-conflict-resolution-policy-research` (Obsidian vault, interconnected markdown, mermaid diagrams, mathematical notation where appropriate).

## 3. Scope-reducing assumption

**The modeled system is a SysMLv2 model conformant with OMG specifications.** The ontology assumes `omg-sysml:` IRIs (openCAESAR OWL rendering) are dereferenceable as the canonical model vocabulary. Requirements, evidence, and attestations are structured around SysMLv2 elements.

## 4. Certification model

`flexo-rtm` v0.1's certification model is **traditional bidirectional traceability** (§4.1) plus named-approver attestation infrastructure (§4.3). The topological framework (Zargham 2026's typed simplicial complex framing applied to RTM) is **a related research line, not `flexo-rtm`'s destination** (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]); §4.10 frames the relationship and points to `flexo-rtm-research/Topological Framework Future Work.md` for the research-line documentation (registry concept, recursion challenge, open questions).

| Capability | v0.1 status | Where it lives |
|---|---|---|
| Traditional bidirectional traceability + coverage stats | **In scope** (primary surface) | §4.1 |
| Attestation vocabulary with named-approver SHACL enforcement | **In scope** (independently valuable for accountability) | §4.3 |
| Ontology vocabulary for Guidance / AdequacyCriteria / SufficiencyCriteria / Aspect | **In scope** (terms available; aligned with the topological research line as forward-compatible interop per [[ADR-020 Vocabulary Alignment with Zargham 2026]]) | §4.2 |
| Assurance triangles as audit primitive | Not in `flexo-rtm` — research-line problem | topological research line (§4.10) |
| Topological invariants (V−F, etc.) | Not in `flexo-rtm` — research-line problem (further research determined numerical check alone insufficient) | topological research line (§4.10) |
| Recursive completeness audit + registry of pre-approved types | Not in `flexo-rtm` — research-line problem | topological research line (§4.10) |
| Persistent homology / TDA | Not in `flexo-rtm` — research-line problem | topological research line (§4.10) |

§4.1 specifies the v0.1 primary surface. §4.2 documents the vocabulary `flexo-rtm` carries that aligns with the topological research line as forward-compatible interop. The vocabulary is included so adopters can begin tagging adequacy/sufficiency criteria and recording named-approver attestations now; the data is then consumable by any downstream-analysis path the adopter chooses to run (topological or otherwise — SLSA, GSN, ARP4754A, in-house).

### 4.1 Traditional bidirectional traceability (v0.1 primary)

**Minimal vocabulary** for v0.1 traditional bidirectional analysis (the bare RTM kernel):

- `rtm:Requirement` — a stated requirement
- `rtm:Artifact` — evidence (a SysMLv2 model element, a proof script, a simulation result, a test report, …)
- `rtm:satisfies` (Artifact → Requirement) — verification edge: "this artifact claims to satisfy this requirement"

**Forward traceability analysis.** For each $r \in R$, enumerate $\{a \in A : a \texttt{ rtm:satisfies } r\}$. A requirement is *forward-covered* if this set is non-empty.

**Backward traceability analysis.** For each $a \in A$, enumerate $\{r \in R : a \texttt{ rtm:satisfies } r\}$. An artifact is *backward-traced* if this set is non-empty.

**Coverage statistics** (v0.1 traditional analysis):

- Forward coverage $\% = |\{r \in R : r \text{ forward-covered}\}| \,/\, |R|$
- Backward coverage $\% = |\{a \in A : a \text{ backward-traced}\}| \,/\, |A|$

**Traditional gap codes:**

| Code | Meaning | Source |
|---|---|---|
| `T1.orphan-requirement` | $r \in R$ with no incoming `rtm:satisfies` edge | forward |
| `T2.dangling-evidence` | $a \in A$ with no outgoing `rtm:satisfies` edge | backward |

**Basic certification predicate.** A graph passes basic certification at scope S iff (subject to configurable thresholds):

- Forward coverage $\% \geq \theta_\text{forward}$ (default 100%)
- Backward coverage $\% \geq \theta_\text{backward}$ (default 100%)

This is the analysis Doors/Jama/OSLC users recognize. It works directly against the OSLC-RM adapter's output. The oracle's `certify --level=basic` produces only this analysis: SPARQL-driven, fast, familiar, no commitment to Guidance vertices or attestation structure.

**v0.1's traditional analysis is independently useful.** A team already running Doors, Jama, Polarion, or any other RM tool can produce traceability reports using only v0.1's bidirectional analysis — pulled from their existing data via the OSLC adapter — without ever committing to the topological framework. The reports look like the RTM tables they already use, with cleaner provenance via the transcript and the option to add reproducibility audits via [[Federated Audit and Composition]].

### 4.2 Vocabulary aligned with the topological research line (forward-compatible interop)

`flexo-rtm` v0.1 ships ontology vocabulary aligned with the topological research line per [[ADR-020 Vocabulary Alignment with Zargham 2026]]. Per [[ADR-032 Methodology Agnosticism as Foundational Axiom]], this alignment is **forward-compatible interop for one optional downstream-analysis path among several** (topological, SLSA, GSN, ARP4754A, in-house) — not a commitment that the topological framework is `flexo-rtm`'s eventual destination. The vocabulary is independently useful for traditional traceability; adopters who later choose to run topological or other downstream analysis can do so without translation, and adopters who never do are unaffected.

**v0.1 usage rules (MAY vs MUST):**

- `rtm:Guidance`, `rtm:AdequacyCriteria`, `rtm:SufficiencyCriteria` instances **MAY** be present in the RDF graph (per ADCS regression compatibility).
- The oracle **MUST** parse these terms and accept attestations that reference them (per §4.3 attestation subject bindings).
- The oracle **MUST NOT** validate that guidance content is itself fit-for-purpose. Recursive completeness is a problem in the topological research line (§4.10), not a `flexo-rtm` feature.
- T1–T8 gap codes (§4.7) do **not** depend on guidance validation. G3–G9 (topology-line gap codes — meaningful only if an adopter runs the topological audit as a downstream-analysis mode) do.
- The `rtm:Attestation` subclasses (`SatisfactionAttestation`, `AdequacyAttestation`, `SufficiencyAttestation` per §4.3) **MAY** reference Guidance vertices but v0.1's audit does not require closed assurance triangles.

| Class | Purpose |
|---|---|
| `rtm:Requirement` | a stated requirement (already used in §4.1) |
| `rtm:Artifact` | evidence (already used in §4.1) |
| `rtm:Guidance` (abstract) | rubric or acceptance criteria; specializes into the two flavors below |
| `rtm:AdequacyCriteria` | concerns the **model** — is the SysMLv2 representation fit for the kind of claim being made? |
| `rtm:SufficiencyCriteria` | concerns the **evidence** — does the evidence support the claim strongly enough? |
| `rtm:Attestation` | a named-human attestation; mandatory `rtm:approvedBy <IRI>` |
| `rtm:Aspect` (abstract) | aspect tag — `rtm:functional`, `rtm:performance`, `rtm:safety`, … (extensible) |

These vocabulary terms ship in the core ontology with associated SHACL shapes for well-formedness (e.g., `rtm:Attestation` requires `rtm:approvedBy` with `sh:nodeKind sh:IRI` and `sh:minCount 1` — accountability-by-construction). The shapes do **not** require triangle closure, V−F invariants, or any other topological audit gate; those would belong to a topological downstream-analysis mode (§4.10), not to `flexo-rtm`.

### 4.3 Attestation infrastructure (named-approver accountability for three claim types)

v0.1 ships structurally enforced named-approver accountability for three kinds of attestation. These are independent assertions — each has its own subject and named approver. They do NOT require the topological framework's assurance triangle closure or recursive completeness; those checks belong to the topological research line (§4.10), which is not `flexo-rtm`'s destination — they would operate as one possible downstream analysis on the attestation data if the research line matures.

**Three attestation subclasses:**

| Class | Subject | Asserts |
|---|---|---|
| `rtm:SatisfactionAttestation` | an `rtm:satisfies` triple | "this artifact satisfies this requirement" — named human approves |
| `rtm:AdequacyAttestation` | an artifact + requirement (typically tied to coupling via `rtm:AdequacyCriteria` guidance) | "the model representation is adequate for the kind of claim made about this requirement" — named human approves |
| `rtm:SufficiencyAttestation` | an artifact + requirement (typically tied to coupling via `rtm:SufficiencyCriteria` guidance) | "the evidence is sufficient to support the claim about this requirement" — named human approves |

All three are `rdfs:subClassOf rtm:Attestation` and share:

- `rtm:approvedBy` (IRI) — REQUIRED (SHACL-enforced)
- `earl:result` — passed / failed / inapplicable / cantTell
- `prov:wasGeneratedBy`, `prov:atTime`, `prov:wasAssociatedWith` — provenance
- Optional aspect tag (`rtm:hasAspect`) for per-aspect attestation

**Schema-enforced named-approver requirement:**
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

The shape applies to the parent class and all subclasses. SHACL rejects any attestation of any kind without an approver IRI at write time.

**Optional shapes (off by default in v0.1; profile-toggle):**
- `attested-satisfies` profile — every `rtm:satisfies` triple must have a corresponding `rtm:SatisfactionAttestation`
- `attested-adequacy` profile — every `rtm:satisfies` triple must additionally have an `rtm:AdequacyAttestation` for the artifact's adequacy
- `attested-sufficiency` profile — same for sufficiency

Adopters compose these profiles as their workflow matures.

**Git commit binding:** pre-commit hook verifies the committer matches the `rtm:approvedBy` IRI for any new attestation triple; GitHub Actions re-checks at PR time. Applies to all three attestation subclasses.

**Relationship to the topological research line:** per [[ADR-032 Methodology Agnosticism as Foundational Axiom]], the topological framework is a separate research line, not `flexo-rtm`'s destination. These typed attestations are independently meaningful as `flexo-rtm`'s named-signer accountability primitive. An adopter who chooses to run topological analysis as a downstream-analysis mode can read them as inputs to closed-triangle audits — but the same data is equally consumable by other downstream-analysis paths (SLSA, GSN, ARP4754A, in-house). `flexo-rtm` itself does NOT check "is the guidance itself fit-for-purpose?" — recursive completeness is an open problem in the topological research line, independent of `flexo-rtm`.

The attestation graph is part of the v0.1 certification artifact (§4.8).

### 4.4 Identity boundaries — thin projections of external authoritative sources

`flexo-rtm` does not own identity. Named approvers (per §4.3) are IRIs that reference identities managed by external systems — institutional SSO (OIDC, SAML), LDAP/Active Directory, GitHub/GitLab, or any other authoritative identity provider. Same composition principle as cryptography (§4.6): integrate with established standards, never invent.

**The boundary discipline:**

- **Source of truth lives outside.** Employee records, role assignments, group memberships, attribute claims (clearance, certification status, training) live in the institutional identity provider — not in `flexo-rtm`.
- **Thin projections live inside.** `flexo-rtm` carries just enough RDF projection of identities and policies to support SHACL/SPARQL validation and certify that policies were enforced. The projection is forensic, not authoritative.
- **One bottleneck.** All identity references in the RDF go through typed primitives (`rtm:approvedBy`, `rtm:hasExternalIdentity`). This bottleneck is what makes scope/role/attribute policies enforceable.
- **Configurable per institution.** Adopters wire their identity provider via a thin adapter; v0.1 ships reference adapters and the adapter contract is documented.

**Identity projection vocabulary:**

```turtle
:engineer-zargham a foaf:Person ;
    rtm:hasExternalIdentity "github:zargham" ,
                            "oidc:https://auth.example.org/zargham" ;
    foaf:name "Michael Zargham" ;
    org:hasMembership :membership-1 .

:membership-1 a org:Membership ;
    org:role rtm:role/safety-engineer ;
    org:organization :org-1 ;
    rtm:hasAttribute :attr-clearance-secret ;
    rtm:scopedTo rtm:scope/adcs-program .

:attr-clearance-secret a rtm:Attribute ;
    rtm:attributeKey "security-clearance" ;
    rtm:attributeValue "SECRET" .
```

The projection composes W3C FOAF + W3C Org Ontology + custom `rtm:` extensions for external-identity bindings, attributes, and scope assignments. No novel identity ontology — we use established W3C vocabularies for what they cover, and add `rtm:` only at the integration seams.

**Policy primitives (three configurable kinds; combinable):**

| Kind | Description | Example |
|---|---|---|
| **Role-based (RBAC)** | Authority attached to roles; identities have roles via `org:Membership` | `rtm:role/safety-engineer` is authorized to attest `rtm:SufficiencyAttestation` for `rtm:safety` aspect |
| **Attribute-based (ABAC)** | Authority gated on attribute values | `rtm:hasAttribute` with `rtm:attributeKey = "security-clearance"` and value ≥ `"SECRET"` to attest classified-data sufficiency |
| **Scope-based** | Authority limited to specific `rtm:Scope` IRIs (per §5.3) | Approver authorized only for `rtm:scope/adcs-attitude-control` and its sub-scopes |

All three are SPARQL-evaluable against the identity projection. Policies are themselves RDF resources (`rtm:Policy` instances) — versioned, scoped, queryable, certifiable.

**Policy vocabulary:**

```turtle
:policy-safety-attestation a rtm:Policy ;
    rtm:appliesToRole rtm:role/safety-engineer ;
    rtm:requiresAttribute [
        rtm:attributeKey "security-clearance" ;
        rtm:attributeMinValue "CONFIDENTIAL"
    ] ;
    rtm:permitsAttestationType rtm:SufficiencyAttestation ;
    rtm:permitsAspect rtm:safety ;
    rtm:withinScope rtm:scope/adcs-program .
```

A policy says: "an identity with this role, satisfying these attribute predicates, may emit these attestation types for these aspects within these scopes."

**SHACL enforcement (the bottleneck):**

When a new attestation is written, a SHACL constraint evaluates the applicable policies via SPARQL. The constraint rejects attestations whose approver does not match any authorizing policy under the active configuration. Pseudocode shape:

```turtle
rtm:AttestationAuthorizationShape a sh:NodeShape ;
    sh:targetClass rtm:Attestation ;
    sh:sparql [
        sh:select """
            SELECT $this WHERE {
                $this rtm:approvedBy ?approver ;
                      a ?attestationType ;
                      rtm:hasAspect ?aspect ;
                      rtm:appliesTo ?subject .
                ?subject rtm:inScope ?scope .

                # Reject if no authorizing policy exists
                FILTER NOT EXISTS {
                    ?policy a rtm:Policy ;
                            rtm:permitsAttestationType ?attestationType ;
                            rtm:permitsAspect ?aspect ;
                            rtm:withinScope ?scope .
                    ?approver org:hasMembership/org:role ?policy_role .
                    ?policy rtm:appliesToRole ?policy_role .
                    # ... attribute checks
                }
            }
        """ ;
        sh:message "Approver not authorized for this attestation under current policy"
    ] .
```

**External identity provider integration (reference adapters in v0.1):**

| Provider | Adapter pattern |
|---|---|
| **GitHub** (ADCS prototype's approach) | GitHub user → `foaf:Person` with `rtm:hasExternalIdentity "github:<handle>"`; org membership via GitHub Teams → `org:Membership`; refresh policy on cert run or push |
| **Generic OIDC** | OIDC claims (sub, email, groups, custom claims) → identity projection; group claims → roles; custom claims → attributes |
| **GitHub Actions OIDC** (CI keyless signing) | Ephemeral identity from Fulcio token claims → projection scoped to the workflow run |

Adopters extend by writing thin adapters for SAML, LDAP/AD, Okta, Auth0, Keycloak, etc. — anything that exposes identity claims can be projected.

**Refresh policy:** projections are point-in-time. Adopters choose: refresh on every cert run (always current; high cost), refresh on commit (current at attestation time), refresh on schedule (stable but may drift), or static (test/audit scenarios). The transcript records the projection-as-of-cert-time so audit re-runs are reproducible.

**Reproducibility is structural and local, not global. Refresh and reproducibility are complementary, not in tension.**

The identity projection has two operational roles, and they compose cleanly:

1. **Authoring-time enforcement** (operational layer): when an engineer commits an attestation, the projection-at-that-moment determines policy authorization. Once the commit lands, the result is structurally captured — the SHACL gate evaluated, recorded the outcome, and the projection-as-of-cert-time is in the transcript.
2. **Audit-time reproduction** (analysis layer): anyone with **adequate local permissions** for the facts they want to verify can re-execute the recorded steps and confirm. Reproduction is **local in the traceability graph** — verifying a single attestation does not require re-dereferencing the whole graph or the whole projection.

**Locality of reproduction.** Each fact in the cert artifact (an attestation, an activity, an artifact reference) is **structurally complete for its own context** — the RDF contains the references, the external URIs are dereferenceable, and the projection-at-time is recorded. A reproducing party only needs access to the facts they want to verify, not universal access.

**Federation of reproduction.** Because reproduction is local, it composes:
- **Computationally federated** — different reproducing parties run different subsets of the verification (one verifies a subsystem's simulations; another verifies the same subsystem's safety attestations; a third verifies cross-subsystem traces). Their results compose to a complete audit without any single party owning all compute.
- **Organizationally federated** — different parties have different permission scopes. A safety team can re-verify safety-aspect facts without access to confidential-design facts; an external regulator can verify the audit trail's structural completeness without ever decrypting sensitive payloads. The graph + external URIs are structured so that each party's local verification stands on its own.

**Refresh policy is a freshness/cost trade-off, not a reproducibility hazard.** Adopters who want stronger non-repudiation choose static projection + signed-envelopes profiles. Adopters who want always-current authorization choose refresh-every-cert. Both paths produce structurally-complete artifacts because the projection-at-cert-time is in the transcript, and reproduction is local to each verified fact.

Future revocation semantics (defeaters / SACM-style attestation invalidation) are out of v0.1 scope but would be additive — a revocation event would propagate as a new attestation, locally verifiable, without invalidating the structural completeness of past artifacts.

**What v0.1 ships:**

- Vocabulary: `rtm:hasExternalIdentity`, `rtm:Attribute`, `rtm:scopedTo`, `rtm:Policy`, `rtm:appliesToRole`, `rtm:requiresAttribute`, `rtm:permitsAttestationType`, `rtm:permitsAspect`, `rtm:withinScope`
- SHACL policy-enforcement shapes (the bottleneck)
- Reference adapters: GitHub, generic OIDC, GitHub Actions OIDC
- Adapter contract documentation
- Refresh-policy options + transcript provenance for projections

**What v0.1 does NOT do:**

- Does not authenticate users (relies on external providers)
- Does not store credentials, passwords, tokens
- Does not implement RBAC/ABAC engines beyond SPARQL evaluation (no XACML; no OPA/Rego; just SPARQL because the policies are RDF)
- Does not synchronize projection state in real time (point-in-time; adopters configure refresh)
- Does not arbitrate identity provider conflicts (single provider per adopter; multi-provider is adopter responsibility)

**Forward compatibility:** per [[ADR-032 Methodology Agnosticism as Foundational Axiom]], the identity primitives in this section are methodology-neutral. Any downstream-analysis path that needs named-human authority evaluation — including the topological research line, SLSA, GSN, ARP4754A, or in-house analyses — reads the same SPARQL-evaluable policies against the same projection. The identity discipline is part of what `flexo-rtm` IS, not a hook for any specific downstream methodology.

### 4.5 External URI references — the git+RDF foundation

Evidence, models, and activities in `flexo-rtm` are RDF entities that reference concepts outside the RDF graph via URI. This is the load-bearing mechanism for open-source interoperability, portability, auditability, and reproducibility — not a cosmetic feature. The ADCS prototype already operates this way (Docker compute backend emits `prov:atLocation`, `prov:wasAssociatedWith`, `prov:startedAtTime`); v0.1 formalizes the pattern and adds SHACL discipline.

**Entity classes that bear external URI references:**

- `rtm:Activity` (subclass of `prov:Activity`) — a process: simulation run, model build, test execution, proof check, data import
- `rtm:Artifact` (subclass of `prov:Entity`) — an addressable artifact: model file, evidence file, simulation result, test output, dataset

**Reference vocabulary (v0.1, in `ontology/core/`):**

| Property | Range | Purpose |
|---|---|---|
| `rtm:hasGitRepo` | xsd:anyURI | Git repository URL (e.g., `https://github.com/org/repo`) |
| `rtm:hasGitCommit` | xsd:string | Full commit SHA (immutable reference to a point in history) |
| `rtm:hasGitPath` | xsd:string | Optional path within the repo (file or directory) |
| `rtm:hasContentHash` | xsd:string | Content hash with algorithm prefix (e.g., `sha256:abc...`); canonical content addressing |
| `rtm:hasOCIImage` | xsd:string | OCI image reference with digest (e.g., `registry/image@sha256:digest`); points to the exact image used |
| `dcat:downloadURL` | xsd:anyURI | Optional fetch URL for any artifact (mirror, raw-content URL, IPFS gateway) |

Plus standard PROV-O: `prov:wasDerivedFrom`, `prov:used`, `prov:wasGeneratedBy`, `prov:atLocation`, `prov:hadPlan`, `prov:startedAtTime`, `prov:wasAssociatedWith`.

**Typical patterns:**

```turtle
:simulation-run-2026-05-16-001 a rtm:Activity ;
    prov:startedAtTime "2026-05-16T14:30:00Z"^^xsd:dateTime ;
    rtm:hasGitRepo <https://github.com/org/adcs-sim> ;
    rtm:hasGitCommit "abc123def456..." ;
    rtm:hasGitPath "scripts/slew_maneuver.py" ;
    rtm:hasOCIImage "ghcr.io/org/adcs-sim@sha256:def789..." ;
    prov:used :input-dataset-orbit-params ;
    prov:wasAssociatedWith :engineer-zargham .

:input-dataset-orbit-params a rtm:Artifact ;
    rtm:hasContentHash "sha256:abc987..." ;
    dcat:downloadURL <https://data.example/orbit-params-2026.csv> .

:simulation-result-001 a rtm:Artifact ;
    rtm:hasContentHash "sha256:xyz123..." ;
    prov:wasGeneratedBy :simulation-run-2026-05-16-001 .
```

**SHACL discipline (v0.1, in `ontology/shapes/`):**

- `rtm:Activity` SHOULD have at least one of `rtm:hasGitCommit` or `rtm:hasOCIImage` (poor reproducibility otherwise — warning, not error in v0.1 default)
- `rtm:Artifact` with `prov:wasGeneratedBy <activity>` MUST be traceable to the activity's git/OCI references (the activity's source is the artifact's lineage)
- Optional profile `--profile=strict-provenance` upgrades these from warnings to errors

**Why these references are foundational:**

| Property | What it enables |
|---|---|
| **Reproducibility** | Anyone can fetch the git repo at the commit hash, the data at the content hash, the Docker image at the digest, and re-run the activity. Without these references, the RDF is metadata without anchoring. |
| **Auditability** | External URIs are immutable. A third party can verify the inputs match the claims by computing content hashes. The chain of evidence extends outside the RDF and is independently verifiable. |
| **Portability** | Git URIs, sha256 content addresses, and OCI digests are open standards. No proprietary system can lock the references. The same RDF graph can be consumed by any compliant tool. |
| **Interoperability** | Different tools (DVC, Datalad, IPFS, Nix, OCI registries, git-LFS) can resolve the same URIs via their native protocols. `flexo-rtm` doesn't dictate a single fetching mechanism. |

**Co-versioning with the storage layer:**

When the operational layer commits an attestation, the underlying activity's git refs and Docker digests are captured in the same atomic transaction. The git working tree's HEAD commit becomes part of the certification's reproducibility chain. Model evolution + traceability evolution + execution environment all version together.

**Relationship to the certification artifact:**

- The **transcript** (§4.8) records the external URIs that were referenced during the cert run, alongside the SPARQL+SHACL execution log
- The **attestation graph** carries activities with their git/OCI references
- The **audit report** can include a "reproducibility manifest" listing every external URI the cert depends on
- A third party with (canonical input + transcript + external URIs) can re-run **from scratch** — fetch the code, fetch the data, fetch the container, execute, hash-compare results to the recorded result hashes

This is what makes the certification **verifiable beyond the RDF graph itself** — the RDF references the world, and the world is open-source and content-addressable.

### 4.6 Signed envelopes — composing battle-tested cryptographic standards

`flexo-rtm` does not invent cryptography. Where signing matters, we compose established standards. The ADCS prototype flagged signed envelopes as deferred (bare SHA-256 hashes only); v0.1 closes that gap by specifying the integration surfaces.

**Principle: don't roll our own crypto.** Cryptography is a deep specialty. The right move is to compose battle-tested primitives — git GPG/SSH signing, W3C Data Integrity, DSSE + in-toto, Sigstore — and never invent envelope formats, key management, or transparency logs.

**Integration surfaces (v0.1):**

| Concern | Standard | Integration |
|---|---|---|
| Approver binding to git commit | **Git GPG / SSH commit signing** (`gpg.format = ssh` since git 2.34) | Pre-commit hook + GitHub Actions verify the signature key matches the IRI dereferenced from `rtm:approvedBy` (e.g., to a `foaf:Person` with a published key fingerprint) |
| RDF integrity of attestations | **W3C Verifiable Credentials + Data Integrity** (DI proofs) | `rtm:Attestation` MAY carry `sec:proof` — RDF Dataset Canonicalization + ECDSA/EdDSA. Attestation expressible as VC-DM 2.0 with `flexo-rtm`-typed credential subjects |
| Activity attestation envelopes | **DSSE + in-toto attestation predicates** | When an activity emits a claim about an artifact (build/test/sim provenance), wrap in DSSE envelope with in-toto predicate type. `rtm:Activity` can reference a DSSE-enveloped attestation via `rtm:dsseEnvelope` |
| Container image trust | **Sigstore cosign / OCI image signatures** | OCI digest in `rtm:hasOCIImage` (§4.5) can be cosign-verified by consumers; optional `rtm:cosignBundle` carries the signature bundle |
| Transparency / non-repudiation | **Sigstore Rekor transparency log** | Optional: attestations land in Rekor; the public Rekor log entry IRI is referenced via `rtm:rekorLogEntry` |
| Keyless signing (CI-driven) | **Sigstore keyless** (OIDC-bound ephemeral keys) | GitHub Actions workflows can keyless-sign attestations and activity envelopes; Fulcio binds the OIDC identity to the signature |

**Vocabulary (v0.1, in `ontology/core/`):**

| Property | Range | Purpose |
|---|---|---|
| `sec:proof` | DI proof object | Data Integrity proof on RDF graphs (W3C standard) |
| `rtm:dsseEnvelope` | xsd:anyURI or inline | Reference to a DSSE-enveloped in-toto attestation about an activity |
| `rtm:cosignBundle` | xsd:anyURI or inline | Cosign signature bundle for an OCI image referenced via `rtm:hasOCIImage` |
| `rtm:rekorLogEntry` | xsd:anyURI | Pointer to a Sigstore Rekor transparency-log entry |
| `rtm:commitSignatureRequired` | xsd:boolean | Attestation declares its git commit must carry a valid GPG/SSH signature |

The `sec:` namespace is W3C Security Vocabulary (used by VC-DI). The other terms are `flexo-rtm` glue around external standards — they wrap, they don't replace.

**Optional SHACL profiles** (composable; off by default):

- `signed-commits` — every attestation triple must originate from a GPG/SSH-signed git commit; verified at pre-commit hook + GitHub Actions
- `data-integrity-attestations` — every `rtm:Attestation` must carry a valid `sec:proof`
- `dsse-activities` — every `rtm:Activity` that emits attestations must reference a DSSE-enveloped in-toto attestation
- `cosign-images` — every `rtm:hasOCIImage` reference must carry a verifying `rtm:cosignBundle`
- `rekor-transparency` — every attestation must have a corresponding Rekor log entry

**What we DO NOT do:**

- No custom crypto schemes — exclusively use W3C / Sigstore / OpenSSF / git-native standards
- No custom envelope formats — DSSE wraps payloads; VC-DI wraps RDF
- No custom transparency logs — use Rekor when transparency is wanted
- No custom key management — adopt the host system's: gnupg, ssh-agent, cosign, GitHub OIDC, cloud KMS

**Why each standard fits:**

- **Git signing** is universally available and integrates with the operational-layer commit workflow without any extra tooling
- **W3C Data Integrity** is RDF-native — proofs attach to the graph without leaving the data model
- **DSSE + in-toto** is the supply-chain attestation standard (SLSA, Trivy, BuildKit, Bazel, Conan all converge on it); reusing it makes `flexo-rtm` interop with the broader software-supply-chain ecosystem
- **Sigstore** provides keyless signing tied to OIDC identities — eliminates the key-management burden for CI workflows
- **OCI image signatures** are the de facto standard for container trust; cosign and notary are the dominant implementations

**Forward compatibility with downstream-analysis paths:** the standards stack above is methodology-neutral; any downstream-analysis path that needs signed evidence can read it. If an adopter chooses to run topological analysis as a downstream-analysis mode (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]), closed-face inputs compose naturally — a closed face has a signed validation edge with a signed approver attestation referencing signed activities producing content-hashed artifacts in signed containers. The same data is equally consumable by other downstream-analysis paths (SLSA — which uses the same DSSE + in-toto stack natively — GSN, ARP4754A, in-house).

### 4.7 Gap taxonomy

v0.1 reports the following gap codes:

| Code | Meaning | Detection |
|---|---|---|
| `T1.orphan-requirement` | `r ∈ R` with no incoming `rtm:satisfies` edge | v0.1 forward analysis |
| `T2.dangling-evidence` | `a ∈ A` with no outgoing `rtm:satisfies` edge | v0.1 backward analysis |
| `T3.unattested-satisfaction` | `rtm:satisfies` triple with no `rtm:SatisfactionAttestation` (only when `attested-satisfies` profile is active) | Attestation infrastructure |
| `T4.unattested-adequacy` | `rtm:satisfies` triple without `rtm:AdequacyAttestation` for the artifact (only when `attested-adequacy` profile is active) | Attestation infrastructure |
| `T5.unattested-sufficiency` | `rtm:satisfies` triple without `rtm:SufficiencyAttestation` for the artifact (only when `attested-sufficiency` profile is active) | Attestation infrastructure |
| `T6.failed-attestation` | An attestation of any kind with `earl:result earl:failed` | Attestation review |
| `T7.unapproved-attestation` | Attestation without `rtm:approvedBy` IRI | **Cannot exist** — SHACL rejects at write |
| `T8.aspect-uncovered` | A multi-aspect requirement has satisfaction attestation but is missing attestation for one or more declared aspects | Per-aspect rollup |

`T7` is structurally absent — SHACL gates at write time. This is the "by construction" mechanism for accountability.

`T3`–`T5` and `T8` only surface when the corresponding profile is active (`attested-satisfies`, `attested-adequacy`, `attested-sufficiency`, `aspect-coverage`). Adopters enable these profiles as their workflow matures.

Additional gap codes that are meaningful only to adopters running the topological audit as a downstream-analysis mode (`G3.uncoupled`, `G4.unvalidated`, `G5.unapproved-validation-edge`, `G6.assurance-triangle-incomplete`, `G7.stale-recursive-attestation`, `G8.dangling-sysml-ref`, `G9.registry-unknown-type`) are documented in `flexo-rtm-research/Topological Framework Future Work.md`. They depend on a community-curated registry and the topological research line maturing; they are not on `flexo-rtm`'s critical path, and `flexo-rtm` does not commit to ever emitting them.

(`G5.unapproved-validation-edge` is structurally absent under any topological audit's SHACL gate — the gate on validation edges would reject any without an approver IRI. It is reserved in the code enumeration for diagnostic completeness if SHACL is somehow bypassed.)

### 4.8 Three-layer certification artifact

1. **Transcript** — deterministic SPARQL+SHACL execution log; one `prov:Activity` per step; replayable; the load-bearing primitive. Also records the external URIs (git+commit, content hashes, OCI digests) referenced by activities in scope.
2. **Attestation graph** — named graph of `rtm:Attestation` records bound to `rtm:satisfies` triples, with PROV provenance (who/when/what). Mandatory `rtm:approvedBy` per §4.3. Approver IRIs are evaluated against the identity projection per §4.4. Activities referenced by attestations carry their external URI references per §4.5.
3. **Audit report** — forward / backward coverage table; T1–T8 gap enumeration; certification grade (PASS/FAIL); transcript IRI; attestation graph IRI; **reproducibility manifest** listing every external URI the cert depends on.

### 4.9 Reproducibility chain — structural completeness enables local, federated verification

**The core principle:** reproducibility is **structural and local**, not global. The cert artifact carries everything a verifying party needs to reproduce a specific fact — without requiring re-dereferencing the whole traceability graph or holding universal permissions.

A verifier with **adequate local permissions** for the fact they want to reproduce can:
- Read the relevant subset of the RDF (the fact's local neighborhood)
- Dereference the external URIs in that subset (per their access rights)
- Replay the recorded SPARQL/SHACL steps that produced the fact
- Compare the result hashes

Reproduction federates naturally — multiple parties verify different subsets, composing to a complete audit without any single party owning everything.

**The chain has five dimensions, each locally verifiable:**

**RDF-internal (canonical equivalence):** Inputs to any cert step are RDFC-1.0 canonicalized → input-hash. Transcript records input-hash + recorded-result-hash per step. A verifier with read access to the relevant input subset can re-execute and confirm byte-identical results.

**External URI (re-execution):** Activities carry git+commit, content-hash, and OCI-digest URIs (§4.5). A verifier with fetch access to those URIs can re-execute the underlying activity from scratch — pull the code, fetch the data, run the container, content-hash the outputs, compare to recorded artifact hashes. Verifiers without fetch access can still verify the structural completeness of the references (presence, format, registry membership) without dereferencing.

**Identity projection (§4.4):** the projection-as-of-cert-time of identities and policies is recorded in the transcript. A verifier with read access to the projection can re-evaluate authorization for any specific attestation. A verifier without that access can verify the projection's structural completeness (every approver IRI resolves, every policy referenced is present) without resolving against the live identity provider.

**Signed envelopes (§4.6):** when the relevant profiles are active, integrity proofs are themselves locally verifiable:
- Attestations carry `sec:proof` (W3C Data Integrity) — verify against the public key, no live service needed
- Activities reference DSSE-enveloped in-toto attestations — verify the envelope signature
- Container images are cosign-verified — verify the cosign bundle
- Git commits are GPG/SSH-signed — verify against the publisher's published keys
- Optional Rekor entries — verify the Merkle inclusion proof against Rekor (public service)

Each signature is independently checkable. A verifier with the signer's public key (typically published) can confirm without contacting the original signer.

**Git binding for approvers:** the GPG/SSH-signed commit and the `rtm:approvedBy` IRI together let any verifier confirm "this human attested this fact at this time" using public-key infrastructure they already trust.

**Federation in practice:**
- A safety reviewer with safety-aspect permissions verifies safety-aspect facts; their local audit composes with other reviewers' audits to a complete cert.
- An external regulator verifies structural integrity (references present, signatures valid, projection complete) without ever dereferencing classified payloads.
- A reproduction team in a sister organization runs the same activities in their environment, comparing their result hashes to the recorded ones, without needing access to the original cert's compute.

No proprietary dependencies anywhere in the chain. No single party needs universal access. Reproducibility is a property of the artifact, not a workflow that requires central coordination.

### 4.10 Topological framework as related research line, not flexo-rtm's destination

The typed simplicial complex framework from Zargham 2026 (assurance triangles, recursive completeness, named-approver-enforced validation edges, V−F-type invariants, TDA over commit-sequence filtration) is **a related research line, not `flexo-rtm`'s destination** (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]). It is one possible **downstream-analysis path** an adopter may choose to run on top of `flexo-rtm`'s data, among several plausible ones (SLSA, GSN, ARP4754A, custom in-house analysis layers). `flexo-rtm` does not privilege one downstream-analysis target over another. Documented at length in `flexo-rtm-research/Topological Framework Future Work.md` — including:

- The vision (if the research line matures): full-assurance certification via closed (Artifact, Requirement, Guidance) triangles, computed as a downstream-analysis mode over `flexo-rtm`'s data
- The recursive completeness condition: every artifact used as evidence has its own assurance triangle; supporting guidance and specifications must themselves be fit-for-purpose
- The registry problem: termination of the recursion requires a community-curated registry of pre-approved artifact types, specifications, and guidance — a substantial commitment internal to the topological research line
- Why V−F ≤ 1 alone is insufficient (purely numerical check; doesn't enforce the recursive completeness)
- Open questions: registry curation governance, recursion termination, integration with TDA / persistent homology
- The roadmap for the research line — separate from `flexo-rtm`'s release schedule

The vocabulary v0.1 ships (§4.2) is **forward-compatible interop** with this research line per [[ADR-020 Vocabulary Alignment with Zargham 2026]]: an adopter who chooses to run topological analysis as a downstream mode reads it natively; an adopter who runs a different downstream analysis reads the same data. The external URI references (§4.5), identity projections (§4.4), and signed envelopes (§4.6) are equally methodology-neutral — they constitute the substrate any downstream-analysis path consumes.

## 5. Three-layer architecture

```
┌─────────────────────────────────────────────────────────────┐
│  OPERATIONAL  — fast, in-memory, model-state-induced        │
│  - working-set rdflib dataset (slice of full complex)        │
│  - Pydantic models for authoring; SHACL gate on every write │
│  - skill + CLI operate here; UX must feel weightless        │
│  - batch commit to Flexo with model/sim/data co-versioned   │
└─────────────────────────┬───────────────────────────────────┘
                          │ atomic transaction
┌─────────────────────────▼───────────────────────────────────┐
│  STORAGE  — Flexo MMS                                        │
│  - authoritative named graphs (branched, versioned)          │
│  - model triples, attestations, transcripts, audit graphs    │
│  - git tracks operational serializations alongside           │
└─────────────────────────┬───────────────────────────────────┘
                          │ scoped read
┌─────────────────────────▼───────────────────────────────────┐
│  ANALYSIS  — scoped certification, reporting, TDA            │
│  - input = Scope IRI → resolves to graph union + filter      │
│  - materializes complex via `knowledgecomplex` (opt-in)      │
│  - emits transcript / attestation / audit                    │
│  - results write back to storage as derived named graphs     │
└──────────────────────────────────────────────────────────────┘
```

### 5.1 Operational layer (UX critical path)

Materializes only the **working set** induced by what's checked out. Local rdflib in-memory dataset (~hundreds of triples). SHACL gates on every write — fast because the graph is small. Skill prompts at judgment moments ("is the model adequate?", "is the evidence sufficient?", "who is approving?") and either creates the validation edge with the engineer's approver IRI, returns to the edit loop, or creates a `rtm:DeferredJudgment` marker.

Batch commit to Flexo is atomic — model triples + evidence refs + attestation triples land together. Model evolution and traceability evolution version together.

### 5.2 Storage layer (Flexo)

One named graph per logical partition (model, requirements, attestations, guidance, transcripts, audit). Flexo branches isolate concurrent engineering streams. Conflict resolution per `flexo-conflict-resolution-policy-research` (verification-scope automated via SHACL/SPARQL ASK; validation-scope escalated to human review). Per-commit metadata identifies the active scope during authoring.

**Interface contract** (testable acceptance criteria in §9.A.1):

- **Atomic transactions** (F1) — `flexo-rtm commit` is one Flexo transaction; partial commits forbidden
- **Provenance integrity** (F2) — every triple in a commit shares a single `prov:Activity` IRI
- **Named-graph layout** (F3) — fixed partitioning + per-resource source graphs for imported content
- **Scope metadata** (F4) — every commit records its active `rtm:Scope` IRI; round-trip recoverable
- **Merge policy** (F5) — constraint-aware synthesis; verification-scope auto, validation-scope escalated
- **Branch conventions** (F6) — `main` / `engineering/<team>` / `cert/<run-id>`
- **Live-skippable tests** (F7) — `@pytest.mark.live` auto-skip without `FLEXO_TOKEN`

### 5.3 Analysis layer (composable scopes)

`rtm:Scope` is a first-class RDF resource. Scopes name graph unions plus optional SPARQL filters. Compositions (union/intersection/extension) supported. Examples:

```turtle
rtm:scope/adcs-attitude-control a rtm:Scope ;
    rtm:includesGraph <adcs:structural>, <adcs:requirements/attitude> ;
    rtm:scopeFilter "FILTER(?aspect IN (rtm:functional, rtm:performance))" .

rtm:scope/safety-critical a rtm:Scope ;
    rtm:scopeFilter "FILTER(?aspect = rtm:safety)" ;
    rtm:includesAllGraphsMatching "adcs:*" .

rtm:scope/adcs-safety a rtm:Scope ;
    rtm:extends rtm:scope/adcs-attitude-control ;
    rtm:intersectsWith rtm:scope/safety-critical .
```

Audit reports name their scope. Stakeholders compare scopes across baselines: "is safety-critical aspect coverage growing or shrinking commit over commit?"

## 6. Ontology architecture

### 6.1 Layered

| Layer | Path | Content |
|---|---|---|
| Core | `ontology/core/` | Domain-general TBox: vertices, edges, attestation, scope, transcript, deferred-judgment |
| Alignment | `ontology/alignment/` | `owl:equivalentClass` / `skos:closeMatch` bindings to OSLC-RM, OSLC-QM, SysMLv2, INCOSE, GSN, PROV, EARL, P-PLAN |
| Profiles | `ontology/profiles/` | Composable SHACL contracts: `oslc-rm-roundtrip`, `oslc-qm-roundtrip`, `sysmlv2-anchored`, `incose-aligned` |
| Shapes | `ontology/shapes/` | Structural enforcement: approver-required, face-closure, aspect-coverage, stale-attestation, V−F invariant |
| Imports | `ontology/imports/` | Vendored full external vocabs (read-only) for reproducibility |
| Parsimony | `ontology/parsimony/` | MIREOT / SLME extracts; `manifest.yaml` lists kept classes/properties per import; deterministic build |

### 6.2 Parsimony policy

External vocabs are **never** loaded wholesale at runtime. Build-time extraction via SPARQL `CONSTRUCT` or ROBOT `extract --method MIREOT` produces minimal subsets. The assembled `rtm.ttl` target: **under ~2k triples**. Anything larger triggers a parsimony review. `manifest.yaml` is the audit trail of every external class/property kept.

### 6.3 GSN adoption

Adequacy and sufficiency claims use OntoGSN Solution + Justification patterns (parsimony-extracted), consistent with the ADCS prototype's encoding. ADR documents the choice.

### 6.4 Profile mechanism

Composable SHACL contracts. Oracle accepts `--profile=oslc-rm-roundtrip` (or comma-separated multiple). Scope = data selection; Profile = constraint selection. Orthogonal.

## 7. Oracle architecture

### 7.1 Sub-packages

```
oracle/src/oracle/
├── models/             # Pydantic shared across layers (Scope, Attestation, Transcript, Audit)
├── canonicalize/       # RDFC-1.0
├── operational/        # UX hot path: workspace, checkout, author, batch, commit
├── storage/            # Flexo adapter: client, transaction, checkout queries
├── analysis/           # scope.py, materialize.py, coverage.py, topology.py, emit/, verify/
└── cli.py              # Typer entry routing into layers
```

### 7.2 Dependency policy

| Layer | Required | Optional extras |
|---|---|---|
| Oracle hot path (operational + storage) | `rdflib`, `pyshacl`, `pydantic` | — |
| OSLC adapters | `rdflib`, `pydantic-xml` | — |
| Build / parsimony | `rdflib` | `robot` CLI |
| Analysis & topology | — | `[analysis]`: `knowledgecomplex`, `owlrl`, `pandas`, `numpy` |
| TDA | — | `[tda]`: `gudhi` or `dionysus2`, `scipy` |
| Visualization | — | `[viz]`: `matplotlib`, `networkx`, `graphviz` |

Default `pip install flexo-rtm` is lean: hot path + adapters only. Analysis layer is opt-in via `pip install 'flexo-rtm[analysis]'`.

### 7.3 Pydantic surface (preview of v0.2 OpenAPI)

```python
class Scope(BaseModel):
    iri: AnyUrl
    label: str
    includes_graphs: list[AnyUrl]
    scope_filter: str | None
    extends: AnyUrl | None
    intersects_with: list[AnyUrl] = []

class TranscriptStep(BaseModel):
    seq: int
    step_kind: Literal["sparql", "shacl", "canonicalize", "knowledgecomplex-op"]
    query_text: str | None
    shape_iri: AnyUrl | None
    inputs_hash: str
    result_hash: str
    prov_activity: AnyUrl

class GapRecord(BaseModel):
    # v0.1 codes (T-series); G-series codes are topology-line (see §4.10) — meaningful
    # only if an adopter runs topological analysis as a downstream-analysis mode.
    # T7 and G5 are structurally absent — SHACL rejects at write; included here for
    # diagnostic completeness if pyshacl is somehow bypassed.
    code: Literal[
        "T1", "T2", "T3", "T4", "T5", "T6", "T7", "T8",      # v0.1
        "G3", "G4", "G5", "G6", "G7", "G8", "G9",            # topology-line (downstream-analysis mode)
    ]
    vertex_iri: AnyUrl | None
    aspect: AnyUrl | None
    detail: str

class AttestationRecord(BaseModel):
    iri: AnyUrl
    approved_by: AnyUrl
    certifies_triple: tuple[AnyUrl, AnyUrl, AnyUrl]
    earl_result: Literal["passed", "failed", "inapplicable"]
    timestamp: AwareDatetime
    transcript_ref: AnyUrl | None

class AuditReport(BaseModel):
    run_id: UUID
    scope: AnyUrl
    profile: AnyUrl | None
    input_hash: str
    transcript_iri: AnyUrl
    attestation_graph_iri: AnyUrl
    coverage: CoverageStats
    topology: TopologyStats
    gaps: list[GapRecord]
    certified: bool
```

These models become FastAPI request/response schemas in v0.2 with zero rework.

## 8. Spec deliverables

| File | Form | Purpose |
|---|---|---|
| `spec/bidirectional-rtm.md` | Normative prose | Formal predicate, traditional bidirectional analysis, accountability model, scope semantics |
| `spec/certification-predicate.md` | Mathematical + prose | Basic predicate (v0.1) formalized; quantitative outcome; T1-T8 gap codes |
| `spec/transcript-model.md` | Schema + semantics | Transcript schema, hash chain, replay semantics; references RDFC-1.0; **reproducibility manifest format (per §9.A.4 U5)** |
| `spec/adapter-contracts.md` | Normative | General adapter contract framework |
| `spec/oslc-roundtrip-acceptance.md` | Normative | **OSLC-RM/QM enumerated core class set; carry-through registry structure; per-class roundtrip acceptance conditions (per §9.A.2)** |
| `spec/identity-adapter-contract.md` | Normative | **Identity-projection adapter input/output schema; reference adapter conformance; new-provider extension guide (per §9.A.3 I6)** |
| `spec/scope-semantics.md` | Algebra | Scope composition (union/intersection/extension); IRI conventions; scope hierarchy rules (used by §9.A.3 I4) |
| `spec/conformance/shacl/` | SHACL files | Every normative shape (attestation, identity-projection, profile-gated shapes, vocabulary shapes) |
| `spec/conformance/sparql/` | SPARQL files | Every certification predicate as parameterized query; **policy evaluation test cases with positive/negative fixtures (per §9.A.3 I2–I4)** |
| `spec/conformance/fixtures/` | RDF graphs | Minimal positive + negative test graphs per requirement; OSLC reference + vendor sample fixtures |

The spec is normative; the oracle is the reference implementation; conformance is the contract. **§9.A defines binary acceptance criteria; this section names the normative artifacts that define each criterion in detail.**

## 9. OSLC adapter — hard v0.1 requirement

**Both OSLC-RM and OSLC-QM ship as full read+write adapters in v0.1.** Lossless roundtrip integration tests pass from day one against reference fixtures (canonical OSLC examples + sanitized vendor exports). This is non-negotiable for institutional adoption: "we cannot get institutional adoption if we cannot demonstrably roundtrip losslessly."

Scope nuance: v0.1 ships the **adapter** (parse, serialize, roundtrip) and the **fixture-based integration tests**. v0.1 does **not** ship **live connectors** to running Doors / Jama instances — those are v0.2 work, but they will plug into the v0.1 adapter without modification. The adapter is the contract; live connectors are network code on top of it.

**Interface contract** (testable acceptance criteria in §9.A.2):

- **Layer A core equivalence** (O1) — RDFC-1.0 canonical-form byte-equality for OSLC-RM/QM core constructs
- **Layer C carry-through** (O2) — vendor extensions stored verbatim, re-emitted verbatim, structural count preserved
- **Enumerated core class set** (O3) — normative mapping table in `spec/oslc-roundtrip-acceptance.md`
- **Canonical fixtures** (O4) — every fixture in `examples/oslc-fixtures/canonical/` roundtrips losslessly
- **Vendor fixtures** (O5) — Doors and Jama sanitized exports roundtrip with Layer A + Layer C
- **SHACL profile gate** (O6) — `--profile=oslc-rm-roundtrip` PASSes only when all profile shapes pass
- **Vendor extension registry** (O7) — adding a new vendor requires only a registry entry, no code changes

**Lossless criterion:**
- **A. RDFC-1.0 triple-set equivalence** for OSLC-RM/QM core constructs (RDFC-1.0 canonical form of input == canonical form of output)
- **C. Opaque carry-through** for vendor extensions (Doors-X, Jama-Y predicates): stored verbatim in a per-resource source named graph, emitted verbatim on output, structural-only checks. The certification predicate does not certify content within carry-through subgraphs.

**Source-preserving import:** imported OSLC graphs are stored verbatim in `<oslc-rm:source/{id}>`. Internal augmentations live in separate named graphs that reference the source. Write-back emits only the source graph. Round-trip is lossless by construction.

## 9.A v0.1 Acceptance Criteria — Interface Contracts as Design Constraints

The mission (§1) is `flexo-rtm`'s **objective function** — verifiable self-certification of SysMLv2-anchored bidirectional traceability via open-source, self-hostable infrastructure. The interface contracts at the essential boundaries are this objective's **constraints**: any implementation that violates a constraint is not `flexo-rtm`, regardless of how well it optimizes elsewhere.

This section enumerates the **testable acceptance criteria** for each constraint family. Every criterion is binary (PASS/FAIL) and traceable to a conformance test fixture or live integration test in `spec/conformance/` and `tests/`.

### 9.A.1 Constraint family: Flexo as datastore primitive

**Interface contract:** `flexo-rtm` stores authoritative graph state in Flexo MMS (OpenMBEE) via the Layer 1 REST API. The contract is the union of Flexo's REST surface + `flexo-rtm`'s named-graph conventions + transaction semantics.

| ID | Acceptance criterion | Test |
|---|---|---|
| F1 | A `flexo-rtm commit` writes model triples, evidence triples, attestation triples, and transcript-fragment triples in a **single Flexo transaction**. If any sub-write fails, ALL sub-writes roll back; no partial persistence. | `tests/integration/flexo/test_atomic_commit.py` |
| F2 | All triples from a single commit reference a single `prov:Activity` IRI (the commit's `flexo:Commit` resource). No orphans across commits. | `tests/integration/flexo/test_commit_provenance.py` |
| F3 | Named-graph conventions: one named graph per logical partition (`<model>`, `<requirements>`, `<attestations>`, `<transcripts>`, `<audit>`). Source-preserved imports go in per-resource source graphs (`<oslc-rm:source/{id}>`). | `tests/integration/flexo/test_named_graph_layout.py` |
| F4 | Commit metadata MUST capture the active `rtm:Scope` IRI. Round-trip: read a commit, recover the scope it was authored under. | `tests/integration/flexo/test_scope_metadata.py` |
| F5 | Conflict resolution at merge follows `constraint-aware synthesis` (per `flexo-conflict-resolution-policy-research`) — verification-scope conflicts auto-resolved via SHACL ASK; validation-scope conflicts escalated to named approver. | `tests/integration/flexo/test_merge_policy.py` |
| F6 | Branch model: `main` for published baselines; `engineering/<team>` for concurrent streams; `cert/<run-id>` for immutable certification artifacts. | `tests/integration/flexo/test_branch_conventions.py` |
| F7 | All live Flexo tests are marked `@pytest.mark.live` and **auto-skip** when `FLEXO_TOKEN` env var is absent. Test suite is runnable end-to-end without a live Flexo instance. | `tests/conftest.py` |

### 9.A.2 Constraint family: OSLC-RM/QM lossless roundtrip

**Interface contract:** v0.1 ships full read+write adapters for OSLC-RM 2.1 and OSLC-QM 2.1. Lossless roundtrip is non-negotiable for institutional adoption.

| ID | Acceptance criterion | Test |
|---|---|---|
| O1 | **Layer A (core)**: for the enumerated OSLC-RM/QM core class set (see `spec/oslc-roundtrip-acceptance.md`), `RDFC-1.0(parse(emit(parse(input)))) == RDFC-1.0(input)` — canonical-form byte-equality. | `tests/integration/oslc-roundtrip/test_layer_a_rm.py`, `test_layer_a_qm.py` |
| O2 | **Layer C (vendor extensions)**: for predicates outside OSLC-RM/QM core, the triples are stored verbatim in `<oslc-rm:source/{id}>` and re-emitted verbatim. Structural check: triple count per resource is preserved across roundtrip. | `tests/integration/oslc-roundtrip/test_layer_c_carrythrough.py` |
| O3 | **Enumerated core class set** (normative): every OSLC-RM/QM construct claimed to satisfy Layer A is listed in `spec/oslc-roundtrip-acceptance.md` with its mapping to `rtm:` constructs. Any new core mapping requires updating the spec. | `tests/conformance/test_mapping_table.py` |
| O4 | **Reference fixtures**: at minimum, every fixture in `examples/oslc-fixtures/canonical/` (W3C/OASIS OSLC spec examples) roundtrips losslessly (Layer A). | `tests/integration/oslc-roundtrip/test_canonical_fixtures.py` |
| O5 | **Vendor sample fixtures**: sanitized exports from at least Doors and Jama in `examples/oslc-fixtures/vendor/` roundtrip with Layer A on core + Layer C on extensions. | `tests/integration/oslc-roundtrip/test_vendor_fixtures.py` |
| O6 | **SHACL profile gate**: the `oslc-rm-roundtrip` SHACL profile enumerates the required predicates and link types; running the oracle with `--profile=oslc-rm-roundtrip` PASSes only if all profile shapes pass. | `tests/conformance/test_oslc_profile.py` |
| O7 | **Vendor extension registry**: `examples/oslc-fixtures/vendor-registry.yaml` maps known vendor namespaces to handling rules (carry-through only; never mapped). Adding a new vendor requires only a registry entry, not code changes. | manual review + `test_registry_completeness.py` |

### 9.A.3 Constraint family: Identity & authority for actors (named approvers)

**Interface contract:** `flexo-rtm` does not authenticate users. It carries thin RDF projections of identities and policies that an external authoritative provider has authored. SHACL is the single bottleneck where authority is checked at attestation-write time.

| ID | Acceptance criterion | Test |
|---|---|---|
| I1 | **Schema-enforced approver**: every `rtm:Attestation` instance MUST have `rtm:approvedBy <IRI>` (`sh:minCount 1`, `sh:nodeKind sh:IRI`). Writes without this fail at SHACL gate. | `tests/conformance/test_attestation_shape.py` |
| I2 | **Policy positive case**: an approver with role R, attribute K=V, scoped to S, IS authorized to emit `rtm:SatisfactionAttestation` for aspect X iff there exists `rtm:Policy` P with `rtm:appliesToRole R`, `rtm:requiresAttribute [K, ≥V]`, `rtm:permitsAttestationType rtm:SatisfactionAttestation`, `rtm:permitsAspect X`, `rtm:withinScope S` (or ancestor scope). | `tests/conformance/test_policy_positive.py` |
| I3 | **Policy negative case (attribute)**: same approver without attribute K MUST FAIL policy evaluation even if role matches. | `tests/conformance/test_policy_negative_attribute.py` |
| I4 | **Policy negative case (scope)**: approver scoped to `rtm:scope/adcs-attitude-control` is authorized for that scope and its sub-scopes; NOT authorized for sibling scopes (e.g., `rtm:scope/adcs-power`). | `tests/conformance/test_policy_scope_hierarchy.py` |
| I5 | **Reference adapters compile and produce projections**: GitHub, generic OIDC, and GitHub Actions OIDC adapters each take a sample claim payload and produce conforming `foaf:Person` + `org:Membership` + `rtm:Attribute` triples that pass SHACL projection-shape validation. | `tests/conformance/test_identity_adapters.py` |
| I6 | **Adapter contract**: writing a new adapter (e.g., for SAML) requires only conforming to the input/output schema documented in `spec/identity-adapter-contract.md`. No code changes to oracle core. | manual review + `test_adapter_contract_schema.py` |
| I7 | **Git approver binding** (when `signed-commits` profile active): a git commit introducing an attestation triple MUST be GPG/SSH-signed by a key whose fingerprint matches the `rtm:approvedBy` IRI's published key. Pre-commit hook + GitHub Actions check both verify. | `tests/integration/git/test_approver_binding.py` |
| I8 | **Local & federated reproducibility of identity facts**: a verifier with read access to the recorded projection-at-cert-time can re-evaluate authorization for any specific attestation locally. The recorded projection is structurally complete (every approver IRI, role, attribute, policy referenced is present in the artifact). Identity changes after cert do NOT invalidate past attestations because reproduction operates against the recorded projection, not the live identity provider. | `tests/conformance/test_projection_local_reproducibility.py` |

### 9.A.4 Constraint family: Identity for artifacts (dereferenceable URIs)

**Interface contract:** Evidence, models, and activities in the RDF graph reference external content via URI. These URIs MUST be dereferenceable for audits and playback (verifiable third-party re-fetch + re-execute).

| ID | Acceptance criterion | Test |
|---|---|---|
| U1 | **Vocabulary required**: any `rtm:Activity` SHOULD carry at least one of `rtm:hasGitCommit` or `rtm:hasOCIImage` (`--profile=strict-provenance` upgrades to MUST/error). | `tests/conformance/test_activity_provenance.py` |
| U2 | **Content-hash verification**: if the oracle is given network access (audit mode), it MAY fetch the referenced URI for any `rtm:hasContentHash` and compute the hash. Computed hash MUST equal recorded hash, or the audit FAILs with a `T-fetch-mismatch` warning. | `tests/integration/dereferenceable/test_content_hash_verify.py` |
| U3 | **Git commit existence**: in audit mode, fetching `rtm:hasGitRepo + rtm:hasGitCommit` MUST succeed (commit must exist in the repo at the recorded hash). | `tests/integration/dereferenceable/test_git_commit_resolves.py` |
| U4 | **OCI image digest existence**: in audit mode, fetching `rtm:hasOCIImage` digest reference MUST succeed against an OCI-compliant registry. Cosign-verifiable when `--profile=cosign-images` is active. | `tests/integration/dereferenceable/test_oci_digest_resolves.py` |
| U5 | **Reproducibility manifest**: every audit report MUST include a "Reproducibility Manifest" enumerating every external URI the cert depends on, organized by URI type. Manifest format normatively defined in `spec/transcript-model.md`. | `tests/conformance/test_audit_manifest_completeness.py` |
| U6 | **Source-preserving OCI/git references in storage**: an activity's URI references persist verbatim through Flexo round-trips (no normalization, no rewriting). | `tests/integration/flexo/test_uri_preservation.py` |

### 9.A.5 Cross-cutting acceptance criteria

| ID | Acceptance criterion | Test |
|---|---|---|
| X1 | **Determinism**: same canonical input → byte-identical transcript across runs (different machines, different process IDs, different times). RDFC-1.0 canonicalization + deterministic SPARQL solution ordering. | `tests/determinism/test_byte_identical_transcripts.py` |
| X2 | **Replay**: anyone with the canonical input-hash + transcript can re-execute every recorded SPARQL/SHACL step and produce byte-identical result hashes. | `tests/conformance/test_transcript_replay.py` |
| X3 | **Quantitative outcomes only**: no audit report contains a single "% certified" rolled-up number. Coverage is always reported per-dimension (forward, backward, per-claim-type, per-aspect). | `tests/conformance/test_audit_report_shape.py` |
| X4 | **No proprietary deps**: `pip install flexo-rtm` works with only PyPI packages + system `git`. Cosign, OCI tooling, identity adapters are optional extras. | `tests/conformance/test_minimal_install.py` |
| X5 | **Parsimony**: assembled `rtm.ttl` (Core + Alignment + Parsimony extracts) is ≤ 2000 triples. Build fails if exceeded; review required. | `tests/conformance/test_ontology_parsimony.py` |
| X6 | **Local reproducibility of any fact**: for any individual fact in the cert artifact (an attestation, activity, artifact reference), a verifier with read access to that fact's local neighborhood (the RDF subgraph induced by the fact and its immediate references) plus dereference access to the relevant external URIs can re-execute the recorded SPARQL/SHACL steps and confirm byte-identical hashes. No requirement to hold permissions over the whole graph. | `tests/conformance/test_local_fact_reproducibility.py` |
| X7 | **Federated reproducibility composes**: multiple verifying parties, each with non-overlapping permission subsets, can each reproduce their permitted fact-set; the union of their per-fact PASS results equals a global PASS over the union of their permission subsets. No single party needs universal access for the audit to be complete. | `tests/conformance/test_federated_reproducibility.py` |
| X8 | **Structural completeness without dereferencing**: a verifier without fetch access to external URIs can still confirm structural completeness (every referenced URI is well-formed, registered in the reproducibility manifest, and consistent with the recorded SHACL profile) by reading the RDF alone. Dereferencing is required for re-execution; not required for structural validation. | `tests/conformance/test_structural_completeness.py` |

### 9.A.6 Acceptance criteria for the topological research line (NOT `flexo-rtm` criteria)

These criteria document what an applied audit would check **if the topological research line matures**. They are **not `flexo-rtm` criteria** and do NOT gate any v0.1 or later release of `flexo-rtm`. Per [[ADR-032 Methodology Agnosticism as Foundational Axiom]], the topological framework is a related research line — one possible downstream-analysis mode an adopter may choose to run on top of `flexo-rtm`'s data. Listed here for traceability so that, if an adopter (or the research line itself) builds a topological audit, its acceptance contract is documented in the same place as `flexo-rtm`'s v0.1 contract.

| ID | Topology-line criterion | Reference test |
|---|---|---|
| D1 | Closed assurance triangle audit | `tests/future/test_triangle_closure.py` |
| D2 | Recursive completeness check against registry | `tests/future/test_recursive_completeness.py` |
| D3 | Persistent homology over commit-sequence filtration | `tests/future/test_tda_barcodes.py` |
| D4 | V−F invariant (alternative formulation pending research) | `tests/future/test_topological_invariants.py` |

The acceptance criteria in §9.A.1–§9.A.5 are the v0.1 release gate. Implementations passing all criteria MAY claim `flexo-rtm` v0.1 compliance. The criteria are normative; the prose elsewhere in this spec is explanatory.

---

## 10. v0.1 scope summary

**In scope:**

- **Traditional bidirectional traceability — primary deliverable**
  - Forward and backward analysis with SPARQL implementations
  - Forward / backward coverage statistics
  - T1 / T2 gap enumeration
  - `certify` CLI / oracle entry point producing the three-layer artifact
  - Reports in formats familiar to Doors/Jama/OSLC users
- **Named-approver attestation infrastructure (three claim types)**
  - `rtm:SatisfactionAttestation` — named-human attests that an artifact satisfies a requirement
  - `rtm:AdequacyAttestation` — named-human attests that the model representation is adequate for the claim
  - `rtm:SufficiencyAttestation` — named-human attests that the evidence is sufficient for the claim
  - All three: SHACL-enforced approver IRI requirement (`sh:minCount 1`, `sh:nodeKind sh:IRI`)
  - Git pre-commit hook + GitHub Actions binding approver to committer (all three types)
  - Per-aspect attestation supported via `rtm:hasAspect`
  - Composable optional profiles: `attested-satisfies`, `attested-adequacy`, `attested-sufficiency`, `aspect-coverage`
  - **ADCS regression tests require this** — the prototype already operates with adequacy/sufficiency attestations
- **Audit dimensions and gap codes** (T1–T8 per §4.7) — coverage stats per claim type, per aspect; gap enumeration
- **Identity boundaries — thin projections of external authoritative sources (§4.4)**
  - Vocabulary: `rtm:hasExternalIdentity`, `foaf:Person`, `org:Membership`, `rtm:Attribute`, `rtm:scopedTo`, `rtm:Policy`, `rtm:appliesToRole`, `rtm:requiresAttribute`, `rtm:permitsAttestationType`, `rtm:permitsAspect`, `rtm:withinScope`
  - Three policy primitives (combinable, configurable): role-based, attribute-based, scope-based
  - SHACL bottleneck: every attestation evaluates approver authority against applicable policies via SPARQL
  - Reference adapters: GitHub, generic OIDC, GitHub Actions OIDC; adapter contract documented for SAML/LDAP/Okta/Auth0/Keycloak
  - Refresh policy options (every cert run / on commit / scheduled / static); projections recorded in transcript with timestamp for reproducibility
  - No authentication; no credential storage; no novel policy engine — pure SPARQL evaluation against RDF projection
- **External URI references (the git+RDF foundation; §4.5)**
  - `rtm:hasGitRepo`, `rtm:hasGitCommit`, `rtm:hasGitPath` for source provenance
  - `rtm:hasContentHash` for content-addressed data (sha256 / IPFS)
  - `rtm:hasOCIImage` for infrastructure-as-code (Docker / OCI registry digests)
  - PROV-O activity provenance: `prov:wasGeneratedBy`, `prov:used`, `prov:wasDerivedFrom`, `prov:atLocation`, `prov:hadPlan`
  - SHACL: activities SHOULD have at least one of `rtm:hasGitCommit` / `rtm:hasOCIImage` (warning by default; error under `--profile=strict-provenance`)
  - **Reproducibility manifest** in audit reports: enumerates every external URI the cert depends on
  - These URIs are the source of open-source interoperability, portability, auditability, and reproducibility
- **Signed envelopes — composition of established standards (§4.6)**
  - Vocabulary: `sec:proof` (W3C Data Integrity on attestations), `rtm:dsseEnvelope` (DSSE + in-toto for activities), `rtm:cosignBundle` (Sigstore cosign for OCI images), `rtm:rekorLogEntry` (transparency log)
  - Optional SHACL profiles (off by default): `signed-commits`, `data-integrity-attestations`, `dsse-activities`, `cosign-images`, `rekor-transparency`
  - Pre-commit hook + GitHub Actions verify GPG/SSH commit signatures against `rtm:approvedBy` key fingerprint
  - No custom crypto — composition of git native signing, W3C VC-DI, DSSE/in-toto, Sigstore, OCI image signatures
  - Closes the ADCS prototype's "signed envelopes deferred" gap
- **Forward-compatible vocabulary aligned with the topological research line** (no triangle-closure audit gate in `flexo-rtm` core; the audit, if built, lives in the research line per §4.10)
  - `rtm:Guidance`, `rtm:AdequacyCriteria`, `rtm:SufficiencyCriteria`
  - `rtm:Aspect` taxonomy (extensible)
  - The attestation infrastructure listed above already uses these terms; the recursive completeness audit that would consume them is a research-line problem (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]), and the data is equally consumable by any other downstream-analysis path (SLSA, GSN, ARP4754A, in-house)
- Ontology: core + alignment + profiles + shapes + parsimony extracts
- Formal spec: all documents in §8
- Conformance suite: SHACL + SPARQL + fixtures
- Oracle: operational + storage + analysis (analysis as optional extras)
- OSLC-RM + OSLC-QM full adapters with lossless roundtrip integration tests
- Scope as first-class RDF resource; composition algebra
- Regression corpus: ADCS prototype graphs (must certify under v0.1 traditional analysis)

**Out of scope (not `flexo-rtm` features — these are problems in the related topological research line, documented in `flexo-rtm-research/Topological Framework Future Work.md`; per [[ADR-032 Methodology Agnosticism as Foundational Axiom]] the research line is not `flexo-rtm`'s destination):**

- Topological framework (assurance triangles as audit primitive, recursive completeness condition)
- Topological invariants (V−F and successors; further research determined the numerical check alone is insufficient)
- Pre-approved artifact/specification/guidance registry
- G3–G9 gap codes (apply only under the topological research line; surface only if an adopter chooses to run topological analysis as a downstream-analysis mode)
- Persistent homology / TDA

**Out of scope (deferred to v0.2+):**

- OpenAPI / Swagger service (FastAPI; triggers transfer to OpenMBEE)
- Claude skill + CLI MVC wrapper (RIME-pattern; multiple role-scoped skills)
- SysMLv2 bidirectional I/O (`.kerml` / `.sysml.json` ↔ storage)
- Flexo + git conventions doc + pre-commit hooks + GitHub Actions
- Live Doors / Jama connectors (v0.1 ships contracts + fixture tests)
- Persistent homology / TDA capability (filtration over commit-sequence)
- Companion `flexo-rtm-research` Obsidian vault content (built **before** v0.1 implementation begins, per §2)

## 11. v0.2+ roadmap

| Capability | v0.2 / future work | Triggers |
|---|---|---|
| OpenAPI service | Pydantic models → FastAPI; CLI becomes thin wrapper | MVP service triggers transfer to OpenMBEE org |
| Claude skill + CLI | RIME pattern: `flexo-rtm-mgmt`, `-attest`, `-reconcile` skills routing to Typer subcommands | Operational layer is the substrate |
| SysMLv2 I/O | `.kerml` / `.sysml.json` ↔ storage layer with conformance tests | New work; minimal in ADCS prototype |
| Flexo+git conventions | `docs/conventions/flexo-git.md`; pre-commit hooks; GitHub Actions for approver binding | Operational commit semantics formalized |
| Live OSLC connectors | Doors + Jama integrations against the v0.1 contract | Adapter contract is the v0.1 hedge |
| **Topological framework** | Assurance triangles, recursive completeness check, registry of pre-approved types, alternative to V−F invariant, G3–G9 gaps | Substantial research + community engagement required — see `flexo-rtm-research/Topological Framework Future Work.md` |
| Persistent homology | Filtration over commit-sequence; barcodes per scope | Builds on topological framework |

## 12. Testing strategy

| Category | Path | Asserts |
|---|---|---|
| Unit | `tests/unit/` | Pydantic models, canonicalization, SHACL pass/fail per fixture |
| Conformance | `tests/conformance/` | Reference implementation passes the full conformance suite |
| Regression | `tests/regression/adcs/` | ADCS prototype corpus certifies identically (catches ontology drift) |
| Integration | `tests/integration/oslc-roundtrip/` | OSLC-RM + OSLC-QM lossless roundtrip across reference fixtures — **must pass from day one** |
| Integration | `tests/integration/flexo/` | Live Flexo transaction tests (marked `@pytest.mark.live`, auto-skip without `FLEXO_TOKEN`) |
| Property | `tests/property/` | Hypothesis-style: arbitrary valid graph → certify → re-verify → identical |
| Determinism | `tests/determinism/` | Same input → byte-identical transcript across runs / machines |

## 13. `flexo-rtm-research` — companion repo scope

Built **before** `flexo-rtm` implementation begins. Modeled after `flexo-conflict-resolution-policy-research` (Obsidian vault with interconnected markdown, mathematical notation, mermaid diagrams).

**Expected content (full layout to be planned in the next step):**

- `README.md` — overview + navigation
- `00-mission-and-thesis/` — verifiable self-certification thesis; relationship to INCOSE IS 2026 paper
- `10-internal-research/` — synthesis of prior work
  - `flexo-conflict-coexistence.md` — findings from `flexo-conflict-resolution-policy-research` applied to RTM
  - `adcs-prototype-lessons.md` — what works, what to extract, what to abstract
  - `mvc-pattern-from-rime-trl-ant.md` — applied to RTM operator workflow
  - `human-ai-accountability.md` — Zargham 2026 paper restated for RTM context
- `20-external-research/` — literature
  - `oslc-rm-qm-review.md` — IBM/Doors steering analysis, what to adopt, what to reject
  - `incose-v2-review.md` — concept hierarchy alignment, what's informative vs. normative
  - `omg-sysmlv2.md` — canonical model vocabulary; openCAESAR rendering
  - `prov-earl-gsn-pplan.md` — adopted vocabularies, parsimony extracts
- `30-certification-model/` — typed simplicial complex framework for RTM
  - `vertices-edges-faces.md` — formal types
  - `predicate-and-gaps.md` — certification predicate, gap taxonomy
  - `quantitative-outcomes.md` — coverage % vs. binary; thresholds; institutional adoption story
  - `aspect-coverage.md` — adequacy + sufficiency by aspect; GSN encoding
- `40-three-layer-architecture/` — operational, storage, analysis
  - `operational-ux-discipline.md` — why UX latency matters; working-set semantics
  - `storage-flexo-conventions.md` — named graphs, branches, transactions
  - `analysis-scope-algebra.md` — Scope as first-class; composition
- `50-ontology-design/` — layered ontology, alignment, profiles, parsimony
- `60-adapter-contracts/` — OSLC roundtrip definition; vendor extension carry-through
- `70-reproducibility/` — RDFC-1.0; transcript replay; approver binding via git
- `80-decision-log/` — ADRs (one per locked design choice; cross-linked)
- `90-incose-is-2026/` — stub / pointer to forthcoming paper; alignment notes

Mathematical detail, mermaid diagrams, and decision rationale live here. `flexo-rtm` references this repo from its ADRs.

## 14. Locked decisions log

| # | Decision | Rationale |
|---|---|---|
| D1 | Approach A (foundations-first) with iterative research/implement/standardize | User direction; prevents UX choices freezing ontology before research catches up |
| D2 | SysMLv2 anchoring (OMG conformant) | User-supplied scope reducer; concrete and well-specified |
| D3 | Typed simplicial complex framework (Zargham 2026) **documented as related research line; not on `flexo-rtm`'s roadmap** | Further research determined a proper topological audit requires recursive completeness (every evidence artifact has its own assurance triangle), which terminates only via a community-curated registry of pre-approved types. That registry conversation is internal to the topological research line. Per [[ADR-032 Methodology Agnosticism as Foundational Axiom]], if the research line matures it operates as one downstream-analysis path among several (SLSA, GSN, ARP4754A, in-house); `flexo-rtm` does not commit to it. Documented in `flexo-rtm-research/Topological Framework Future Work.md` |
| D3a | **v0.1 ships traditional analysis only; topological framework is a related research line** | Same rationale as D3 under [[ADR-032 Methodology Agnosticism as Foundational Axiom]]. The Level 1 / Level 2 naming previously used was simplified — there is now just "v0.1's analysis" (traditional bidirectional plus named-signer attestation) and "the topological framework" (related research line, not `flexo-rtm`'s destination). Vocabulary alignment with the topological framework is forward-compatible interop in v0.1 ontology, not a commitment to that research line as `flexo-rtm`'s downstream-analysis destination |
| D4 | Quantitative certification outcome | Institutional adoption needs the gradient, not stark pass/fail; coverage % is the primary outcome metric |
| D5 | Adequacy + sufficiency as explicit Guidance subtypes | Engineer judgment surfacing requires explicit checkpoint concepts |
| D6 | Three-layer architecture (operational / storage / analysis) | UX latency = adoption; persistent authority = Flexo; reporting = scoped reads |
| D7 | Scope as first-class RDF resource with composition algebra | Institutional unit of accountability is a named scope, not a global cert |
| D8 | `flexo-rtm` name; org → OpenMBEE transfer at MVP service | User direction |
| D9 | Companion `flexo-rtm-research` repo built **first**, then `flexo-rtm` | User direction; preserves research/design artifacts separately from clean software repo |
| D10 | OSLC-RM + OSLC-QM full adapters in v0.1 with lossless roundtrip tests | Hard requirement: "we cannot get institutional adoption if we cannot demonstrably roundtrip losslessly" |
| D11 | Lossless criterion = A (RDFC-1.0 equivalence) + C (opaque carry-through for vendor extensions) | Practical for vendor extensions; rigorous for core |
| D12 | Direct RDF properties for edges (not reified); approver enforcement on Attestation | Leaner data model; SHACL still enforces structurally |
| D13 | Simplicial complex as derived view (SPARQL CONSTRUCT → `knowledgecomplex`) | Avoids carrying complex objects in storage; analysis is opt-in |
| D14 | Parsimony layer: MIREOT/SLME extracts at build time; ~2k-triple target | Performance; clarity; auditable provenance of every imported triple |
| D15 | GSN adoption (parsimony-extracted) for adequacy/sufficiency claims | Consistent with ADCS prototype; interop with assurance-case tooling |
| D16 | Profile mechanism = composable SHACL contracts | Constraint selection orthogonal to data selection (Scope) |
| D17 | `knowledgecomplex` as `[analysis]` optional extras | Lean default install; analysis opt-in |
| D18 | V−F topological invariant is **not a `flexo-rtm` feature** — it is a research-line question, distinct from `flexo-rtm`'s scope | Further research determined purely numerical invariants insufficient; the proper topological audit requires recursive completeness checked against a registry of pre-approved types — a problem internal to the topological research line per [[ADR-032 Methodology Agnosticism as Foundational Axiom]] |
| D21 | **Topological framework is a related research line, not `flexo-rtm`'s destination; research repo documents the vision, registry concept, recursion challenge, open questions** | `flexo-rtm` is methodology-agnostic (per [[ADR-032 Methodology Agnosticism as Foundational Axiom]]); the topological framework articulated in Zargham (2026) shares philosophical kinship but is not required and is not on `flexo-rtm`'s critical path. If the research line matures, it operates as one optional downstream-analysis mode on top of `flexo-rtm`'s data alongside other paths (SLSA, GSN, ARP4754A, in-house). Aligned vocabulary ships in v0.1 ontology as forward-compatible interop for that and other downstream paths |
| D22 | **Adequacy and sufficiency attestations ship in v0.1 as typed `rtm:Attestation` subclasses** (independent of topological audit) | The ADCS regression corpus operates with adequacy and sufficiency attestations today; v0.1 must support these to pass regression tests. Three subclasses (`rtm:SatisfactionAttestation`, `rtm:AdequacyAttestation`, `rtm:SufficiencyAttestation`) all share named-approver SHACL enforcement. Audit reports show coverage and gaps per claim type per aspect. The recursive completeness audit (does the guidance itself meet adequacy/sufficiency criteria?) is what's deferred — the per-claim attestations are first-class v0.1 features |
| D23 | **External URI references (git+commit, content addresses, OCI digests) are foundational v0.1 vocabulary** | Evidence, models, and activities in the RDF graph reference concepts outside it via URI. These references — not the RDF metadata in isolation — are the source of true open-source interoperability, portability, auditability, and reproducibility. The ADCS prototype already operates this way (Docker compute backend captures `prov:atLocation` / `prov:wasAssociatedWith`); v0.1 formalizes the vocabulary (`rtm:hasGitRepo`, `rtm:hasGitCommit`, `rtm:hasContentHash`, `rtm:hasOCIImage`) plus PROV-O provenance, and adds SHACL discipline. Reproducibility chain (§4.9) extends beyond RDF-internal canonical hashing to include re-fetching code/data/containers from their external URIs and re-executing |
| D24 | **Cryptography by composition of battle-tested standards, never invention** | Signed envelopes use: git GPG/SSH commit signing, W3C Verifiable Credentials + Data Integrity proofs, DSSE + in-toto attestation predicates, Sigstore cosign + Rekor transparency log, OCI image signatures. Vocabulary support shipped in v0.1 (`sec:proof`, `rtm:dsseEnvelope`, `rtm:cosignBundle`, `rtm:rekorLogEntry`); profile-gated requirements (`signed-commits`, `data-integrity-attestations`, `dsse-activities`, `cosign-images`, `rekor-transparency`) off by default. No custom crypto, no custom envelopes, no custom transparency logs. Closes the ADCS prototype's "signed envelopes deferred" gap |
| D25 | **Identity by thin projection of external authoritative sources, never ownership** | `flexo-rtm` does not authenticate users or store credentials. Named approvers (per D21) are IRIs referencing identities owned by institutional SSO (OIDC, SAML), LDAP/AD, GitHub/GitLab, etc. v0.1 ships vocabulary for thin RDF projections (`rtm:hasExternalIdentity`, `foaf:Person`, `org:Membership`, `rtm:Attribute`, `rtm:Policy`) plus three configurable policy primitives (role-based, attribute-based, scope-based) all SPARQL-evaluable. Single bottleneck via SHACL ensures authority can be certified. Reference adapters: GitHub, OIDC, GitHub Actions OIDC. Adopters extend for SAML/LDAP/Okta/Auth0/Keycloak via thin adapter pattern. The ADCS prototype hard-coded GitHub IDs; v0.1 generalizes the integration boundary |
| D26 | **Reproducibility is structural and local, enabling federated verification** | Each fact in the cert artifact is structurally complete for its own local context — the RDF neighborhood, external URIs, projection-at-cert-time, and signatures sufficient to reproduce that fact in isolation. Verifying parties need only permissions for the facts they want to verify, not universal access. Reproduction federates computationally (compute distributes across parties) and organizationally (different parties verify different permission slices, composing to a complete audit). This is not a tension with refresh policies — refresh affects authoring-time freshness; reproduction always operates on the recorded projection-at-cert-time. The locality property is what makes multi-party institutional verification possible without central coordination. Cross-cutting acceptance criteria X6, X7, X8 enforce this (§9.A.5) |
| D19 | Binary certification view derived from quantitative metrics (configurable threshold) | Reconciles paper's TDD pass/fail with industrial coverage-growing reality |
| D20 | Vocabulary: "assurance complex / assurance face / assurance triple" verbatim from Zargham 2026 | Paper and implementation mutually citable |

## 15. Open items for next step

The next step is **`writing-plans`** for `flexo-rtm-research` (the companion research repo), **not** for `flexo-rtm` implementation. Planning the research repo allows the user to review the full design + rationale in depth before implementation begins.

After `flexo-rtm-research` is built and reviewed, a separate planning session will scope `flexo-rtm` v0.1 implementation.
