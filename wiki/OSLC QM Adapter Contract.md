<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# OSLC QM Adapter Contract

> **Status:** Normative adapter contract for OSLC-QM 2.1 (OASIS Standard, 2022). Parallel to [[OSLC RM Adapter Contract]]; together they discharge the v0.1 mandate in [[Design Spec]] §9 ("Both OSLC-RM and OSLC-QM ship as full read+write adapters in v0.1") against the binary acceptance criteria in §9.A.2 (**O1**–**O7**). Critical reading of the standard lives in [[OSLC RM and QM Review]]; this page is the contract the v0.1 implementation must honor and the v0.2 live-HTTP connector must plug into without modification.

## Purpose

The QM adapter is the file-level translator between OSLC-QM 2.1 documents (RDF/XML on the wire, Turtle locally) and `flexo-rtm`'s internal `rtm:` graph. It ranges over the **test vocabulary** — plans, cases, scripts, execution records, results, verdicts — and does two things:

1. **Read.** Parse an OSLC-QM document into an internal `rtm:` graph plus a verbatim per-source named graph (`<oslc-qm:source/{id}>`) carrying every triple, core and vendor alike.
2. **Write.** Emit an OSLC-QM document from the `rtm:` graph plus the source named graph such that a downstream OSLC-QM 2.1 consumer reads back exactly what was originally provided (RDFC-1.0 canonical-form byte-equality, per §9.A.2 **O1**).

Live HTTP connectors against Jazz QM, Jama, IBM ETM, or Polarion instances are v0.2 work. The v0.1 contract is **file-level and stateless**.

## Mapping table — OSLC-QM construct to `rtm:` construct

The enumerated core class set for QM is normative; new entries require a spec edit (§9.A.2 **O3**). Predicates and classes outside this table are routed through Layer C carry-through (§9.A.2 **O2**), not silently mapped.

| OSLC-QM construct | `rtm:` construct | Notes |
|---|---|---|
| `oslc_qm:TestPlan` | `rtm:TestPlan` | First-class class; plans are not artifacts because their identity persists independently of any executable. |
| `oslc_qm:TestCase` | `rtm:Artifact` typed `rtm:TestArtifact` | Test cases are evidence-bearing artifacts in the [[Vertices Edges Faces]] sense — they participate in `rtm:satisfies` triples once results report PASS against a requirement. `rtm:TestArtifact` is an `rdfs:subClassOf rtm:Artifact` marker. |
| `oslc_qm:TestScript` | `rtm:Artifact` typed `rtm:TestArtifact` (executable variant) | Scripts are the executable form of a case; same `rtm:Artifact` parent so coverage queries do not special-case them. The "executable" flag is `rtm:executable true`, not a new class — keeps the parsimony budget (§9.A.5 **X5**) intact. |
| `oslc_qm:TestExecutionRecord` | `rtm:ExecutionRecord` | First-class class; carries the run's environment, timing, and the script link. Aligns upward to `prov:Activity` so PROV-O queries find executions natively. |
| `oslc_qm:TestResult` | `rtm:Artifact` (the result data) **+** `rtm:Attestation` (the verdict claim) | Splits into two pieces: the **observed payload** is an artifact; the **verdict** is an attestation candidate. This split is what lets passed verdicts drive `rtm:SatisfactionAttestation` candidacy (see § "QM-RM bridge") without conflating data and claim. |

### Link-type predicates

| OSLC-QM predicate | `rtm:` predicate | Direction |
|---|---|---|
| `oslc_qm:usesTestCase` | `rtm:includesArtifact` | Plan → case |
| `oslc_qm:usesTestScript` | `rtm:hasScript` | Case → script |
| `oslc_qm:executesTestScript` | `prov:used` | Execution → script (aligned to PROV-O) |
| `oslc_qm:runsTestCase` | `rtm:runs` | Execution → case |
| `oslc_qm:reportsOnTestCase` | `prov:wasGeneratedBy` (inverse) | Result → case |
| `oslc_qm:reportsOnTestPlan` | `rtm:reportsOnPlan` | Result → plan |
| `oslc_qm:producedByTestExecutionRecord` | `prov:wasGeneratedBy` | Result → execution (PROV-O) |
| `oslc_qm:runsOnTestEnvironment` | `rtm:hasEnvironment` | Execution → environment literal/IRI |
| `oslc_qm:validatesRequirement` | `rtm:satisfies` **candidate** | Case → requirement; the **QM↔RM bridge** — promoted on passed results (see below) |
| `oslc_qm:validatesRequirementCollection` | `rtm:satisfies` candidate | Plan → requirement collection |
| `oslc_qm:status` | `earl:result` on the verdict-attestation | Per the verdict vocabulary below |

