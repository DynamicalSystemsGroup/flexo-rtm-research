<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Identity Boundaries and Policy Projections

> Elaborates [[Design Spec]] §4.4 (Identity boundaries — thin projections of external authoritative sources). The acceptance criteria **I1–I8** in §9.A.3 are normative for this page. v0.1 ships vocabulary, three reference adapters, the SHACL bottleneck shape, the adapter contract, and refresh-policy options with transcript provenance. Defeaters / SACM-style revocation are deferred.

## Same composition principle as cryptography

Identity is to `flexo-rtm` what cryptography is to a signed envelope: a domain where the system MUST integrate with established external standards and MUST NOT invent. [[Signed Envelopes and Established Standards]] explains the parallel for crypto — `flexo-rtm` does not implement cipher primitives; it consumes signatures produced by Sigstore, GPG, SSH, X.509. The same discipline applies here. `flexo-rtm` does not authenticate users, does not store credentials, does not arbitrate group membership. It carries **thin RDF projections** of identity facts that an external authoritative system has already produced, and uses those projections to certify that policy enforcement occurred.

The ADCS prototype (see [[ADCS Prototype Lessons]]) hardcoded GitHub user IDs as approver references. That worked for one institution but was a category leak — a specific identity provider was baked into the oracle's data model. v0.1 generalizes the integration surface so any identity provider (OIDC, SAML, LDAP/AD, GitHub/GitLab, Keycloak, Okta, Auth0, custom internal SSO) can be wired in via a thin adapter, while the RDF projection inside the system uses W3C-foundational vocabularies (FOAF + Org Ontology) with minimal `rtm:` extensions at the integration seams.

## The four-property boundary discipline

Every aspect of v0.1's identity story follows from four properties:

1. **Source of truth lives outside.** Employee records, role assignments, group memberships, attribute claims (clearance, certification, training status), and policy authoring all happen in the institutional identity provider and adopter-managed RDF — not in `flexo-rtm`. The oracle never asks "is this person really a safety engineer?" — the projection says they are or it doesn't, and the projection came from a system that has the authoritative answer.
2. **Thin projections live inside.** Just enough RDF to support SHACL/SPARQL validation. No PII beyond the IRI handle and what the policy actually evaluates. No credentials, no tokens, no session state. The projection is forensic, not authoritative: it records "at certification time, the projection said X" so an auditor can re-evaluate authorization without dereferencing the live provider.
3. **One bottleneck.** All identity references in the graph go through typed primitives — `rtm:approvedBy` on attestations, `rtm:hasExternalIdentity` on `foaf:Person`. A single SHACL shape (`rtm:AttestationAuthorizationShape`, §9.A.3 I1) enforces that every attestation has an approver IRI and that the approver matches an authorizing `rtm:Policy`. This bottleneck is what makes policy enforcement certifiable: there is one place where it happens, and it is structural.
4. **Configurable per institution.** Adopters wire their identity provider via a thin adapter conforming to the documented adapter contract. v0.1 ships three reference adapters (GitHub, generic OIDC, GitHub Actions OIDC); the contract makes SAML, LDAP/AD, Okta, Auth0, Keycloak adapters straightforward to author without touching oracle core (§9.A.3 I6).

These four properties together mean: `flexo-rtm` never owns identity, but `flexo-rtm` can certify that identity-based policy was enforced at the moment of attestation.

## Identity projection vocabulary

The projection uses three established W3C vocabularies plus three `rtm:` extension predicates:

- **W3C FOAF** — `foaf:Person`, `foaf:name`, `foaf:mbox` — for the human identity itself
- **W3C Organization Ontology** — `org:Membership`, `org:role`, `org:organization` — for the role / org binding
- **`rtm:hasExternalIdentity`** — carries the source-system identifier so the projection can be reverse-linked to the authoritative system
- **`rtm:Attribute` + `rtm:attributeKey` / `rtm:attributeValue`** — for arbitrary key/value claims (clearance level, certification status, training completion, jurisdictional authority)
- **`rtm:scopedTo`** — binds memberships and attribute claims to a scope IRI from [[Analysis Layer Scope Algebra]], enabling scope-based authority

A worked Turtle projection:

