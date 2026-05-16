<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# OSLC RM and QM Review

> **Status:** Critical reading of OSLC-RM 2.1 and OSLC-QM 2.1 against `flexo-rtm` v0.1's adapter contract. Identifies what we adopt as alignment + roundtrip surface and what we deliberately decline. See [[Design Spec]] §9 for the adapter mandate and §9.A.2 (O1–O7) for binary acceptance criteria.

---

## 1. What OSLC is

**Open Services for Lifecycle Collaboration (OSLC)** is an OASIS Open Project family of specifications for resource-oriented integration across ALM/PLM tools. Its primitives are RDF resources accessed over HTTP using W3C Linked Data Platform patterns. OSLC is two stacked things:

1. **A data model** — cross-domain RDF vocabularies (Core, RM, QM, CM, AM, Config) describing requirements, tests, change requests, architectural elements, and the links between them.
2. **A deployment model** — service-provider catalogs, delegated UIs (HTML iframes with `postMessage`), creation factories, and runtime discovery for embedding tool capabilities.

The two have different shelf lives. The data model is the durable contribution; the deployment model encodes assumptions about an era of proprietary servers and browser embeddings that age poorly in an open-source, self-hostable world. `flexo-rtm`'s position: **adopt the data model in full; decline the deployment model.**

OSLC 3.0 Core is the current foundation; OSLC-RM 2.1 (OASIS Standard, 2021) and OSLC-QM 2.1 (OASIS Standard, 2022) are the domain specs relevant to bidirectional requirements traceability. Both publish a normative Turtle vocabulary file alongside the HTML, making data-model adoption tractable.

---

## 2. OSLC-RM 2.1 core vocabulary

**Namespace:** `http://open-services.net/ns/rm#` (prefix `oslc_rm`)

### Classes

| Class | Definition |
|---|---|
| `oslc_rm:Requirement` | A statement of need. The unit of requirements management. |
| `oslc_rm:RequirementCollection` | An ordered/unordered collection of requirements; uses zero or more `Requirement` resources. Used for documents, modules, baselines. |

### Link-type properties

OSLC-RM 2.1 ships a directed link vocabulary; inverse predicates are paired where appropriate.

| Predicate | Direction | Meaning |
|---|---|---|
| `oslc_rm:elaboratedBy` / `:elaborates` | Requirement ↔ elaborating artifact | Object elaborates the subject (e.g., model element elaborating a requirement) |
| `oslc_rm:specifiedBy` / `:specifies` | Requirement ↔ specifying artifact | Object further clarifies or specifies the subject |
| `oslc_rm:decomposedBy` / `:decomposes` | Requirement ↔ sub-requirements | Object decomposes the subject into finer requirements |
| `oslc_rm:constrainedBy` / `:constrains` | Requirement ↔ constraining requirement | Object constrains the subject (e.g., safety req constrains functional req) |
| `oslc_rm:satisfiedBy` / `:satisfies` | Requirement ↔ satisfying requirement/artifact | Subject is satisfied by object (e.g., user req satisfied by system req) |
| `oslc_rm:implementedBy` | Requirement → implementing artifact | Object is a necessary or desirable aspect of implementation |
| `oslc_rm:validatedBy` | Requirement → validating artifact | Object validates the subject (e.g., test plan validating requirement) |
| `oslc_rm:trackedBy` | Requirement → tracking artifact | Object tracks or governs evolution of subject (e.g., change request) |
| `oslc_rm:affectedBy` | Requirement → affecting artifact | Object affects the subject (e.g., defect affecting requirement) |
| `oslc_rm:uses` | Resource → used resource | Object is used by the subject |

Servers MAY introduce subclasses and additional properties; OSLC-RM is explicitly extensible. This is the seam through which vendor predicates (Doors-X, Jama-X, Polarion-X) enter real-world exports — and the seam our **Layer C carry-through** strategy targets (§4 below).

---

## 3. OSLC-QM 2.1 core vocabulary

**Namespace:** `http://open-services.net/ns/qm#` (prefix `oslc_qm`)

### Classes