### Verdict vocabulary

OSLC-QM 2.1 does not enumerate verdict values; deployments converge on a small set (see [[OSLC RM and QM Review]] §3). The adapter maps the converged set to W3C EARL:

| OSLC-QM verdict | `earl:` verdict | Semantics |
|---|---|---|
| `oslc_qm:Passed` | `earl:passed` | Verification succeeded |
| `oslc_qm:Failed` | `earl:failed` | Verification produced a negative result |
| `oslc_qm:Inconclusive` | `earl:cantTell` | Insufficient evidence; **not** a failure |
| Other recognized OSLC literals (e.g. `Blocked`, `Error`) | verbatim literal on `earl:result` | Preserved opaquely rather than coerced |
| Unrecognized vendor literals | Layer C carry-through | Not promoted to `earl:result` |

The `cantTell` mapping is load-bearing: it lets the certification predicate distinguish "tested and failed" from "tested and could not tell" — a distinction safety auditors rely on.

## Lossless guarantees (Layer A + Layer C)

Same two-layer contract as the RM adapter, restated for the QM construct set:

**Layer A — core equivalence (§9.A.2 O1).** For every OSLC-QM construct in the enumerated core class set:

```
RDFC-1.0(parse(emit(parse(input)))) == RDFC-1.0(input)
```

RDFC-1.0 canonicalization neutralizes bnode relabeling and serialization ordering; byte-equality of canonical forms is stronger than "semantically equivalent."

**Layer C — opaque carry-through (§9.A.2 O2).** Predicates outside the core set (Jama-QM, RQM, Polarion-QM, Jenkins-QM, etc.) are stored verbatim in `<oslc-qm:source/{id}>` and re-emitted verbatim. Structural-only checks apply: triple count per resource preserved across roundtrip. The certification predicate does **not** certify content inside carry-through subgraphs; see [[Vendor Extension Carry-Through]] and [[Lossless Roundtrip Definition]].

## SHACL profile — `oslc-qm-roundtrip`

Loaded via `--profile=oslc-qm-roundtrip` (§9.A.2 **O6**). Composable with the RM profile per [[Profile Mechanism]]; a pre-publication composite typically requests both: `--profile=oslc-rm-roundtrip,oslc-qm-roundtrip,sysmlv2-anchored,attested-satisfies`.

Shapes enumerated by the QM profile:

- **Required fields per OSLC-QM 2.1.** Every `TestCase` carries `dcterms:identifier`, `dcterms:title`; every `TestPlan` carries `dcterms:identifier`; every `TestExecutionRecord` carries `oslc_qm:executesTestScript` or `oslc_qm:runsTestCase`; every `TestResult` carries `oslc_qm:status` and `oslc_qm:reportsOnTestCase`.
- **Result-execution coupling.** Every `TestResult` MUST reference its `TestExecutionRecord` (`oslc_qm:producedByTestExecutionRecord` `sh:minCount 1`).
- **Plan-case-script chain integrity.** `oslc_qm:usesTestCase` targets MUST be `TestCase` instances; `oslc_qm:usesTestScript` targets MUST be `TestScript`.
- **Verdict literal allow-list.** `oslc_qm:status` values promoted to `earl:result` MUST be in the EARL enumeration; unrecognized values are deflected to Layer C carry-through rather than rejected.
- **Vendor extensions allowed in carry-through only.** Non-core predicates MUST appear in `<oslc-qm:source/{id}>`, never silently mapped into core.

The profile is declarative; the adapter implementation can evolve while the profile remains stable.

## Test fixtures

Per §9.A.2 **O4** and **O5**, regression corpus under `examples/oslc-fixtures/`:

- **Canonical OSLC-QM example** — `examples/oslc-fixtures/canonical/qm/` carries the worked examples from the OASIS OSLC-QM 2.1 normative HTML and from `oasis-tcs/oslc-domains`. Every fixture roundtrips losslessly under Layer A.
- **Doors-Next QM export** (if available) — `examples/oslc-fixtures/vendor/doors-next-qm/`, contributed under CLA; Layer A on core + Layer C on `doors:` predicates.
- **Jama QM export** (if available) — `examples/oslc-fixtures/vendor/jama-qm/`, same pattern with `jama:` extensions.
- **EARL-bearing fixture** — `examples/oslc-fixtures/canonical/qm/with-earl/` carries a result that uses `earl:result` upstream; verifies adapter idempotence.

