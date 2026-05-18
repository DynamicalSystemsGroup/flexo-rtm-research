<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Signed Envelope Shapes

> **Normative contract** for signed envelopes in `flexo-rtm`. The SHACL shapes for verifying VC-DI proofs / DSSE envelopes / cosign bundles / Rekor entries, cryptosuite identifiers, and dependency posture live here. The `flexo-rtm` [[Design Spec]] §4.5 and §6.5 reference this page. See also [[Signed Envelopes and Established Standards]] (rationale), [[ADR-023 Cryptography by Composition of Battle-Tested Standards]], [[ADR-026 Cryptographic Agility via Algorithm Profiles]].

## 1. Scope and principle

`flexo-rtm` does not invent cryptography. Five integration surfaces compose battle-tested standards:

1. **Git commit signing** (GPG / SSH) — approver binding
2. **W3C Data Integrity** (VC-DI proofs on RDF) — attestation integrity
3. **DSSE + in-toto attestation** — activity envelopes (supply-chain native)
4. **Sigstore cosign / OCI image signatures** — container trust
5. **Sigstore Rekor** — transparency log

This page specifies the SHACL shapes that validate these envelopes, the cryptosuite identifiers, and how the oracle's `cryptography` dependency lazy-loads verification helpers per profile.

## 2. Composable profiles

Five profiles, off by default. Adopters enable as their workflow requires.

| Profile | Activates verification of | Profile file |
|---|---|---|
| `signed-commits` | GPG/SSH-signed git commits matching `rtm:approvedBy` published keys | `ontology/profiles/signed-commits.shacl.ttl` |
| `data-integrity-attestations` | `sec:proof` on every `rtm:Attestation` | `ontology/profiles/data-integrity-attestations.shacl.ttl` |
| `dsse-activities` | DSSE-enveloped in-toto attestation per `rtm:Activity` | `ontology/profiles/dsse-activities.shacl.ttl` |
| `cosign-images` | Cosign signature bundle per `rtm:hasOCIImage` | `ontology/profiles/cosign-images.shacl.ttl` |
| `rekor-transparency` | Rekor log entry per attestation | `ontology/profiles/rekor-transparency.shacl.ttl` |

## 3. Cryptosuite registry

Per [[ADR-027 Cryptographic Agility via Algorithm Profiles]], the active cryptosuite supplies algorithm identifiers. v0.1 supports:

| Suite | Source | Digest | Signature | Cryptosuite IRI |
|---|---|---|---|---|
| `eddsa-rdfc-2022` | W3C VC-DI | SHA-256 | Ed25519 | `https://w3id.org/security/data-integrity/v2/eddsa-rdfc-2022` |
| `ecdsa-rdfc-2019` | W3C VC-DI | SHA-256 | ECDSA P-256 | `https://w3id.org/security/data-integrity/v2/ecdsa-rdfc-2019` |
| `ecdsa-rdfc-2019-p384` | W3C VC-DI | SHA-384 | ECDSA P-384 | (suite-specific) |
| `cosign-v1` | Sigstore | SHA-256 | ECDSA P-256 | `cosign:v1` |
| `dsse-v1` | OpenSSF | (payload-defined) | (per envelope) | `dsse:v1` |
| `gpg-default` | GnuPG | SHA-256 | per key (Ed25519, RSA, ECDSA) | `openpgp:v1` |
| `ssh-default` | OpenSSH | SHA-256 | per key (Ed25519, RSA, ECDSA) | `openssh:v1` |

The cryptosuite IRI is recorded in `sec:cryptosuite` on each `sec:proof`. The oracle's signature-verification helper dispatches on this IRI to select the right algorithm.

## 4. Surface 1: Git commit signing (`signed-commits`)

### 4.1 Mechanism

Per [[Design Spec]] §4.5 and §6.5 S1:

1. The engineer's git commit introducing an attestation triple MUST be GPG/SSH-signed
2. The signature key's fingerprint MUST match the public key fingerprint declared on the `rtm:approvedBy` person's `foaf:Person` resource in the identity projection

### 4.2 Key fingerprint declaration

The identity projection (per [[Identity Adapter Contract]] §3) declares published keys for each `foaf:Person`:

