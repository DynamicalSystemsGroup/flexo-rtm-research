<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Identity Adapter Contract

> **Normative contract** for identity-projection adapters. The input/output schema, reference adapter specifications, SHACL projection shape, refresh-policy semantics, and new-provider extension guide live here. The `flexo-rtm` [[Design Spec]] §4.3 and §6.3 reference this page; tests under `tests/conformance/test_identity_adapters.py`, `test_adapter_contract_schema.py` enforce it. See also [[ADR-025 Identity by Thin Projection of External Sources]], [[Identity Boundaries and Policy Projections]] (rationale).

## 1. Scope

`flexo-rtm` does not authenticate users. It carries thin RDF projections of identities authored by external authoritative systems (institutional SSO via OIDC / SAML, LDAP / Active Directory, GitHub / GitLab, custom identity providers).

Adapters are **thin** — they translate provider-specific identity claims into the projection schema (§4 below). Adapters have no business logic; they do not arbitrate identity provider conflicts; they do not store credentials.

This contract specifies (a) the projection schema all adapters MUST produce, (b) the reference adapters shipped in v0.1, (c) the SHACL shape that validates conforming projections, (d) refresh-policy semantics, and (e) how to extend `flexo-rtm` to support a new provider.

## 2. The boundary discipline

1. **Source of truth lives outside.** Employee records, role assignments, group memberships, attribute claims live in the institutional identity provider.
2. **Thin projections live inside.** RDF projection captures just enough for SHACL/SPARQL policy evaluation.
3. **One bottleneck.** All identity references in `flexo-rtm` go through typed primitives (`rtm:approvedBy`, `rtm:hasExternalIdentity`).
4. **Configurable per institution.** Adopters wire their identity provider via an adapter conforming to this contract.

## 3. Projection schema (RDF output)

The output of any adapter is RDF using these vocabularies:

- W3C **FOAF** for persons (`foaf:Person`, `foaf:name`, `foaf:mbox`)
- W3C **Org Ontology** for organizations and memberships (`org:Organization`, `org:Membership`, `org:role`, `org:organization`)
- W3C **PROV-O** for projection provenance (`prov:wasGeneratedAtTime`, `prov:wasAttributedTo`)
- `rtm:` namespace for the integration seams (external-identity strings, attributes, scope, policy)

### 3.1 Person projection

```turtle
:engineer-zargham a foaf:Person ;
    rtm:hasExternalIdentity "github:zargham" ,                       # required: at least one
                            "oidc:https://idp.example/sub-123" ;     # multiple allowed
    foaf:name "Michael Zargham" ;                                    # optional
    foaf:mbox <mailto:michael@example.org> ;                         # optional
    org:hasMembership :membership-1 .

:membership-1 a org:Membership ;
    org:role rtm:role/safety-engineer ;                              # required
    org:organization :org-adcs ;                                     # required
    rtm:scopedTo rtm:scope/adcs-program ;                            # optional; if absent, scope-unbounded
    rtm:hasAttribute :attr-clearance-secret .                        # optional; many allowed
```

### 3.2 Attribute projection

```turtle
:attr-clearance-secret a rtm:Attribute ;
    rtm:attributeKey "security-clearance" ;
    rtm:attributeValue "SECRET" .
```

Attribute values are typed by the adapter:

- `xsd:string` for symbolic values (clearance levels, certification names)
- `xsd:dateTime` for date-bounded attributes (training-completion-date)
- `xsd:integer` / `xsd:decimal` for numerical attributes
- `xsd:boolean` for flags

When attribute values are ordered (e.g., clearance levels: `UNCLASSIFIED < CONFIDENTIAL < SECRET < TOP_SECRET`), the adapter MUST provide a separate ordering declaration via `rtm:attributeOrdering`:

```turtle
rtm:attributeKey/security-clearance rtm:attributeOrdering (
    "UNCLASSIFIED" "CONFIDENTIAL" "SECRET" "TOP_SECRET"
) .
```

Policies using `rtm:attributeMinValue` consult this ordering at SPARQL evaluation time.

### 3.3 Organization projection (per ADR-028)

```turtle
:org-adcs a org:Organization ;
    foaf:name "ADCS Engineering Team" ;
    rtm:hasExternalIdentity "github-team:dynamicalsystemsgroup/adcs" ;
    rtm:hasQualifiedRole rtm:role/qualified-auditor-aerospace ,       # optional; for §4.8 L3 audits
                         rtm:role/asot-holder .                       # optional; for ADR-030 ASOT
```

Organizations participate in scope ASOT designation (`rtm:asotHeldBy`) and qualified-role audits (§4.8 Level 3 of Design Spec).

### 3.4 Policy projection

Policies are RDF resources independent of any single identity. The projection contains policies the adapter has authority to attach to identities under its provider domain:

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

A policy says: an identity with this role, satisfying these attribute predicates, may emit these attestation types for these aspects within these scopes.