```turtle
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix org:  <http://www.w3.org/ns/org#> .
@prefix rtm:  <https://flexo-rtm.example.org/ns#> .

:engineer-zargham a foaf:Person ;
    foaf:name "Michael Zargham" ;
    rtm:hasExternalIdentity "github:zargham" ,
                            "oidc:https://auth.example.org/zargham" ,
                            "ldap:CN=Zargham,OU=Engineering,DC=example,DC=org" ;
    org:hasMembership :membership-safety-zargham .

:membership-safety-zargham a org:Membership ;
    org:role rtm:role/safety-engineer ;
    org:organization :org-flexo-aerospace ;
    rtm:hasAttribute :attr-clearance-zargham ,
                     :attr-cert-safety-zargham ;
    rtm:scopedTo rtm:scope/adcs-program .

:attr-clearance-zargham a rtm:Attribute ;
    rtm:attributeKey "security-clearance" ;
    rtm:attributeValue "SECRET" .

:attr-cert-safety-zargham a rtm:Attribute ;
    rtm:attributeKey "safety-certification" ;
    rtm:attributeValue "DO-178C-DER" .
```

Three identity strings on the same `foaf:Person` is intentional: an institution may federate GitHub for code authorship, OIDC for SSO, and LDAP for HR records. The projection asserts that all three handles refer to the same person; downstream policy evaluation can reference any of them, and a `signed-commits` profile (§9.A.3 I7) can bind a GPG/SSH key fingerprint to the GitHub identity for git-level approver checks. See [[Approver Binding via Git]] for the signed-commit binding mechanism.

The projection is composed, not invented. FOAF and Org Ontology cover the parts that have W3C standards; `rtm:` predicates appear only at the seams where standard vocabularies don't reach (external-identity strings, opaque attribute claims, scope-binding).

## Three policy primitives

Policies in v0.1 are RDF resources (`rtm:Policy` instances), versioned and queryable like any other graph. Three primitive kinds compose:

| Kind | RDF expression | Worked example |
|---|---|---|
| **Role-based (RBAC)** | `rtm:Policy` with `rtm:appliesToRole <role-iri>` | "Safety engineers may attest `rtm:SufficiencyAttestation` for `rtm:safety` aspect" |
| **Attribute-based (ABAC)** | `rtm:Policy` with `rtm:requiresAttribute [ rtm:attributeKey "X" ; rtm:attributeMinValue "Y" ]` | "Clearance ≥ SECRET to attest classified-data sufficiency" |
| **Scope-based** | `rtm:Policy` with `rtm:withinScope <scope-iri>` | "Approver authorized only for `rtm:scope/adcs-attitude-control` and its sub-scopes" |

A policy can require any combination of role + attributes + scope. The combination is conjunctive by default — all predicates must be satisfied — and disjunction is expressed by authoring multiple policies (any one authorizes).

The full policy vocabulary:

- `rtm:Policy` — a policy resource
- `rtm:appliesToRole`, `rtm:appliesToIdentity` — which identities the policy authorizes (role-level or specific person)
- `rtm:requiresAttribute` (nested blank node with `rtm:attributeKey`, `rtm:attributeMinValue`, `rtm:attributeValue`)
- `rtm:withinScope` — scope IRI(s) where the authorization applies; sub-scopes inherit by default (§9.A.3 I4)
- `rtm:permitsAttestationType` — which `rtm:Attestation` subclass the policy authorizes (e.g., `rtm:SufficiencyAttestation`, `rtm:SatisfactionAttestation`)
- `rtm:permitsAspect` — which aspect(s) the attestation may address (`rtm:safety`, `rtm:performance`, `rtm:security`, etc.)
- `rtm:effectiveAt`, `rtm:expiresAt` — temporal bounds for policy versioning

A worked policy:

```turtle
:policy-safety-sufficiency a rtm:Policy ;
    rtm:appliesToRole rtm:role/safety-engineer ;
    rtm:requiresAttribute [
        rtm:attributeKey "security-clearance" ;
        rtm:attributeMinValue "CONFIDENTIAL"
    ] ;
    rtm:permitsAttestationType rtm:SufficiencyAttestation ;
    rtm:permitsAspect rtm:safety ;
    rtm:withinScope rtm:scope/adcs-program ;
    rtm:effectiveAt "2026-01-01T00:00:00Z"^^xsd:dateTime .
```

Reads as: an identity holding the `safety-engineer` role, with a `security-clearance` attribute valued at least CONFIDENTIAL, may emit a `rtm:SufficiencyAttestation` for the `rtm:safety` aspect anywhere within `rtm:scope/adcs-program` (or sub-scopes thereof), as of 2026-01-01.

## The SHACL bottleneck

Policy enforcement is one SHACL shape with an embedded SPARQL pattern. This is the single point where authority is checked in v0.1 (§9.A.3 I1, I2, I3, I4):

