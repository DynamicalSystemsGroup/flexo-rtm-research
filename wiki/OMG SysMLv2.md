<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# OMG SysMLv2

> **Status:** Anchoring review. This page elaborates the scope-reducing assumption stated in [[Design Spec]] §3 — that the modeled system is a SysMLv2 model conformant with OMG specifications, and that `omg-sysml:` IRIs (openCAESAR OWL rendering) are the canonical model vocabulary in `flexo-rtm`'s RDF graph.

## What SysMLv2 is

The Systems Modeling Language version 2 (SysMLv2) is an Object Management Group (OMG) standard for model-based systems engineering. The OMG approved final adoption of **SysML v2.0** in July 2025 (alongside KerML v1.0 and the SysML v2 API & Services specification); editorial updates in March 2026 prepared the spec for ISO submission. This wiki anchors on the **OMG SysML v2.0** final spec.

SysMLv2 is not a cosmetic refresh of SysML 1.x. It is a ground-up redesign with three properties that matter for `flexo-rtm`:

1. **Textual concrete syntax.** SysMLv2 models are authored as `.kerml` and `.sysml` text files. The Kernel Modeling Language (KerML) provides the foundational vocabulary; SysML proper is a KerML extension. Textual authoring makes models diff-able, mergeable, and amenable to ordinary git-based workflows — a precondition for the git+RDF foundation described in [[Design Spec]] §1.
2. **MOF-based abstract syntax (metamodel).** Behind the textual syntax sits a Meta-Object Facility metamodel that defines the abstract structure of every well-formed SysMLv2 element: parts, ports, actions, constraints, requirements, analysis cases, and so on. The metamodel is what makes interoperability tractable.
3. **Standardized serializations and API.** Models can be serialized to `.sysml.json` (the JSON projection defined by the SysML v2 API & Services specification) and accessed through a REST API that the SysMLv2 Pilot Implementation, Magic Systems of Systems Architect, and other tools share. The API is the integration substrate.

For `flexo-rtm`, "SysMLv2" therefore means the triple (textual `.kerml`/`.sysml` source, MOF metamodel, `.sysml.json` / API projection) — not any single concrete file format.

## Why we anchor on SysMLv2

[[Design Spec]] §3 frames anchoring on SysMLv2 as a **scope-reducing assumption**, not a bet. The reasoning is straightforward:

- **Broad but well-specified category.** SysMLv2 covers structure, behavior, requirements, constraints, analyses, verifications, and views in one specification. Anchoring there gives `flexo-rtm` a generous slice of MBSE practice without committing to any tool vendor's idiosyncratic dialect.
- **OMG governance (open standard).** The specification is normative, publicly available at omg.org/spec/SysML/2.0, and on a path to ISO standardization. Adopters are not locked into a vendor's metamodel; the metamodel itself is a public artifact under change-controlled governance.
- **openCAESAR OWL rendering — first-class RDF interop.** openCAESAR's "Implementing SysML v2 Ontology" effort produces an OML (Ontological Modeling Language) vocabulary equivalent to the MOF-based SysMLv2 metamodel via a MOF2OML adapter, which in turn renders to OWL2-DL via openCAESAR's `owl-adapter`. The result is an `omg-sysml:` namespace under which every SysMLv2 metaclass appears as an OWL class and every SysMLv2 relationship appears as an OWL property. This is the substrate that lets `flexo-rtm` keep models as RDF without inventing a parallel SysMLv2 vocabulary.
- **The ADCS prototype already uses this pattern.** `structural/satellite.ttl` and `structural/parameters.ttl` in the ADCS lifecycle demo (see [[ADCS Prototype Lessons]]) declare SysMLv2 elements as `sysml:PartDefinition`, `sysml:PartUsage`, `sysml:RequirementDefinition`, `sysml:AttributeUsage`, `sysml:ConstraintDefinition`, and so on, with the `sysml:` prefix bound to `https://www.omg.org/spec/SysML/2.0/`. The prototype's local alias maps to openCAESAR's `omg-sysml:` namespace. This pattern is the empirical proof point: the anchor works in practice.