Policy IRIs MUST be stable across refreshes. Policies SHOULD be versioned via `owl:versionInfo` when their content changes; new versions get new IRIs.

### 3.5 Projection provenance

Every projection bundle SHOULD include provenance for the projection itself:

```turtle
:projection-2026-05-18T14-30-00Z a prov:Entity ;
    prov:wasGeneratedAtTime "2026-05-18T14:30:00Z"^^xsd:dateTime ;
    prov:wasAttributedTo :github-adapter-v0-1 ;
    prov:specializationOf rtm:identity-projection ;
    rtm:refreshPolicy "every-cert-run" .                              # see §6
```

The audit transcript references this entity to record the projection-as-of-cert-time.

## 4. SHACL projection shape (validation target)

`flexo-rtm` validates adapter output against `ontology/shapes/identity-projection.shacl.ttl`. The shape enforces:

```turtle
rtm:PersonProjectionShape a sh:NodeShape ;
    sh:targetClass foaf:Person ;
    sh:property [
        sh:path rtm:hasExternalIdentity ;
        sh:minCount 1 ;
        sh:datatype xsd:string ;
        sh:message "Every projected Person requires at least one rtm:hasExternalIdentity string"
    ] .

rtm:MembershipProjectionShape a sh:NodeShape ;
    sh:targetClass org:Membership ;
    sh:property [
        sh:path org:role ;
        sh:minCount 1 ;
        sh:nodeKind sh:IRI ;
        sh:message "Every Membership requires an org:role IRI"
    ] ;
    sh:property [
        sh:path org:organization ;
        sh:minCount 1 ;
        sh:nodeKind sh:IRI ;
        sh:message "Every Membership requires an org:organization IRI"
    ] .

rtm:AttributeProjectionShape a sh:NodeShape ;
    sh:targetClass rtm:Attribute ;
    sh:property [ sh:path rtm:attributeKey ; sh:minCount 1 ; sh:datatype xsd:string ] ;
    sh:property [ sh:path rtm:attributeValue ; sh:minCount 1 ] .

rtm:PolicyProjectionShape a sh:NodeShape ;
    sh:targetClass rtm:Policy ;
    sh:property [ sh:path rtm:permitsAttestationType ; sh:minCount 1 ; sh:nodeKind sh:IRI ] ;
    sh:property [ sh:path rtm:withinScope ; sh:minCount 1 ; sh:nodeKind sh:IRI ] .
```

An adapter that produces RDF passing this shape is **conforming**.

## 5. SHACL policy-enforcement bottleneck

When a new attestation is written, the following SHACL constraint evaluates applicable policies via SPARQL. This is the single point where authority is checked:

```turtle
rtm:AttestationAuthorizationShape a sh:NodeShape ;
    sh:targetClass rtm:Attestation ;
    sh:sparql [
        sh:message "Approver not authorized for this attestation under current policy" ;
        sh:select """
            PREFIX rtm: <https://example.org/rtm/>
            PREFIX org: <http://www.w3.org/ns/org#>
            
            SELECT $this WHERE {
                $this rtm:approvedBy ?approver ;
                      a ?attestationType ;
                      rtm:appliesTo ?subject .
                ?subject rtm:hasAspect ?aspect ;
                         rtm:inScope ?scope .
                
                FILTER NOT EXISTS {
                    ?policy a rtm:Policy ;
                            rtm:permitsAttestationType ?attestationType ;
                            rtm:permitsAspect ?aspect ;
                            rtm:withinScope ?scopeMatch .
                    
                    # Scope match: policy scope == subject scope OR subject scope is sub-scope
                    { ?subject rtm:inScope ?scopeMatch }
                    UNION
                    { ?subject rtm:inScope/rtm:extends* ?scopeMatch }
                    
                    # Approver has the role
                    ?approver org:hasMembership/org:role ?role .
                    ?policy rtm:appliesToRole ?role .
                    
                    # All attribute requirements satisfied
                    FILTER NOT EXISTS {
                        ?policy rtm:requiresAttribute ?req .
                        ?req rtm:attributeKey ?reqKey .
                        FILTER NOT EXISTS {
                            ?approver org:hasMembership/rtm:hasAttribute ?attr .
                            ?attr rtm:attributeKey ?reqKey .
                            # Value satisfies minValue ordering (if applicable)
                            # ... detailed value-check pattern; see implementation
                        }
                    }
                }
            }
        """
    ] .
```

A failing constraint result indicates the approver is not authorized for the attestation under any policy. The attestation write is rejected at the SHACL gate.

## 6. Refresh policy

Projections are **point-in-time**. Adopters configure refresh via `rtm:refreshPolicy`:

| Mode | Semantics | Cost | Use case |
|---|---|---|---|
| `every-cert-run` | Adapter is invoked each time the oracle runs `certify`; projection is current at cert time | High (provider load + latency) | Always-current authorization |
| `on-commit` | Adapter invoked when the engineer commits an attestation; projection cached until next commit | Medium | Standard workflow |
| `scheduled` | Adapter runs on a cron (e.g., nightly); projection cached between runs | Low | Predictable cost, bounded staleness |
| `static` | Projection is loaded at startup and not refreshed | Zero | Test scenarios, audit replay |

