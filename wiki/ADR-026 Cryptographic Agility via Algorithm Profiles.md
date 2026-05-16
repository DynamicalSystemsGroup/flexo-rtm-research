<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-026: Cryptographic Agility via Algorithm Profiles

**Status:** Accepted
**Date:** 2026-05-17
**Deciders:** Michael Zargham
**Related:** [[ADR-023 Cryptography by Composition of Battle-Tested Standards]]; [[ADR-016 Composable SHACL Profiles]]; [[ADR-022 External URI References as Open-Source Foundation]]; [[Signed Envelopes and Established Standards]]; [[RDFC-1.0 Canonicalization]]; [[Verifiable Self-Certification]]; [[Design Spec]]

## Context

Across the v0.1 wiki the phrase "SHA-256" appears in several load-bearing locations: the transcript's `rtm:inputsHash` / `rtm:resultHash`, the RDFC-1.0 canonical-form hash, `rtm:hasContentHash` examples, and the transcript-level Merkle commitment. Naming a specific algorithm in prose is convenient but invites a real failure mode: a reader (or worse, an implementer) takes "SHA-256" to be hardcoded into the data model rather than a default chosen by the active cryptographic suite. When SHA-256 — or the P-256 curve, or any other primitive — eventually retires from acceptable use, a hardcoded reading forces code surgery across the `flexo-rtm` codebase and invalidates every prior cert artifact's algorithm assumption.

[[ADR-023 Cryptography by Composition of Battle-Tested Standards]] already establishes that `flexo-rtm` does not invent crypto; it composes W3C VC Data Integrity 2.0, DSSE + in-toto, Sigstore cosign, Rekor, and git GPG/SSH commit signing. Each of these standards already carries its own algorithm-identifier mechanism: VC-DI suites are named (`ecdsa-rdfc-2019`, `eddsa-rdfc-2022`, future suites for post-quantum primitives), cosign embeds algorithm metadata in its signature bundles, DSSE envelopes carry algorithm IDs in their payload-type fields, and OCI image signatures follow the OCI signature specification's algorithm registry. The composition principle therefore extends naturally to algorithm choice: **the algorithm is a suite parameter, not a hard pin in `flexo-rtm` core**. See [[Design Spec]] §4.6 and the principle stated in [[Signed Envelopes and Established Standards]].

The motivation for this ADR is to make that principle explicit, name the mechanism that delivers it, and align the wiki's prose so that "SHA-256" appears only as the v0.1 default — derived from the active suite — and never as an unconditional fact about the architecture.

## Decision

`flexo-rtm` v0.1 treats **hash-algorithm and signature-algorithm choice as a suite parameter, not a hard pin**. The active cryptographic suite — VC-DI 2.0 `cryptosuite` ID for Data Integrity proofs, cosign's signature-bundle metadata for OCI / DSSE, the `multihash`-style algorithm prefix on `rtm:hasContentHash` — supplies the algorithm. Where the wiki currently names "SHA-256," it should be read as "the content-hash algorithm specified by the active suite; v0.1's default is SHA-256 because that is the W3C Data Integrity 2.0 default for the `ecdsa-rdfc-2019` and `eddsa-rdfc-2022` cryptosuites and the cosign default." Tooling is and remains **established libraries** — `hashlib`, `cryptography`, `sigstore-python`, `libssl` bindings — never hand-rolled primitives.

## Consequences

### Positive

- Forward-compatibility: when SHA-256 or P-256 retire, `flexo-rtm` rotates by updating the suite catalog and the SHACL profile defaults, not by surgery across the codebase
- Tool footprint stays compact: one Python crypto stack (`hashlib` + `cryptography`), one cosign install, one Sigstore client, one git signing setup — adding a new algorithm means a new suite ID, not a new dependency
- Suite-driven framing aligns `flexo-rtm` with the surrounding ecosystem (W3C VC-DI, cosign, OCI signatures) — auditors recognise the pattern; no bespoke algorithm-negotiation vocabulary is introduced
- Cert artifacts remain auditable across suite rotations: each artifact records the suite ID it was certified under, and verifiers locate the right primitive from that ID

### Negative / Tradeoffs

- Wiki prose becomes slightly more verbose — "the content-hash algorithm specified by the active suite (default: SHA-256 per VC-DI 2.0 and cosign defaults)" instead of bare "SHA-256"; mitigated by the prose being clearer about what is variable and what is fixed
- A reader scanning quickly may still take "SHA-256" as the algorithm; mitigated by the agility framing being introduced up front in [[Signed Envelopes and Established Standards]] and recapped wherever a specific algorithm name appears
- Implementations MUST parse suite IDs from incoming artifacts rather than assuming SHA-256; this is established practice for VC-DI / cosign verifiers, so the cost is bounded