| Class | Definition |
|---|---|
| `oslc_qm:TestPlan` | A plan describing testing intent and scope. |
| `oslc_qm:TestCase` | A specific testable scenario; the unit of test design. |
| `oslc_qm:TestScript` | An executable or human-followable procedure used by a Test Case. |
| `oslc_qm:TestExecutionRecord` | A scheduled or actual execution of a Test Case against a configuration. |
| `oslc_qm:TestResult` | The outcome of an execution; carries verdict and links back to Case/Plan. |

### Link-type properties

| Predicate | Direction | Meaning |
|---|---|---|
| `oslc_qm:usesTestCase` | TestPlan → TestCase | Test Case included by a Test Plan |
| `oslc_qm:usesTestScript` | TestCase → TestScript | Test Script used by a Test Case |
| `oslc_qm:executesTestScript` | TestExecutionRecord → TestScript | Script executed by the run |
| `oslc_qm:runsTestCase` | TestExecutionRecord → TestCase | Test Case run by the execution record |
| `oslc_qm:reportsOnTestCase` | TestResult → TestCase | Test Case the result reports on |
| `oslc_qm:reportsOnTestPlan` | TestResult → TestPlan | Test Plan the result reports on |
| `oslc_qm:producedByTestExecutionRecord` | TestResult → TestExecutionRecord | Execution that produced the result |
| `oslc_qm:runsOnTestEnvironment` | TestExecutionRecord → environment | Environment details for the execution |
| `oslc_qm:validatesRequirement` | TestCase → Requirement | Requirement validated by Test Case — the **RM↔QM bridge** |
| `oslc_qm:validatesRequirementCollection` | TestPlan → RequirementCollection | Collection validated by Test Plan |
| `oslc_qm:blockedByChangeRequest` | TestExecutionRecord → ChangeRequest | Change preventing execution |
| `oslc_qm:affectedByChangeRequest` | TestResult → ChangeRequest | Change affecting results |
| `oslc_qm:relatedChangeRequest` | TestCase/Result → ChangeRequest | Associated change |
| `oslc_qm:testsChangeRequest` | TestCase → ChangeRequest | Change tested by Test Case |
| `oslc_qm:status` | TestResult → literal/IRI | Verdict; values defined by the service provider |

### Verdict vocabulary

`oslc_qm:status` intentionally **does not enumerate** verdict values — they are defined by the service provider. Deployments converge on a small set (`passed`, `failed`, `inconclusive`, `blocked`, `error`); W3C EARL's `earl:TestResult` enumeration (`earl:passed`, `earl:failed`, `earl:cantTell`, `earl:inapplicable`, `earl:untested`) is a widely understood superset. `flexo-rtm`'s alignment maps `oslc_qm:status` to `earl:result` for recognized literals and carries unrecognized literals verbatim (Layer C). This open verdict design is a strength for federation.

---

## 4. What we adopt

Two adoption strategies, applied to both vocabularies:

### 4.1 Alignment (`ontology/alignment/`)

Every OSLC-RM/QM core class and predicate gets an `owl:equivalentClass` / `owl:equivalentProperty` binding (or `skos:closeMatch` where semantics are close-but-not-identical) to its `rtm:` counterpart. The alignment file is the **bidirectional dictionary** the adapter consults at parse and emit time. Examples: `oslc_rm:Requirement` ≡ `rtm:Requirement`; `oslc_rm:satisfiedBy` (inverse) ≡ `rtm:satisfies`; `oslc_qm:TestCase` ≡ `rtm:Artifact` typed as `rtm:TestCase`; `oslc_qm:validatesRequirement` → `rtm:satisfies` for `verification` aspect, EARL verdict carried. Result: the entire RM/QM core vocabulary lands in the `rtm:` graph in `rtm:` form, SPARQL-queryable with no special cases.

### 4.2 Roundtrip profile (`ontology/profiles/oslc-rm-roundtrip`, `oslc-qm-roundtrip`)

A composable SHACL contract enumerating predicates and shapes required for **lossless roundtrip** (§9.A.2 O6). Running `oracle ... --profile=oslc-rm-roundtrip` PASSes only when every shape passes — meaning the in-memory `rtm:` graph carries enough structure to be re-serialized to OSLC-RM byte-equal to canonical input. The profile is declarative; the adapter implementation can evolve, the profile is the contract.

---

## 5. What we reject, and why

