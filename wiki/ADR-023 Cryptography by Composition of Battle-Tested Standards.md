<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-023: Cryptography by Composition of Battle-Tested Standards

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-022 External URI References as Open-Source Foundation]]; [[ADR-024 Identity by Thin Projection of External Sources]]; [[ADR-016 Composable SHACL Profiles]]; [[Signed Envelopes and Established Standards]]; [[Approver Binding via Git]]; [[Design Spec]]

## Context

Cert artifacts in `flexo-rtm` carry assertions whose integrity matters: named-approver attestations (see [[ADR-021 Three Attestation Subclasses Ship in v0.1]]), provenance of build activities, references to external artifacts (see [[ADR-022 External URI References as Open-Source Foundation]]). These need to be cryptographically attestable so that auditors can verify that a given attestation actually came from the named approver, the build activity actually executed as recorded, and the external artifacts referenced are the ones the cert was computed against. The ADCS prototype deferred signed envelopes entirely; v0.1 closes that gap. The high-stakes question is **how**: invent custom signing schemes tailored to RTM, or compose established cryptographic standards? Cryptography is a deep specialty; inventing custom schemes is one of the most common ways security goes wrong. See [[Design Spec]] §10 and [[Signed Envelopes and Established Standards]].

## Decision

`flexo-rtm` v0.1's cryptography is **composition of battle-tested standards, never invention**. Signed envelopes use:

- **Git GPG/SSH commit signing** (built into git since 2.34) — see [[Approver Binding via Git]]
- **W3C Verifiable Credentials + Data Integrity proofs** (RDF-native; ECDSA/EdDSA)
- **DSSE + in-toto attestation predicates** (the supply-chain signing standard; SLSA, BuildKit, Bazel all use it)
- **Sigstore cosign** for keyless signing + **Rekor** transparency log
- **OCI image signatures** via cosign / notary

Vocabulary in v0.1 ontology: `sec:proof`, `rtm:dsseEnvelope`, `rtm:cosignBundle`, `rtm:rekorLogEntry`. **Five composable SHACL profiles** (all **off by default** per [[ADR-016 Composable SHACL Profiles]]): `signed-commits`, `data-integrity-attestations`, `dsse-activities`, `cosign-images`, `rekor-transparency`. **No custom crypto, no custom envelope formats, no custom key infrastructure, no custom transparency logs.**

## Consequences

### Positive

- Security through composition: every cryptographic primitive in v0.1 is an established, audited standard with a vetted reference implementation — no custom code in the trust-critical path
- Interoperability: cert artifacts can be verified using off-the-shelf tools (`git verify-commit`, `cosign verify`, `rekor-cli`, JSON-LD VC verifiers); no custom verifier required
- The composition pattern matches the SLSA / supply-chain-security ecosystem — institutions already familiar with DSSE, in-toto, and Sigstore can adopt `flexo-rtm` without a new mental model
- Closes the ADCS prototype's "signed envelopes deferred; W3C VC Data Integrity + sigstore integration deferred" gap explicitly
- The crypto profiles are off-by-default and composable — adopters opt in to the crypto discipline appropriate to their cert run (e.g., a safety-critical cert turns on all five; an exploratory cert turns on none)

### Negative / Tradeoffs

- Multi-standard composition is more complex to document and explain than a single envelope format; mitigated by the `Signed Envelopes and Established Standards` wiki page and by each standard being well-known independently
- Adopters new to cryptography have to learn five established standards instead of one custom envelope; mitigated by the standards being industry-standard and well-supported
- Verification dependencies grow with each profile enabled; mitigated by the off-by-default policy and by each profile's tools being standalone

### Neutral

- The composition pattern is the same one used for identity (see [[ADR-024 Identity by Thin Projection of External Sources]]) — integrate at the boundary via standardized vocabularies and let the external authoritative source own the truth

## Alternatives Considered

- **Roll custom signing/envelope schemes tailored to RTM use cases:** Design `rtm:` prefixed custom signing primitives optimized for RTM cert semantics. Rejected: cryptography is a deep specialty, and inventing custom schemes is one of the most common ways security goes wrong. Custom envelopes mean custom verifiers, custom audit tooling, custom security review burden — and one wrong move (poor key management, weak signature primitive, missing replay protection) breaks the entire integrity model. Battle-tested standards composition is the only responsible path.

## Implementation Notes

- Crypto profiles ship as TTL files in `ontology/profiles/`: `signed-commits.ttl`, `data-integrity-attestations.ttl`, `dsse-activities.ttl`, `cosign-images.ttl`, `rekor-transparency.ttl`
- Vocabulary includes `sec:proof` (W3C VC Data Integrity), `rtm:dsseEnvelope`, `rtm:cosignBundle`, `rtm:rekorLogEntry`
- Git commit signing integration documented in [[Approver Binding via Git]]
- DSSE / in-toto integration for build activities references the external URI vocabulary (see [[ADR-022 External URI References as Open-Source Foundation]])
- All verification uses off-the-shelf tools — `flexo-rtm` ships only the SHACL profiles and vocabulary, not custom verifiers
- See [[Signed Envelopes and Established Standards]] for the canonical documentation

## References

- [[Design Spec]] §10 (Cryptography Composition), §10.1–10.5 (Per-Standard Profiles)
- [[Signed Envelopes and Established Standards]] — the canonical composition documentation
- [[Approver Binding via Git]] — git commit signing integration
- [[ADR-022 External URI References as Open-Source Foundation]] — the references that get signed
- W3C Verifiable Credentials Data Integrity: https://www.w3.org/TR/vc-data-integrity/
- DSSE: https://github.com/secure-systems-lab/dsse
- in-toto: https://in-toto.io/
- Sigstore (cosign + Rekor): https://www.sigstore.dev/