```turtle
:engineer-zargham a foaf:Person ;
    rtm:hasExternalIdentity "github:zargham" ;
    rtm:hasPublicKey [
        rtm:keyType "openpgp" ;
        rtm:keyFingerprint "ABC1 2345 DEAD BEEF 0987 ..."
    ] ,
    [
        rtm:keyType "ssh-ed25519" ;
        rtm:keyFingerprint "SHA256:abc123..."
    ] .
```

Multiple keys per person allowed; commit signature matching ANY declared key passes the gate.

### 4.3 SHACL shape

```turtle
rtm:SignedCommitsShape a sh:NodeShape ;
    sh:targetClass rtm:Attestation ;
    sh:sparql [
        sh:message "Attestation's introducing git commit must be signed by a key matching rtm:approvedBy's published key fingerprint" ;
        sh:select """
            # Pseudo: validation is via a SPARQL-evaluable check that the commit's
            # signature key fingerprint (recorded in commit metadata when committed)
            # matches rtm:approvedBy's rtm:hasPublicKey/rtm:keyFingerprint.
            # The check is implemented in the pre-commit hook + GitHub Actions check;
            # SHACL validates the recorded fingerprint match for already-committed data.
            SELECT $this WHERE {
                $this rtm:approvedBy ?approver ;
                      rtm:introducedByCommit ?commit .
                ?commit rtm:signedByKey ?keyFingerprint .
                FILTER NOT EXISTS {
                    ?approver rtm:hasPublicKey/rtm:keyFingerprint ?keyFingerprint .
                }
            }
        """
    ] .
```

### 4.4 Pre-commit hook + CI

The pre-commit hook (`scripts/check-approver-binding.sh`) reads new attestation triples in the commit's diff and verifies the commit's signature key matches the approver's published key. GitHub Actions runs the same check at PR time.

Bypass paths (e.g., `git commit --no-verify`) are blocked by branch protection in CI.

## 5. Surface 2: W3C Data Integrity (`data-integrity-attestations`)

### 5.1 Mechanism

Per [[Design Spec]] §4.5 and §6.5 S2:

Each `rtm:Attestation` MAY (or MUST under the profile) carry a `sec:proof` linking to a W3C Data Integrity proof object. The proof is computed over the canonical (RDFC-1.0) form of the attestation's RDF graph.

### 5.2 Proof structure (per W3C VC-DI 2.0)

```turtle
:attestation-001 a rtm:SatisfactionAttestation ;
    rtm:approvedBy :engineer-zargham ;
    rtm:appliesTo :triple-001 ;
    rtm:status rtm:status/pass ;
    sec:proof [
        a sec:DataIntegrityProof ;
        sec:cryptosuite "eddsa-rdfc-2022" ;
        sec:created "2026-05-18T14:30:00Z"^^xsd:dateTime ;
        sec:verificationMethod <https://example.org/keys/zargham#key-1> ;
        sec:proofPurpose sec:assertionMethod ;
        sec:proofValue "z3FtR..."   # base58btc-encoded signature
    ] .
```

### 5.3 SHACL shape

```turtle
rtm:DataIntegrityAttestationShape a sh:NodeShape ;
    sh:targetClass rtm:Attestation ;
    sh:property [
        sh:path sec:proof ;
        sh:minCount 1 ;
        sh:node rtm:DataIntegrityProofShape ;
        sh:message "Attestation must carry a sec:proof when data-integrity-attestations profile is active"
    ] .

rtm:DataIntegrityProofShape a sh:NodeShape ;
    sh:targetClass sec:DataIntegrityProof ;
    sh:property [
        sh:path sec:cryptosuite ;
        sh:minCount 1 ;
        sh:datatype xsd:string ;
        sh:in ("eddsa-rdfc-2022" "ecdsa-rdfc-2019" "ecdsa-rdfc-2019-p384") ;
        sh:message "Cryptosuite must be a recognized W3C VC-DI cryptosuite"
    ] ;
    sh:property [
        sh:path sec:verificationMethod ;
        sh:minCount 1 ;
        sh:nodeKind sh:IRI ;
    ] ;
    sh:property [
        sh:path sec:proofValue ;
        sh:minCount 1 ;
        sh:datatype xsd:string ;
    ] .
```

### 5.4 Verification

The oracle's `oracle/identity/signing/vc_di.py` module verifies `sec:proof`:

