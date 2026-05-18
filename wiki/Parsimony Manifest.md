<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Parsimony Manifest

> **Normative contract** for which exact terms `flexo-rtm` extracts from each external vocabulary (PROV-O, EARL, OntoGSN, ORG, FOAF, DCAT, OSLC-RM, OSLC-QM, omg-sysml). The `manifest.yaml` schema, sample entries, and ≤ 2000-triple budget rules live here. The `flexo-rtm` [[Design Spec]] §6.6 X6 references this page; `tests/conformance/test_ontology_parsimony.py` enforces it. See also [[Parsimony Policy]] (rationale), [[ADR-014 Parsimony Layer Build-Time Extraction]].

## 1. Scope

External vocabularies are **never** loaded wholesale into `rtm.ttl`. Build-time MIREOT/SLME extraction produces minimal subsets containing only the terms `flexo-rtm` actually uses. The assembled `rtm.ttl` (Core + Alignment + Parsimony extracts) MUST be ≤ 2000 triples per X6 acceptance criterion.

`manifest.yaml` (in `ontology/parsimony/manifest.yaml`) is the **declarative source of truth** for what gets extracted. This page documents the schema and the per-vocabulary extraction set.

## 2. Manifest schema

```yaml
# ontology/parsimony/manifest.yaml
version: "1.0"
target_triple_budget: 2000

vocabularies:
  - name: <human-readable name>
    iri: <vocabulary base IRI>
    source_file: <path to vendored full vocabulary>
    extract_method: MIREOT | SLME | SPARQL_CONSTRUCT
    extracted_classes:
      - iri: <class IRI>
        purpose: <one-line note on usage>
    extracted_properties:
      - iri: <property IRI>
        purpose: <one-line note on usage>
    extracted_individuals:
      - iri: <individual IRI>
        purpose: <e.g., earl:passed>
    target_extract_file: <output path, e.g., ontology/parsimony/extracts/prov-subset.ttl>
```

The build script `ontology/parsimony/build.py` reads this manifest, invokes the declared extraction method per vocabulary, and emits the subset files. The extracts are git-tracked (reproducible build).

## 3. Per-vocabulary extraction sets

### 3.1 PROV-O

**Source:** `ontology/imports/prov-o.ttl` (W3C PROV-O REC 2013)
**Extract:** `ontology/parsimony/extracts/prov-subset.ttl`
**Method:** MIREOT

```yaml
- name: PROV-O
  iri: "http://www.w3.org/ns/prov#"
  extracted_classes:
    - iri: prov:Activity
      purpose: superclass of rtm:Activity; processes the cert artifact records
    - iri: prov:Entity
      purpose: superclass of rtm:Artifact; addressable artifacts
    - iri: prov:Agent
      purpose: superclass of foaf:Person / org:Organization in our model
    - iri: prov:Person
      purpose: ditto
    - iri: prov:Organization
      purpose: ditto
    - iri: prov:Plan
      purpose: declared activity blueprints (executable plans)
  extracted_properties:
    - iri: prov:wasGeneratedBy
      purpose: artifact ← activity that produced it
    - iri: prov:used
      purpose: activity → artifact it consumed
    - iri: prov:wasDerivedFrom
      purpose: artifact lineage
    - iri: prov:wasAssociatedWith
      purpose: activity → agent (who ran it)
    - iri: prov:wasAttributedTo
      purpose: entity → agent (who produced it)
    - iri: prov:startedAtTime
      purpose: activity start time
    - iri: prov:endedAtTime
      purpose: activity end time
    - iri: prov:atTime
      purpose: instantaneous events (e.g., attestation moment)
    - iri: prov:atLocation
      purpose: where an activity ran (compute location)
    - iri: prov:hadPlan
      purpose: activity → its blueprint
    - iri: prov:wasInformedBy
      purpose: activity → activity (chain of derived activities)
    - iri: prov:wasInvalidatedBy
      purpose: entity → invalidating event (used by ADR-031 deprecated attestations)
    - iri: prov:specializationOf
      purpose: entity is a specialization of another
```

**Approximate triple count after extract:** ~80

### 3.2 EARL

**Source:** `ontology/imports/earl.ttl` (W3C Evaluation and Report Language 1.0)
**Extract:** `ontology/parsimony/extracts/earl-subset.ttl`
**Method:** MIREOT

