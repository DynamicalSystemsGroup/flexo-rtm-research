<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Flexo REST Binding

> **Normative contract** for `flexo-rtm`'s use of Flexo MMS. The Layer 1 REST API endpoints consumed, named-graph IRI scheme, transaction semantics, branch conventions, and merge policy details live here. The `flexo-rtm` [[Design Spec]] §5.4 and §6.1 reference this page; tests under `tests/integration/flexo/` enforce it. See also [[Storage Layer Flexo Conventions]] (rationale), [[Flexo Git Coexistence]] (background research).

## 1. Scope

`flexo-rtm` stores authoritative graph state in **Flexo MMS** (OpenMBEE Flexo, Layer 1 REST API). The contract is the union of:

- Flexo's REST surface (the endpoints the oracle consumes)
- `flexo-rtm`'s named-graph IRI scheme
- Transaction semantics (atomic batches per commit)
- Branch conventions
- Merge policy (per `flexo-conflict-resolution-policy-research`)

This contract is independent of Flexo's UI, GraphQL, or admin surfaces — `flexo-rtm` does not consume them.

## 2. Flexo version pin

v0.1 pins to:

- **Flexo MMS Layer 1 API** v1 (semver-stable; backward-compatible across patch versions)
- **Flexo SPARQL endpoint** consuming SPARQL 1.1 Query and SPARQL 1.1 Update

Future Flexo major versions (Layer 1 API v2+) require a new binding contract.

## 3. Endpoints consumed

`flexo-rtm`'s storage adapter (`oracle/src/oracle/storage/flexo_client.py`) calls these endpoints. All are HTTPS with bearer-token auth (`FLEXO_TOKEN` env var or configured equivalent).

### 3.1 Resource provisioning + write

| Operation | Endpoint | Purpose |
|---|---|---|
| Ensure org | `PUT /orgs/{org}` | Idempotent; `text/turtle` body sets `dcterms:title`; `409 Conflict` is treated as success |
| Ensure repo | `PUT /orgs/{org}/repos/{repo}` | Same idempotency; creates the default branch (`master`) implicitly |
| Ensure branch | `PUT /orgs/{org}/repos/{repo}/branches/{branch}` | Body includes `mms:ref <./master>` for non-default branches |
| SPARQL UPDATE | `POST /orgs/{org}/repos/{repo}/branches/{branch}/update` | The atomic-write endpoint; body is `application/sparql-update` (typically `INSERT DATA { … }`). A single POST is one atomic commit (see §5.1). |

### 3.2 Query

| Operation | Endpoint | Purpose |
|---|---|---|
| SPARQL Query | `POST /orgs/{org}/repos/{repo}/branches/{branch}/query` | `application/sparql-query` body; `Accept: text/turtle` or `application/sparql-results+json` |

The SPARQL endpoint queries the branch's single named graph (Flexo's branch-is-graph semantics; see §4). The oracle's analysis layer issues all certification queries here.

