<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Vendor Extension Carry-Through

> **Status:** Normative mechanism for OSLC-RM/QM Layer C. Derived from [[Design Spec]] §9 and §9.A.2 (criteria **O2** and **O7**). See also [[Lossless Roundtrip Definition]], [[OSLC RM Adapter Contract]], [[OSLC QM Adapter Contract]].

## Purpose

OSLC-RM 2.1 and OSLC-QM 2.1 define a **core vocabulary** (Requirement, RequirementCollection, TestCase, `oslc_rm:validatedBy`, etc.). Real-world tools — IBM Doors NG, Jama Connect, PTC Integrity, Polarion — ship a long tail of vendor-specific predicates outside that core: `doors:absoluteNumber`, `jama:itemType`, custom enumerations, vendor link types, internal IDs. These predicates are unavoidable in production exports and the principal reason naive OSLC roundtripping fails in practice.

`flexo-rtm`'s response is **Layer C carry-through**: the adapter preserves every non-core triple byte-faithfully without attempting to interpret, map, or normalize it. This page details how vendor triples are stored, what guarantees they enjoy, what guarantees they explicitly do **not** enjoy, and how new vendors are onboarded without touching adapter code.

[[Design Spec]] §9.A.2 **O2** gates this mechanism; **O7** gates the registry-driven extensibility. Both are binary acceptance criteria.

## Source-preserving named graphs

The mechanism is built on a single storage convention: **one named graph per imported OSLC resource**.

```
<oslc-rm:source/{resource-id}>   ←  every triple from the source RDF, verbatim
```

The adapter creates one named graph per resource, with an IRI derived deterministically from the resource's OSLC identifier. **All** triples present in the source RDF — core OSLC predicates **and** vendor extensions, indistinguishably — are written to that graph exactly as parsed. No predicate is rewritten. No literal is re-typed. No blank node is renamed beyond the canonical labelling required for storage.

`flexo-rtm`'s own augmentations — `rtm:` attestations, transcript fragment refs, scope membership, projection-at-cert-time identity triples — live in **separate named graphs** (`<attestations>`, `<transcripts>`, `<audit>`, per [[Storage Layer Flexo Conventions]]) that reference the source graph via stable IRIs. The source graph is an inviolable input artifact; internal graphs are derivative work product.

Two consequences are load-bearing for the whole certification story:

1. **Write-back emits only the source graph.** When the adapter serializes a resource back out to a Doors or Jama endpoint, it reads the source graph and serializes its triples. None of `flexo-rtm`'s internal augmentations leak into the OSLC output. Round-trip is lossless **by construction**, not by post-hoc filtering.
2. **The [[Certification Predicate]] never evaluates carry-through content.** Certification operates on `rtm:` triples in the augmentation graphs. A vendor predicate the oracle has never seen cannot accidentally flip a certification result, because certification SHACL shapes do not target the source graph.

## What carry-through preserves

For any triple `?s ?p ?o` present in the source RDF where `?p` is **not** in the OSLC-RM/QM core class set enumerated in `spec/oslc-roundtrip-acceptance.md`:

- **Predicate IRI verbatim.** No mapping to `rtm:`. `doors:absoluteNumber` stays `doors:absoluteNumber`.
- **Object value verbatim.** Literal lexical form, datatype IRI, and language tag preserved exactly. A `"42"^^xsd:integer` does not become `"42"^^xsd:int`; an `"OK"@en-GB` does not become `"OK"@en`.
- **Blank-node structure preserved per RDFC-1.0 isomorphism.** Any blank-node subgraph reachable from a vendor predicate is preserved up to RDFC-1.0 canonical isomorphism. The **O2** structural-count check confirms per-resource triple counts are identical pre- and post-roundtrip.

This is the same equivalence relation Layer A uses for core predicates; the difference is **semantic interpretation**, not storage fidelity.

## What carry-through explicitly does NOT do

Carry-through is a **storage and re-emission** guarantee. It is **not**:

- **Not inference.** The adapter does not materialize any new triple from a vendor predicate. Equivalence assertions belong in vendor-side mappings, not in the carry-through layer.
- **Not validation.** SHACL shapes from `oslc-rm-roundtrip` or any shipped `flexo-rtm` profile do **not** target vendor predicates. A user MAY author a custom profile that constrains them, but no shipped profile does.
- **Not certification.** The [[Certification Predicate]] does not evaluate vendor content. The `rtm:` certification artifact references the source graph by IRI but does not assert correctness of its contents. Certifying a Doors-specific predicate would commit `flexo-rtm` to opinions about Doors semantics that are out of scope for v0.1.