Three OSLC features are deliberately out of scope for v0.1. Each rejection has a rationale grounded in open-source, self-hostable, verifiable certification.

| Rejected feature | Rationale |
|---|---|
| **Service provider catalogs & discovery** | Catalogs assume a centralized authoritative tool publishing capabilities. `flexo-rtm` is peer-cooperative and git-anchored. Discovery is replaced by **explicit configuration**: adopters declare OSLC sources in `flexo-rtm.yaml`. No `oslc:ServiceProvider` / `oslc:ServiceProviderCatalog`. |
| **Delegated UIs (HTML iframe + postMessage)** | Vendor-specific browser embeddings tied to a hosted tool. `flexo-rtm`'s UX is the Claude skill + git-native workflow; embedded dialogs are anti-pattern for an oracle that must be reproducible from the command line. No `oslc:CreationDialog` / `oslc:SelectionDialog`. |
| **OSLC-RM's centralized-RM-tool assumption** | OSLC-RM was written for a world where one server is "the" RM database. `flexo-rtm` is multi-party: every collaborator's git checkout is a peer. We carry RM data faithfully but do not pretend to be a centralized RM server. The adapter operates at the **file/RDF level**, not the HTTP service level. (Live HTTP connectors are v0.2 work, additive on the adapter contract.) |

What this is *not*: a rejection of the data model. We adopt the data model. We reject the deployment surface that wraps it.

---

## 6. Where OSLC reflects IBM/Doors steering

OSLC emerged from IBM Rational's Jazz initiative in the late 2000s with strong influence from the DOORS family. Three artifacts of that origin are visible in the spec:

- **The link-type taxonomy was largely shaped by Doors.** Predicates `elaboratedBy`, `specifiedBy`, `decomposedBy`, `satisfiedBy`, `validatedBy` map closely onto Doors' built-in link types. This is **good**: Doors encodes decades of requirements-engineering practice; inheriting that vocabulary is a feature.
- **The service-provider model assumes proprietary tool hosting.** Catalogs, factories, and delegated UIs were designed to integrate Jazz-suite products across vendor boundaries. They assume a server you log into. Where the "tool" is a git repository, these constructs are vestigial.
- **Configuration management was added later (OSLC-CM, OSLC Config) and is incomplete.** Versioning was retrofitted via separate domains and remains less mature than RM/QM. `flexo-rtm` solves versioning natively through git.

**Critical reading:** the data model is good; the deployment model is not. OSLC is the right vocabulary; it is the wrong runtime. `flexo-rtm` adopts the vocabulary and supplies its own runtime (git + RDF + Flexo MMS + the oracle).

---

## 7. What "lossless roundtrip" requires

`flexo-rtm` v0.1 commits to a binary lossless-roundtrip contract for both OSLC-RM and OSLC-QM, enumerated in [[Design Spec]] §9.A.2 as acceptance criteria **O1–O7**. Two independent layers: **A (core)** and **C (carry-through)**.

### Layer A — RDFC-1.0 triple-set equivalence on core constructs (O1, O3, O4)

For every OSLC-RM/QM construct in the enumerated core class set (`spec/oslc-roundtrip-acceptance.md`, normative):

```
RDFC-1.0(parse(emit(parse(input)))) == RDFC-1.0(input)
```

Parse the OSLC document into the internal `rtm:` graph, emit back as OSLC, re-parse, and the RDFC-1.0 canonical form must be byte-identical to the canonical form of the original input. RDFC-1.0 (W3C RDF Dataset Canonicalization 1.0) eliminates bnode-relabeling and serialization-order ambiguity — canonical-form byte-equality is stronger than "semantically equivalent."

- **O3** requires the enumerated core class set to be normatively listed in `spec/oslc-roundtrip-acceptance.md`. Any new construct claimed to satisfy Layer A must be added to that list — no implicit support.
- **O4** requires every canonical W3C/OASIS example fixture in `examples/oslc-fixtures/canonical/` to roundtrip losslessly under Layer A.

### Layer C — opaque carry-through for vendor extensions (O2, O5)

Predicates outside the core set — `doors:`, `jama:`, `polarion:`, any vendor namespace — are stored **verbatim** in a per-source named graph (`<oslc-rm:source/{id}>`) and **re-emitted verbatim**. The certification predicate does not certify content inside carry-through subgraphs (we do not pretend to understand vendor semantics we have not standardized); structural-only checks apply (triple count per resource preserved).

