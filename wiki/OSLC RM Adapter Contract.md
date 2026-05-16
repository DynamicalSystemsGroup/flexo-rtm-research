<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# OSLC RM Adapter Contract

> **Status:** Normative contract for any OSLC-RM 2.1 adapter implementation. `flexo-rtm` v0.1 supplies the reference implementation in `flexo_rtm.adapters.oslc.rm`. The contract is portable: a second implementation in a different language that satisfies this contract is a conforming adapter. See [[Design Spec]] §9 and §9.A.2 (O1–O7) for the binding acceptance criteria; this page restates them in adapter-implementer form.

---

## 1. Purpose

This page defines the interface contract — inputs, outputs, mapping, guarantees, and test surface — that any OSLC-RM adapter must satisfy to conform. It bridges the vocabulary review in [[OSLC RM and QM Review]] and the implementation in `flexo_rtm.adapters.oslc.rm`.

The contract is **file-level and stateless**: RDF documents in, RDF documents out. Live HTTP connectors are v0.2 work and plug into this contract without modification (§9 below).

A conforming adapter satisfies the **lossless A+C criterion** ([[Lossless Roundtrip Definition]]): RDFC-1.0 canonical-form byte-equality on the OSLC-RM core class set, and verbatim carry-through of vendor-namespace predicates. See [[Design Spec]] §9.A.2 **O1** (Layer A) and **O2** (Layer C).

---

## 2. Adapter inputs

A conforming `read(...)` accepts:

1. **OSLC-RM 2.1 RDF payload**, serialized as either **RDF/XML** (the OSLC-mandated wire format) or **Turtle** (supported for local consumption and test fixtures). The payload must be self-describing — namespaces declared, resource IRIs absolute or resolvable against a supplied base IRI.
2. **Optional `source_graph_iri`** — the named-graph IRI under which carry-through triples and the verbatim source are recorded. Defaults to `<oslc-rm:source/{sha256(input)}>` when not supplied. Stable across roundtrips: re-importing the same byte sequence produces the same source-graph IRI.
3. **Optional vendor registry hint** — a path or in-memory dict overriding the default `examples/oslc-fixtures/vendor-registry.yaml` ([[Design Spec]] §9.A.2 **O7**). The hint controls which namespaces are treated as carry-through and any per-namespace re-emission rules; it never introduces new core mappings (adding a core mapping requires editing `spec/oslc-roundtrip-acceptance.md`, per **O3**).

Inputs MUST NOT be modified in place. The adapter is referentially transparent: equal byte-sequences in produce equal `rtm:` graphs out.

---

## 3. Adapter outputs

A conforming `read(...)` returns an internal RDF dataset containing:

1. **Internal `rtm:` triples** in the default graph — canonical form, produced by alignment-vocabulary translation (§4 below). These are the triples downstream SPARQL/SHACL operates on. Every OSLC-RM core construct present in the input must appear here in `rtm:` form (no special cases), satisfying **O1**.
2. **Source-preserved named graph** `<oslc-rm:source/{id}>` — the verbatim parsed RDF, including vendor-namespace predicates ("Layer C carry-through"; see [[Vendor Extension Carry-Through]]). This graph is the regeneration substrate for write-back and is referenced by `prov:wasDerivedFrom` on resources that originated from it. The certification predicate does not certify content inside carry-through subgraphs ([[Design Spec]] §9.A.2 **O2**).
3. **Roundtrip-on-demand**: `write(read(input))` yields a payload whose RDFC-1.0 canonical form is byte-identical to the RDFC-1.0 canonical form of the input, for every core construct enumerated in `spec/oslc-roundtrip-acceptance.md` (**O1**, **O3**). Vendor-namespace triples are re-emitted verbatim from the source graph (**O2**, **O5**).

Outputs are deterministic — RDFC-1.0 canonicalization plus deterministic bnode labeling guarantees that the byte-level result is independent of process ID, time, and machine.

---

## 4. Mapping table — OSLC-RM construct → `rtm:` construct

This is the **alignment surface** the adapter consults. The full table is normative in `spec/oslc-roundtrip-acceptance.md` per **O3**; the page here is the human-readable summary. Every row is realized in `ontology/alignment/oslc-rm.ttl` as `owl:equivalentClass`, `owl:equivalentProperty`, or `skos:closeMatch` (where semantics are close-but-not-identical).

### Classes

| OSLC-RM construct | `rtm:` construct | Alignment |
|---|---|---|
| `oslc_rm:Requirement` | `rtm:Requirement` | `owl:equivalentClass` |
| `oslc_rm:RequirementCollection` | `rtm:RequirementCollection` | `owl:equivalentClass` |

### Link-type properties

