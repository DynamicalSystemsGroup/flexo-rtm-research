<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# External URI Rules

> **Normative contract** for external URI references in `flexo-rtm` data. Required vs. optional rules per artifact type, URI format validation, audit-mode fetch behavior, and the reproducibility manifest format live here. The `flexo-rtm` [[Design Spec]] §4.4 and §6.4 reference this page. See also [[External URI References]] (background), [[ADR-022 External URI References as Open-Source Foundation]].

## 0. ASOT mapping (the principle this contract implements)

Per [[ADR-033 Generalized ASOT Principle for All Identified Things]] and [[Design Spec]] §4.0 (ASOT principle), every external URI reference in `flexo-rtm` data points to content whose **authoritative source of truth lives outside `flexo-rtm`** — with the entity that produces, maintains, or hosts the content. The reference vocabulary `flexo-rtm` ships is a thin, dereferenceable pointer to that ASOT.

**Per-URI-kind ASOT mapping:**

| Reference vocabulary | ASOT (where the content authoritatively lives) | Dereferencing protocol |
|---|---|---|
| `rtm:hasGitRepo + rtm:hasGitCommit` | the git host (GitHub, GitLab, Codeberg, self-hosted, …) | `git ls-remote`, `git fetch`, or HTTPS Smart Protocol |
| `rtm:hasGitPath` (combined with above) | same — the file or directory at that path at that commit in that repo | `git show <commit>:<path>`, `git archive`, or repo browse |
| `rtm:hasContentHash` (`sha256:` / `sha384:` / `sha512:` / `sha3-*:`) | wherever the content is hosted; **the hash is the identity, not the location** | HTTPS fetch (any mirror) + hash verify; or content-addressed gateway |
| `rtm:hasContentHash` (`ipfs:` / `cid:`) | the IPFS / IPLD network | IPFS gateway (`ipfs.io`, `dweb.link`, or adopter's pinned gateway) |
| `rtm:hasOCIImage` | the OCI registry hosting the image at the digest | OCI Distribution Specification (`GET /v2/<image>/manifests/<digest>`) |
| `dcat:downloadURL` | mirror or alternative fetch location for any of the above | HTTPS GET; informational only, not authoritative on its own |

**Dereferencing is governed by each ASOT's own access policy.** `flexo-rtm` does NOT authenticate the verifier with any ASOT, does NOT proxy content, and does NOT cache. A verifier with permission to access (e.g., a private git repo via SSO, a private OCI registry via pull credentials, IPFS via a pinned-content gateway) can dereference and verify; a verifier without permission can still confirm **structural completeness** of the references per acceptance criterion X8 of [[Design Spec]] §6.6 (every URI is well-formed, every reference is in the manifest, the SHACL profile passes against the recorded data) without ever fetching.

**Security property.** This makes a cert artifact **shareable widely without leaking ASOT content** — the artifact carries identifiers, not content. Sensitive payloads remain behind whichever ASOT owns them. The cert can be published, mailed, audited by any party — what they can resolve depends on what their permissions at each ASOT allow.

## 1. Scope

`flexo-rtm` RDF entities reference concepts outside the graph via URI:

- **git** repositories at specific commit hashes
- **Content-addressed data** (sha256, IPFS CIDs, …)
- **OCI image digests** for execution-environment containers
- Optional **download URLs** for fetch convenience (mirrors, raw-content URLs, IPFS gateways)

These references are foundational, not cosmetic — they are the source of open-source interoperability, portability, auditability, and reproducibility. This page specifies the rules for their use.

## 2. Vocabulary recap

| Property | Range | Purpose |
|---|---|---|
| `rtm:hasGitRepo` | xsd:anyURI | Git repository URL |
| `rtm:hasGitCommit` | xsd:string | Full commit SHA (40 hex chars for SHA-1; 64 hex chars for SHA-256 per ADR-026) |
| `rtm:hasGitPath` | xsd:string | Optional path within the repo |
| `rtm:hasContentHash` | xsd:string | Content hash with algorithm prefix |
| `rtm:hasOCIImage` | xsd:string | OCI image reference with digest |
| `dcat:downloadURL` | xsd:anyURI | Optional fetch URL |

Plus PROV-O: `prov:wasGeneratedBy`, `prov:used`, `prov:wasDerivedFrom`, `prov:atLocation`, `prov:hadPlan`.

## 3. URI format validation

Each property has format constraints enforced by SHACL.

### 3.1 `rtm:hasGitRepo`

```turtle
rtm:HasGitRepoShape a sh:NodeShape ;
    sh:property [
        sh:path rtm:hasGitRepo ;
        sh:datatype xsd:anyURI ;
        sh:pattern "^https://[a-zA-Z0-9.-]+/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\\.git)?/?$" ;
        sh:message "rtm:hasGitRepo must be an HTTPS URL pointing to a git repo (e.g., https://github.com/org/repo)"
    ] .
```

Validation rules:

- MUST be HTTPS (no SSH URLs like `git@github.com:...`; HTTPS supports anonymous read for audit)
- Path SHOULD be `org/repo` or `user/repo` form (no deep paths)
- Trailing `.git` accepted but not required
- No fragment identifiers (`#`) in the URL

### 3.2 `rtm:hasGitCommit`

```turtle
rtm:HasGitCommitShape a sh:NodeShape ;
    sh:property [
        sh:path rtm:hasGitCommit ;
        sh:datatype xsd:string ;
        sh:or (
            [ sh:pattern "^[0-9a-f]{40}$" ]    # SHA-1
            [ sh:pattern "^[0-9a-f]{64}$" ]    # SHA-256 (git's experimental SHA-256 mode per ADR-026)
        ) ;
        sh:message "rtm:hasGitCommit must be a 40-char SHA-1 or 64-char SHA-256 hex string"
    ] .
```

Algorithm is **suite-derived** per [[ADR-026 Cryptographic Agility via Algorithm Profiles]]. v0.1 default: SHA-1 (git's current default) with SHA-256 acceptance for git repos in SHA-256 mode.

### 3.3 `rtm:hasGitPath`

Free-form `xsd:string` (no scheme — it's a relative path). MAY be a file path or directory path within the repo at the specified commit.

### 3.4 `rtm:hasContentHash`

```turtle
rtm:HasContentHashShape a sh:NodeShape ;
    sh:property [
        sh:path rtm:hasContentHash ;
        sh:datatype xsd:string ;
        sh:pattern "^(sha256|sha384|sha512|sha3-256|sha3-512|ipfs|cid):[a-zA-Z0-9+/=_-]+$" ;
        sh:message "rtm:hasContentHash must be 'algo:hex-or-base64' with a recognized algorithm"
    ] .
```

Accepted algorithm prefixes (per [[ADR-026 Cryptographic Agility via Algorithm Profiles]]):

- `sha256:` (v0.1 default; 64 hex chars)
- `sha384:`, `sha512:` (NIST/FIPS suites)
- `sha3-256:`, `sha3-512:` (SHA-3 family)
- `ipfs:` (IPFS CID v1 in base32 or v0 in base58)
- `cid:` (multibase-prefixed CID, IPLD)

Other algorithms accepted only if declared in the active cryptosuite (per [[Signed Envelope Shapes]] §3).

### 3.5 `rtm:hasOCIImage`

```turtle
rtm:HasOCIImageShape a sh:NodeShape ;
    sh:property [
        sh:path rtm:hasOCIImage ;
        sh:datatype xsd:string ;
        sh:pattern "^[a-z0-9.-]+(:[0-9]+)?/[a-z0-9._/-]+@sha[0-9]+:[0-9a-f]+$" ;
        sh:message "rtm:hasOCIImage must include a digest (registry/image@sha256:digest)"
    ] .
```

Format: `<registry>[:port]/<image-path>@<algo>:<digest>`. The `@digest` form is REQUIRED — image tags alone (without digest) are mutable and not acceptable for reproducibility.

### 3.6 `dcat:downloadURL`

Standard `xsd:anyURI`; HTTPS preferred. This is informational only — the authoritative reference is the content hash. Download URLs MAY become stale; the cert artifact is still verifiable as long as the content hash can be computed against any fetched copy.

## 4. Required vs. optional per artifact type

### 4.1 `rtm:Activity`

| Property | Status | Rationale |
|---|---|---|
| `rtm:hasGitRepo` + `rtm:hasGitCommit` | **SHOULD** (one of either git or OCI is required for reproducibility) | Code execution requires identifying the code |
| `rtm:hasOCIImage` | **SHOULD** (alternative to git) | Code-in-container execution identifies environment |
| `prov:used` | **MUST** if the activity consumed any artifact | PROV provenance requirement |
| `prov:wasAssociatedWith` | **SHOULD** | Who ran the activity (named approver per identity projection) |
| `prov:startedAtTime` | **MUST** | When the activity ran |
| `prov:atLocation` | OPTIONAL | Physical/network location if relevant |

Under `--profile=strict-provenance`, the SHOULDs become MUSTs (warning → error).

### 4.2 `rtm:Artifact`

| Property | Status | Rationale |
|---|---|---|
| `rtm:hasContentHash` | **SHOULD** | Content-addressing is what makes the artifact auditable |
| `dcat:downloadURL` | OPTIONAL | Mirror for fetch; not authoritative |
| `prov:wasGeneratedBy` | **MUST** if the artifact has a known producing activity | PROV provenance requirement |
| `rtm:hasGitRepo` + `rtm:hasGitCommit` + `rtm:hasGitPath` | OPTIONAL | If the artifact is a file in a git repo, MAY identify it by git rather than content hash |

An `rtm:Artifact` MUST have at least one of: `rtm:hasContentHash` OR (`rtm:hasGitRepo` + `rtm:hasGitCommit` + `rtm:hasGitPath`).

### 4.3 SysMLv2 model elements

SysMLv2 model elements ingested per [[SysMLv2 Ingestion Contract]] are typed as `rtm:Artifact` but identified by `omg-sysml:elementId` rather than `rtm:hasContentHash`. The source graph (`urn:rtm:source/sysmlv2/{path-hash}`) carries a content hash for the whole ingested file; individual elements are identified by their `elementId`.

## 5. SHACL profile `strict-provenance`

The profile lives in `ontology/profiles/strict-provenance.shacl.ttl`. When active, the SHOULDs in §4 become MUSTs:

```turtle
rtm:StrictActivityProvenanceShape a sh:NodeShape ;
    sh:targetClass rtm:Activity ;
    sh:or (
        [ sh:property [ sh:path rtm:hasGitCommit ; sh:minCount 1 ] ]
        [ sh:property [ sh:path rtm:hasOCIImage ; sh:minCount 1 ] ]
    ) ;
    sh:severity sh:Violation ;
    sh:message "Under strict-provenance, every Activity must reference git or OCI" .
```

Adopters enable `--profile=strict-provenance` when their workflow can guarantee every activity carries its execution-environment URIs.

## 6. Audit-mode fetch behavior

The oracle has two modes:

| Mode | Default | Behavior |
|---|---|---|
| **Structural** (default) | Yes | Validates URIs format-only; does NOT fetch. The cert is fast and offline-runnable. |
| **Audit** (`--audit-mode`) | No | For each referenced URI, attempts to fetch and verify (per §7). Slower; requires network access. |

### 6.1 Structural mode (offline)

Per [[Design Spec]] §6.4 U1, U5, U6:

- Validate URI format against §3 shapes
- Validate every reference in the cert is present in the reproducibility manifest (§8)
- Validate the URI references persist verbatim through Flexo round-trips
- Does NOT issue HTTP/git/registry requests

### 6.2 Audit mode (online)

Per [[Design Spec]] §6.4 U2, U3, U4:

For each `rtm:hasContentHash` value:

1. Identify a fetch source: `dcat:downloadURL` if present; otherwise attempt content-addressed resolution (IPFS gateway for `ipfs:`/`cid:`; or skip if no source)
2. Fetch the content
3. Compute the hash with the declared algorithm
4. Compare to the recorded hash
5. PASS if match; FAIL with `T-fetch-mismatch` if mismatch

For each `rtm:hasGitRepo + rtm:hasGitCommit`:

1. `git ls-remote` the repo and check for the commit (lightweight; doesn't require full clone)
2. PASS if commit exists; FAIL with `T-git-commit-not-found` if not

For each `rtm:hasOCIImage`:

1. Resolve the registry via OCI Distribution Specification (`GET /v2/<image>/manifests/<digest>`)
2. PASS if digest resolves; FAIL with `T-oci-digest-not-found` if not
3. If `--profile=cosign-images` active, additionally verify the cosign bundle (per [[Signed Envelope Shapes]] §6)

### 6.3 Fetch errors that are NOT failures

| Condition | Treatment |
|---|---|
| Network timeout (no response) | `T-fetch-skipped-timeout` warning; structural validation still gates PASS/FAIL |
| 401/403 (auth required) | `T-fetch-skipped-auth` warning |
| Rate-limited (429) | `T-fetch-skipped-rate-limit` warning; retry with backoff |
| Registry / repo deleted | `T-fetch-not-found` FAILURE (the reference is broken; the cert is structurally unsound) |

The distinction: a verifier without fetch access can still confirm structural completeness (warnings are not failures). But a confirmed deletion of a referenced URI is a failure — it indicates the audit chain is broken.

## 7. Hash algorithm pinning

The recorded hash algorithm (sha256 vs. sha384 vs. sha3-256 vs. ipfs vs. cid) is encoded in the hash string itself (`<algo>:<digest>`). The oracle's compute step uses the algorithm declared.

If the cryptosuite changes between cert authoring and audit replay, the recorded hash algorithm is what's verified — not the current default. This makes audits stable across cryptosuite updates (per [[ADR-026 Cryptographic Agility via Algorithm Profiles]]).

## 8. Reproducibility manifest format

Every audit report MUST include a "Reproducibility Manifest" enumerating every external URI the cert depends on. Format:

```turtle
:manifest-2026-05-18-runABC a rtm:ReproducibilityManifest ;
    prov:wasGeneratedBy :audit-run-runABC ;
    rtm:totalGitRefs 12 ;
    rtm:totalContentHashes 47 ;
    rtm:totalOCIImages 5 ;
    rtm:gitRefs (
        [ rtm:hasGitRepo <https://github.com/dynamicalsystemsgroup/adcs-sim> ;
          rtm:hasGitCommit "abc123..." ;
          rtm:hasGitPath "scripts/slew_maneuver.py" ;
          rtm:referencedBy ( :simulation-run-001 ) ]
        # ... more entries
    ) ;
    rtm:contentHashes ( ... ) ;
    rtm:ociImages ( ... ) .
```

The manifest is also rendered in human-readable form (markdown) in the audit report. Re-running the audit produces a manifest with identical content for the same cert artifact (per X1 of [[Design Spec]] §6.6).

## 9. Auditor playbook

A third-party auditor with network access can verify a cert artifact end-to-end:

1. Fetch the cert artifact (transcript + attestation graph + audit report) from Flexo or wherever it's published
2. Read the Reproducibility Manifest
3. For each git ref in the manifest: `git ls-remote` to confirm commit existence
4. For each content hash: fetch via `dcat:downloadURL` or content-addressed gateway; compute hash; compare
5. For each OCI image: query the registry for the digest; if cosign profile active, verify cosign bundle
6. Re-execute the transcript (per X3, X7 of [[Design Spec]] §6.6) using fetched code/data/containers
7. Compare results to recorded hashes (bit-exact regime) or tolerances (tolerance-aware regime per X2)

Each step is locally verifiable. An auditor without network access can still verify structural completeness (X8).

## 10. What is NOT in v0.1 scope

- **Automatic mirroring** of referenced content into a `flexo-rtm`-controlled archive. Adopters who want long-lived archives operate their own mirroring infrastructure (e.g., Software Heritage for git refs, content-addressed storage for data).
- **Fetcher proliferation.** v0.1 ships fetch support for HTTPS (content-addressed and `dcat:downloadURL`) and OCI Distribution Specification. IPFS gateway support is optional via a configurable gateway URL.
- **Automatic URI rewriting** on mirror failure. If a `dcat:downloadURL` 404s, the audit reports a warning; v0.1 does NOT try alternative URLs automatically. Adopters set up retry logic at the network layer if needed.