The alternative — defining `flexo-rtm`'s own RDF vocabulary for systems modeling — would either reinvent SysMLv2 badly or constrain adopters to a non-standard dialect. Anchoring closes that surface area.

## Key constructs we use

`flexo-rtm` v0.1 reads, writes, and reasons over the following SysMLv2 constructs as `omg-sysml:` RDF:

- **`omg-sysml:Part`** — system parts. SysMLv2 distinguishes `PartDefinition` (the type) from `PartUsage` (the instance/role). The ADCS corpus uses both: `adcs:ReactionWheelDef` (definition) and `adcs:ReactionWheel_X`, `_Y`, `_Z` (usages typed by the definition).
- **`omg-sysml:Action`** — behavior and process. Actions are SysMLv2's primary behavior primitive; they compose into action sequences, decisions, and concurrent flows. `flexo-rtm` references actions when an artifact attests to behavior (a simulation run, a test execution, a control law evaluation).
- **`omg-sysml:Constraint`** — formal constraints. `ConstraintDefinition` and `ConstraintUsage` express predicates over part attributes (e.g., the ADCS prototype's `PDControllerDef` is a `sysml:ConstraintDefinition` that defines `tau = -Kp/2 * theta_error - Kd * omega`). Constraints are how engineering math enters the model.
- **`omg-sysml:RequirementUsage`** — requirement instances. Where `RequirementDefinition` declares the requirement's text and parameters, `RequirementUsage` instantiates the requirement in a specific context (a part decomposition, a verification case, a satisfy relationship). The ADCS corpus uses `sysml:RequirementDefinition` together with `sysml:SatisfyRequirementUsage` to bind a requirement to its satisfying elements.
- **Connection points and ports.** `omg-sysml:Port` (typed by `PortDefinition`) and connection usages (`omg-sysml:ConnectionUsage`, `omg-sysml:InterfaceUsage`) describe how parts couple. The certification surface uses ports to scope analyses to interface contracts.

These five constructs cover the bulk of structural-trace and requirements-trace queries the oracle issues. Behavior round-trip (full `Action` semantics) is intentionally narrower — see open questions.

## Two ways to model requirements in flexo-rtm

`flexo-rtm` supports **two equivalent representations** for requirements, and the certification predicate is agnostic between them:

1. **Native SysMLv2.** A requirement is an `omg-sysml:RequirementDefinition` / `omg-sysml:RequirementUsage` carried verbatim from the SysMLv2 source. The `sysml:SatisfyRequirementUsage` pattern (used in the ADCS corpus) attaches satisfying elements directly. No `rtm:Requirement` wrapper is introduced.
2. **`flexo-rtm` bridge.** A requirement is an `rtm:Requirement` instance that references the underlying SysMLv2 element via `rtm:appliesTo`. The `rtm:Requirement` carries the certification-relevant predicates (`rtm:satisfies`, attestation links, scope membership) while the SysMLv2 element retains its native semantics.

Both representations are first-class. The basic certification predicate ([[Design Spec]] §4.1) computes forward and backward coverage uniformly over either form. The OSLC adapter ([[Alignment Strategy]]) **prefers the bridge representation** because OSLC-RM does not know about SysMLv2 natively — `rtm:Requirement` aligns cleanly with `oslc_rm:Requirement` while still carrying a back-pointer to the SysMLv2 element. Adopters who never round-trip to OSLC can stay with the native form.

## What `flexo-rtm`'s SysMLv2 I/O does (v0.2+)

v0.1 ships the certification core against models already in RDF. SysMLv2 ingestion and emission land in **v0.2+**:

- **Ingest.** Parse `.kerml` and `.sysml.json` and store the result as `omg-sysml:` RDF using the openCAESAR OWL rendering. The pipeline is: SysMLv2 textual source → SysMLv2 Pilot parser (or equivalent) → MOF abstract model → MOF2OML/OWL adapter → `omg-sysml:` triples in the named graph for structural data.
- **Emit.** RDF → `.kerml` and `.sysml.json`. The inverse path uses the same metamodel mapping in reverse, plus a textual unparser. Output is intended for ingestion into SysMLv2 modeling tools (the Pilot Implementation, Magic Systems, future commercial implementations).
- **Lossless criterion.** Identical in spirit to the OSLC adapter ([[Alignment Strategy]]): a round-trip is lossless iff the input and output triple-sets are equivalent under **RDFC-1.0 canonicalization** (W3C RDF Dataset Canonicalization). Whitespace, blank-node renaming, statement ordering, and prefix choice are all permitted to vary; semantic content must not. The conformance suite enforces this on a regression corpus.

This is the minimum surface for `flexo-rtm` to participate in a SysMLv2 toolchain without forcing adopters to abandon their authoring tools.

## Toolchain considerations

The SysMLv2 implementation landscape `flexo-rtm` targets for interoperability:

- **SysMLv2 Pilot Implementation** (Eclipse-based, open source on GitHub at `Systems-Modeling/SysML-v2-Release`). The reference implementation; ships the textual parser, the API server, and Jupyter integration. This is the primary regression target.
- **Magic Systems of Systems Architect** (Dassault / No Magic). Commercial; supports SysMLv2 export. Interop target for industrial adopters.
- **openCAESAR tooling** (`owl-adapter`, OML workbench). The bridge between SysMLv2's MOF metamodel and the RDF world `flexo-rtm` inhabits. Operationally co-evolves with `flexo-rtm`'s ingest path.
- **Flexo MMS** (the broader Flexo SysML v2 Team's OWL2-DL ontology work). `flexo-rtm` shares vocabulary with Flexo MMS where the SysMLv2 ontology surfaces overlap; divergence is a co-evolution concern.

## Open questions

- **Stability of openCAESAR OWL rendering vs. SysMLv2 spec evolution.** The OMG spec is now final but will see point revisions; the openCAESAR rendering is driven by the MOF2OML adapter and may lag or lead. `flexo-rtm` pins to a specific openCAESAR rendering version per release and treats version skew between (SysMLv2 spec, openCAESAR rendering, `flexo-rtm` ontology) as a conformance-suite concern.
- **Behavior model semantics in RDF.** Full round-trip of `Action`, state machines, and time-varying behavior over RDF is non-trivial — the metamodel encodes operational semantics that OWL-DL does not natively express. v0.1 carries behavior **structurally** (the metaclass instances exist as RDF) but does not attempt to reason over behavioral semantics. Whether to lift behavior into SHACL rules, SPARQL property paths, or a separate semantic layer is open.
- **Granularity of the `rtm:appliesTo` bridge.** When the bridge representation references a SysMLv2 element, should it reference the `RequirementDefinition`, a specific `RequirementUsage` in a containment context, or both? The OSLC adapter's behavior is sensitive to this choice; the regression corpus needs to nail it down.

## Reference fixtures

`flexo-rtm`'s regression corpus needs SysMLv2 example models covering the metaclass range above. Candidate sources:

- **OMG-published SysMLv2 sample models** distributed with the spec and the Pilot Implementation (the Flashlight Starter Model is one well-known small example).
- **openCAESAR example projects** that exercise the OWL rendering end-to-end.
- **ADCS lifecycle demo** (the `structural/` directory). Already encoded as `omg-sysml:` RDF; useful as a hand-curated fixture against which round-trip from a future `.kerml` emission can be verified.

Each fixture in the corpus carries the SysMLv2 source, the expected `omg-sysml:` RDF (canonicalized), and a manifest noting which constructs it exercises.

## Cross-links

- [[ADCS Prototype Lessons]]
- [[Alignment Strategy]]
- [[Design Spec]]
