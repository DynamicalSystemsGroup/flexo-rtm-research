<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# OSLC Roundtrip Acceptance

> **Normative contract** for the OSLC-RM 2.1 and OSLC-QM 2.1 adapters. The enumerated core class mapping, link-type table, carry-through registry schema, and per-class roundtrip acceptance conditions live here. The `flexo-rtm` [[Design Spec]] §6.2 references this page; tests under `tests/integration/oslc-roundtrip/` and `tests/conformance/test_mapping_table.py` enforce it. See also [[ADR-010 OSLC-RM and OSLC-QM in v0.1]], [[ADR-011 Lossless Criterion A plus C]], [[OSLC RM and QM Review]] (rationale).

## 1. Scope

The OSLC adapters parse and emit RDF conforming to:

- **OSLC Core 3.0** (resource shapes; query capabilities; service discovery)
- **OSLC-RM 2.1** (requirements management domain)
- **OSLC-QM 2.1** (quality management domain)

v0.1 ships the **adapter** (parse, serialize, roundtrip against fixtures). v0.1 does **NOT** ship **live connectors** to running Doors / Jama / Polarion instances; those are v0.2 work and plug into the v0.1 adapter without modification.

## 2. Lossless criterion

**Layer A — RDFC-1.0 triple-set equivalence for OSLC core constructs** (per [[ADR-011 Lossless Criterion A plus C]]):

$$\text{RDFC-1.0}(\text{parse}(\text{emit}(\text{parse}(input)))) = \text{RDFC-1.0}(input)$$

restricted to triples whose predicate is in the enumerated core mapping (§4–§5 below).

**Layer C — opaque carry-through for vendor extensions**: triples outside the core mapping are stored verbatim in `<oslc-rm:source/{resource-id}>` named graphs and re-emitted verbatim. Structural check: the per-resource triple count is preserved across roundtrip.

## 3. Source-preserving import

Imported OSLC graphs land verbatim in per-resource source graphs:

- `<oslc-rm:source/{resource-id}>` for RM resources
- `<oslc-qm:source/{resource-id}>` for QM resources

Internal augmentations (attestations, transcripts, audit) live in **separate** named graphs that reference the source graph. Write-back emits **only** the source graph. Layer A round-trip is lossless **by construction**.

## 4. OSLC-RM 2.1 core class mapping (normative)

### 4.1 Classes

| OSLC-RM class | `rtm:` equivalent | Notes |
|---|---|---|
| `oslc_rm:Requirement` | `rtm:Requirement` | `owl:equivalentClass` |
| `oslc_rm:RequirementCollection` | `rtm:RequirementCollection` (`rdfs:subClassOf rtm:Requirement` for query simplicity) | container of requirements |

### 4.2 Link types (predicates)

Each row is `owl:equivalentProperty` unless noted. Directionality is preserved.

| OSLC-RM predicate | `rtm:` predicate | Cardinality |
|---|---|---|
| `oslc_rm:elaboratedBy` | `rtm:elaboratedBy` | many-to-many |
| `oslc_rm:elaborates` | `rtm:elaborates` (inverse of `rtm:elaboratedBy`) | many-to-many |
| `oslc_rm:specifiedBy` | `rtm:specifiedBy` | many-to-many |
| `oslc_rm:specifies` | `rtm:specifies` (inverse) | many-to-many |
| `oslc_rm:satisfiedBy` | `rtm:satisfiedBy` | many-to-many |
| `oslc_rm:satisfies` | `rtm:addresses` | **the evidence-linkage edge** (§4.1 of Design Spec); v0.1 PRIMARY. The OSLC predicate's "satisfies" naming is misleading per the Hawkins-Habli ACP split — satisfaction is judgment, not evidence — but the *graph shape* maps cleanly. Satisfaction synthesis is recorded via `rtm:SatisfactionAttestation`, not on this edge. |
| `oslc_rm:tracedTo` | `rtm:tracedTo` | many-to-many; weaker than satisfies |
| `oslc_rm:affectedBy` | `rtm:affectedBy` | many-to-many |
| `oslc_rm:constrainedBy` | `rtm:constrainedBy` | many-to-many |
| `oslc_rm:constrains` | `rtm:constrains` (inverse) | many-to-many |
| `oslc_rm:decomposedBy` | `rtm:decomposedBy` | many-to-many |
| `oslc_rm:decomposes` | `rtm:decomposes` (inverse) | many-to-many |
| `oslc_rm:implementedBy` | `rtm:implementedBy` | many-to-many |
| `oslc_rm:trackedBy` | `rtm:trackedBy` | many-to-many |
| `oslc_rm:validatedBy` | `rtm:validatedBy` | many-to-many; relates RM to QM TestCase |

