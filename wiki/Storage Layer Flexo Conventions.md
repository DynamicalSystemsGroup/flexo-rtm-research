<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Storage Layer Flexo Conventions

> Normative reference for the `flexo-rtm` storage layer. Elaborates [[Design Spec]] §5.2 and the F1–F7 acceptance criteria in §9.A.1. Companion to [[Flexo Git Coexistence]] (which covers the merge policy in depth) and [[Operational Layer UX Discipline]] (which covers the working-set materialisation that feeds commits into Flexo).

## Why Flexo

Flexo MMS is the open-source Model Management System maintained in the OpenMBEE ecosystem. The storage layer of `flexo-rtm` sits on Flexo for four reasons:

- **Native RDF.** Models, requirements, attestations, transcripts, guidance, and audit content all serialise to RDF triples. Flexo stores them as named graphs without an impedance layer.
- **Commit DAG + branches + locks.** Flexo's Layer 1 service maintains a commit DAG with branches and lock-protected refs over each named graph, mirroring the version-control semantics engineers already know from git but operating on the graph itself rather than on text.
- **Self-hostable.** The reference deployment in `flexo-mms-deployment` runs on Docker Compose (single-tenant) or Kubernetes (shared). No vendor lock-in; no cloud-only path.
- **Provenance-friendly.** Each commit carries metadata identifying its `prov:Activity`, which is how F2 is enforced at the storage layer rather than reinvented at the application layer.

The ADCS prototype (`ADCS-lifecycle-demo/pipeline/backends/flexo.py`) already exercises this integration against both `try-layer1.starforge.app` and a local Compose-up stack, proving the pattern at small scale before `flexo-rtm` formalises it.

## Named-graph conventions (F3)

The storage layer partitions content into **logical-partition graphs**, **source-preserved import graphs**, and **derived materialisation graphs**. The first two are durable; the third is ephemeral.

### Logical partitions (durable)

Every `flexo-rtm` repository hosts at minimum the following named graphs, each holding triples of a specific concern:

| Graph IRI pattern | Content |
|---|---|
| `<model>` | SysMLv2-aligned structural and behavioural triples for the system under traceability. |
| `<requirements>` | Requirement vertices, their satisfies/derives/refines edges, and per-requirement metadata. |
| `<guidance>` | Reusable guidance content referenced by skill prompts and judgment surfaces — what [[Operational Layer UX Discipline]] dispatches into the working-set as the engineer edits. |
| `<attestations>` | Validation edges with approver IRIs, evidence references, and the temporal envelope of each attestation. |
| `<transcripts>` | Persisted transcript fragments from skill invocations that produced the attestations; their hashes are referenced from `<attestations>`. |
| `<audit>` | Append-only audit records — every commit, every scope, every approver, every escalation. |

The partitioning is fixed. New domain content is added by composing scopes (see [[Analysis Layer Scope Algebra]]) rather than by inventing new top-level partitions per project. F3 in §9.A.1 is the normative test that this layout is preserved.

### Per-resource source graphs (durable)

Imported content from upstream MBSE/PLM tools is preserved verbatim in per-resource graphs, never edited in place. The IRI scheme:

- `<oslc-rm:source/{id}>` — one graph per OSLC-RM resource imported via the OSLC adapter. The id is the OSLC resource identifier.
- `<sysmlv2:source/{path}>` — one graph per SysMLv2 element imported via the SysMLv2 KerML adapter. The path is the SysMLv2 qualified name.

Internal augmentations — attestations, scope memberships, derived edges — are written to the logical-partition graphs and **reference** the source graphs by IRI. This separation is the foundation of [[Vendor Extension Carry-Through]]: a round-trip emits only the source graph for that resource, the augmentations stay behind, and the upstream tool sees lossless content. See [[External URI References]] for the IRI minting policy that keeps the augmentation-to-source references stable across imports.

### Derived materialisation graphs (ephemeral)