```turtle
rtm:AttestationAuthorizationShape a sh:NodeShape ;
    sh:targetClass rtm:Attestation ;
    sh:property [
        sh:path rtm:approvedBy ;
        sh:minCount 1 ;
        sh:nodeKind sh:IRI ;
        sh:message "Every attestation MUST carry rtm:approvedBy <IRI> (I1)."
    ] ;
    sh:sparql [
        sh:select """
            PREFIX rtm: <https://flexo-rtm.example.org/ns#>
            PREFIX org: <http://www.w3.org/ns/org#>

            SELECT $this WHERE {
                $this rtm:approvedBy ?approver ;
                      a ?attestationType ;
                      rtm:hasAspect ?aspect ;
                      rtm:appliesTo ?subject .
                ?subject rtm:inScope ?scope .

                # Reject if NO authorizing policy exists
                FILTER NOT EXISTS {
                    ?policy a rtm:Policy ;
                            rtm:permitsAttestationType ?attestationType ;
                            rtm:permitsAspect ?aspect ;
                            rtm:withinScope ?policyScope ;
                            rtm:appliesToRole ?policyRole .
                    ?scope rtm:withinScopeAncestor* ?policyScope .
                    ?approver org:hasMembership ?membership .
                    ?membership org:role ?policyRole .
                    # Attribute predicate check: every required attribute
                    # on the policy is satisfied by the approver's membership
                    FILTER NOT EXISTS {
                        ?policy rtm:requiresAttribute ?reqAttr .
                        ?reqAttr rtm:attributeKey ?k ;
                                 rtm:attributeMinValue ?minV .
                        FILTER NOT EXISTS {
                            ?membership rtm:hasAttribute ?attr .
                            ?attr rtm:attributeKey ?k ;
                                  rtm:attributeValue ?v .
                            FILTER (?v >= ?minV)
                        }
                    }
                }
            }
        """ ;
        sh:message "Approver not authorized for this attestation under current policy."
    ] .
```

The shape combines a structural property check (every attestation has an `rtm:approvedBy` IRI — I1) with a SPARQL pattern that returns offending instances when no authorizing policy can be found. The nested `FILTER NOT EXISTS` over `rtm:requiresAttribute` implements the ABAC predicate: a policy without required attributes vacuously passes; a policy with required attributes is satisfied only if every required attribute has a matching attribute on the approver's membership with sufficient value (I3). The `rtm:withinScopeAncestor*` transitive path implements scope hierarchy: an approver scoped to an ancestor scope is authorized for descendants, but not siblings (I4).

This shape is **the** point where v0.1's identity authority is checked. Profile gating allows stricter or laxer variants — `--profile=require-role-policy` makes the role match mandatory rather than optional; `--profile=require-clearance-attribute` requires an explicit clearance attribute predicate.

## Three reference adapters

v0.1 ships three working reference adapters demonstrating the projection contract (§9.A.3 I5):

### GitHub adapter

Mirrors the ADCS prototype's approach, generalized. Input: GitHub user object (handle, name, email) plus GitHub Teams membership for the relevant org. Output: `foaf:Person` with `rtm:hasExternalIdentity "github:<handle>"`; one `org:Membership` per team with `org:role` derived from a configurable team-to-role mapping. Refresh policies supported: cert run, on commit, scheduled, static. Uses the GitHub REST API (or GraphQL) with a least-privilege read token. Suited for projects whose authoritative identity provider IS GitHub.

### Generic OIDC adapter

Input: OIDC ID token claims per OIDC Core 1.0 (`sub`, `email`, `name`, `groups`, plus arbitrary custom claims). Output: `foaf:Person` with `rtm:hasExternalIdentity "oidc:<issuer>/<sub>"`; `org:Membership` per group claim with role mapping configurable per institution; `rtm:Attribute` per configured custom claim (e.g., `clearance`, `certification`). Refresh on token validation or scheduled refresh of the claims graph. Suited for any Keycloak / Okta / Auth0 / Azure AD / Google deployment.

### GitHub Actions OIDC adapter

A specialization for CI keyless signing. Input: the ephemeral OIDC token GitHub Actions provides to a workflow run, with claims for `repository`, `workflow`, `ref`, `sha`, `actor`, `job_workflow_ref`. Output: a short-lived `foaf:Person` projection bound to the workflow run, with `rtm:hasExternalIdentity "github-actions:<repo>/<workflow>@<ref>"` and `rtm:scopedTo` set to a scope derived from the workflow. Designed for keyless-signed attestations in CI per Sigstore Fulcio — see [[Signed Envelopes and Established Standards]]. The projection is created at workflow start, used for one cert run, and not persisted as an institutional identity.