## Round-trip mechanics

Two operations:

**On read** — `oslc → rdf-graph → flexo-mms`:
1. Parse the OSLC resource (RDF/XML, Turtle, JSON-LD all permitted).
2. Compute a deterministic resource-id from `dcterms:identifier` (or `rdf:about`) of the root resource.
3. Write every parsed triple verbatim into `<oslc-rm:source/{resource-id}>`.
4. Optionally derive `rtm:` augmentation triples into separate graphs; derivations never modify the source.

**On write** — `flexo-mms → rdf-graph → oslc`:
1. Read `<oslc-rm:source/{resource-id}>`.
2. Serialize its triples in the target OSLC media type.
3. Emit. Augmentation graphs are not consulted.

Layer A (**O1**): `RDFC-1.0(parse(emit(parse(input)))) == RDFC-1.0(input)`. Layer C (**O2**) restricts this to per-resource structural-count equivalence. See [[Lossless Roundtrip Definition]] for the precise formulation.

## Vendor registry

Per **O7**, `examples/oslc-fixtures/vendor-registry.yaml` maps known vendor namespaces to handling rules:

```yaml
vendors:
  doors-ng:
    namespace: "http://jazz.net/ns/rm/dng/"
    handling: carry-through
    sample-fixture: examples/oslc-fixtures/vendor/doors-ng-sample.ttl
    known-predicates: [doors:absoluteNumber, doors:moduleContext]
  jama:
    namespace: "https://jamasoftware.com/oslc/"
    handling: carry-through
    sample-fixture: examples/oslc-fixtures/vendor/jama-sample.ttl
    known-predicates: [jama:itemType, jama:projectId]
```

The registry is **declarative metadata only**. It supports:

- **Zero-code-change vendor onboarding.** A registry entry plus a sample fixture is sufficient for the integration harness to exercise roundtrip — exactly the **O7** guarantee.
- **Analytics.** Reporting how many vendor-specific predicates a graph carries, grouped by vendor, for migration-readiness assessments.
- **Documentation surface.** Auditors can resolve `doors:` to a human-readable vendor description without dereferencing live ontologies.

The registry is **not required for correctness**. An unregistered vendor predicate roundtrips just as faithfully as a registered one — registration is metadata, not a permission gate.

## Failure modes

1. **Structural placement collision.** A vendor predicate appears where OSLC-RM core requires a specific type — e.g., a Doors export attaches `doors:status` directly to an `oslc_rm:Requirement` in a position where the core shape expects an `oslc_rm:validatedBy` link to an `oslc_qm:TestCase`. The Layer A SHACL profile gate (**O6**, `--profile=oslc-rm-roundtrip`) flags this. Resolution: extend the registry with a structural-tolerance note, or treat the source as drifted and resolve out-of-band before re-import.

2. **Vendor predicate IRI churn.** A vendor changes its namespace IRI between tool versions. Roundtrip remains lossless within a single version; cross-version diffing requires registry entries for both old and new namespaces. Documented drift, not a carry-through bug.

Neither mode invalidates already-stored source graphs — the inviolability of the source graph is preserved precisely so drift can be analyzed against an unmodified historical record.

## Integration test pattern

For every entry in the vendor registry, the harness asserts:

- **(a) Canonical-form preservation.** `RDFC-1.0(parse(emit(parse(fixture)))) == RDFC-1.0(fixture)` after restriction to core predicates (Layer A); structural per-resource triple count preserved across the full graph (Layer C).
- **(b) Source-graph integrity.** `<oslc-rm:source/{resource-id}>` after read contains exactly the triple set of the parsed fixture, with no augmentation predicates intermixed.
- **(c) Augmentation isolation.** No `rtm:` predicate appears inside any source graph; no vendor predicate appears inside any augmentation graph.

Together these operationalize **O2** and mechanize the **O7** "no code changes" guarantee: a new registry entry triggers the same three checks against the new fixture without any test-code modification.

## Cross-links

- [[Lossless Roundtrip Definition]] — formal statement of the Layer A and Layer C equivalence relations
- [[OSLC RM Adapter Contract]] — read/write surface for OSLC-RM 2.1
- [[OSLC QM Adapter Contract]] — read/write surface for OSLC-QM 2.1
- [[Storage Layer Flexo Conventions]] — named-graph layout that carry-through plugs into
- [[Design Spec]] §9, §9.A.2 — normative source for **O2** and **O7**