### 4.3 Common metadata (preserved verbatim)

| OSLC / Dublin Core predicate | `rtm:` handling |
|---|---|
| `dcterms:identifier` | preserved as-is (Dublin Core retained) |
| `dcterms:title` | preserved as-is |
| `dcterms:description` | preserved as-is |
| `dcterms:created`, `dcterms:modified` | preserved as-is |
| `dcterms:creator`, `dcterms:contributor` | preserved as-is; `rtm:` does not redefine these |
| `dcterms:subject` | preserved as-is |
| `oslc:instanceShape` | preserved as-is (OSLC shape constraint) |
| `oslc:serviceProvider` | preserved as-is |

These are NOT remapped — they remain in their native Dublin Core / OSLC namespaces in the internal RDF.

## 5. OSLC-QM 2.1 core class mapping (normative)

### 5.1 Classes

| OSLC-QM class | `rtm:` equivalent | Notes |
|---|---|---|
| `oslc_qm:TestPlan` | `rtm:TestPlan` | `owl:equivalentClass` |
| `oslc_qm:TestCase` | `rtm:TestCase` | `owl:equivalentClass`; subClass of `rtm:Artifact` (test-as-evidence) |
| `oslc_qm:TestScript` | `rtm:TestScript` | `owl:equivalentClass`; subClass of `rtm:Artifact` |
| `oslc_qm:TestExecutionRecord` | `rtm:TestExecutionRecord` | `owl:equivalentClass`; subClass of `rtm:Activity` (execution-as-activity) |
| `oslc_qm:TestResult` | `rtm:TestResult` | `owl:equivalentClass`; subClass of `rtm:Artifact` (result-as-evidence) |

### 5.2 Link types

| OSLC-QM predicate | `rtm:` predicate |
|---|---|
| `oslc_qm:usesTestCase` | `rtm:usesTestCase` |
| `oslc_qm:executesTestScript` | `rtm:executesTestScript` |
| `oslc_qm:producedByTestExecutionRecord` | `rtm:producedByTestExecutionRecord` |
| `oslc_qm:reportsOnTestCase` | `rtm:reportsOnTestCase` |
| `oslc_qm:reportsOnTestPlan` | `rtm:reportsOnTestPlan` |
| `oslc_qm:runsTestCase` | `rtm:runsTestCase` |
| `oslc_qm:runsOnTestEnvironment` | `rtm:runsOnTestEnvironment` |
| `oslc_qm:validatesRequirement` | `rtm:addresses` (cross-domain: QM TestResult `rtm:addresses` RM Requirement; satisfaction is recorded via `rtm:SatisfactionAttestation`) |
| `oslc_qm:blocksTestExecutionRecord` | `rtm:blocksTestExecutionRecord` |
| `oslc_qm:relatedChangeRequest` | `rtm:relatedChangeRequest` |

### 5.3 TestResult outcome vocabulary

OSLC-QM verdict values map to `rtm:status` (per [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]):

