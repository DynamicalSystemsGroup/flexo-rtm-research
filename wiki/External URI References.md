<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# External URI References

> Elaborates [[Design Spec]] §4.5 (External URI references — the git+RDF foundation; **normative source**) and §9.A.4 acceptance criteria **U1–U6**. Cross-reference with §4.8 (three-layer artifact + reproducibility manifest) and §4.9 (reproducibility chain).

**Status:** Ships in v0.1. Foundational to the open-source / self-hostable thesis. The ADCS prototype already operates this way (Docker compute backend emits `prov:atLocation`, `prov:wasAssociatedWith`, `prov:startedAtTime`); v0.1 formalizes the vocabulary, adds SHACL discipline, and binds the result into the audit report's reproducibility manifest.

These references are not cosmetic. They are the load-bearing mechanism by which `flexo-rtm`'s certification artifacts achieve **open-source interoperability, portability, auditability, and reproducibility** — without proprietary dependencies, without living-service dependencies, and without lock-in to any single tool.

## 1. The premise — RDF as a non-closed world

The RDF graph in `flexo-rtm` is not a closed world. It carries metadata about evidence, models, attestations, and activities — but the **actual content lives outside**: in git repositories, on filesystems, in object storage, in container registries, on IPFS. The RDF entities **reference that content via URI**, and those references are first-class.

Without external URIs the RDF is metadata floating free of any anchor: nothing computable can be re-fetched, re-hashed, or re-executed. With them, the RDF becomes an index over a content-addressable open-source world — a verifier can `git clone`, `oras pull`, `curl`, `ipfs get`, recompute hashes, and compare to the values recorded in the graph using only standard tooling.

## 2. Entity classes that bear external URI references

Two `flexo-rtm` classes carry external URI references and pull in PROV-O semantics:

- **`rtm:Activity`** (`rdfs:subClassOf prov:Activity`) — a process: simulation run, model build, test execution, proof check, data import. The principal site of the git+OCI provenance pattern.
- **`rtm:Artifact`** (`rdfs:subClassOf prov:Entity`) — an addressable artifact: model file, evidence file, simulation result, dataset. The principal site of the content-hash pattern.

Attestations (per [[Design Spec]] §4.3) reference activities; activities reference artifacts; artifacts carry content hashes. The chain is locally re-traversable.

## 3. The reference vocabulary (v0.1, normative)

The vocabulary lives in `ontology/core/` and is committed to v0.1 stability.

| Property | Range | Purpose |
|---|---|---|
| `rtm:hasGitRepo` | `xsd:anyURI` | Git repository URL. Works against any git host: GitHub, GitLab, Bitbucket, Gitea/Forgejo, bare repos over HTTPS or SSH. |
| `rtm:hasGitCommit` | `xsd:string` | Full commit SHA. Cryptographically pins the tree and all parents. |
| `rtm:hasGitPath` | `xsd:string` | Optional path within the repo. Scopes a reference to a specific file or subdirectory. |
| `rtm:hasContentHash` | `xsd:string` | `multihash`-style algorithm-prefixed content hash, e.g., `sha256:abcd1234...`, `sha3-256:...`, `blake3:...`. Algorithm is read from the prefix, not hardcoded; SHA-256 is the v0.1 default per the active cryptographic suite (see [[ADR-026 Cryptographic Agility via Algorithm Profiles]]). Canonical content addressing for artifact bytes. |
| `rtm:hasOCIImage` | `xsd:string` | OCI image reference with digest, e.g., `ghcr.io/org/image@sha256:def...`. Resolvable against any OCI-compliant registry (Docker Hub, ghcr, ECR, GAR, Quay, Harbor). |
| `dcat:downloadURL` | `xsd:anyURI` | Optional fetch URL: mirror, raw-content URL, IPFS gateway, S3 link. The integrity guarantee is the content hash, not this URL. |

The vocabulary composes with standard PROV-O: `prov:wasDerivedFrom`, `prov:used`, `prov:wasGeneratedBy`, `prov:atLocation`, `prov:hadPlan`, `prov:startedAtTime`, `prov:endedAtTime`, `prov:wasAssociatedWith`. PROV-O carries the relationships; `rtm:*` carries the content references.

## 4. Turtle examples

### 4.1 An activity that ran a simulation