- **O5** requires sanitized Doors and Jama exports in `examples/oslc-fixtures/vendor/` to roundtrip with Layer A on core + Layer C on extensions.

### Profile gate and vendor registry (O6, O7)

- **O6**: `--profile=oslc-rm-roundtrip` (and the QM counterpart) is the SHACL profile enumerating required predicates and link types; the oracle PASSes only when all profile shapes pass.
- **O7**: `examples/oslc-fixtures/vendor-registry.yaml` maps known vendor namespaces to handling rules. **Adding a new vendor requires only a registry entry, not code changes.** A new OEM with its own OSLC-RM extension is supported by editing a YAML file.

Together A + C is the **lossless A+C criterion**, testable end-to-end against `examples/oslc-fixtures/`. The tests in `tests/integration/oslc-roundtrip/` are the binary gates that make §9.A.2 enforceable rather than aspirational. See [[Lossless Roundtrip Definition]] and [[Vendor Extension Carry-Through]].

---

## 8. Reference fixtures for testing

The integration tests in `tests/integration/oslc-roundtrip/` consume a regression corpus in `examples/oslc-fixtures/` (`canonical/` for public W3C/OASIS examples; `vendor/` for sanitized exports; `vendor-registry.yaml` for namespace handling rules per O7).

Public sources:

- **OASIS `oasis-tcs/oslc-domains`** — working repository for the OSLC-OP TC, carrying machine-readable vocabulary files (`requirements-management-vocab.ttl`, `quality-management-vocab.ttl`) and historical sample documents.
- **Eclipse Lyo** reference implementation projects — publicly redistributable RM/QM example payloads.
- **OSLC-OP project specifications** — worked examples embedded in the HTML normative text, extracted into fixtures.

Vendor fixtures are **sanitized exports** contributed under the project's CLA. They are the regression corpus that proves Layer C survives contact with the predicates real tools actually emit.

---

## 9. Adapter implementation notes (high-level)

The OSLC adapter is two functions and a registry:

**Reader** (`oslc → rtm` graph). Parse RDF/XML (OSLC-mandated wire format) or Turtle into a generic RDF dataset. Consult the alignment vocabulary to map every OSLC-RM/QM core predicate to its `rtm:` counterpart, producing the internal `rtm:` graph. Predicates **not** in the core enumeration are written verbatim into the per-source named graph (`<oslc-rm:source/{id}>`). The reader does not interpret vendor predicates; it preserves them.

**Writer** (`rtm → oslc` document). Emit internal `rtm:` triples translated back through the alignment vocabulary into OSLC-RM/QM predicates. Then re-attach the verbatim contents of the source named graph for every resource that originated from OSLC. Canonicalize the output via RDFC-1.0 before byte-comparison in tests. Emit as RDF/XML for OSLC compatibility; Turtle is supported for local consumption.

**Vendor-extension registry** (`vendor-registry.yaml`). Maps vendor namespace URIs to handling rules. Adding a namespace is a registry edit, never a code change (O7).

The adapter is intentionally **stateless and file-level**, not service-level. Live HTTP connectors to Doors and Jama instances are v0.2 work and plug into the same adapter without modification; the adapter contract is independent of transport. See [[OSLC RM Adapter Contract]] and [[OSLC QM Adapter Contract]] for per-adapter detail, [[Alignment Strategy]] for alignment-vocabulary structure, and [[Vendor Extension Carry-Through]] for named-graph mechanics.

---

## 10. Cross-references

- [[OSLC RM Adapter Contract]] — RM-specific normative adapter contract
- [[OSLC QM Adapter Contract]] — QM-specific normative adapter contract
- [[Lossless Roundtrip Definition]] — formal A+C criterion, RDFC-1.0 dependence
- [[Vendor Extension Carry-Through]] — named-graph layout, vendor registry
- [[Alignment Strategy]] — `owl:equivalentClass` / `skos:closeMatch` mapping discipline
- [[Design Spec]] — §9 (adapter mandate), §9.A.2 (O1–O7), §6.1 (ontology layering)