| OSLC-QM verdict | `rtm:status` | Notes |
|---|---|---|
| `oslc_qm:passed` | `rtm:status/pass` | |
| `oslc_qm:failed` | `rtm:status/fail` | |
| `oslc_qm:inconclusive` | `rtm:status/deferred` | inconclusive = unresolved judgment |
| `oslc_qm:error` | `rtm:status/fail` | execution error → fail |
| `oslc_qm:blocked` | `rtm:status/deferred` | blocked = unresolved; preserve `oslc_qm:status/blocked` in source graph for round-trip fidelity |

Roundtrip fidelity: the original OSLC-QM verdict is preserved verbatim in the source graph; the `rtm:status` is **derived** for internal analysis. On write-back, the source-graph verdict is emitted unchanged.

## 6. Vendor extension carry-through (Layer C)

### 6.1 Mechanism

For any imported predicate `p` whose namespace is NOT in `{oslc_rm:, oslc_qm:, oslc:, dcterms:, rdf:, rdfs:, owl:, xsd:}`, the triple `(s, p, o)` is stored in the per-resource source graph `<oslc-rm:source/{resource-id}>` (or `oslc-qm:source/`) verbatim. On serialize, the triple is re-emitted unchanged.

### 6.2 Vendor extension registry

`examples/oslc-fixtures/vendor-registry.yaml` declares known vendor namespaces for diagnostic purposes (not for normalization). Schema:

```yaml
vendors:
  - name: IBM-Doors-Next
    namespace_prefix: rm_rm
    namespace_uri: "http://jazz.net/ns/rm/dng/rm#"
    handling: carry-through
    notes: |
      Doors Next Generation custom attributes appear under this namespace.
      `flexo-rtm` carries them verbatim; no semantic interpretation.

  - name: Jama-Connect
    namespace_prefix: jama
    namespace_uri: "https://api.jamasoftware.com/oslc/2.0/"
    handling: carry-through
    notes: |
      Jama custom item types and field extensions.

  - name: Polarion
    namespace_prefix: polarion
    namespace_uri: "http://www.polarion.com/2010/oslc-rm#"
    handling: carry-through
    notes: |
      Polarion ALM custom fields.
```

### 6.3 Registry usage

The registry is **diagnostic** — it does not affect roundtrip behavior. Even an entirely unknown vendor namespace is carried through correctly under Layer C. The registry enables:

- Audit reports labeling carried-through triples by vendor
- Test fixtures organized per vendor
- Documentation tooling for adopters

Adding a new vendor is a yaml entry only; no code changes.

## 7. Per-class acceptance conditions

For each class in §4–§5, the corresponding integration test asserts:

```python
# Pseudocode pattern; concrete tests in tests/integration/oslc-roundtrip/
def test_layer_a_roundtrip_for_class(class_iri, fixture_path):
    input_graph = parse_rdf(fixture_path)
    internal = oslc_adapter.parse(input_graph)
    output_graph = oslc_adapter.emit(internal)
    
    # Extract triples whose predicate is in the core mapping
    input_core = filter_core_triples(input_graph)
    output_core = filter_core_triples(output_graph)
    
    assert rdfc_1_0_canonical(input_core) == rdfc_1_0_canonical(output_core)

def test_layer_c_carrythrough(class_iri, fixture_path):
    input_graph = parse_rdf(fixture_path)
    internal = oslc_adapter.parse(input_graph)
    output_graph = oslc_adapter.emit(internal)
    
    input_extensions = filter_non_core_triples(input_graph)
    output_extensions = filter_non_core_triples(output_graph)
    
    # Structural: same triple count per resource
    assert triple_count_by_resource(input_extensions) == triple_count_by_resource(output_extensions)
    # Verbatim: same triples in canonical form
    assert rdfc_1_0_canonical(input_extensions) == rdfc_1_0_canonical(output_extensions)
```

## 8. Fixtures

### 8.1 Canonical fixtures (Layer A only)

Location: `examples/oslc-fixtures/canonical/`

Source: W3C / OASIS published OSLC-RM 2.1 and OSLC-QM 2.1 specification examples. Each canonical fixture exercises a specific class or link type from §4–§5.