## Adapter contract for new providers

Adapters are thin: **input** = source-system identity claims, **output** = conforming `foaf:Person` + `org:Membership` + `rtm:Attribute` triples that pass the projection SHACL shape. No business logic. No identity resolution heuristics. Pure projection.

The contract is documented in the spec deliverable `spec/identity-adapter-contract.md` (referenced in [[Design Spec]] §8 Table). New adapters require zero code changes to oracle core (§9.A.3 I6). Adding a provider:

- **SAML 2.0** — Input: SAML assertion with `Subject/NameID` and `AttributeStatement` (groups, clearance). Output: `foaf:Person` with `rtm:hasExternalIdentity "saml:<entityID>/<nameID>"`; `org:Membership` per group attribute. Useful where an institution already runs Shibboleth or ADFS. Refresh on session establishment.
- **LDAP / Active Directory** — Input: LDAP `inetOrgPerson` / AD user objects with `memberOf` group references. Output: `foaf:Person` with `rtm:hasExternalIdentity "ldap:<DN>"`; `org:Membership` per `memberOf` through a DN-to-role configuration. Refresh on schedule or cert run. Common for enterprises whose source of truth is AD.
- **Okta** — Use the generic OIDC adapter against Okta's OIDC endpoints, or use SCIM 2.0 for a richer attribute map. Group memberships become `org:Membership`; custom profile attributes become `rtm:Attribute`.
- **Auth0** — OIDC adapter against Auth0's `/userinfo` endpoint. Auth0 rules shape custom claims into the ID token, which the adapter projects as `rtm:Attribute`.
- **Keycloak** — OIDC adapter, with role claims mapped to `org:Membership` per the realm's role mapper. Keycloak's flexible claim shaping means most institutions route arbitrary attributes through standard OIDC without a custom adapter.

In every case the adapter authors only the translation; the SHACL projection shape validates that the output conforms. An adapter that produces malformed projections fails CI before it can land.

## Refresh policy: four options

Projections are **point-in-time** by design — `flexo-rtm` is not a real-time identity sync, and pretending otherwise would violate the source-of-truth-lives-outside discipline. Adopters configure refresh policy per institution:

| Option | Behavior | Trade-off |
|---|---|---|
| **Every cert run** | Projection rebuilt from authoritative source on each certification | Always current; high cost on slow/rate-limited providers |
| **On commit** | Projection captured at attestation-author time; persisted with the commit | Correct at the moment of authoring; may drift before audit |
| **Scheduled** | Nightly/weekly refresh job rebuilds projection | Predictable cost; bounded staleness; not real-time |
| **Static** | Snapshot loaded at startup, fixed for the session | Deterministic for tests and historical audit replay |

The transcript (see [[Verifiable Self-Certification]]) records **both** the refresh policy that was active **and** the projection-as-of-cert-time. This means an audit re-run is reproducible against the recorded projection regardless of what the live identity provider currently says (§9.A.3 I8). If a person's clearance is downgraded a week after an attestation, the attestation does not retroactively become unauthorized — the projection-at-cert-time still shows the clearance they held at the moment of authoring, and the SHACL outcome at that moment is structurally captured.

Freshness and reproducibility are complementary, not in tension. Adopters who want stronger non-repudiation choose `static` + `signed-commits` profiles; adopters who want always-current authorization choose `every cert run`. Both paths produce structurally-complete artifacts because the projection-at-cert-time is in the transcript.

## Worked policy enforcement scenario

Engineer Zargham attempts to commit a `rtm:SufficiencyAttestation` for the safety aspect of a requirement in the `adcs-attitude-control` scope.

**Identity projection at commit time:**

```turtle
:engineer-zargham a foaf:Person ;
    rtm:hasExternalIdentity "github:zargham" ;
    org:hasMembership :m1 .
:m1 a org:Membership ;
    org:role rtm:role/safety-engineer ;
    rtm:hasAttribute [ rtm:attributeKey "security-clearance" ;
                       rtm:attributeValue "SECRET" ] ;
    rtm:scopedTo rtm:scope/adcs-program .
```

**Applicable policy:** `:policy-safety-sufficiency` (shown earlier) — requires `safety-engineer` role, `security-clearance ≥ CONFIDENTIAL`, scope `adcs-program`.