```yaml
- name: EARL
  iri: "http://www.w3.org/ns/earl#"
  extracted_classes:
    - iri: earl:Assertion
      purpose: ancestral pattern for rtm:Attestation; informational alignment
    - iri: earl:TestResult
      purpose: pattern for evaluation outcomes
    - iri: earl:TestCriterion
      purpose: pattern for test definitions
  extracted_properties:
    - iri: earl:result
      purpose: rtm:Attestation alignment; conveys outcome
    - iri: earl:subject
      purpose: what is being attested about
    - iri: earl:test
      purpose: which test produced the result
    - iri: earl:assertedBy
      purpose: who asserted (parallel to rtm:approvedBy)
  extracted_individuals:
    - iri: earl:passed
      purpose: aligned with rtm:status/pass
    - iri: earl:failed
      purpose: aligned with rtm:status/fail
    - iri: earl:cantTell
      purpose: aligned with rtm:status/deferred
    - iri: earl:inapplicable
      purpose: edge-case outcome (rare in flexo-rtm; preserved for OSLC-QM compat)
    - iri: earl:untested
      purpose: ditto
```

**Approximate triple count:** ~40

### 3.3 OntoGSN

**Source:** `ontology/imports/ontogsn.ttl` (Goal Structuring Notation ontology)
**Extract:** `ontology/parsimony/extracts/gsn-subset.ttl`
**Method:** SLME

Per [[ADR-015 GSN Adoption for Adequacy and Sufficiency]], `flexo-rtm` uses GSN's Solution + Justification patterns for adequacy / sufficiency claims (consistent with ADCS prototype).

```yaml
- name: OntoGSN
  iri: "https://w3id.org/ontogsn/"
  extracted_classes:
    - iri: gsn:Goal
      purpose: top-level claim structure (used in adequacy/sufficiency criteria definitions)
    - iri: gsn:Strategy
      purpose: argumentation strategy
    - iri: gsn:Solution
      purpose: superclass of rtm:AdequacyClaim / rtm:SufficiencyClaim
    - iri: gsn:Justification
      purpose: rationale for an argument step
    - iri: gsn:Assumption
      purpose: underlying assumption
    - iri: gsn:Context
      purpose: applicable scope / conditions
  extracted_properties:
    - iri: gsn:supports
      purpose: solution → claim relationship
    - iri: gsn:byJustification
      purpose: argument step's rationale
    - iri: gsn:inContextOf
      purpose: applicable context/assumptions
```

**Approximate triple count:** ~60

### 3.4 W3C Org Ontology

**Source:** `ontology/imports/org.ttl` (W3C Org Ontology, October 2014)
**Extract:** `ontology/parsimony/extracts/org-subset.ttl`
**Method:** MIREOT

```yaml
- name: Org Ontology
  iri: "http://www.w3.org/ns/org#"
  extracted_classes:
    - iri: org:Organization
      purpose: organizations in identity projection (per ADR-028 polycentric ASOT)
    - iri: org:Membership
      purpose: person ↔ org with role
    - iri: org:Role
      purpose: roles in RBAC policies
    - iri: org:OrganizationalUnit
      purpose: hierarchical org structure (informational)
  extracted_properties:
    - iri: org:hasMembership
      purpose: person → membership
    - iri: org:organization
      purpose: membership → org
    - iri: org:role
      purpose: membership → role
    - iri: org:memberOf
      purpose: convenience inverse
```

**Approximate triple count:** ~50

### 3.5 FOAF

**Source:** `ontology/imports/foaf.rdf` (FOAF Vocabulary Specification 0.99)
**Extract:** `ontology/parsimony/extracts/foaf-subset.ttl`
**Method:** MIREOT

```yaml
- name: FOAF
  iri: "http://xmlns.com/foaf/0.1/"
  extracted_classes:
    - iri: foaf:Person
      purpose: human identity in projection
    - iri: foaf:Agent
      purpose: superclass of Person and Organization
  extracted_properties:
    - iri: foaf:name
      purpose: human-readable name
    - iri: foaf:mbox
      purpose: email contact (optional)
```

**Approximate triple count:** ~20

### 3.6 DCAT (for `dcat:downloadURL`)

**Source:** `ontology/imports/dcat.ttl` (W3C DCAT v3)
**Extract:** `ontology/parsimony/extracts/dcat-subset.ttl`
**Method:** MIREOT