1. Resolve `sec:verificationMethod` IRI → fetch the public key (typically a `did:key:` or `https://`-published key)
2. Canonicalize the attestation's RDF graph (excluding the proof block) using RDFC-1.0
3. Verify the signature against the canonical bytes using the cryptosuite's signature algorithm

Verification is offline once the public key is fetched (no live service required).

## 6. Surface 3: DSSE + in-toto (`dsse-activities`)

### 6.1 Mechanism

Per [[Design Spec]] §4.5 and §6.5 S3:

Each `rtm:Activity` that emits an attestation about an artifact (build provenance, test result, simulation output) MAY (or MUST under the profile) reference a DSSE-enveloped in-toto attestation via `rtm:dsseEnvelope`.

### 6.2 Envelope structure (DSSE per https://github.com/secure-systems-lab/dsse)

```turtle
:simulation-run-001 a rtm:Activity ;
    rtm:hasGitCommit "abc123..." ;
    rtm:hasOCIImage "ghcr.io/org/adcs-sim@sha256:def..." ;
    rtm:dsseEnvelope <https://archive.example.org/attestations/run-001.dsse.json> .
```

The dereferenced DSSE envelope (JSON):

```json
{
  "payloadType": "application/vnd.in-toto+json",
  "payload": "<base64 of in-toto attestation>",
  "signatures": [
    {
      "keyid": "fulcio:...",
      "sig": "<base64 signature>"
    }
  ]
}
```