The audit transcript records the active refresh policy and the projection-as-of-cert-time. Re-running the transcript months later evaluates against the **recorded** projection, not the live identity provider — per [[ADR-026 Reproducibility is Structural and Local]], identity changes after cert do not invalidate past attestations.

## 7. Reference adapters (v0.1)

### 7.1 GitHub adapter

**Input:** GitHub user data (REST API or GraphQL) for an authenticated query.

**Mapping:**

| GitHub field | Projection target |
|---|---|
| `login` (e.g., `"zargham"`) | `rtm:hasExternalIdentity "github:zargham"` |
| `name` | `foaf:name` |
| `email` (if public) | `foaf:mbox` |
| GitHub Teams (per org) | one `org:Membership` per team; `org:role` = team name; `org:organization` = parent org |
| Custom team labels (e.g., `clearance:secret`) | `rtm:hasAttribute` with `rtm:attributeKey/attributeValue` derived from label |

**Adapter location:** `oracle/src/oracle/identity/adapters/github.py`

**Conformance test:** sample GitHub user payload + expected projection output; `tests/conformance/test_identity_adapters.py::test_github_adapter`.

### 7.2 Generic OIDC adapter

**Input:** OIDC ID token + UserInfo endpoint payload.

**Mapping:**

| OIDC claim | Projection target |
|---|---|
| `sub` | `rtm:hasExternalIdentity` with `oidc:` prefix + issuer URI + sub |
| `name` | `foaf:name` |
| `email` | `foaf:mbox` |
| `groups` (array of group names) | one `org:Membership` per group; `org:role` derived from group name; `org:organization` derived from issuer or convention |
| Custom claims (configurable mapping) | `rtm:Attribute` instances |

**Configuration:** YAML mapping file declaring which OIDC claims map to which `rtm:` predicates (so adopters can use their custom claims without code changes).

**Adapter location:** `oracle/src/oracle/identity/adapters/oidc.py`

**Conformance test:** sample OIDC ID token + UserInfo payload + custom-claim YAML + expected projection.

### 7.3 GitHub Actions OIDC adapter (CI keyless)

**Input:** Fulcio-issued OIDC token from GitHub Actions workflow context.

**Mapping:**

| Claim | Projection target |
|---|---|
| `sub` (e.g., `repo:dynamicalsystemsgroup/flexo-rtm:ref:refs/heads/main`) | ephemeral `rtm:hasExternalIdentity` with `fulcio:` prefix |
| `repository`, `workflow`, `ref` | `rtm:hasAttribute` projecting CI context |
| `job_workflow_ref` | `rtm:hasAttribute` capturing the workflow file SHA |

The ephemeral identity is **scoped to the workflow run** — the projection has a short TTL and is intended for keyless-signed attestations only.

**Adapter location:** `oracle/src/oracle/identity/adapters/gha_oidc.py`

## 8. Extending to a new provider

Writing a new adapter (e.g., SAML, LDAP, Okta, Auth0, Keycloak) requires:

1. **Input adapter** — code that consumes the provider's native claim format (XML for SAML, LDIF for LDAP, JSON for Okta/Auth0/Keycloak)
2. **Field mapping** — translate provider fields to projection schema (§3); document the mapping in the adapter's docstring
3. **Configuration surface** — declarative YAML for any custom field mappings (so adopters can tune without code changes)
4. **Conformance test** — sample payload + expected projection RDF; place in `tests/conformance/test_identity_adapters.py`
5. **No core code changes** — the oracle dispatches to adapters by configuration; adding an adapter is additive

The acceptance criterion for a new adapter: the projection it produces passes the SHACL shape in §4 AND a representative sample passes the policy SPARQL pattern in §5.

## 9. Anti-patterns (what adapters MUST NOT do)

- **No authentication.** Adapters do not log in. They consume already-authenticated claims (the host application authenticates, then hands the adapter the claim payload).
- **No credential storage.** Adapters do not persist passwords, tokens, refresh tokens, certificates. Tokens are consumed and discarded.
- **No business logic.** Adapters do not decide who is authorized — they only project. Policy evaluation happens in SHACL via SPARQL.
- **No provider-side writes.** Adapters do not write back to the identity provider. The relationship is read-only.
- **No identity de-duplication.** If the same human appears under multiple external identities (e.g., GitHub + OIDC), the projection includes both via multiple `rtm:hasExternalIdentity` values on the same `foaf:Person`; cross-provider de-duplication is the adopter's responsibility.

## 10. Versioning

This contract pins to:

- W3C **FOAF** Vocabulary Specification 0.99 (Paddington Edition)
- W3C **Org Ontology** (October 2014)
- W3C **PROV-O** REC 2013

Future revisions of these vocabularies require a new contract version. v0.1 adapters MUST conform to the versions listed above.
