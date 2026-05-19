<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# SysMLv2 Ingestion Contract

> **Normative contract** for SysMLv2 model ingestion in `flexo-rtm`. Accepted serializations, conformance profile, mapping rules to `rtm:`, and the read-only v0.1 boundary live here. The `flexo-rtm` [[Design Spec]] §3 references this page. See also [[OMG SysMLv2]] (background), [[ADR-002 SysMLv2 Anchoring]].

## 1. Scope and v0.1 boundary

`flexo-rtm`'s **scope-reducing assumption** (per [[Design Spec]] §3): the modeled system is a SysMLv2 model conformant with OMG specifications, represented as RDF via the openCAESAR `omg-sysml:` OWL rendering.

**v0.1 ships READ ingestion only.** Bidirectional I/O (write-back of internal augmentations to native `.kerml` / `.sysml.json`) is v0.2+. v0.1 reads SysMLv2 → RDF; subsequent attestations, transcripts, and audit graphs live alongside the SysMLv2 RDF in Flexo.

## 2. SysMLv2 version pin

v0.1 pins to:

- **OMG SysMLv2 1.0** (formal/2024-08-01 or successor formal release at v0.1 development time)
- **openCAESAR SysMLv2 OWL rendering** v1.x (the `omg-sysml:` namespace)
- **KerML 1.0** (the kernel language SysMLv2 inherits from)

Future SysMLv2 major versions require a new ingestion contract; old fixtures remain ingestible under the old contract via versioned profile.

## 3. Accepted input serializations

| Format | Extension(s) | v0.1 status |
|---|---|---|
| **KerML textual notation** | `.kerml` | Accepted via the openCAESAR ingestion toolchain (external dependency) |
| **SysMLv2 textual notation** | `.sysml` | Accepted via the openCAESAR ingestion toolchain |
| **SysMLv2 JSON serialization** (OMG normative) | `.sysml.json` | Accepted via openCAESAR or direct JSON-LD ingestion |
| **omg-sysml: RDF** (pre-converted) | `.ttl`, `.nt`, `.jsonld` | Accepted natively (the canonical internal form) |

The recommended adopter workflow:

1. Author in SysMLv2 textual notation or visual editor
2. Export to `.sysml.json` via the SysMLv2 Pilot Implementation
3. Convert to `omg-sysml:` RDF via openCAESAR's converter
4. Commit the RDF to Flexo via `flexo-rtm`

v0.1 does NOT bundle the SysMLv2 → RDF conversion toolchain — it consumes RDF. Adopters who need conversion install openCAESAR's converter as a separate dependency (out of `flexo-rtm`'s default install per X5 of §6.6).

### 3.1 Where to get openCAESAR

The openCAESAR project provides the JVM-based `owl-adapter` (MOF2OML + OWL) and `sysml-adapter` toolchains that perform the SysMLv2 ↔ `omg-sysml:` RDF conversion in both directions. Canonical source:

- **GitHub org:** https://github.com/opencaesar
- **`owl-adapter`:** https://github.com/opencaesar/owl-adapter
- **`sysml-adapter`:** https://github.com/opencaesar/sysml-adapter

**Adopter dependency posture:**