```turtle
@prefix rtm:  <https://flexo-rtm.org/ontology/core#> .
@prefix prov: <http://www.w3.org/ns/prov#> .
@prefix dcat: <http://www.w3.org/ns/dcat#> .
@prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .

:simulation-run-2026-05-16-001 a rtm:Activity ;
    prov:startedAtTime "2026-05-16T14:30:00Z"^^xsd:dateTime ;
    prov:endedAtTime   "2026-05-16T14:31:42Z"^^xsd:dateTime ;
    rtm:hasGitRepo  <https://github.com/example-org/adcs-sim> ;
    rtm:hasGitCommit "9f3a17c4e2b8d6f5a1c9e7b3d8f6a4c2e1b9d7f5" ;
    rtm:hasGitPath  "scripts/slew_maneuver.py" ;
    rtm:hasOCIImage "ghcr.io/example-org/adcs-sim@sha256:def7891ab2c3d4e5f6789a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1" ;
    prov:used         :orbit-params-input ;
    prov:wasAssociatedWith <https://github.com/zargham> .

:orbit-params-input a rtm:Artifact ;
    rtm:hasContentHash "sha256:1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b" ;
    dcat:downloadURL <https://data.example.org/orbit-params-2026.csv> .

:simulation-result-001 a rtm:Artifact ;
    rtm:hasContentHash "sha256:f1e2d3c4b5a6978869594a3b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2" ;
    prov:wasGeneratedBy :simulation-run-2026-05-16-001 .
```

A third party with the values above can `git clone` + `git checkout 9f3a17c4`, `docker pull ghcr.io/example-org/adcs-sim@sha256:def7891a...`, fetch the orbit-params CSV and verify its content hash, then re-execute the simulation and compare the output's hash to `sha256:f1e2d3c4...`. **No proprietary protocol; no shared credentials; no live `flexo-rtm` service required.**

### 4.2 An attestation referencing an activity

```turtle
:attestation-thermal-validated a rtm:SufficiencyAttestation ;
    rtm:satisfies :evidence-thermal-cycle :req-thermal-margins ;
    rtm:approvedBy <https://github.com/zargham> ;
    prov:atTime "2026-05-16T15:00:00Z"^^xsd:dateTime ;
    prov:wasGeneratedBy :simulation-run-2026-05-16-001 .
```

The attestation binds a satisfaction claim to a named approver, and the activity that produced the supporting evidence is reachable via `prov:wasGeneratedBy`. That activity carries the git+OCI references — the chain from attestation → activity → external URIs is fully traversable in the RDF, and the URIs hand off to standard tooling for re-fetch.

### 4.3 A model artifact referenced by git path plus content hash

```turtle
:model-rigid-body-dynamics a rtm:Artifact ;
    rtm:hasGitRepo  <https://github.com/example-org/adcs-models> ;
    rtm:hasGitCommit "c7d2f8a3b1e0d9c8b7a6f5e4d3c2b1a0e9f8d7c6" ;
    rtm:hasGitPath  "src/dynamics/rigid_body.smt2" ;
    rtm:hasContentHash "sha256:b3a1f9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0" .
```

The git path locates the file for human review; the content hash pins the exact bytes. The two MUST agree, and an audit-mode oracle MAY verify the agreement (per **U2**).

## 5. SHACL discipline (v0.1)

The vocabulary is governed by a SHACL shape in `ontology/shapes/`. The default severity is `sh:Warning`; the `--profile=strict-provenance` profile upgrades to `sh:Violation`.

```turtle
@prefix sh:  <http://www.w3.org/ns/shacl#> .
@prefix rtm: <https://flexo-rtm.org/ontology/core#> .

rtm:ActivityProvenanceShape a sh:NodeShape ;
    sh:targetClass rtm:Activity ;
    sh:or (
        [ sh:path rtm:hasGitCommit ; sh:minCount 1 ]
        [ sh:path rtm:hasOCIImage  ; sh:minCount 1 ]
    ) ;
    sh:severity sh:Warning ;
    sh:message "Activity should reference at least one of git commit or OCI image for reproducibility" .
```

This shape implements acceptance criterion **U1** ([[Design Spec]] §9.A.4): any `rtm:Activity` SHOULD carry at least one of `rtm:hasGitCommit` or `rtm:hasOCIImage`, with `--profile=strict-provenance` upgrading SHOULD to MUST/error. The default profile lets adopters incrementally adopt the discipline; the strict profile is for organizations whose policy mandates full provenance on every activity.

Companion shapes constrain content-hash format (algorithm prefix required), OCI reference syntax (registry + image + `@sha256:`-style digest), git commit length, and well-formedness of `dcat:downloadURL`. All default to warnings; the strict-provenance profile upgrades them.