### Neutral

- The decision composes cleanly with [[ADR-016 Composable SHACL Profiles]]: a profile may pin a specific suite for a regulated context (e.g., a FIPS-only profile), while the default profile leaves the suite to whatever the artifact carries
- v0.1's empirical defaults — SHA-256, Ed25519, P-256 — are unchanged; only the framing is corrected

## Alternatives Considered

- **Hard-pin SHA-256 + ECDSA-P-256 (or Ed25519) for v0.1 simplicity, defer agility to a later version:** Rejected. Algorithm retirement (NIST deprecation, post-quantum migration, regulatory mandate) is a near-term reality on the same horizon as v0.1's expected adoption. A hard pin forces code surgery and invalidates prior artifacts' algorithm assumptions when retirement happens; agility is cheap if introduced at the design phase and expensive to retro-fit.
- **Define an `rtm:` core vocabulary for algorithm negotiation:** Rejected. W3C VC-DI 2.0 already supplies the `sec:cryptosuite` mechanism; cosign and OCI image-signature standards already supply theirs; DSSE carries algorithm IDs in its payload-type fields. Inventing a parallel `rtm:cryptoAlgorithm` predicate duplicates standards work and creates a second, less-supported negotiation surface. Composition over invention (per [[ADR-023 Cryptography by Composition of Battle-Tested Standards]]) — read the algorithm from the suite, not from an `rtm:`-prefixed parallel.
- **Multi-algorithm bundled hashes (carry SHA-256 AND SHA-3 AND BLAKE3 simultaneously for every artifact):** Rejected for v0.1. Multi-hashing adds storage and computation cost and answers a problem (algorithm consensus disagreement among verifiers) that does not arise in v0.1's adoption profile. The right time for multi-hashing is during a specific algorithm-retirement transition window, gated by a profile, not as a default.

## Implementation Notes

- The wiki sites where this ADR governs prose: [[Signed Envelopes and Established Standards]] (new "Cryptographic agility" section near the top), [[RDFC-1.0 Canonicalization]] (replace bare "SHA-256" with suite-aware framing), [[Transcript Replay Semantics]] (the `rtm:inputsHash` / `rtm:resultHash` algorithm is suite-derived), [[Verifiable Self-Certification]] (canonical-form-hash algorithm comes from the active suite), [[External URI References]] (`rtm:hasContentHash` uses a `multihash`-style algorithm prefix), [[Lossless Roundtrip Definition]] (the byte-equality test references whatever hash the active suite specifies)
- Active suite IDs are read from VC-DI proofs (`sec:cryptosuite`), cosign bundles (signature-algorithm metadata), DSSE envelopes (payload-type / algorithm ID), and the `multihash` prefix on `rtm:hasContentHash`
- The v0.1 ontology continues to declare SHA-256 as the default hash for the bundled `data-integrity-attestations`, `dsse-activities`, and `cosign-images` profiles, because those are the standards' own defaults; a future profile can override
- Tool pin: `hashlib` (stdlib), `cryptography` (PyCA), `sigstore-python` (Sigstore), system `openssl`/`libssl` bindings via `cryptography`. No hand-rolled primitives, no custom suite catalog
- Profile registry sketch lives in `ontology/profiles/cryptosuites.ttl`, enumerating VC-DI suite IDs flexo-rtm recognises; this is **informational** — verification reads the suite ID from the artifact and applies the matching standard primitive
- No backward-incompatible RDF changes: existing artifacts that record raw SHA-256 hashes remain valid (the algorithm is unambiguously SHA-256 in those cases via the active-default suite at the time of cert)

## References

- [[Design Spec]] §4.6 (Signed envelopes — composition of established standards), §4.9 (Reproducibility chain)
- [[Signed Envelopes and Established Standards]] — the canonical composition documentation; new "Cryptographic agility" section
- [[ADR-023 Cryptography by Composition of Battle-Tested Standards]] — composition principle this ADR extends to algorithm choice
- [[ADR-016 Composable SHACL Profiles]] — composability the suite catalog rides on
- W3C Verifiable Credentials Data Integrity 2.0 (`sec:cryptosuite`): https://www.w3.org/TR/vc-data-integrity/
- W3C Data Integrity ECDSA Cryptosuite: https://www.w3.org/TR/vc-di-ecdsa/
- W3C Data Integrity EdDSA Cryptosuite: https://www.w3.org/TR/vc-di-eddsa/
- Sigstore cosign signature-bundle format: https://docs.sigstore.dev/
- OCI Image Signature Specification: https://github.com/opencontainers/image-spec/blob/main/signature.md
- Multihash: https://github.com/multiformats/multihash
- Closes flexo-rtm-research issue #1 (Cryptographic Agility)
