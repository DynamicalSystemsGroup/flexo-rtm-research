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

### 3.1 Graph operations

| Operation | Endpoint | Purpose |
|---|---|---|
| Read graph | `GET /orgs/{org}/repos/{repo}/branches/{branch}/graphs/{graph-iri}` | Fetch a named graph as RDF |
| Write graph | `PUT /orgs/{org}/repos/{repo}/branches/{branch}/graphs/{graph-iri}` | Replace a named graph (within a transaction) |
| Patch graph | `PATCH /orgs/{org}/repos/{repo}/branches/{branch}/graphs/{graph-iri}` | SPARQL UPDATE on a named graph (within a transaction) |
| List graphs | `GET /orgs/{org}/repos/{repo}/branches/{branch}/graphs` | Enumerate named graphs on a branch |
| Delete graph | `DELETE /orgs/{org}/repos/{repo}/branches/{branch}/graphs/{graph-iri}` | Remove a named graph (rare; carry-through preservation usually preferred) |

### 3.2 Transaction operations

| Operation | Endpoint | Purpose |
|---|---|---|
| Begin | `POST /orgs/{org}/repos/{repo}/branches/{branch}/transactions` | Open a new transaction; returns transaction ID |
| Commit | `POST /orgs/{org}/repos/{repo}/branches/{branch}/transactions/{tx-id}/commit` | Atomically commit all writes in this transaction |
| Abort | `POST /orgs/{org}/repos/{repo}/branches/{branch}/transactions/{tx-id}/abort` | Discard all writes |

### 3.3 Query

| Operation | Endpoint | Purpose |
|---|---|---|
| SPARQL Query | `POST /orgs/{org}/repos/{repo}/branches/{branch}/sparql` | SPARQL 1.1 SELECT / CONSTRUCT / ASK / DESCRIBE |

The SPARQL endpoint queries across all named graphs on the branch (federated default graph). The oracle's analysis layer issues all certification queries here.

### 3.4 Branch & commit metadata

| Operation | Endpoint | Purpose |
|---|---|---|
| Create branch | `POST /orgs/{org}/repos/{repo}/branches` | Create a branch (e.g., `engineering/safety-team`) |
| List branches | `GET /orgs/{org}/repos/{repo}/branches` | Enumerate branches |
| Read commit | `GET /orgs/{org}/repos/{repo}/commits/{commit-iri}` | Fetch commit metadata (parent, message, scope) |
| List commits | `GET /orgs/{org}/repos/{repo}/branches/{branch}/commits` | Branch history |
| Merge | `POST /orgs/{org}/repos/{repo}/merges` | Merge source branch into target with policy hints (§6) |

## 4. Named-graph IRI scheme

`flexo-rtm` uses a **stable, prefix-based IRI scheme** so adopters can identify graph kind from the IRI alone.

### 4.1 Per-partition graphs

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

A single `flexo-rtm commit` translates to **one Flexo transaction**:

```
1. POST /transactions → tx-id
2. PUT /graphs/<urn:rtm:model>            (in tx-id)
3. PUT /graphs/<urn:rtm:attestations>     (in tx-id)
4. PUT /graphs/<urn:rtm:transcripts>      (in tx-id)
5. POST /transactions/{tx-id}/commit
```

If any sub-write fails (HTTP non-2xx, SHACL violation server-side, conflict), the client:

1. Issues `POST /transactions/{tx-id}/abort`
2. Surfaces the error to the operational layer
3. The local working set is unchanged

**Partial commits are forbidden.** No state persists in Flexo until the final commit succeeds.

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
| `main` | Published baselines; protected; merges only via reviewed PR | Mutable via reviewed merge |
| `engineering/{team}` | Concurrent engineering streams per team or person | Mutable; teams operate independently |
| `cert/{run-id}` | Immutable certification artifacts for a specific cert run | Read-only after first push |

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
    
    def create_branch(self, name: str, from_branch: str = "main"): ...
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