## 6. Why these specific URI schemes — the open-source rationale

Each scheme is **open, content-addressable, and free of proprietary chokepoints**.

- **git URLs + commit hashes.** A commit hash is cryptographically immutable: same hash, same tree, every client. Clones work over HTTPS, SSH, file, or git wire; no single host is required.
- **`multihash`-style content hashes (default `sha256:`).** Any storage layer — filesystem, S3, HTTP, IPFS, git-LFS, DVC, Datalad, Nix store — produces the same hash for the same bytes. The hash is the identity; storage is interchangeable. The algorithm prefix (e.g., `sha256:`, `sha3-256:`, `blake3:`) makes content addressing algorithm-agile; SHA-256 is the v0.1 default per the active cryptographic suite (see [[ADR-026 Cryptographic Agility via Algorithm Profiles]]) but the system rotates by changing the prefix, not by code surgery.
- **OCI image digests.** `ghcr.io/org/image@sha256:digest` is resolvable against Docker Hub, ghcr, ECR, GAR, Quay, Harbor, Zot, or any OCI-conformant registry. `oras pull` / `docker pull` fetch; `cosign verify` checks signatures.
- **`dcat:downloadURL`.** A W3C-standard vocabulary for fetch hints, interoperable with data catalogs and dataset registries.

The alternative — proprietary identifiers — locks adopters to the issuing system and defeats the open-source thesis.

## 7. What each URI enables independently

| Property | What it enables |
|---|---|
| **Reproducibility** | Fetch the same bytes, run the same code in the same image, get the same result. No proprietary auth, no living-service dependency, no link rot. |
| **Auditability** | A third party computes the content hash of fetched bytes, compares to the recorded hash, and verifies that the inputs match the claims. |
| **Portability** | The same RDF is consumable by any compliant tool. Migrating between hosts (GitHub → Forgejo, ghcr → Harbor) does not invalidate references — the hashes are stable. |
| **Interoperability** | DVC, Datalad, Nix, IPFS, git-LFS, OCI registries can all resolve these URIs through their native protocols. `flexo-rtm` does not dictate a single fetcher. |

## 8. The ADCS prototype precedent

The pattern is not new. The ADCS lifecycle demo (`ADCS-lifecycle-demo/evidence/binding.py`) already emits the PROV envelope on activities:

```turtle
<urn:adcs:activity:SA-001> a prov:Activity ;
    prov:atLocation         <urn:adcs:location:engineering-workstation> ;
    prov:wasAssociatedWith  <urn:adcs:executor:SymPyEngine> ;
    prov:startedAtTime      "2025-..."^^xsd:dateTime .
```

The prototype demonstrates the shape of the discipline; what it lacks is full OCI-digest capture and SHACL verification. v0.1 closes that gap by formalizing `rtm:hasGitCommit`, `rtm:hasOCIImage`, and `rtm:hasContentHash` as first-class properties and adding the SHACL shape above. The prototype's Docker backend is the empirical seed — patterns that worked in practice are the patterns v0.1 standardizes.

## 9. Co-versioning with the storage layer (Flexo)

When the operational layer commits an attestation, the underlying activity's git refs and OCI digests are captured **in the same atomic transaction**. This is the [[Flexo Git Coexistence]] property: model + traceability + execution environment all version together. The cert run's HEAD commit is recorded on the cert artifact; the activity that ran the pipeline carries its own `rtm:hasGitCommit` and `rtm:hasOCIImage`; transcript / attestation graph / audit report carry content hashes computed at commit time.

A future verifier can reconstruct **exactly** the state of the model + traceability + execution environment at the time the cert was emitted, by checking out the recorded commit and pulling the recorded image. Acceptance criterion **U6** ([[Design Spec]] §9.A.4) requires that URI references **persist verbatim** through Flexo round-trips (no normalization, no rewriting). See [[Storage Layer Flexo Conventions]].

## 10. Reproducibility chain — three dimensions

The full reproducibility story has five dimensions (see [[Design Spec]] §4.9). This page focuses on the three rooted in external URI references; the remaining two are covered in their own pages.

**RDF-internal (canonical equivalence).** Inputs to any cert step are RDFC-1.0 canonicalized to an input-hash. The transcript records (input-hash, recorded-result-hash) per step. A verifier with read access to the input subgraph can re-execute locally and confirm byte-identical results. See [[RDFC-1.0 Canonicalization]] and [[Transcript Replay Semantics]].