The in-toto attestation payload follows [in-toto Attestation Framework v1](https://github.com/in-toto/attestation):

```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "subject": [{"name": "result.csv", "digest": {"sha256": "..."}}],
  "predicateType": "https://slsa.dev/provenance/v1",
  "predicate": { /* SLSA Provenance v1 fields */ }
}
```

### 6.3 SHACL shape

```turtle
rtm:DSSEActivityShape a sh:NodeShape ;
    sh:targetClass rtm:Activity ;
    sh:property [
        sh:path rtm:dsseEnvelope ;
        sh:minCount 1 ;
        sh:nodeKind sh:IRI ;
        sh:message "Activity must reference a DSSE envelope when dsse-activities profile is active"
    ] .
```

### 6.4 Verification

The oracle's `oracle/identity/signing/dsse.py` verifies:

1. Fetch the DSSE envelope from `rtm:dsseEnvelope` IRI
2. Verify each signature against the declared keyid (typically a Fulcio cert from keyless signing)
3. Parse the in-toto payload; verify the `subject.digest` matches the `rtm:hasContentHash` of the activity's produced artifacts
4. Optionally check the `predicateType` is one of the accepted SLSA / in-toto predicate types

## 7. Surface 4: Sigstore cosign / OCI image signatures (`cosign-images`)

### 7.1 Mechanism

Per [[Design Spec]] §4.5 and §6.5 S4:

Each `rtm:hasOCIImage` MAY (or MUST under the profile) carry a `rtm:cosignBundle` referencing a Sigstore cosign signature bundle.

### 7.2 Structure

```turtle
:simulation-run-001 a rtm:Activity ;
    rtm:hasOCIImage "ghcr.io/org/adcs-sim@sha256:def..." ;
    rtm:cosignBundle <https://archive.example.org/cosign/adcs-sim-def.bundle.json> .
```

The cosign bundle (JSON, per [cosign Bundle Spec](https://github.com/sigstore/cosign/blob/main/specs/BUNDLE_SPEC.md)) contains:

- The signature
- The Fulcio-issued cert (X.509)
- The Rekor entry (transparency log inclusion proof)

### 7.3 SHACL shape

```turtle
rtm:CosignImagesShape a sh:NodeShape ;
    sh:targetClass rtm:Activity ;
    sh:sparql [
        sh:message "Every rtm:hasOCIImage on an Activity must have an accompanying rtm:cosignBundle when cosign-images profile is active" ;
        sh:select """
            SELECT $this WHERE {
                $this rtm:hasOCIImage ?image .
                FILTER NOT EXISTS { $this rtm:cosignBundle ?bundle }
            }
        """
    ] .
```

### 7.4 Verification

The oracle's `oracle/identity/signing/cosign.py` verifies:

1. Fetch the cosign bundle
2. Verify the X.509 cert chain against the Fulcio root CA (or against pinned trust roots configured by the adopter)
3. Verify the signature over the OCI image digest
4. Verify the Rekor inclusion proof (independently, via §8)

Verification uses the `sigstore` Python library (optional dependency; lazy-loaded only under `cosign-images` profile).

## 8. Surface 5: Sigstore Rekor (`rekor-transparency`)

### 8.1 Mechanism

Per [[Design Spec]] §4.5 and §6.5 S5:

Each attestation MAY (or MUST under the profile) have a corresponding Rekor log entry. The entry IRI is recorded via `rtm:rekorLogEntry`.

### 8.2 Structure

```turtle
:attestation-001 a rtm:SatisfactionAttestation ;
    rtm:approvedBy :engineer-zargham ;
    rtm:rekorLogEntry <https://rekor.sigstore.dev/api/v1/log/entries/108e9186e8c5f78c...> .
```

### 8.3 SHACL shape

```turtle
rtm:RekorTransparencyShape a sh:NodeShape ;
    sh:targetClass rtm:Attestation ;
    sh:property [
        sh:path rtm:rekorLogEntry ;
        sh:minCount 1 ;
        sh:nodeKind sh:IRI ;
        sh:pattern "^https://rekor\\.[a-zA-Z0-9.-]+/api/v[0-9]+/log/entries/[a-zA-Z0-9]+$" ;
        sh:message "Attestation must reference a Rekor log entry when rekor-transparency profile is active"
    ] .
```

### 8.4 Verification

The oracle's `oracle/identity/signing/rekor.py` verifies:

1. Fetch the Rekor entry by IRI
2. Verify the entry contains the expected signature + signed payload
3. Verify the Merkle inclusion proof against the Rekor public log (the proof allows offline verification once the log's root hash is known)

This provides public, append-only audit trail without requiring `flexo-rtm` to run its own transparency infrastructure.

## 9. Dependency posture

`flexo-rtm` default install: `pip install flexo-rtm` includes only:

- `rdflib`, `pyshacl`, `pydantic` (hot path)
- `cryptography` (for VC-DI verification of common cryptosuites)

Signing-verification extras are lazy-loaded **only when** the corresponding profile is active:

| Profile | Extra | Triggers `pip install 'flexo-rtm[...]'` |
|---|---|---|
| `signed-commits` | nothing extra (uses `subprocess` for `git verify-commit` / `ssh-keygen -Y verify`) | — |
| `data-integrity-attestations` | nothing extra (uses `cryptography` for ECDSA/Ed25519) | — |
| `dsse-activities` | `in-toto-attestation`, `securesystemslib` | `flexo-rtm[dsse]` |
| `cosign-images` | `sigstore` | `flexo-rtm[cosign]` |
| `rekor-transparency` | `sigstore` (same lib) | `flexo-rtm[cosign]` (shares dep) |

The `pyproject.toml` declares these as optional dependency groups. The oracle imports them inside profile-handler functions; if the import fails, the profile fails with a clear error message instructing the adopter to install the extra.

## 10. What is NOT in v0.1 scope

- **Custom signing tooling.** Adopters use the host system's existing tools: GnuPG, ssh-agent, cosign CLI, GitHub Actions OIDC. `flexo-rtm` verifies signatures; it does not sign on the adopter's behalf.
- **Key management.** No key generation, rotation, or revocation flows. Adopters use their existing PKI (CA, KMS, hardware tokens, …).
- **Custom transparency logs.** Rekor is the standard; if adopters need air-gapped transparency, that's their infrastructure to provide and a different (out-of-v0.1) integration.
- **Hash truncation or non-standard signature formats.** Only the cryptosuites in §3 are accepted.
- **Re-signing on storage.** Once an attestation lands in Flexo with a `sec:proof`, the proof is immutable — `flexo-rtm` never re-signs (no key management).

## 11. Versioning

This contract pins to:

- W3C **Verifiable Credentials Data Model 2.0** (Recommendation)
- W3C **Data Integrity 1.0** (Recommendation)
- DSSE **v1** (Secure Systems Lab)
- in-toto **Attestation Framework v1**
- Sigstore **cosign Bundle Spec v0.3** (or current at v0.1 release)
- OCI **Distribution Specification v1.1**

Future versions of these standards require a new contract version.