> **Spec-vs-reality note:** Earlier drafts of this contract listed a separate transaction surface (`POST /transactions`, `/commit`, `/abort`). Live testing against `try-layer1.starforge.app` confirmed those endpoints do not exist in the real OpenMBEE Flexo MMS Layer-1 API. The atomic-batch semantics are achieved by buffering staged writes client-side and emitting a single `POST .../update` with combined `INSERT DATA` at commit time. Tracked at [research-repo #20](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/20).

### 3.3 Branch & commit metadata

| Operation | Endpoint | Purpose |
|---|---|---|
| Create branch | `POST /orgs/{org}/repos/{repo}/branches` | Create a branch (e.g., `engineering/safety-team`) |
| List branches | `GET /orgs/{org}/repos/{repo}/branches` | Enumerate branches |
| Read commit | `GET /orgs/{org}/repos/{repo}/commits/{commit-iri}` | Fetch commit metadata (parent, message, scope) |
| List commits | `GET /orgs/{org}/repos/{repo}/branches/{branch}/commits` | Branch history |
| Merge | `POST /orgs/{org}/repos/{repo}/merges` | Merge source branch into target with policy hints (§6) |

## 4. Named-graph IRI scheme

> **Spec-vs-reality note:** Live-testing against `try-layer1.starforge.app` (2026-05-18) revealed that Flexo MMS Layer-1 treats **a branch as a named graph** — one branch holds exactly one named graph. `INSERT DATA { GRAPH <iri> { … } }` raises `QuadsNotAllowedException`. Adopters who want multiple partition graphs map each partition to its own branch (the ADCS-lifecycle-demo pattern). Tracked at [research-repo #22](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/22).

`flexo-rtm` uses a **stable, prefix-based IRI scheme** so adopters can identify graph kind from the IRI alone. In a multi-partition deployment, each partition IRI below maps to a Flexo branch with the same name.

### 4.1 Per-partition graphs (one per Flexo branch)

| IRI pattern | Contents |
|---|---|
| `urn:rtm:model` | SysMLv2 model triples (the `omg-sysml:` graph) |
| `urn:rtm:requirements` | `rtm:Requirement` instances |
| `urn:rtm:guidance` | `rtm:AdequacyCriteria`, `rtm:SufficiencyCriteria` instances |
| `urn:rtm:attestations` | `rtm:Attestation` (all subclasses) |
| `urn:rtm:transcripts` | `rtm:Transcript`, `rtm:TranscriptStep` instances |
| `urn:rtm:audit` | `rtm:AuditReport`, gap records |
| `urn:rtm:identity-projection` | `foaf:Person`, `org:Organization`, `org:Membership`, `rtm:Policy`, `rtm:Attribute` (the projection per [[Identity Adapter Contract]]) |
| `urn:rtm:scopes` | `rtm:Scope` definitions |
| `urn:rtm:lifecycle` | optional `rtm:lifecycleStage` annotations (per ADR-029) |

Single-branch deployments (the default for v0.1 smoke tests) put all triples on `master` (see §6); the partition IRIs are still informative annotations a client can use to taxonomize the corpus, but Flexo doesn't enforce per-IRI separation.

### 4.2 Per-resource source graphs (Layer C carry-through)

| IRI pattern | Contents |
|---|---|
| `urn:rtm:source/oslc-rm/{resource-id}` | Verbatim imported OSLC-RM resource (Layer C of [[OSLC Roundtrip Acceptance]]) |
| `urn:rtm:source/oslc-qm/{resource-id}` | Verbatim imported OSLC-QM resource |
| `urn:rtm:source/sysmlv2/{path-hash}` | Verbatim ingested SysMLv2 model fragment (see [[SysMLv2 Ingestion Contract]]) |

### 4.3 Run-scoped graphs

Each `certify` run produces:

| IRI pattern | Contents |
|---|---|
| `urn:rtm:transcript/{run-id}` | The full transcript for the run (one `prov:Activity` per step) |
| `urn:rtm:attestation-graph/{run-id}` | Attestations produced or referenced by the cert run |
| `urn:rtm:audit/{run-id}` | The audit report with coverage + gaps + reproducibility manifest |

The `run-id` is a UUIDv7 (time-ordered) for chronological listing.

### 4.4 Scope-bound graphs

When a Scope (per `rtm:Scope`) constrains which graphs are in-scope for cert, the scope's `rtm:includesGraph` predicate references the IRIs above (or any subset/extension).

## 5. Transaction semantics

### 5.1 Atomic batch (F1 of §6.1)

A single `flexo-rtm commit` translates to **one SPARQL UPDATE POST**:

```
1. (idempotent) PUT /orgs/{org}                              (ensure org)
2. (idempotent) PUT /orgs/{org}/repos/{repo}                 (ensure repo + auto-creates master)
3. (idempotent, non-master) PUT /orgs/{org}/repos/{repo}/branches/{branch}
4. POST /orgs/{org}/repos/{repo}/branches/{branch}/update
       Content-Type: application/sparql-update
       Body: INSERT DATA { <s1> <p1> <o1> . <s2> <p2> <o2> . … }
```

Steps 1–3 are idempotent provisioning (`200`/`201`/`409` all treated as success). **Step 4 is the atomic commit:** the entire `INSERT DATA` body is one Flexo Layer-1 transaction. There is no client-side `begin/commit/abort` cycle and no transaction endpoints (see §3.1 spec-vs-reality note); the client buffers staged writes locally between `begin_transaction()` and `commit_transaction()` calls and flushes the union as one `INSERT DATA` body at commit time.

If step 4 fails (HTTP non-2xx, SHACL violation server-side, conflict), the client surfaces the error to the operational layer and the Flexo branch is unchanged — partial commits are impossible because the failed `INSERT DATA` is rejected as a whole.

**Abort semantics** at the client are simply "discard the pending buffer"; no server call is needed.

### 5.2 Activity provenance (F2)

Every triple committed in a single transaction shares a single `prov:Activity` IRI:

```turtle
urn:rtm:commit/{run-id}-{seq} a prov:Activity ;
    prov:startedAtTime "2026-05-18T14:30:00Z"^^xsd:dateTime ;
    prov:wasAssociatedWith :engineer-zargham ;
    rtm:writesScope rtm:scope/adcs-attitude-control ;
    rtm:onBranch "engineering/adcs-team" ;
    rtm:parentCommit urn:rtm:commit/{prior-run-id} .
```

All triples committed in this batch reference this activity IRI via `prov:wasGeneratedBy`. The test `tests/integration/flexo/test_commit_provenance.py` enforces no orphan triples.

### 5.3 Scope metadata in commit (F4)

The commit's `prov:Activity` records `rtm:writesScope` pointing to the active `rtm:Scope` IRI. Round-trip: any subsequent read of the commit recovers the scope under which it was authored.

This is what enables cross-scope audit composition (per [[Federated Audit and Composition]]).

## 6. Branch model (F6)

| Branch pattern | Purpose | Mutability |
|---|---|---|
| `master` (Flexo default) **or** `main` | Published baselines; protected; merges only via reviewed PR | Mutable via reviewed merge |
| `engineering/{team}` | Concurrent engineering streams per team or person | Mutable; teams operate independently |
| `cert/{run-id}` | Immutable certification artifacts for a specific cert run | Read-only after first push |

> **Spec-vs-reality note:** OpenMBEE Flexo MMS Layer-1 auto-creates the branch named `master` (not `main`) on repo PUT. `flexo-rtm`'s `is_valid_branch_name` accepts both names as published-baseline equivalents; adopters who prefer `main` create it explicitly (with `mms:ref <./master>`) and treat `master` as a deprecated alias. Tracked at [research-repo #21](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/21).

Branch creation requires the configured Flexo authorization; `flexo-rtm` does not bypass Flexo's own ACL.

## 7. Merge policy (F5)

Merges follow **constraint-aware synthesis** per `flexo-conflict-resolution-policy-research`. The flexo-rtm storage adapter passes merge policy hints to Flexo's merge endpoint:

```json
POST /orgs/{org}/repos/{repo}/merges
{
  "source": "engineering/adcs-team",
  "target": "main",
  "policy": {
    "verification_scope": "auto-resolve-via-shacl",
    "validation_scope": "escalate-to-named-approver"
  }
}
```

**Verification-scope conflicts** (different SHACL outcomes on the same data; structural conflicts) are auto-resolved via SHACL ASK queries — the merged graph must pass the union of both branches' SHACL profiles, or the merge fails.

**Validation-scope conflicts** (different attestations on the same claim; different approvers reaching different conclusions) are escalated:

1. Merge does not auto-resolve
2. Flexo returns a conflict report listing the disputed attestations
3. The escalation requires a named approver to author a new attestation that resolves the conflict (typically a `rtm:status/deprecated` on the rejected attestation + `prov:wasInvalidatedBy` pointing to the resolving attestation, per [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]])
4. The merge re-runs with the resolution committed

## 8. Live-skippable testing (F7)

All live Flexo integration tests are marked with `@pytest.mark.live`:

```python
@pytest.mark.live
def test_atomic_commit_against_live_flexo():
    if os.environ.get("FLEXO_TOKEN") is None:
        pytest.skip("FLEXO_TOKEN not set; live Flexo test skipped")
    # ... test body
```

The conftest at `tests/conftest.py` configures `pytest.mark.live` to auto-skip when `FLEXO_TOKEN` env var is absent. The non-live conformance suite covers the full contract via mock Flexo behavior and replays of recorded Flexo responses.

CI runs:

- **PR builds**: non-live tests only (no `FLEXO_TOKEN` in PR contexts)
- **Main builds (with `FLEXO_TOKEN` secret)**: full suite including live integration

## 9. Client implementation outline

`oracle/src/oracle/storage/flexo_client.py`:

```python
from dataclasses import dataclass
from rdflib import Graph

@dataclass
class FlexoConfig:
    base_url: str        # e.g., "https://flexo.example.org/api/v1"
    org: str
    repo: str
    token: str           # bearer token; read from FLEXO_TOKEN env

class FlexoClient:
    def __init__(self, config: FlexoConfig): ...
    
    def begin_transaction(self, branch: str) -> str: ...                            # returns tx-id
    def write_graph(self, tx_id: str, branch: str, graph_iri: str, graph: Graph): ...
    def commit_transaction(self, tx_id: str, branch: str) -> str: ...               # returns commit IRI
    def abort_transaction(self, tx_id: str, branch: str): ...
    
    def read_graph(self, branch: str, graph_iri: str) -> Graph: ...
    def query_sparql(self, branch: str, query: str) -> "QueryResult": ...
    
    def create_branch(self, name: str, from_branch: str = "master"): ...
    def merge(self, source: str, target: str, policy: dict) -> "MergeResult": ...
```

The client surface is intentionally narrow — `flexo-rtm` does not expose Flexo internals; the rest of the oracle codebase consumes only this client.

## 10. Error handling and retries

| Error class | Handling |
|---|---|
| Network timeout / 5xx | Exponential backoff retry (max 3 attempts); after final failure, abort transaction and surface |
| 401 Unauthorized | No retry; surface (token expired or invalid) |
| 403 Forbidden | No retry; surface (scope/branch permission denied) |
| 409 Conflict (during transaction commit) | No retry; the conflict is the user's domain to resolve (merge policy per §7) |
| SHACL violation in transaction | No retry; surface the violation report |

All errors include the Flexo response body for diagnostic context. No error swallowing.

## 11. Out of v0.1 scope

- Flexo GraphQL surface (not consumed)
- Flexo admin endpoints (user management, repo creation — handled by adopter ops, not the oracle)
- Flexo locks / leases (v0.1 relies on optimistic concurrency via transaction commit; locks are v0.2+ if needed for high-contention workflows)
- Multi-repo federation within Flexo (v0.1 binds to a single repo per oracle instance; cross-repo composition is at the `rtm:Scope` level via [[Federated Audit and Composition]])