- The openCAESAR toolchain is **not** installed by `pip install flexo-rtm` or `uv sync`. It's a separate JVM (Java 17+) + Gradle dependency adopters install only if their source-of-truth is SysMLv2 native rather than pre-converted RDF.
- `flexo-rtm` pins to **OMG SysMLv2 1.0** (formal/2024-08-01) and **openCAESAR rendering v1.x** (see §2 of this contract).
- An end-to-end live test of the conversion pipeline is tracked at [research-repo issue #24](https://github.com/DynamicalSystemsGroup/flexo-rtm-research/issues/24) (decide JVM-in-CI vs pre-cached fixtures vs container).

For adopters who already have `omg-sysml:` RDF on disk (e.g., from a prior conversion pipeline), the openCAESAR dependency is not required; `flexo-rtm` reads and writes the RDF directly.

## 4. Conformance profile

The `sysmlv2-anchored` SHACL profile (in `ontology/profiles/sysmlv2-anchored.shacl.ttl`) validates that an ingested model is well-formed `omg-sysml:` RDF. The profile enforces:

### 4.1 Required root types

Every `rtm:Artifact` claimed to be a SysMLv2 model element MUST be typed as one of:

- `omg-sysml:Element` (the root abstract class) or a subclass
- Concrete subclasses including: `omg-sysml:PartUsage`, `omg-sysml:PartDefinition`, `omg-sysml:RequirementUsage`, `omg-sysml:RequirementDefinition`, `omg-sysml:Constraint`, `omg-sysml:Action`, `omg-sysml:PortUsage`, `omg-sysml:Connection`

### 4.2 Identity invariants

```turtle
sysmlv2:ElementShape a sh:NodeShape ;
    sh:targetClass omg-sysml:Element ;
    sh:property [
        sh:path omg-sysml:elementId ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:string ;
        sh:message "Every SysMLv2 element requires a stable elementId"
    ] ;
    sh:property [
        sh:path omg-sysml:qualifiedName ;
        sh:minCount 1 ;
        sh:datatype xsd:string ;
        sh:message "Every SysMLv2 element requires a qualifiedName"
    ] .
```

The `omg-sysml:elementId` is the **stable identity** across re-ingestions; the qualifiedName is a human-readable path.

### 4.3 Containment structure

```turtle
sysmlv2:OwnershipShape a sh:NodeShape ;
    sh:targetClass omg-sysml:Element ;
    sh:property [
        sh:path omg-sysml:owner ;
        sh:maxCount 1 ;
        sh:nodeKind sh:IRI ;
        sh:message "An element has at most one owning element (containment hierarchy)"
    ] .
```

## 5. Mapping rules to `rtm:`

### 5.1 Requirements

SysMLv2 has first-class requirement constructs. The mapping to `rtm:` is:

| SysMLv2 construct | `rtm:` mapping |
|---|---|
| `omg-sysml:RequirementUsage` instance | `rtm:Requirement` (`owl:equivalentClass` between `omg-sysml:RequirementUsage` and `rtm:Requirement`) |
| `omg-sysml:RequirementDefinition` | `rtm:RequirementDefinition` (a class of requirements; analogous to `oslc_rm:RequirementCollection`) |
| `omg-sysml:requirement` annotation property | `rdfs:subPropertyOf rtm:hasRequirement` |
| `omg-sysml:satisfies` connection | `rtm:addresses` (the **v0.1 evidence-linkage edge**; cross-domain to other SysMLv2 elements OR to `rtm:Artifact` external evidence). Per the Hawkins-Habli ACP split: no individual artifact satisfies a requirement; satisfaction is recorded via `rtm:SatisfactionAttestation`. |
| `omg-sysml:verifies` connection | `rtm:addresses` (validation/test relationship; cross-domain to `omg-sysml:VerificationCaseUsage` instances). The design-time-`satisfies` vs verification-time-`verifies` distinction is preserved in the source `omg-sysml:` graph; both surface as the same `rtm:addresses` edge in the projection. A `rtm:verifies` convenience alias (subPropertyOf `rtm:addresses`) is declared in `rtm-core.ttl` for adopters who want the OSLC-QM cross-domain narrative. |
| `omg-sysml:assumes` annotation | preserved as-is (assumption captured in source graph) |

### 5.2 Parts, actions, ports

Other SysMLv2 model elements that may serve as **evidence artifacts** (per `rtm:Artifact`):

| SysMLv2 construct | `rtm:Artifact` subclass |
|---|---|
| `omg-sysml:PartUsage` | `rtm:Artifact` (a designed component instance) |
| `omg-sysml:PartDefinition` | `rtm:Artifact` (a designed component class) |
| `omg-sysml:Action` (analysis, simulation, calculation) | `rtm:Activity` (a SysMLv2-native activity; complements `rtm:Activity` for external activities like git+OCI) |
| `omg-sysml:Constraint` | `rtm:Constraint` (a model-level constraint statement) |
| `omg-sysml:VerificationCaseUsage` | `rtm:TestCase` (cross-classification with OSLC-QM test cases per [[OSLC Roundtrip Acceptance]] §5.1) |

### 5.3 Aspect tagging

SysMLv2 does not have a built-in aspect taxonomy matching `rtm:Aspect` (`rtm:functional`, `rtm:performance`, `rtm:safety`, …). Adopters tag SysMLv2 RequirementUsage instances with `rtm:hasAspect` annotations either:

- At ingestion time via an annotation file (`ingestion-annotations.ttl`)
- During authoring as SysMLv2 metadata that the converter preserves
- Post-ingestion as a separate annotation graph (`urn:rtm:annotations`)

The choice is the adopter's; v0.1 does not mandate one mechanism over another.

## 6. Source-preserving ingestion

Imported SysMLv2 RDF lands verbatim in `urn:rtm:source/sysmlv2/{path-hash}` per [[Flexo REST Binding]] §4.2. Internal augmentations (attestations, transcripts) reference SysMLv2 elements by their `omg-sysml:elementId` and live in separate named graphs (`urn:rtm:attestations`, etc.).

**Round-trip property:** the source graph for a SysMLv2 file is byte-identical to the input RDF (after RDFC-1.0 canonicalization). Internal augmentations do NOT contaminate the source.

This makes write-back (v0.2) clean: emit the source graph as RDF → convert to SysMLv2 JSON → present to the adopter for re-import into their SysMLv2 tooling.

## 7. Element identity stability

The `omg-sysml:elementId` is the **stable identity** that `rtm:` attestations attach to. When a SysMLv2 model is re-ingested after edits, elements that retain their `elementId` retain their attestations; elements that are renamed-but-same-`elementId` retain attestations; elements that are deleted-and-recreated with new `elementId` lose attestations (the original attestation transitions to `rtm:status/deprecated` per [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] via `prov:wasInvalidatedBy` linked to the deletion event).

**Deprecation cascade detection** (v0.2+ per ADR-031) auto-marks attestations as `deprecated` when their subject's `elementId` is no longer present after re-ingestion. v0.1 surfaces the deprecation as a manual operator step.

## 8. Acceptance criteria (informative; normative are in [[Design Spec]] §6)

### 8.1 Read

- Ingestion of any `omg-sysml:` RDF graph from openCAESAR's reference output produces a Flexo-committable representation passing the `sysmlv2-anchored` SHACL profile.
- Sample SysMLv2 models (the OMG-published examples + ADCS-lifecycle-demo SysMLv2 graphs) ingest cleanly.
- The `omg-sysml:elementId` for each ingested element is preserved verbatim in the source graph.

### 8.1a Write-back (per-file RDF emit; pulled into v0.1)

- For every `omg-sysml:` RDF input file, `flexo-rtm` emits a corresponding RDF artifact preserving the source's `omg-sysml:elementId` set; the round-trip `parse → emit → parse → canonical-equality` is the read-step's correctness proof.
- Per-file separation is enforced via per-source named graphs in the storage layer; cross-file ingestion preserves separation through the roundtrip.
- Per-native-format emission (`.kerml`, `.sysml.json`) remains out of v0.1 scope — that's openCAESAR's owl-adapter direction, symmetric to ingest (see §3.1).

### 8.2 Cross-class compatibility

- A `rtm:SatisfactionAttestation` whose `rtm:appliesTo` references an `omg-sysml:RequirementUsage`'s `elementId` passes SHACL.
- A `rtm:Artifact` typed as both `rtm:Artifact` and `omg-sysml:PartUsage` is accepted (multi-typing is allowed).

### 8.3 Aspect tagging

- An external `ingestion-annotations.ttl` referencing `omg-sysml:elementId` values can attach `rtm:hasAspect` annotations to ingested elements; the annotations land in `urn:rtm:annotations` and do not contaminate the source graph.

## 9. What is NOT in v0.1

- **Write-back to SysMLv2 native formats** (`.kerml`, `.sysml.json` emit). v0.2 — that's openCAESAR's owl-adapter job, symmetric to ingest. Per-file `omg-sysml:` RDF write-back ships in v0.1 (see §8.1a).
- **SysMLv2 model authoring** within `flexo-rtm`. Adopters use their existing SysMLv2 tools (Pilot Implementation, MagicDraw, Cameo Systems Modeler, …).
- **SysMLv2 textual notation parser**. v0.1 consumes RDF; conversion is via openCAESAR's converter as an external dependency.
- **Live SysMLv2 tool connectors** (e.g., direct Cameo API integration). v0.2+.
- **Behavior model semantics** (full simulation of `omg-sysml:Action` chains). SysMLv2 behavior models are ingested as RDF; their executable semantics are outside `flexo-rtm`'s certification scope — they're modeled as `rtm:Activity` instances with external URIs referencing the simulation code (per [[External URI Rules]]).

## 10. Versioning notes

This contract pins to SysMLv2 1.0 + openCAESAR rendering v1.x. The openCAESAR rendering is the **canonical** RDF projection of SysMLv2; if it changes (e.g., adopts a different ontology pattern in v2.x), `flexo-rtm` will require a contract update.

Adopters using a different SysMLv2 → RDF converter must produce RDF that matches the `omg-sysml:` namespace and shapes; otherwise the `sysmlv2-anchored` SHACL profile will fail validation.