**External re-fetch (re-execution).** Activities carry git+commit, content-hash, and OCI-digest URIs. A verifier with **fetch access** can re-execute the activity from scratch — pull the code at the recorded commit, fetch the data at the recorded content hash, run the recorded image, content-hash the outputs, compare to the recorded artifact hashes. Acceptance criteria **U2** (content-hash verification), **U3** (git commit existence), and **U4** (OCI digest existence) gate this dimension in audit mode. Verifiers without fetch access can still verify **structural completeness** of the references (well-formed, registered in the manifest, consistent with the profile) by reading the RDF alone — acceptance criterion **X8** in §9.A.5.

Important distinction: **content-hash verification applies to *artifact bytes* — the file content fetched at the dereferenced URI** (a model file, an evidence file, an input dataset, a serialized result). The bytes-of-the-evidence-file path is **bit-exact**: the recomputed content hash either equals the recorded `rtm:hasContentHash` or it does not. This is the same regime as RDF-internal canonical-form hashing. However, when the cert artifact's claim depends on a **numerical result derived from running an activity** (a Monte Carlo simulation output, an FEA residual, a regression-fit coefficient), bit-identical reproduction across runs and platforms is often physically impossible — floating-point non-associativity, BLAS code-path divergence, parallelism non-determinism, library minor-version differences. That numerical-result verification path is the **tolerance-aware regime** per [[ADR-027 Bit-Exactness vs Numerical Tolerances Are Both First-Class]]: the recorded numerical result is checked against the recorded expected outcome under the tolerance declared by the relevant sufficiency criteria (see [[Aspect Coverage with Adequacy and Sufficiency]]). The two paths are orthogonal — `rtm:hasContentHash` on an artifact pins the bytes that were observed at cert time (bit-exact); the tolerance on a sufficiency criterion pins how closely a re-execution must reproduce the numerical content of those bytes (tolerance-aware). A verifier may exercise both: confirm the recorded bytes match the recorded hash (bit-exact), then confirm the numerical content of those bytes is within tolerance of the recorded expected outcome (tolerance-aware).

**Approver binding.** The git commit introducing an attestation triple is GPG/SSH-signed by the named approver (when `signed-commits` is active). The signature key resolves to the `rtm:approvedBy` IRI's published key, binding "this human attested this fact at this time" to public-key infrastructure verifiers already trust. See [[Approver Binding via Git]].

A fourth dimension — **signed envelopes** (W3C Data Integrity, DSSE+in-toto, Sigstore cosign, Rekor) — composes orthogonally with these references; see [[Signed Envelopes and Established Standards]]. A fifth — **identity projection** (the projection-as-of-cert-time of identities and policies, recorded in the transcript) — is covered by [[Identity Boundaries and Policy Projections]].

Together: a complete reproducibility chain end-to-end, with no proprietary dependencies anywhere in the chain.

## 11. Reproducibility manifest

Acceptance criterion **U5** ([[Design Spec]] §9.A.4) requires every audit report to include a **Reproducibility Manifest** enumerating every external URI the cert depends on, organized by URI type. The manifest format is normatively defined in `spec/transcript-model.md`; the structure:

- **Git refs** — `(rtm:hasGitRepo, rtm:hasGitCommit, rtm:hasGitPath?)` triples, deduplicated.
- **Content hashes** — `(algorithm, hash, dcat:downloadURL?)` entries, deduplicated.
- **OCI digests** — `(registry, image, digest, cosign-bundle?)` entries, deduplicated.

A third party uses the manifest as a **checklist**: for each row, fetch the content (`git clone`+`git checkout`, `curl`, `oras pull`), compute the hash (commit-tree, sha256, OCI digest), compare to the recorded value. The manifest passes if every row passes. The audit report records the outcome.

Crucially, the manifest is **structurally complete** even when the verifier cannot dereference. Per acceptance criterion **X8**, a verifier without network access can still confirm that every URI in the manifest is well-formed and that every external reference appearing in the RDF is registered in the manifest. Dereferencing is required for re-execution; not for structural validation.

## 12. Tooling that consumes these URIs (no `flexo-rtm` lock-in)

Standard tools resolve the v0.1 vocabulary natively:

- `git clone` / `git checkout <commit>` — source
- `oras pull` / `docker pull` / `skopeo copy` — OCI images
- `cosign verify` — OCI signatures (`cosign-images` profile)
- `curl` / `wget` / `ipfs get` — `dcat:downloadURL` retrieval
- DVC / Datalad / git-LFS / Nix — content-hash-driven fetch
- `sha256sum` / `openssl dgst` — content-hash verification

