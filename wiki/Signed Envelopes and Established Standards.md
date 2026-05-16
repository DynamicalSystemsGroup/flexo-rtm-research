<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Signed Envelopes and Established Standards

**Status:** Ships in v0.1 as **vocabulary support + composable profile-gated requirements** (all profiles off by default). Closes the ADCS prototype's "signed envelopes deferred" gap by specifying the integration surfaces, not by inventing crypto.

**Normative source:** [[Design Spec]] §4.6. This page is the narrative companion to that section; the spec governs in any conflict.

---

## Guiding principle: don't roll our own crypto

Cryptography is a deep specialty with a well-earned graveyard of clever-looking-but-broken constructions. The discipline `flexo-rtm` adopts is unambiguous: **we do not invent envelope formats, key management schemes, transparency logs, or signature primitives.** The right move is to **compose battle-tested standardized tools** at well-defined integration surfaces and treat them as opaque components maintained by the standards community — W3C, OpenSSF, Sigstore, the git maintainers, the in-toto and DSSE working groups.

What `flexo-rtm` v0.1 ships is the **glue vocabulary** that lets the RDF data model reference these external envelopes, plus **composable SHACL profiles** that adopters opt into when their workflow is ready. We do not write signature code; we reference signed artifacts produced by tools maintainers already trust.

---

## The five integration surfaces

### 1. Approver binding via git GPG/SSH commit signing

**Mechanism.** Every attestation triple in `flexo-rtm` is materialized as a git commit (per [[Flexo Git Coexistence]] and [[Approver Binding via Git]]). When the `signed-commits` profile is active, that commit MUST carry a GPG or SSH signature. Since git 2.34, `gpg.format = ssh` is supported alongside the original GPG path, so adopters can use whichever key infrastructure they already operate.

**Verification flow.** A pre-commit hook reads the commit being authored, extracts the `rtm:approvedBy` IRI, dereferences it to a `foaf:Person` (or `org:Membership`) record carrying a published key fingerprint, and checks that the commit signature was produced by the matching key. GitHub Actions re-runs the same check at PR time as defense in depth, leveraging GitHub's built-in signature verification as the second eye.

**Key management.** Adopters use their existing GPG and SSH key infrastructure — `gnupg`, `ssh-agent`, OS keyrings, hardware tokens, enterprise key escrow. `flexo-rtm` ships no key directory, no key distribution mechanism, no key rotation tooling. Identity continues to be owned by the host organization's existing systems (see [[Verifiable Self-Certification]] and [[Design Spec]] §4.4).

**Acceptance criterion.** [[Design Spec]] §9.A.3 **I7** is normative: when `signed-commits` is active, a git commit introducing an attestation triple MUST be GPG/SSH-signed by a key whose fingerprint matches the `rtm:approvedBy` IRI's published key. Pre-commit hook plus GitHub Actions check both verify.

### 2. RDF integrity via W3C Verifiable Credentials + Data Integrity

**Mechanism.** An `rtm:Attestation` may be expressed as a W3C Verifiable Credential (VC Data Model 2.0) and carry a Data Integrity proof in the `sec:proof` property. The proof is computed over the **canonicalized RDF dataset** using RDFC-1.0 (see [[RDFC-1.0 Canonicalization]]) and signed with a standard primitive — typically EdDSA over Ed25519 or ECDSA over P-256 — using one of the registered Data Integrity cryptosuites (`eddsa-rdfc-2022`, `ecdsa-rdfc-2019`, etc.).

**Verification flow.** A verifier re-canonicalizes the credential subject, recomputes the proof hash, and verifies the signature against the issuer's published verification key. Crucially, the proof attaches to the **RDF graph itself** — verification never leaves the data model. There is no auxiliary file to track and no out-of-band envelope to parse.

**Profile.** `data-integrity-attestations` requires `sec:proof` on every `rtm:Attestation` instance and validates the proof at audit time.

**Why this fits.** Data Integrity is **RDF-native**: proofs attach to graphs, canonicalization is part of the spec, and multiple interoperable implementations exist across JavaScript, Rust, Python, and Go. Using a W3C standard ensures `flexo-rtm` attestations interoperate with the broader VC ecosystem without bespoke tooling.

### 3. Activity attestation envelopes via DSSE + in-toto

**Mechanism.** When an `rtm:Activity` emits a claim about an artifact — a build provenance, a test result, a simulation output, a model check — the payload is wrapped in a DSSE (Dead Simple Signing Envelope) whose payload type is an in-toto attestation predicate. The envelope carries one or more signatures with key identifiers; the payload is base64-encoded JSON conforming to the in-toto Statement layout (`_type`, `predicateType`, `subject`, `predicate`).