**SHACL evaluation:**
- Approver IRI present: yes (I1 satisfied)
- Role match: `safety-engineer` = `rtm:appliesToRole` value (I2 role predicate satisfied)
- Attribute predicate: `SECRET ≥ CONFIDENTIAL`, satisfied (I2 attribute predicate satisfied)
- Scope: `adcs-attitude-control` is a descendant of `adcs-program` via `rtm:withinScopeAncestor*` (I2/I4 scope predicate satisfied)
- All predicates satisfied: SHACL passes, attestation is accepted, the cert artifact records the projection-at-cert-time

**Counterfactual A — attribute fails (I3):** if Zargham's clearance were `UNCLASSIFIED`, the ABAC predicate `?v >= "CONFIDENTIAL"` fails, the `FILTER NOT EXISTS` over policies returns true (no authorizing policy found), SHACL returns the violation, and the write is rejected with the message *"Approver not authorized for this attestation under current policy."* The transcript records the rejection along with the projection-at-cert-time, so a remediation review can see exactly what attribute was missing.

**Counterfactual B — scope fails (I4):** if Zargham were scoped only to `rtm:scope/adcs-power` (a sibling scope, not an ancestor of `adcs-attitude-control`), the transitive scope check fails, no authorizing policy is found, and the attestation is rejected. Sibling scopes are not transitively connected by `rtm:withinScopeAncestor`.

## Why not XACML / OPA / VC-only / bake auth in

**Why not XACML?** XACML 3.0 is a heavyweight XML policy language with its own evaluation engine. The data model `flexo-rtm` already requires is RDF + SPARQL; reusing it for policy means zero new languages, zero new engines, and policies that compose naturally with the rest of the graph.

**Why not OPA / Rego / Cedar?** OPA is excellent for general-purpose authorization, but it introduces a separate policy DSL the audit chain would have to understand. One substrate is simpler than two. An adopter that prefers OPA can run it upstream of an attestation gate and project the OPA decision as an `rtm:Attribute` — the bottleneck remains the SHACL shape; OPA is just one more attribute source.

**Why not bake auth into the oracle?** Owning identity means owning credentials, sessions, MFA, account lifecycle, GDPR data subject requests, and audit trails of authentication itself. Every adopter institution already has that infrastructure. Building it again would violate the thin-projection principle and drift from institutional ground truth.

**Why not Verifiable Credentials only?** VCs (W3C VC Data Model 2.0) are valuable for asserting claims about identities — a clearance VC, a certification VC. These compose with the projection: a VC parses to `rtm:Attribute` triples scoped to the membership. VC and projection are not in competition. VC-only isn't sufficient because not every adopter institution issues VCs today, and the projection layer needs to integrate with the systems institutions actually run — mostly OIDC, SAML, LDAP, and platform-native auth.

## What v0.1 ships vs. what's deferred

**Ships in v0.1:**
- Vocabulary: `rtm:hasExternalIdentity`, `rtm:Attribute`, `rtm:scopedTo`, `rtm:Policy`, `rtm:appliesToRole`, `rtm:appliesToIdentity`, `rtm:requiresAttribute`, `rtm:permitsAttestationType`, `rtm:permitsAspect`, `rtm:withinScope`, `rtm:effectiveAt`, `rtm:expiresAt`
- SHACL policy-enforcement shape (`rtm:AttestationAuthorizationShape`, the bottleneck) covering I1–I4
- Three reference adapters: GitHub, generic OIDC, GitHub Actions OIDC (I5)
- Adapter contract documentation in `spec/identity-adapter-contract.md` (I6)
- Refresh-policy options + transcript provenance for projections (I8)
- Profile-gated optional shapes (`require-role-policy`, `require-clearance-attribute`, `signed-commits` for I7)

**Deferred to v0.2+ future framework:**
- No user authentication, sessions, credential storage, password resets, MFA, OAuth refresh flows
- No XACML / OPA / Cedar / Rego policy engines; policy IS RDF + SPARQL
- No real-time projection sync; refresh is point-in-time and adopter-configurable
- No identity provider conflict arbitration; one primary provider per adopter — multi-provider federation is the adopter's responsibility
- No policy authoring UI; policies are RDF and adopter tooling provides authoring UX
- No defeaters / SACM-style attestation revocation — would propagate as a new attestation in a future revision, locally verifiable, without invalidating past artifacts' structural completeness

## Org-level identities (extension for federated audit)