| OSLC-RM predicate | `rtm:` predicate | Alignment | Notes |
|---|---|---|---|
| `oslc_rm:elaboratedBy` | `rtm:refinedTo` | `skos:closeMatch` | Direction preserved; documented semantic: object elaborates subject |
| `oslc_rm:elaborates` | `rtm:refinedFrom` | `skos:closeMatch` | Inverse of `elaboratedBy` |
| `oslc_rm:specifiedBy` | `rtm:specifiedBy` | `owl:equivalentProperty` | Direct mapping |
| `oslc_rm:specifies` | `rtm:specifies` | `owl:equivalentProperty` | Inverse |
| `oslc_rm:satisfiedBy` | `rtm:satisfiedBy` | `owl:equivalentProperty` | Inverse direction recorded |
| `oslc_rm:satisfies` (inferred inverse) | `rtm:satisfies` | `owl:equivalentProperty` | Canonical traceability predicate |
| `oslc_rm:tracedTo` | `rtm:tracedTo` | `owl:equivalentProperty` | Generic trace; direction preserved |
| `oslc_rm:decomposedBy` | `rtm:hasSubrequirement` | `owl:equivalentProperty` | Hierarchical decomposition |
| `oslc_rm:decomposes` | `rtm:subrequirementOf` | `owl:equivalentProperty` | Inverse |
| `oslc_rm:constrainedBy` | `rtm:constrainedBy` | `owl:equivalentProperty` | E.g., safety req constrains functional req |
| `oslc_rm:constrains` | `rtm:constrains` | `owl:equivalentProperty` | Inverse |
| `oslc_rm:implementedBy` | `rtm:implementedBy` | `owl:equivalentProperty` | Realization link |
| `oslc_rm:validatedBy` | `rtm:validatedBy` | `owl:equivalentProperty` | RM-side mirror of QM `validatesRequirement` |
| `oslc_rm:trackedBy` | `rtm:trackedBy` | `owl:equivalentProperty` | E.g., change request governing requirement |
| `oslc_rm:affectedBy` | `rtm:affectedBy` | `owl:equivalentProperty` | E.g., defect affecting requirement |
| `oslc_rm:uses` | `rtm:uses` | `owl:equivalentProperty` | Generic resource-uses-resource |

### Dublin Core attributes (required on every Requirement)

| OSLC field | `rtm:` field | Required? |
|---|---|---|
| `dcterms:identifier` | `rtm:identifier` | yes (SHACL `sh:minCount 1`) |
| `dcterms:title` | `rtm:title` | yes |
| `dcterms:creator` | `rtm:creator` | yes |
| `dcterms:description` | `rtm:description` | optional |
| `dcterms:modified` | `rtm:modified` | optional |

Any OSLC-RM predicate **not** in the table above is treated as a vendor extension under §5 Layer C and held verbatim in the source graph. Adding a new row is a normative spec edit (see **O3**).

---

## 5. Lossless guarantees

Two independent guarantees, layered as defined in [[Lossless Roundtrip Definition]]:

### Layer A — RDFC-1.0 canonical equivalence on core constructs ([[Design Spec]] §9.A.2 **O1**)

For every construct enumerated in §4 above:

```
RDFC-1.0(parse(emit(parse(input)))) == RDFC-1.0(input)
```

Adapter implementations achieve this by (a) translating into `rtm:` form via the alignment vocabulary on read, (b) translating back to OSLC-RM predicates on write, and (c) canonicalizing the output via RDFC-1.0 before any byte comparison in tests. RDFC-1.0 (W3C RDF Dataset Canonicalization 1.0) handles bnode-relabeling and serialization-order ambiguity — canonical-form byte-equality is stronger than "semantically equivalent."

### Layer C — opaque carry-through on vendor extensions ([[Design Spec]] §9.A.2 **O2**)

Predicates outside the §4 enumeration — `doors:`, `jama:`, `polarion:`, any vendor namespace — are stored verbatim in `<oslc-rm:source/{id}>` and re-emitted verbatim by `write(...)`. Triple count per resource is preserved across the roundtrip. The certification predicate does not certify content inside carry-through subgraphs; structural-only checks apply.

The composition is the **A+C criterion**: core constructs roundtrip semantically (canonical-form byte-equal), vendor extensions roundtrip structurally (verbatim re-emission, triple-count preserved). Together they are testable end-to-end against `examples/oslc-fixtures/`; see §6.

---

## 6. SHACL profile — `oslc-rm-roundtrip`

The adapter's normative gate ([[Design Spec]] §9.A.2 **O6**) is a SHACL profile in `ontology/profiles/oslc-rm-roundtrip/`. Running the oracle with `--profile=oslc-rm-roundtrip` PASSes only when **every** shape in the profile passes. See [[Profile Mechanism]] for the profile-composition contract.

### Required predicates (per Requirement)

- `dcterms:identifier` — `sh:minCount 1`, `sh:datatype xsd:string`
- `dcterms:title` — `sh:minCount 1`
- `dcterms:creator` — `sh:minCount 1`, `sh:nodeKind sh:IRI`