Aspect-coverage reports, audit summaries, and other analytical artifacts are materialised on demand into graphs of the form `<rtm:complex/{run-id}>`. They are written by `flexo-rtm` analysis jobs, read by reporting and visualisation tooling, and garbage-collected on a retention policy (default: 30 days after the run-id's parent commit is no longer a branch head). They MUST NOT be treated as a source of truth — replaying the SPARQL CONSTRUCT against the durable graphs regenerates them exactly.

## Branch conventions (F6)

Three branch-name patterns are normative:

- **`main`** — published baselines. A commit on `main` represents a state someone is willing to be accountable for. Fast-forward only; non-fast-forward merges go through a named approver.
- **`engineering/<team>`** — concurrent engineering streams. Teams cut from `main`, work in isolation, and merge back via constraint-aware synthesis (see [[Flexo Git Coexistence]]). The team segment is a human-readable identifier; no central registry — naming collisions are a social problem.
- **`cert/<run-id>`** — certification artifacts. Immutable post-publish: once a `cert/<run-id>` branch ref is signed and announced, no further commits are accepted on it. The run-id is bound to a certification run produced by [[Verifiable Self-Certification]].

F6 in §9.A.1 tests that these three patterns are honoured by branch-creation and merge tooling. Other branch names are not forbidden, but anything outside these patterns gets no special treatment from the merge policy.

## Commit conventions (F1, F2, F4)

Each `flexo-rtm commit` is exactly one Flexo transaction. There is no concept of a partial commit: either every triple in the package — model, evidence references, attestation, transcript fragment — lands, or none of it does. F1 in §9.A.1 is the normative test of this property.

Every triple in that transaction shares a single `prov:Activity` IRI (F2), so orphans across commits are impossible. Commit metadata additionally records the active `rtm:Scope` IRI under which the commit was authored, so a downstream reader can recover the lens through which the author was working (F4) — see [[Analysis Layer Scope Algebra]] for why scope membership at authoring time matters for downstream interpretation.

Commit metadata MAY also capture the active **lifecycle stage** of the scope (`rtm:lifecycleStage`) alongside the scope IRI — but only when the adopter is using a lifecycle vocabulary. The `rtm:lifecycleStage` property is optional (see [[Engineering Lifecycle Stages]] and the revised [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]]); the framework is methodology-neutral and ships no scope-level state machine. INCOSE / ISO 15288 stages are one example vocabulary; programs using DO-178C, NASA Phase A–F, ISO 9001, Agile, MIL-STD-498, or custom phasing capture their own SKOS concept IRIs in the same field; programs not using a lifecycle vocabulary leave the field absent. **Regression handling is at the attestation level**, not at the scope level: when upstream changes invalidate a downstream attestation, the affected attestation is marked `rtm:status/deprecated` with `prov:wasInvalidatedBy` recording the cause (per [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]). The cert artifact surfaces deprecated attestations as **T9** gaps; the commit-metadata lifecycle field plays no role in regression handling.

Commit messages follow Conventional Commits adapted for RTM:

```
<type>(<scope-id>): <summary>

<body — what changed and why>

<trailers — Co-Authored-By, Refs, etc.>
```

Where `<type>` is one of `feat`, `fix`, `refactor`, `docs`, `chore`, `attest`, `audit`; `<scope-id>` is the active `rtm:Scope` short id (which matches the IRI captured in commit metadata); and the body explains intent rather than diff. The `attest` and `audit` types are RTM-specific extensions to Conventional Commits, reserved for commits whose primary purpose is to land an attestation or close an audit checkpoint, respectively.

## Transaction structure

The accumulated changes packaged into the Flexo transaction at commit time fan across all relevant partitions in a single atomic unit:

- Model and requirement triples land in `<model>` and `<requirements>`.
- Evidence references land in `<attestations>` alongside the validation edge they witness.
- Transcript fragments — the chat history the skill produced at the judgment moment — land in `<transcripts>`, with their content hash embedded in the attestation triple in `<attestations>`.
- Audit records are appended to `<audit>` automatically by the commit handler.

The on-the-wire representation is a SPARQL UPDATE patch, gzip-compressed and stored as `mms-datatype:SPARQL` in Flexo's metadata graph. Branch heads materialise as snapshots; intermediate states are reconstructed by replaying patches from the nearest ancestor snapshot. This is procedural delta storage — see [[Flexo Git Coexistence]] §"Patch semantics" for why we accept the implications.

## Conflict resolution

The merge policy is **constraint-aware synthesis** (F5). The full treatment lives in [[Flexo Git Coexistence]]; for the storage layer, what matters is the dispatch rule:

- **Verification-scope conflicts** — concurrent edits to the same triples, schema violations of the merged set, RDFC-1.0 equality failures — are auto-resolved. The predicate compliance oracle dispatches each compliance predicate (SHACL ASK, SPARQL ASK, etc.) and the synthesis machinery proposes a resolution that minimises deviation from the intended composition subject to all active constraints. Shadow prices attribute each remaining deviation to a binding constraint.
- **Validation-scope conflicts** — semantic disagreements that turn on engineering intent — escalate to the named approver of the attestation whose state is at stake. The unit of escalation is the validation edge's `approver` IRI, consistent with the [[Verifiable Self-Certification]] thesis that every claim resolves to a named, accountable human.

CI runs the predicate compliance oracle against every proposed merge. F5 is the normative test that this dispatch rule is honoured.

## Source-preserving imports

Adapters never overwrite imported content. The contract is:

1. The OSLC-RM adapter loads each OSLC resource into its own `<oslc-rm:source/{id}>` graph, verbatim.
2. The SysMLv2 adapter loads each KerML element into its own `<sysmlv2:source/{path}>` graph, verbatim.
3. `flexo-rtm` augmentations — attestations, scope memberships, derived edges, judgment markers — live in the logical-partition graphs and reference the source IRIs.
4. Round-trip emits only the source graph for the target resource. By construction this is lossless: the augmentation triples are simply not part of the emit set. See [[Vendor Extension Carry-Through]] for the parallel pattern that handles vendor-specific extension properties.

Re-importing the same resource overwrites its source graph atomically, and a SHACL re-check fires across all augmentations that reference it. Any augmentation whose referent has moved triggers a deferred judgment — see [[Operational Layer UX Discipline]] for how the working-set surfaces this back to the engineer.

## Backups and disaster recovery

Flexo's commit DAG is the authoritative log. Backup strategy:

- The Flexo deployment's persistent volumes are snapshotted on whatever cadence the host operations team runs (daily is typical; see `flexo-mms-deployment` for guidance).
- Disaster recovery replays from any ancestor commit: snapshots at branch heads plus the SPARQL UPDATE patch chain are sufficient to regenerate any state Flexo has ever held.
- The ADCS prototype demonstrates the replay path end-to-end at small scale — `pipeline/backends/flexo.py` re-pushes a Dataset to a fresh repo by treating each named graph as an idempotent INSERT DATA.

There is no separate `flexo-rtm` backup: the storage layer's authoritative state is in Flexo, and Flexo's backup story is the storage layer's backup story.

## Deployment topology

Two reference deployments:

- **Single-tenant.** Default for org-internal use. Docker Compose stack from `flexo-mms-deployment/local/` — Layer 1 service, auth service, persistent volume, optional ingress.
- **Multi-tenant.** Kubernetes manifests in `flexo-mms-deployment/k8s/` — multiple orgs/repos behind a single Layer 1 instance, with auth-service gating per-org access. Suits federated installations where teams share infrastructure but not state.

Authentication is uniform: bearer token issued by the auth service, set in the environment as `FLEXO_TOKEN`, consumed by `flexo-rtm` and the live-Flexo test suite.

## Live-skippable tests (F7)

Every integration test that touches a live Flexo instance is marked `@pytest.mark.live` and auto-skips when `FLEXO_TOKEN` is absent. `tests/conftest.py` wires the skip. F7 in §9.A.1 is the normative test that the suite remains runnable end-to-end without a live Flexo — contributors can run all unit tests and all non-live integration tests in CI or on a laptop without provisioning Flexo. This is the discipline that lets `flexo-rtm` development scale beyond contributors who happen to have a Flexo running.

## Cross-references

- [[Design Spec]] §5.2 (normative storage-layer interface) and §9.A.1 (F1–F7 acceptance criteria).
- [[Flexo Git Coexistence]] — the conflict-resolution policy in depth.
- [[Operational Layer UX Discipline]] — the working-set materialisation that feeds commits into the storage layer.
- [[Analysis Layer Scope Algebra]] — how `rtm:Scope` IRIs in commit metadata (F4) are interpreted by readers.
- [[Vendor Extension Carry-Through]] — the source-preserving-import pattern as applied to vendor extension properties.
- [[External URI References]] — IRI minting policy for stable cross-references between augmentation and source graphs.
- [[Engineering Lifecycle Stages]] — optional `rtm:lifecycleStage` capture in commit metadata; methodology-neutral, only useful when the adopter is using a lifecycle vocabulary.
- [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] — methodology-neutral regression handling at the attestation level.