Vendor namespaces register in `examples/oslc-fixtures/vendor-registry.yaml` (§9.A.2 **O7**); see [[Vendor Extension Carry-Through]].

## API surface

Mirrors [[OSLC RM Adapter Contract]] in `flexo_rtm.adapters.oslc.qm`:

```python
from flexo_rtm.adapters.oslc import qm

rtm_graph, source_graph = qm.read(qm_document_bytes, source_iri="...")
qm_document_bytes = qm.write(rtm_graph, source_graph, format="application/rdf+xml")
```

Signatures are symmetric to `flexo_rtm.adapters.oslc.rm`; v0.2 HTTP connectors wrap the same `read`/`write` with transport code. The adapter contract is independent of transport.

## The QM-RM bridge

OSLC-QM test results are how OSLC-RM requirements get verified in practice, and `flexo-rtm` preserves that link rather than letting it dissolve at the adapter boundary. The bridge has two parts.

**1. `oslc_qm:validatesRequirement` becomes a candidate `rtm:satisfies` triple.**

When the adapter imports a TestCase that carries `oslc_qm:validatesRequirement` (or a TestPlan with `oslc_qm:validatesRequirementCollection`) and the target requirement is resolvable in the `rtm:` graph, the adapter emits a candidate `rtm:satisfies` triple with the TestCase (as `rtm:TestArtifact`) as subject and the Requirement as object. **Candidate** means the verification edge is recorded as claimed in the source — not yet attested.

**2. Passed test results are candidates for `rtm:SatisfactionAttestation` (requires a named approver).**

When an imported `oslc_qm:TestResult` maps to `earl:passed` and links via `oslc_qm:reportsOnTestCase` to a TestCase carrying `oslc_qm:validatesRequirement`, the adapter marks the corresponding `rtm:satisfies` triple as **attestation-eligible**: a named approver MAY emit an `rtm:SatisfactionAttestation` whose subject is that triple, citing the imported result as evidence.

The adapter never emits the attestation itself. Attestations require a **named human approver IRI** (`rtm:approvedBy <IRI>`, `sh:minCount 1`, `sh:nodeKind sh:IRI`) per [[Attestation Infrastructure in v0.1]] and [[Design Spec]] §9.A.3 **I1**. A separate workflow step — a test engineer or test lead asserting `rtm:SatisfactionAttestation` against the imported result — closes the loop. Under the `attested-satisfies` profile the certification predicate will not accept the verification edge without that approval. Failed and inconclusive (`earl:cantTell`) results produce candidate edges that are **not** attestation-eligible and may surface as `T1`-class verification gaps (see [[Gap Taxonomy]]).

## What is NOT in v0.1

Parallel to the RM adapter's exclusions and rooted in [[OSLC RM and QM Review]] §5:

- **Live HTTP connectors** to Jazz QM, Jama, Polarion, IBM ETM, or other test-management servers. v0.1 is file-level; v0.2 layers HTTP transport on the unchanged adapter.
- **Service catalog discovery.** No `oslc:ServiceProviderCatalog` traversal, no `oslc:CreationFactory`. Adopters declare QM sources in `flexo-rtm.yaml`.
- **Delegated UIs.** No `oslc:CreationDialog` or `oslc:SelectionDialog` iframes — embedded vendor dialogs are a reproducibility anti-pattern for a command-line-replayable oracle.

## Cross-references

- [[OSLC RM and QM Review]] — critical reading of OSLC-RM 2.1 / OSLC-QM 2.1; what we adopt and what we decline
- [[OSLC RM Adapter Contract]] — sibling adapter contract; identical layout for the requirements vocabulary
- [[Lossless Roundtrip Definition]] — formal A+C criterion, RDFC-1.0 dependence
- [[Vendor Extension Carry-Through]] — per-source named graph layout and `vendor-registry.yaml` schema
- [[Profile Mechanism]] — how `oslc-qm-roundtrip` composes with other v0.1 profiles
- [[Vertices Edges Faces]] — where `rtm:TestArtifact`, `rtm:satisfies`, `rtm:Attestation` sit in the assurance complex
- [[Attestation Infrastructure in v0.1]] — the named-approver shape that gates `rtm:SatisfactionAttestation`
- [[Design Spec]] §9 (adapter mandate), §9.A.2 (O1–O7 acceptance criteria), §4.3 (attestation shape)