**Predicate types.** Where possible, `flexo-rtm` adopts existing in-toto predicate types — SLSA Provenance v1.0 for build provenance is the obvious anchor. Where no community predicate fits (e.g., a domain-specific simulation transcript), the engineering choice is to **propose a new predicate to the in-toto community first, then fall back to a `flexo-rtm`-namespaced predicate only if necessary**, treating that namespaced predicate as a candidate for future upstream contribution rather than a permanent fork.

**RDF reference.** An `rtm:Activity` references its DSSE-enveloped attestation through `rtm:dsseEnvelope` (`xsd:anyURI` or inline).

**Profile.** `dsse-activities` requires every `rtm:Activity` emitting an attestation to reference a DSSE envelope through `rtm:dsseEnvelope`.

**Verification flow.** Standard DSSE and in-toto tooling — `witness`, `cosign verify-attestation`, the in-toto reference verifier — performs envelope signature validation and payload-type checking. `flexo-rtm` exposes the envelope reference; it runs no verification logic of its own.

**Why this fits.** DSSE is **the** supply-chain attestation envelope: SLSA, Trivy, BuildKit, Bazel, Conan, GitHub Artifact Attestations, and Google Cloud Build all use it. Composing on DSSE means `flexo-rtm` activity attestations interoperate with the entire software-supply-chain ecosystem without translation glue.

### 4. Container image trust via Sigstore cosign / OCI signatures

**Mechanism.** When an `rtm:Activity` references an OCI image via `rtm:hasOCIImage` (per [[Design Spec]] §4.5), that image digest can be cosign-verified. The optional `rtm:cosignBundle` property carries the Sigstore cosign signature bundle for the image — either inline or by reference to a bundle file stored in the registry alongside the image.

**Verification flow.** `cosign verify` against the bundle confirms that the image at the recorded digest was signed by a known identity. In **keyless mode** (the dominant production pattern), GitHub Actions, GitLab CI, or other OIDC providers issue ephemeral signing keys via Sigstore's Fulcio CA bound to the workflow's OIDC identity; the signature lands in Rekor, and the verifier checks the Fulcio certificate chain plus the Rekor inclusion proof.

**Profile.** `cosign-images` requires `rtm:cosignBundle` to accompany every `rtm:hasOCIImage` reference, and audit-mode tooling runs `cosign verify` against each.

**Acceptance criterion.** [[Design Spec]] §9.A.4 **U4** is normative: in audit mode, fetching `rtm:hasOCIImage` digest reference MUST succeed against an OCI-compliant registry, and is cosign-verifiable when `--profile=cosign-images` is active.

**Why this fits.** Cosign is the dominant OCI image signing tool, aligned with the OpenSSF reference architecture and the OCI signature specification. Keyless mode eliminates per-developer key management for CI workflows while delivering equivalent or stronger trust through OIDC + transparency.

### 5. Transparency and non-repudiation via Sigstore Rekor

**Mechanism.** Any signature `flexo-rtm` references — a DSSE envelope, a cosign bundle, a Data Integrity proof — can be entered into Rekor, Sigstore's public append-only transparency log. The `rtm:rekorLogEntry` property points to the Rekor entry IRI; verifiers retrieve the Merkle inclusion proof and confirm the signature was logged at a specific time.

**Profile.** `rekor-transparency` requires a Rekor entry for every attestation. This is the heaviest of the five profiles — it commits an organization to a public transparency posture — and exists for regulatory contexts that require public, non-repudiable audit trails without standing up custom transparency infrastructure.

**Why this fits.** Rekor is the dominant transparency log for software supply chains, backed by OpenSSF and the Linux Foundation, widely deployed in production, and supported by mature tooling. Using Rekor closes the non-repudiation surface without `flexo-rtm` having to operate (or specify) its own append-only log — which would be **exactly the kind of crypto invention this page exists to forbid**.

---

## Vocabulary shipped in v0.1

| Term | Provenance | Range | Purpose |
|---|---|---|---|
| `sec:proof` | W3C Security Vocabulary | DI proof object | Data Integrity proof attached to an RDF graph |
| `rtm:dsseEnvelope` | `flexo-rtm` | `xsd:anyURI` or inline | Reference to a DSSE-enveloped in-toto attestation about an activity |
| `rtm:cosignBundle` | `flexo-rtm` | `xsd:anyURI` or inline | Cosign signature bundle for an OCI image referenced via `rtm:hasOCIImage` |
| `rtm:rekorLogEntry` | `flexo-rtm` | `xsd:anyURI` | Pointer to a Sigstore Rekor transparency-log entry |
| `rtm:commitSignatureRequired` | `flexo-rtm` | `xsd:boolean` | Marks that an attestation's git commit MUST carry a valid GPG/SSH signature |