`flexo-rtm` produces references; consumers use whatever tooling fits. **The format is the contract, not the tool.**

## 13. What v0.1 ships

- The six properties in §3 in `ontology/core/`.
- `rtm:ActivityProvenanceShape` and companion shapes in `ontology/shapes/`, defaulting to warning severity.
- `--profile=strict-provenance` upgrading severities to error.
- Reproducibility-manifest emitter in the audit-report generator (per **U5**).
- Flexo round-trip preservation per **U6**, tested in `tests/integration/flexo/test_uri_preservation.py`.
- Integration tests against ADCS Docker-backend activities, exercising the end-to-end pattern.
- An optional audit-mode oracle path (off by default) performing **U2** / **U3** / **U4** checks against live registries.

## 14. What v0.1 does NOT do — the boundary

- **No fetcher.** The references are produced; consumption is by external tooling. Building a fetcher would couple `flexo-rtm` to a specific tool stack.
- **No content-hash verification at cert time.** It is an audit-time check (per **U2**), opt-in via audit mode. Cert-time SHACL operates on the RDF metadata; it does not block on the network.
- **No online dependency during cert.** Cert is offline-clean; consumption of references is a separate concern.
- **No recursive registry of pre-approved artifact types.** That registry belongs to the future topological framework. Forward compatibility is preserved — when the framework lands, it operates against URI references already captured under v0.1 conventions.
- **No new URI schemes.** Every property reuses an established standard (git, sha256, OCI, DCAT). The point is to compose, not to invent.

## 15. Forward compatibility with the topological framework

When the future topological framework is built ([[Topological Framework Future Work]]), every assurance-triangle vertex references external URIs via this exact vocabulary: an Artifact carries `rtm:hasContentHash`, a Guidance vertex carries `rtm:hasGitRepo`+`rtm:hasGitCommit`+`rtm:hasGitPath`, a Requirement references its source spec the same way. **The URI vocabulary is stable across v0.1 and the future framework.** Adopters of v0.1 accumulate data that remains valid when the framework lands.

## 16. Acceptance criteria recap (§9.A.4 U1–U6)

| ID | Criterion (paraphrase from [[Design Spec]] §9.A.4) |
|---|---|
| **U1** | Any `rtm:Activity` SHOULD carry `rtm:hasGitCommit` or `rtm:hasOCIImage`; `--profile=strict-provenance` upgrades to MUST/error. |
| **U2** | Audit mode MAY fetch `rtm:hasContentHash` references; computed hash MUST equal recorded hash or audit emits `T-fetch-mismatch`. |
| **U3** | Audit mode: fetching `rtm:hasGitRepo`+`rtm:hasGitCommit` MUST succeed. |
| **U4** | Audit mode: fetching `rtm:hasOCIImage` digest MUST succeed; cosign-verifiable under `--profile=cosign-images`. |
| **U5** | Every audit report MUST include a Reproducibility Manifest organized by URI type. |
| **U6** | URI references persist verbatim through Flexo round-trips (no normalization, no rewriting). |

These six are the v0.1 release gate for the artifact-identity boundary. If this page's prose conflicts with the criteria, **the criteria win**.

## 17. Cross-references

- [[Design Spec]] §4.5 (normative source), §4.8 (artifact + manifest), §4.9 (reproducibility chain), §9.A.4 (U1–U6)
- [[Verifiable Self-Certification]] — the artifact that consumes these references
- [[Storage Layer Flexo Conventions]] — round-trip preservation (**U6**)
- [[Flexo Git Coexistence]] — co-versioning of model + traceability + environment
- [[RDFC-1.0 Canonicalization]] — RDF-internal reproducibility
- [[Transcript Replay Semantics]] — manifest recording and replay
- [[Approver Binding via Git]] — approver-binding dimension
- [[Signed Envelopes and Established Standards]] — signature dimension
- [[Identity Boundaries and Policy Projections]] — identity-projection dimension
- [[ADCS Prototype Lessons]] — empirical seed
- [[Topological Framework Future Work]] — forward compatibility
- [[ADR-026 Cryptographic Agility via Algorithm Profiles]] — `rtm:hasContentHash` algorithm prefix is suite-driven, not hardwired
- [[ADR-027 Bit-Exactness vs Numerical Tolerances Are Both First-Class]] — bytes-vs-numerical-result regime distinction