### Link-type targets

Every OSLC-RM link-type predicate listed in §4 MUST point only to `oslc_rm:Requirement` or `oslc_rm:RequirementCollection` (or their `rtm:` equivalents) within the OSLC-RM payload. Cross-domain links (`oslc_rm:validatedBy` pointing into OSLC-QM resources) are checked by the combined `oslc-rm-qm-bridge` profile, not by this one in isolation.

### Vendor extensions

Vendor-namespace predicates are **allowed only in carry-through graphs**. The profile MUST FAIL if any vendor predicate appears in the default `rtm:` graph (a sign the alignment failed open). Vendor predicates inside `<oslc-rm:source/{id}>` are not gated by this profile.

---

## 7. Test fixtures

Fixtures live in `examples/oslc-fixtures/` and are consumed by `tests/integration/oslc-roundtrip/`. Acceptance criteria **O4** and **O5** bind on these.

- **Canonical OSLC examples** (`canonical/`) — W3C/OASIS spec-embedded payloads, the OASIS `oasis-tcs/oslc-domains` repository, Eclipse Lyo reference projects. Every fixture here MUST roundtrip losslessly under Layer A alone (**O4**).
- **Sanitized Doors export** (`vendor/doors/`) — contributed under the project CLA, vendor-namespace predicates retained. Roundtrips with Layer A on core + Layer C on extensions (**O5**).
- **Sanitized Jama export** (`vendor/jama/`) — as above for Jama Connect.
- **Negative fixtures** (`negative/`) — malformed input: missing `dcterms:identifier`, link-type pointing at a non-Requirement, vendor predicate appearing in the default graph after `read(...)`. Each MUST fail the `oslc-rm-roundtrip` profile with a specific, machine-readable error code.

Adding a new vendor source is a **registry edit** (`examples/oslc-fixtures/vendor-registry.yaml`), not a code change ([[Design Spec]] §9.A.2 **O7**).

---

## 8. API surface (Python)

The reference implementation lives in `flexo_rtm.adapters.oslc.rm` and exposes two pure functions:

```python
from flexo_rtm.adapters.oslc.rm import read, write

# Read: OSLC-RM bytes → internal rtm: graph (default graph) + source named graph
internal_dataset = read(
    oslc_rdf_bytes,
    source_graph_iri="oslc-rm:source/req-123",  # optional; defaults to content-hash IRI
    vendor_registry=None,                        # optional override of default registry
)

# Write: internal rtm: graph + source named graph → OSLC-RM bytes (RDF/XML or Turtle)
oslc_rdf_bytes = write(
    internal_dataset,
    source_graph_iri="oslc-rm:source/req-123",
    format="application/rdf+xml",                # or "text/turtle"
)
```

Both functions are pure: same inputs yield byte-identical outputs. Errors are raised as `flexo_rtm.adapters.oslc.AdapterError` with a structured `code` field aligned to the SHACL profile's error codes (so a SHACL FAIL and an adapter-time FAIL on the same defect carry the same code).

---

## 9. What is NOT in v0.1

These are deliberate exclusions from the v0.1 adapter contract. They are mentioned here so that adopters do not mistake their absence for an oversight.

- **Live HTTP connectors** to running Doors / Jama / Polarion servers — **v0.2 work**, additive on this contract. The adapter is intentionally stateless and file-level; transport is a separate concern.
- **OSLC service-provider catalog discovery** (`oslc:ServiceProvider`, `oslc:ServiceProviderCatalog`) — **explicitly out of scope**. `flexo-rtm` replaces runtime discovery with explicit configuration in `flexo-rtm.yaml`. See [[OSLC RM and QM Review]] §5 for the rationale.
- **OSLC delegated UIs** (HTML iframe + `postMessage` creation/selection dialogs) — **explicitly out of scope**. `flexo-rtm`'s UX is the Claude skill plus git-native workflow; embedded vendor dialogs are anti-pattern for an oracle that must be reproducible from the command line.
- **OSLC-CM and OSLC Config integration** — versioning is handled natively through git in `flexo-rtm`; the OSLC-CM/Config domains are not in the v0.1 adapter surface.

A future v0.2 may add live connectors and additional domain adapters without changing this v0.1 contract.

---

## 10. Cross-references

- [[OSLC RM and QM Review]] — vocabulary survey, what we adopt vs. reject, OSLC's IBM/Doors lineage
- [[Lossless Roundtrip Definition]] — formal A+C criterion, RDFC-1.0 dependence
- [[Vendor Extension Carry-Through]] — named-graph layout, vendor registry mechanics
- [[Profile Mechanism]] — SHACL profile composition contract
- [[Design Spec]] — §9 (adapter mandate), §9.A.2 (O1–O7 acceptance criteria)
