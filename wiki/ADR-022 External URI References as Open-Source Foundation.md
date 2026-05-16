<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-022: External URI References as Open-Source Foundation

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-023 Cryptography by Composition of Battle-Tested Standards]]; [[ADR-025 Reproducibility is Structural and Local]]; [[External URI References]]; [[Design Spec]]

## Context

A cert artifact in `flexo-rtm` describes evidence, models, and activities by **reference** — git commits, content-addressed blobs, OCI image digests, project URLs. The RDF metadata in isolation says "verification activity V was executed against model M producing result R," but the **actual** model, activity definition, and result are external to the RDF graph and are reached via URI. If those external URI references are informal practice rather than disciplined vocabulary, then the cert artifact is opaque about how to reproduce, audit, or verify the underlying facts. The ADCS prototype already operates this way at the implementation level (Docker compute backend captures `prov:atLocation` / `prov:wasAssociatedWith`), but the vocabulary and SHACL discipline were not formalized. The question is whether v0.1 formalizes external URI references as a **foundational** vocabulary commitment — the basis of open-source interoperability, portability, auditability, and reproducibility — or leaves them as informal practice. See [[Design Spec]] §4.9 and [[External URI References]].

## Decision

`flexo-rtm` v0.1 formalizes **external URI references** as foundational vocabulary: `rtm:hasGitRepo`, `rtm:hasGitCommit`, `rtm:hasContentHash`, `rtm:hasOCIImage`, plus PROV-O provenance (`prov:atLocation`, `prov:wasAssociatedWith`, `prov:wasGeneratedBy`). SHACL profiles discipline the references — activities **SHOULD** carry at least one of `rtm:hasGitCommit` / `rtm:hasOCIImage` (warning by default; **error** under the `strict-provenance` profile). The **reproducibility chain** extends beyond RDF-internal canonical hashing to include **re-fetching code/data/containers** from their external URIs and **re-executing**.

## Consequences

### Positive

- External URI references are the source of true open-source interoperability — adopters can verify a cert artifact independently by re-fetching the referenced artifacts from their canonical sources
- Portability: a cert artifact is portable between institutions because the external references are universal (git URLs, content hashes, OCI digests) rather than institution-specific
- Auditability: every external dependency the cert relies on is enumerated; the audit reports include a **reproducibility manifest** listing every external URI
- Reproducibility: re-execution from external URIs is the **third dimension** of reproducibility (alongside RDFC-1.0 canonical equivalence per [[ADR-011 Lossless Criterion A plus C]] and transcript replay per [[Transcript Replay Semantics]])
- Closes the ADCS prototype's gap: the prototype operated this way implicitly; v0.1 formalizes it as discipline

### Negative / Tradeoffs

- SHACL discipline adds constraints adopters have to satisfy — `strict-provenance` cert runs fail without complete external URI metadata; mitigated by the warning-default-error-strict gradient
- External URIs are dereferenceable today but may not be in the future (link rot, repo deletion); mitigated by content-addressing (`rtm:hasContentHash`) and by recommending mirror practices in the reproducibility documentation
- Adopters with air-gapped or restricted-internet environments need local mirrors of external dependencies; the URI references still work, but resolution is institutional

### Neutral

- The vocabulary composes cleanly with the crypto stack (see [[ADR-023 Cryptography by Composition of Battle-Tested Standards]]): signed git commits, cosigned OCI images, DSSE-signed activities all reference the same external-URI vocabulary

## Alternatives Considered

- **Ship the cert vocabulary without external URI discipline, leaving git/content-address/OCI references as informal practice:** Document that adopters *should* reference external artifacts but do not enforce the references via SHACL. Rejected: external URI references are **foundational, not cosmetic** — they are the source of open-source interoperability, portability, auditability, and reproducibility. Without discipline, references drift to free-text annotations and become unreliable. The ADCS prototype already operates this way at the implementation level; v0.1 must formalize and SHACL-discipline the pattern so that cert artifacts have a stable, machine-checkable reproducibility surface.

## Implementation Notes

- Vocabulary defined in the v0.1 ontology: `rtm:hasGitRepo`, `rtm:hasGitCommit`, `rtm:hasContentHash`, `rtm:hasOCIImage`, plus relevant PROV-O properties
- SHACL profile `strict-provenance` enforces external URI presence as **error**; default cert runs emit **warning** for missing external URIs (see [[ADR-016 Composable SHACL Profiles]])
- Audit reports include a **reproducibility manifest** — a structured listing of every external URI the cert depends on, with content hashes where available
- Re-execution support documented in [[External URI References]] (the canonical wiki page)
- Three dimensions of reproducibility: (1) RDFC-1.0 canonical equivalence (see [[ADR-011 Lossless Criterion A plus C]]), (2) transcript replay (see [[Transcript Replay Semantics]]), (3) external-URI re-fetch and re-execute (this ADR)

## References

- [[Design Spec]] §4.9 (Reproducibility Chain), §4.10 (External URI Vocabulary)
- [[External URI References]] — canonical external URI vocabulary documentation
- [[Verifiable Self-Certification]] — the cert artifact this vocabulary supports
- [[ADR-023 Cryptography by Composition of Battle-Tested Standards]] — crypto that signs the references
- [[ADR-025 Reproducibility is Structural and Local]] — the locality property this supports
- PROV-O: https://www.w3.org/TR/prov-o/