```yaml
- name: DCAT
  iri: "http://www.w3.org/ns/dcat#"
  extracted_classes:
    - iri: dcat:Distribution
      purpose: optional; if adopters describe download distributions
  extracted_properties:
    - iri: dcat:downloadURL
      purpose: optional fetch URL for rtm:Artifact (per External URI Rules)
```

**Approximate triple count:** ~10

### 3.7 OSLC-RM 2.1

**Source:** `ontology/imports/oslc-rm.ttl` (OASIS OSLC-RM 2.1 vocabulary)
**Extract:** `ontology/parsimony/extracts/oslc-rm-subset.ttl`
**Method:** SPARQL CONSTRUCT (since OSLC vocab files have shape constraints we don't want)

Per [[OSLC Roundtrip Acceptance]], the core mapping enumerates which OSLC-RM terms `flexo-rtm` consumes:

```yaml
- name: OSLC-RM
  iri: "http://open-services.net/ns/rm#"
  extracted_classes:
    - iri: oslc_rm:Requirement
    - iri: oslc_rm:RequirementCollection
  extracted_properties:
    - iri: oslc_rm:elaboratedBy
    - iri: oslc_rm:elaborates
    - iri: oslc_rm:specifiedBy
    - iri: oslc_rm:specifies
    - iri: oslc_rm:satisfiedBy
    - iri: oslc_rm:satisfies
    - iri: oslc_rm:tracedTo
    - iri: oslc_rm:affectedBy
    - iri: oslc_rm:constrainedBy
    - iri: oslc_rm:constrains
    - iri: oslc_rm:decomposedBy
    - iri: oslc_rm:decomposes
    - iri: oslc_rm:implementedBy
    - iri: oslc_rm:trackedBy
    - iri: oslc_rm:validatedBy
```

**Approximate triple count:** ~80

### 3.8 OSLC-QM 2.1

**Source:** `ontology/imports/oslc-qm.ttl`
**Extract:** `ontology/parsimony/extracts/oslc-qm-subset.ttl`
**Method:** SPARQL CONSTRUCT

```yaml
- name: OSLC-QM
  iri: "http://open-services.net/ns/qm#"
  extracted_classes:
    - iri: oslc_qm:TestPlan
    - iri: oslc_qm:TestCase
    - iri: oslc_qm:TestScript
    - iri: oslc_qm:TestExecutionRecord
    - iri: oslc_qm:TestResult
  extracted_properties:
    - iri: oslc_qm:usesTestCase
    - iri: oslc_qm:executesTestScript
    - iri: oslc_qm:producedByTestExecutionRecord
    - iri: oslc_qm:reportsOnTestCase
    - iri: oslc_qm:reportsOnTestPlan
    - iri: oslc_qm:runsTestCase
    - iri: oslc_qm:runsOnTestEnvironment
    - iri: oslc_qm:validatesRequirement
    - iri: oslc_qm:blocksTestExecutionRecord
    - iri: oslc_qm:relatedChangeRequest
  extracted_individuals:
    - iri: oslc_qm:passed
    - iri: oslc_qm:failed
    - iri: oslc_qm:inconclusive
    - iri: oslc_qm:error
    - iri: oslc_qm:blocked
```

**Approximate triple count:** ~80

### 3.9 omg-sysml (openCAESAR rendering)

**Source:** `ontology/imports/omg-sysml-v1.ttl` (openCAESAR SysMLv2 OWL rendering)
**Extract:** `ontology/parsimony/extracts/omg-sysml-subset.ttl`
**Method:** SLME (preserves logical structure of SysMLv2 metamodel)

Per [[SysMLv2 Ingestion Contract]] §5, `flexo-rtm` uses a focused subset of SysMLv2:

```yaml
- name: omg-sysml
  iri: "https://www.omg.org/spec/SysML/20240801/SysML#"
  extracted_classes:
    - iri: omg-sysml:Element                # root
    - iri: omg-sysml:RequirementUsage       # mapped to rtm:Requirement
    - iri: omg-sysml:RequirementDefinition  # mapped to rtm:RequirementDefinition
    - iri: omg-sysml:PartUsage              # evidence artifact
    - iri: omg-sysml:PartDefinition         # evidence artifact class
    - iri: omg-sysml:Action                 # activity in SysMLv2
    - iri: omg-sysml:Constraint             # constraint
    - iri: omg-sysml:PortUsage              # ports (for connection lineage)
    - iri: omg-sysml:Connection             # connections between elements
    - iri: omg-sysml:VerificationCaseUsage  # mapped to rtm:TestCase
  extracted_properties:
    - iri: omg-sysml:elementId              # stable identity
    - iri: omg-sysml:qualifiedName          # human-readable path
    - iri: omg-sysml:owner                  # containment hierarchy
    - iri: omg-sysml:satisfies              # SysMLv2 satisfies relation
    - iri: omg-sysml:verifies               # SysMLv2 verifies relation
    - iri: omg-sysml:requirement            # requirement annotation
    - iri: omg-sysml:assumes                # assumption annotation
```

**Approximate triple count:** ~150 (SysMLv2 has the largest extract due to metamodel structure)

## 4. Total budget

| Vocabulary | Extract size |
|---|---|
| PROV-O | ~80 |
| EARL | ~40 |
| OntoGSN | ~60 |
| Org Ontology | ~50 |
| FOAF | ~20 |
| DCAT | ~10 |
| OSLC-RM | ~80 |
| OSLC-QM | ~80 |
| omg-sysml | ~150 |
| `rtm:` Core (own vocabulary) | ~600 |
| `rtm:` Alignment (equiv/subClass mappings) | ~200 |
| **Total `rtm.ttl`** | **~1370** |
| **Budget** | **≤ 2000** |

Headroom: ~630 triples for future growth. Builds that would exceed 2000 triples fail the parsimony test (X6).

## 5. Build process

```
ontology/parsimony/build.py
├── 1. Read manifest.yaml
├── 2. For each vocabulary:
│      ├── Load source from ontology/imports/
│      ├── Apply extraction method (MIREOT, SLME, or SPARQL CONSTRUCT)
│      ├── Write to ontology/parsimony/extracts/<vocab>-subset.ttl
│      └── Verify subset size matches expected (manifest declares approximate count)
├── 3. Concatenate: rtm-core.ttl + rtm-alignment.ttl + all extracts
├── 4. Validate against ontology/shapes/well-formedness.shacl.ttl
└── 5. Write assembled ontology/rtm.ttl; report total triple count
```

Build is **deterministic** (same manifest → same `rtm.ttl` byte-for-byte after RDFC-1.0 canonicalization). The build script is run pre-commit; the resulting `rtm.ttl` is git-tracked.

## 6. Update procedure

Adding a new term from an existing vocabulary:

1. Add the term IRI to the corresponding `extracted_classes` / `extracted_properties` list in `manifest.yaml`
2. Add a one-line `purpose:` note
3. Re-run `ontology/parsimony/build.py`
4. Verify the new triple count is still ≤ 2000
5. Commit `manifest.yaml`, the updated extract file, and `rtm.ttl` together

Adding a new vocabulary entirely:

1. Vendor the full source ontology to `ontology/imports/<vocab>.ttl`
2. Add a new top-level entry under `vocabularies:` in `manifest.yaml`
3. Choose extraction method
4. List extracted terms with purposes
5. Re-run the build; verify budget
6. Add an ADR explaining why the new vocabulary is needed

## 7. Auditability

The manifest is the audit trail. For any term in `rtm.ttl`, the manifest tells you:

- Which external vocabulary it came from
- Why it's kept (the `purpose:` note)
- How to reproduce its extraction (the `extract_method` declaration)

This satisfies the "auditable provenance of every imported triple" requirement of [[ADR-014 Parsimony Layer Build-Time Extraction]].

## 8. What is NOT in scope

- **Runtime ontology loading.** v0.1 does NOT load full vocabularies at runtime. The oracle reads `rtm.ttl` (≤ 2000 triples) and that's it.
- **Cross-vocabulary inference.** v0.1 uses SHACL validation, not OWL reasoning. If an adopter wants to reason across the parsimony extracts at query time, they enable `[analysis]` extras and use `owlrl` (per dependency policy in [[Design Spec]] §7.3).
- **Automated extraction discovery.** v0.1 does NOT auto-detect "which terms am I using?" The manifest is the **declared** truth; if `rtm:` core uses a term not in the manifest, the build fails with a missing-term error.
