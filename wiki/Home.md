<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# flexo-rtm-research

> Design, research synthesis, and decision rationale for the `flexo-rtm` standards + software repo.

> **This wiki is a published mirror.** Source of truth: [`wiki/` in the main repo](https://github.com/dynamicalsystemsgroup/flexo-rtm-research/tree/main/wiki). To suggest changes, open a PR against the main repo — see [CONTRIBUTING.md](https://github.com/dynamicalsystemsgroup/flexo-rtm-research/blob/main/CONTRIBUTING.md).

## What this is

`flexo-rtm-research` is the design-and-rationale companion to the forthcoming `flexo-rtm` standards + software repo — a verifiable self-certification protocol for bidirectional requirements traceability of SysMLv2 models, anchored in open source and self-hostable on Flexo MMS.

This wiki holds the **canonical design spec**, internal/external research synthesis, certification-model documents, adapter contracts, reproducibility analysis, and the Architecture Decision Records (ADRs) that lock the design. It is the artifact reviewers read in depth **before** implementation of `flexo-rtm` begins.

## The thesis (8 propositions)

The load-bearing claims of the design. One-line summaries here; full prose lives in [[Mission and Thesis]].

1. **Traditional bidirectional traceability is the trusted primary.** v0.1 ships forward + backward analysis with coverage statistics, in the form Doors/Jama/OSLC practitioners already recognize. No commitment to topological framework required to adopt.
2. **Named-approver attestations (satisfaction / adequacy / sufficiency) are structurally enforced.** Three `rtm:Attestation` subclasses; SHACL `sh:minCount 1 ; sh:nodeKind sh:IRI` on `rtm:approvedBy` rejects unaccountable attestations at write time. ADCS regression compatible.
3. **External URI references (git+commit, content addresses, OCI digests) are the open-source foundation.** Evidence, models, and activities reference content outside the RDF via URI. These references — not the RDF metadata in isolation — are the source of true open-source interoperability, portability, auditability, and reproducibility.
4. **Cryptography by composition of battle-tested standards, never invention.** git GPG/SSH signing + W3C VC Data Integrity + DSSE/in-toto + Sigstore (cosign + Rekor) + OCI image signatures. v0.1 ships vocabulary and composable optional profiles for each surface. No custom crypto.
5. **Identity by thin projection of external authoritative sources, never ownership.** No authentication, no credentials. Named approvers are IRIs referencing identities owned by institutional SSO / LDAP / GitHub. Three SPARQL-evaluable policy primitives (RBAC, ABAC, scope-based). One SHACL bottleneck.
6. **Methodology agnosticism is a foundational axiom.** `flexo-rtm` does not commit to any specific assurance methodology. INCOSE / ISO 15288, DO-178C, NASA Phase A–F, ISO 9001, Agile, MIL-STD-498, and custom phasing participate on equal footing. The topological framework articulated in Zargham (2026) is a related research line with philosophical kinship but **not `flexo-rtm`'s destination** — if it matures, it operates as downstream analysis on data `flexo-rtm` produces, alongside other possible downstream paths (SLSA, GSN, ARP4754A, in-house). Locked in [[ADR-032 Methodology Agnosticism as Foundational Axiom]]; framework details in [[Topological Framework Future Work]].
7. **Verifiability requires reproducibility at multiple levels.** RDF-internal (RDFC-1.0 + transcript replay), external (re-fetch git+commit / content-hash / OCI digest, re-execute, compare), accountability (git-signed commits matching `rtm:approvedBy`), signed envelopes, and identity projection — all composed for end-to-end open-source verifiable self-certification.
8. **Reproducibility is structural and local; verification is federated.** Each fact is structurally complete for its own local context — RDF neighborhood, external URIs, projection-at-cert-time, signatures sufficient to reproduce it in isolation. A verifier with adequate local permissions for a specific fact can re-execute that fact alone. Reproduction federates computationally and organizationally. No central coordination required.

## Relationship to other repos

- **`flexo-rtm`** — the implementation repo (built **after** this wiki is reviewed). Will hold the formal spec, oracle code, ontology, conformance suite, and OSLC adapters.
- **`flexo-conflict-resolution-policy-research`** — the sibling vault analyzing constraint-aware merge synthesis. `flexo-rtm`'s storage layer adopts its conclusions; see [[Flexo Git Coexistence]].
- **`ADCS-lifecycle-demo`** — the prototype that proves the pattern end-to-end (8-stage pipeline, 166 tests, live Flexo integration). v0.1's regression corpus. See [[ADCS Prototype Lessons]].
- **INCOSE IS 2026 paper** — *Formalizing Document Assurance: A Topological Framework for Verification, Validation, and Human Accountability* (Zargham 2026), submitted. Articulates the topological framework as a related research line (not `flexo-rtm`'s destination — see [[ADR-032 Methodology Agnosticism as Foundational Axiom]]); the paper's named-approver accountability principle is part of what `flexo-rtm` IS. See [[INCOSE IS 2026 Paper]].
- **OpenMBEE** — the open-source MBSE ecosystem `flexo-rtm` targets. Both `flexo-rtm-research` and `flexo-rtm` transfer to OpenMBEE at the MVP service milestone.

## Where to start (reading paths)

- **"I want to understand the thesis"** → [[Mission and Thesis]] → [[Verifiable Self-Certification]] → [[Traditional Forward and Backward Analysis]]
- **"I want to evaluate the design decisions"** → [[Design Spec]] (especially §9.A acceptance criteria and §14 locked decisions) → scan ADRs in the sidebar's Decision Log section
- **"I want to dive into a specific boundary"** → use the sidebar's **v0.1 Certification Model** section, or [[Map of Content]] for the comprehensive index with one-line annotations per page

## License

This wiki and the companion repo use a three-license strategy (Apache-2.0 / CC-BY-4.0 / CC0-1.0). See [LICENSE.md](https://github.com/dynamicalsystemsgroup/flexo-rtm-research/blob/main/LICENSE.md) in the main repo. Every wiki page carries an `SPDX-License-Identifier: CC-BY-4.0` header.

## Citation

Citation block for the INCOSE IS 2026 paper will be added in [[INCOSE IS 2026 Paper]] once publication is finalized.