Person-level identities are the natural starting point for named-approver attestations — every claim resolves to an accountable human. Many real-world certification patterns also require **org-level identities**: an accredited reproducibility auditor, a notified body, a regulator-of-record, a customer engineering team, a sister-organization reproducibility verifier. These are properties of an **organization**, not (only) of an individual. The polycentric ASOT model (see [[ADR-030 Polycentric ASOT Authority Model]]) is what makes org-level identity load-bearing: each scope's [Authoritative Source of Truth](https://www.dau.edu/glossary/authoritative-source-truth) is held by an organization, and federated audit attestations require both the human approver and the organization whose scoped authority that approver acts under. [[Federated Audit and Composition]] requires this surface to make qualified-role attestations first-class.

The extension is straightforward — org-level identities project the **same way** person-level identities do, through the same thin-adapter pattern. W3C FOAF (`foaf:Organization`) and the W3C Organization Ontology (`org:Organization`) cover the org-level shape; the `rtm:hasExternalIdentity` predicate carries the external-identity reference; `rtm:hasQualifiedRole` is the org-level analog of `org:role` on a membership.

```turtle
:org-qreliability-labs a org:Organization, foaf:Organization ;
    foaf:name "Q-Reliability Labs" ;
    rtm:hasExternalIdentity "github:qreliability" ,
                            "oidc:https://auth.qreliability.example/org/qreliability-labs" ;
    rtm:hasQualifiedRole rtm:role/accredited-reproducibility-auditor ,
                         rtm:role/notified-body ;
    rtm:scopedTo rtm:scope/adcs-program .

:engineer-jdoe a foaf:Person ;
    foaf:name "Jane Doe" ;
    rtm:hasExternalIdentity "github:jdoe-qreliability" ;
    org:hasMembership :membership-jdoe-qreliability .

:membership-jdoe-qreliability a org:Membership ;
    org:organization :org-qreliability-labs ;
    org:role rtm:role/accredited-reproducibility-auditor .
```

A federated-audit attestation (`rtm:ScopeCertificationAttestation`, see [[Federated Audit and Composition]]) references the person via `rtm:approvedBy` **and** the org via `rtm:approverOrganization`. Both are projected through the same adapter pattern — GitHub orgs, OIDC org claims, LDAP organizational units, SAML attribute groups. The same SHACL bottleneck (`rtm:AttestationAuthorizationShape`) governs org-level attestations because the parent class `rtm:Attestation` is the SHACL target; the qualified-role predicate adds a new dimension to authority checking but does not require a new bottleneck.

The qualified-role set is **adopter-defined** in v0.1. A program declares which roles are "qualified" in its own identity projection — e.g., `rtm:role/accredited-reproducibility-auditor` is meaningful when the adopter's RDF says it is. A community-curated registry of qualified roles and orgs is forward-compatible future work (per [[Federated Audit and Composition]]), similar in spirit to the topological framework's pre-approved-types registry. The same composition principle applies: `flexo-rtm` projects org identity from external authoritative sources; it does not own org records any more than it owns person records.

## Forward compatibility with the topological framework

When the topological framework lands, the identity projection serves the recursive completeness check unchanged. Every assurance face's named approver is policy-evaluated through the same SHACL bottleneck. Policies themselves can be registered as pre-approved authority claims so the registry of authorizing rules is part of the certifiable graph. The projection-at-time discipline carries through: future revocation events propagate as new attestations against the projection, and historical attestations remain locally verifiable against the projection-as-of-cert-time. [[Human-AI Accountability]] is also served — when an attestation is co-authored by a human and an AI agent, both project through the same vocabulary, and policy can require human-in-the-loop approval as an attribute predicate.

## Cross-references

- [[Design Spec]] §4.4 (normative source), §9.A.3 (I1–I8 acceptance criteria)
- [[Attestation Infrastructure in v0.1]]
- [[Signed Envelopes and Established Standards]] — parallel composition principle for cryptography
- [[External URI References]]
- [[Verifiable Self-Certification]]
- [[Approver Binding via Git]] — signed-commits profile binding (I7)
- [[Analysis Layer Scope Algebra]] — scope IRIs and hierarchy (I4)
- [[Human-AI Accountability]]
- [[ADCS Prototype Lessons]] — the GitHub-ID hardcoding this generalizes
- [[Federated Audit and Composition]] — org-level identities and qualified-role attestations layered on this projection model
- [[Multi-Agent Discourse Graph Precedent]] — internal prior art for the "policy IS RDF + SPARQL" discipline and structurally isolated policy graphs