The `sec:` namespace is the W3C Security Vocabulary, reused unchanged. The four `rtm:`-prefixed terms are **glue around external standards**; they wrap, they do not replace.

---

## The five composable SHACL profiles

| Profile | Requires |
|---|---|
| `signed-commits` | GPG/SSH-signed git commits for every attestation triple |
| `data-integrity-attestations` | `sec:proof` on every `rtm:Attestation` |
| `dsse-activities` | DSSE-enveloped in-toto attestation referenced by every `rtm:Activity` that emits claims |
| `cosign-images` | Cosign signature bundle for every `rtm:hasOCIImage` |
| `rekor-transparency` | Rekor log entry for every attestation |

All five are **off by default in v0.1**. Adopters compose them à la carte as their workflow matures: a research team might start with `signed-commits` only; a safety-critical program operating in a regulated environment might enable all five. The profiles do not interact destructively — enabling more makes the SHACL gate stricter; it never invalidates data that was conformant under a weaker setting.

---

## What we DO NOT do

This list is the discipline.

- **No custom envelope formats.** DSSE wraps activity attestation payloads; VC-DI wraps RDF; cosign bundles wrap image signatures. `flexo-rtm` never defines its own envelope.
- **No custom crypto primitives.** Everything ultimately uses well-vetted curves and modes: ECDSA over P-256 or P-384, EdDSA over Ed25519, RSA-PSS, AES-GCM where symmetric crypto is needed by an underlying standard. `flexo-rtm` does not pick or implement primitives.
- **No custom transparency log.** Rekor is the transparency log. We do not specify, operate, or wrap a parallel log.
- **No custom key infrastructure.** Adopters use `gnupg`, `ssh-agent`, OS keyrings, hardware tokens, cloud KMS, GitHub OIDC, cosign keyless — whatever they already operate. `flexo-rtm` ships no key directory and no key distribution.
- **No custom identity binding scheme.** The link from `rtm:approvedBy` IRI to public key is resolved via the same identity projection used for the rest of `flexo-rtm`'s identity story ([[Design Spec]] §4.4); see also [[Verifiable Self-Certification]].
- **No "this looks crypto-ish, let's prototype it" code paths.** Where v0.1 lacks an integration, it lacks the integration; future versions add integrations by **adopting more standards**, never by inventing new primitives.

---

## Worked composition example

Consider an engineer running a guidance-control simulation whose output is offered as evidence for a satisfaction attestation. Every link of the chain rides on an established standard:

1. **Simulation container is cosign-signed.** The CI pipeline that built `ghcr.io/example/adcs-sim@sha256:…` used cosign keyless signing bound to its GitHub Actions OIDC identity. The signature bundle is stored alongside the image, and the bundle's Rekor entry is published.
2. **The engineer runs the simulation.** The `rtm:Activity` records `rtm:hasOCIImage` plus the git commit and content hash of the input scenario (see [[External URI References]]). When `cosign-images` is active, audit-mode verification runs `cosign verify` against the recorded bundle, satisfying §9.A.4 **U4**.
3. **The activity emits a DSSE-enveloped in-toto attestation.** The payload is an in-toto Statement under an appropriate predicate type (SLSA Provenance v1.0 for the build chain, plus a simulation-result predicate). The envelope is signed by the workflow's keyless identity; the Rekor entry IRI is captured.
4. **The engineer authors an attestation.** An `rtm:SatisfactionAttestation` references the simulation activity, with `rtm:dsseEnvelope` and `rtm:rekorLogEntry` pointing at the artifacts from step 3.
5. **The attestation carries a Data Integrity proof.** The graph is canonicalized via RDFC-1.0 and signed with the engineer's `eddsa-rdfc-2022` cryptosuite; the proof is attached as `sec:proof`. The `data-integrity-attestations` profile makes this mandatory.
6. **The engineer commits via Flexo.** Git materializes the attestation as a commit, which the engineer signs with their SSH key (`gpg.format = ssh`). The pre-commit hook resolves `rtm:approvedBy` to the engineer's `foaf:Person` record, finds the published SSH key fingerprint, and confirms the commit signature matches. GitHub Actions re-runs the check at PR time — this is the §9.A.3 **I7** acceptance gate.
7. **Audit replays the chain.** A verifier with appropriate permissions runs `cosign verify` on the image bundle, verifies the DSSE envelope with `witness` or `cosign verify-attestation`, checks the Rekor inclusion proof, re-canonicalizes the attestation and verifies its `sec:proof`, and verifies the git commit signature. Every step uses standard tooling. No `flexo-rtm`-specific cryptographic code runs anywhere in the chain.