Minimum coverage requirement: every class in §4.1, §5.1 has at least one canonical fixture; every link type in §4.2, §5.2 has at least one canonical fixture demonstrating round-trip.

### 8.2 Vendor sample fixtures (Layer A + Layer C)

Location: `examples/oslc-fixtures/vendor/`

Source: sanitized exports from Doors, Jama, Polarion (no proprietary content; structure only). Each vendor sample exercises:

- Core constructs from §4 / §5 (Layer A roundtrip)
- Vendor-specific extension predicates from §6 (Layer C carry-through)

Minimum coverage requirement: at least one fixture per registered vendor in §6.2.

## 9. SHACL profile gate

The `oslc-rm-roundtrip` SHACL profile (in `ontology/profiles/oslc-rm-roundtrip.shacl.ttl`) enumerates the required predicates and link types from §4. The `oslc-qm-roundtrip` profile (in `ontology/profiles/oslc-qm-roundtrip.shacl.ttl`) does the same for §5.

When the oracle runs with `--profile=oslc-rm-roundtrip`, the cert PASSes only if all profile shapes pass against the graph being certified.

## 10. Versioning and updates

This contract pins to **OSLC-RM 2.1** and **OSLC-QM 2.1**. Future OSLC versions (e.g., 3.0) require a new mapping table; old fixtures continue to roundtrip under the old contract.

Any addition to the core mapping table (§4 or §5) requires:

1. Updating this page
2. Updating the corresponding SHACL profile
3. Adding at least one canonical fixture exercising the new mapping
4. Updating `tests/conformance/test_mapping_table.py` to enforce the new row

## 11. Asymmetric audit semantics (OSLC ↔ flexo-rtm)

`flexo-rtm`'s audit bar is strictly *higher* than OSLC's, because we
distinguish **evidence** (`rtm:addresses`) from **judgment**
(`rtm:SatisfactionAttestation`). A graph that passes OSLC's traceability
bar may fail a `flexo-rtm` audit — we flag the missing explicit human
attestations.

Consequence: roundtrips through OSLC are NOT identity for non-trivial
graphs that carry attestations:

| Direction | Faithful? | Notes |
|---|---|---|
| OSLC → flexo-rtm | Layer A faithful by construction (source-preserving). | The result has no attestations; any `attested-*` profile would fail at re-audit. |
| flexo-rtm → OSLC | Lossy. | Attestation triples drop (default) or carry as Layer C extensions other OSLC clients can't interpret. |
| flexo-rtm → OSLC → flexo-rtm | NOT identity. | The intermediate OSLC form loses attestation structure; re-ingesting yields the bare addresses-graph. |

The OSLC adapter source-preserves verbatim — the *triple-set* roundtrip is
lossless for whatever the input contained. The asymmetry is at the
**semantic-bar** level, not the syntactic-fidelity level. `flexo-rtm`
strictly *extends* OSLC; OSLC is a strict semantic subset.

This is unavoidable: OSLC has no normative slot for the
Hawkins-Habli `gsn:Justification` (sufficiency) and `gsn:Assumption`
(adequacy) categories that `flexo-rtm` makes first-class. Any OSLC
consumer that wants to preserve the judgment layer needs a flexo-rtm-aware
extension.

## 12. What is NOT in scope

- **OSLC Service Discovery** (`oslc:ServiceProvider`, `oslc:Discovery`): not used by `flexo-rtm`'s adapter. v0.1 takes RDF in, emits RDF out; service discovery is a runtime concern handled by live connectors (v0.2).
- **OSLC Delegated UIs** (`oslc:Dialog`): vendor-specific UI embedding; out of scope.
- **OSLC Authentication**: identity is handled by `flexo-rtm`'s thin projection model ([[Identity Adapter Contract]]); OSLC's own OAuth1 surface is not consumed.
- **OSLC Change Management (OSLC-CM)** and **Architecture Management (OSLC-AM)**: deferred to v0.2+ following the same adapter pattern as RM / QM.