Sketched in Turtle, the attestation node looks roughly like:

```turtle
ex:att-2026-05-16-attitude-loop a rtm:SatisfactionAttestation ;
    rtm:satisfies <urn:rtm:req/adcs-pointing-accuracy> ;
    rtm:approvedBy <https://example.org/people/engineer-42> ;
    prov:wasGeneratedBy ex:sim-run-2026-05-16T09:00Z ;
    rtm:dsseEnvelope    <https://attestations.example.org/dsse/0xab…> ;
    rtm:rekorLogEntry   <https://rekor.sigstore.dev/api/v1/log/entries/24296fb…> ;
    sec:proof [
        a sec:DataIntegrityProof ;
        sec:cryptosuite "eddsa-rdfc-2022" ;
        sec:verificationMethod <https://example.org/people/engineer-42#key-1> ;
        sec:proofValue "z3MvGcVxN…" ;
    ] .

ex:sim-run-2026-05-16T09:00Z a rtm:Activity ;
    rtm:hasOCIImage     <oci://ghcr.io/example/adcs-sim@sha256:…> ;
    rtm:cosignBundle    <https://attestations.example.org/cosign/0xcd…> ;
    rtm:hasGitRepo      <https://github.com/example/adcs-models> ;
    rtm:hasGitCommit    "abc123def456…" .
```

Every IRI in this snippet lands in a public registry, a transparency log, a git host, or a content-addressed store. Every signature is verifiable with standard off-the-shelf tooling. **No part of the chain depends on cryptographic code authored by the `flexo-rtm` project.**

---

## What v0.1 ships, and what v0.1 does not

**v0.1 ships:**

- Vocabulary terms: `sec:proof` (reused), `rtm:dsseEnvelope`, `rtm:cosignBundle`, `rtm:rekorLogEntry`, `rtm:commitSignatureRequired`.
- Five composable SHACL profiles, **all off by default**.
- Pre-commit hook and GitHub Actions workflow templates for the `signed-commits` profile.
- Documentation for each integration (key formats, verification flow, error handling, recommended tools).

**v0.1 does NOT:**

- Provide a signing service. All signing happens in the adopter's existing tooling (`git`, `gpg`, `ssh`, `cosign`, `witness`, `step-ca`, etc.).
- Enforce any profile by default. Every signing requirement is **opt-in**.
- Bundle a key directory or PKI. Adopters bring their own identity infrastructure (see [[Verifiable Self-Certification]] and [[Design Spec]] §4.4).
- Ship a **recursive registry of approved signer identities**. That belongs with the future topological framework's recursive completeness story — out of scope for v0.1.
- Operate a Rekor instance. Adopters use the public Sigstore Rekor (`rekor.sigstore.dev`) or run their own deployment using upstream Sigstore code.

---

## Forward compatibility

When the future topological framework lands (see [[Design Spec]] §4.10), the same standards stack supports closed-triangle assurance unchanged: every assurance triangle has a signed validation edge with a signed approver attestation referencing signed activities producing content-hashed artifacts inside cosign-verified containers, all anchored to the registry's signed entries. The composition principle holds at every recursion depth because every level uses the same battle-tested primitives. No new crypto is required to scale into the topological framework — only **more disciplined composition of the same primitives**. The v0.1 stack scales into the recursive-completeness regime without `flexo-rtm` ever stepping outside its lane to become a cryptography project.

---

## Cross-references

- [[Design Spec]] §4.6 (normative source), §4.5 (external URI references), §9.A.3 I7 (git approver binding), §9.A.4 U4 (cosign-verifiable OCI digests), §4.10 (forward compatibility)
- [[External URI References]] — git+commit, content hash, OCI digest references that signed envelopes wrap
- [[Attestation Infrastructure in v0.1]] — the attestation surface that DI proofs attach to
- [[Verifiable Self-Certification]] — identity infrastructure the approver-binding chain relies on
- [[Approver Binding via Git]] — operational layer for the `signed-commits` profile
- [[Transcript Replay Semantics]] — how signed envelopes feed into deterministic replay
- [[RDFC-1.0 Canonicalization]] — the canonicalization standard underneath Data Integrity proofs
- [[Flexo Git Coexistence]] — git as the materialization surface for attestation commits
