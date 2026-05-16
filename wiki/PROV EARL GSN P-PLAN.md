<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# PROV EARL GSN P-PLAN

> **Purpose.** Document the four W3C / published vocabularies that `flexo-rtm` builds on — **PROV-O**, **EARL 1.0**, **OntoGSN**, and **P-PLAN** — the specific classes and properties we adopt from each, how they compose in the integration ontology, and the parsimony policy that keeps the assembled `rtm.ttl` under the X5 acceptance ceiling of ≤ 2000 triples ([[Design Spec]] §9.A.5).

`flexo-rtm` introduces **no novel epistemic vocabulary**. Where the project needs a class or property for provenance, assertion outcome, assurance argument, or process model, it adopts the standard term and (where convenient) declares a thin `rdfs:subClassOf` / `rdfs:subPropertyOf` handle in the `rtm:` namespace. The contribution is the **assembly**, not the terms. See [[Alignment Strategy]] for the broader mapping policy and [[Layered Ontology]] for the directory layout that this page populates.

## 1. PROV-O (W3C Recommendation, 2013)

**Specification.** `http://www.w3.org/ns/prov#` — W3C PROV-O.

**Role in `flexo-rtm`.** PROV-O is the **provenance spine** of the cert artifact. Every oracle run, attestation event, simulation, symbolic analysis, Doors / Jama import, and audit emission is a `prov:Activity`. Every approver, automated agent, and computation engine is a `prov:Agent`. Every requirement, evidence artifact, attestation record, and assembled report is a `prov:Entity`. The PROV graph is what makes the cert artifact **replayable** ([[Verifiable Self-Certification]]) and what carries the external URI references — git commits, content hashes, OCI digests — that make verification **local and federated** ([[Design Spec]] §4.5, §4.6, D26).

**Classes used (parsimony target: ~8).**

- `prov:Activity` — every executable step (oracle run, attestation event, simulation, symbolic analysis, import, audit, plan-execution stage)
- `prov:Agent` — every actor (engineer, computation engine, organization)
- `prov:Entity` — every thing that has provenance (requirement, evidence artifact, attestation, transcript, audit summary)
- `prov:SoftwareAgent` — superclass for `rtm:ComputationEngine` (the symbolic analyzer, the simulator, the oracle binary itself)
- `prov:Organization` — superclass for institutional approvers (per [[Design Spec]] §4.4 identity projection)
- `prov:Person` — superclass for individual approvers
- `prov:Plan` — the procedure / SOP / checklist a human attester followed (range of `rtm:followedProcedure`, which is a `rdfs:subPropertyOf prov:hadPlan`)
- `prov:Bundle` — for the cert artifact as a whole; lets us talk about provenance of the cert itself

**Properties used (parsimony target: ~10).**

- `prov:wasGeneratedBy` (Entity → Activity) — every artifact points to the activity that produced it
- `prov:wasAssociatedWith` (Activity → Agent) — every activity points to the responsible agent
- `prov:wasDerivedFrom` (Entity → Entity) — derivation chains (e.g., a built `rtm.ttl` from edit-source TTL plus imports; a subsystem requirement from a parent)
- `prov:wasInformedBy` (Activity → Activity) — one activity informed by another (an audit informed by the closure-rule validation it follows)
- `prov:used` (Activity → Entity) — every activity declares the entities it consumed
- `prov:startedAtTime`, `prov:endedAtTime` (Activity → xsd:dateTime) — timing for staleness checks (the `stale-attestation` SHACL shape)
- `prov:atLocation` (Activity → Location) — git commit, container digest, host
- `prov:hadPlan` (Association → Plan) — links activities to the SOP they followed
- `prov:generatedAtTime` (Entity → xsd:dateTime) — attestation timestamps

**Why these and not more.** Full PROV-O has ~30 classes and ~70 properties — most in the "expanded" category (qualified influence patterns). For v0.1 we keep only the "starting-point" terms; qualified-influence patterns are not required for v0.1 audit gates. See [[Parsimony Policy]].

## 2. EARL 1.0 (W3C Working Group Note, 2017)

**Specification.** `http://www.w3.org/ns/earl#` — W3C Evaluation and Report Language.

**Role in `flexo-rtm`.** EARL is the **assertion + outcome lattice**. Every `rtm:Attestation` is an `earl:Assertion`. Every audit emission (a `T1.orphan-requirement` finding, a `T4.unattested-adequacy` finding, a structural-completeness PASS) is an `earl:TestResult`. The five-valued outcome vocabulary gives the oracle a principled vocabulary for partial-coverage states without inventing terms. This lets a v0.1 traditional-traceability report and a v0.1 attestation report use the **same outcome shape** even though one is structural and the other attestation-bearing.

**Classes used (parsimony target: ~5).**

- `earl:Assertion` — superclass for `rtm:Attestation` (and its three subclasses `SatisfactionAttestation`, `AdequacyAttestation`, `SufficiencyAttestation` per [[Design Spec]] §4.3)
- `earl:TestResult` — the outcome record carried inside an assertion
- `earl:Assertor` — superclass for `rtm:Engineer` (the human or automated party making the assertion)
- `earl:TestSubject` — the thing being asserted about (a requirement, an artifact, a `rtm:satisfies` triple)
- `earl:TestCase` — the criterion being evaluated (a coverage threshold, a SHACL shape, a guidance criterion)

**Properties used (parsimony target: ~6).**

- `earl:result` (Assertion → TestResult) — the outcome record
- `earl:subject` (Assertion → TestSubject) — what the assertion is about
- `earl:test` (Assertion → TestCase) — what criterion the assertion answers
- `earl:assertedBy` (Assertion → Assertor) — who/what made the assertion (mandatory per [[Design Spec]] §4.3 named-approver rule)
- `earl:outcome` (TestResult → OutcomeValue) — the five-valued outcome
- `earl:mode` (Assertion → Mode) — `earl:manual`, `earl:semiAuto`, `earl:automatic` (superproperty of `rtm:attestationMode`)

**Outcome vocab adopted.** `earl:passed`, `earl:failed`, `earl:cantTell`, `earl:inapplicable`, `earl:untested`. The audit module emits exactly these; no `rtm:warning` or `rtm:partial`.

## 3. OntoGSN

**Specification.** `https://w3id.org/OntoGSN/ontology#` — an OWL rendering of the Goal Structuring Notation, the assurance-case dialect standardized by SCSC and used widely in safety-critical assurance (DO-178C, ISO 26262, IEC 61508 contexts). The published paper documents the class structure and the linking properties.

**Role in `flexo-rtm`.** OntoGSN gives us the **assurance-argument shape** for adequacy and sufficiency claims. Following the Hawkins–Habli Assurance Claim Point categorization the ADCS prototype already encodes ([[ADCS Prototype Lessons]]): adequacy is a `gsn:Assumption`, sufficiency is a `gsn:Justification`, satisfaction is a `gsn:Solution`. This is why `rtm:AdequacyAttestation` is declared `rdfs:subClassOf gsn:Solution` per [[Design Spec]] §4.3 and the [[GSN Integration]] plan. The `rtm:` namespace introduces no new epistemic concepts — it provides convenience handles for GSN patterns the prototype already validated.

**Classes used (parsimony target: ~8).**

- `gsn:Goal` — a claim to be supported (a requirement, in our usage)
- `gsn:Strategy` — how a goal is decomposed (forward-trace strategy, backward-trace strategy, attestation-bearing strategy)
- `gsn:Solution` — the evidence offered for a goal (an `rtm:Artifact`; superclass for `rtm:AdequacyAttestation`)
- `gsn:Justification` — the rationale that supports a step (the "sufficiency" claim)
- `gsn:Assumption` — what the argument depends on (the "adequacy" claim)
- `gsn:Context` — stable context the argument is set within (project, mission, aspect)
- `gsn:AwayGoal` — for cross-graph references when an argument cites a goal proved elsewhere
- `gsn:Module` — for partitioning the argument (one module per certification scope)

**Properties used (parsimony target: ~6).**

- `gsn:supports` (Solution → Goal) — the basic argument edge
- `gsn:inContextOf` (any → Context) — context binding
- `gsn:byJustification` (any → Justification) — sufficiency hook
- `gsn:byAssumption` (any → Assumption) — adequacy hook
- `gsn:isDecomposedBy` (Goal → Strategy) — argument decomposition
- `gsn:hasModule` (Argument → Module) — modular structure

**Why GSN and not a homegrown adequacy / sufficiency type?** The ADCS prototype already validated the pattern; GSN is the lingua franca of safety-critical assurance; importing the shape (with parsimony extraction) costs ~50 triples. See D15 in [[Design Spec]] §10.

## 4. P-PLAN

**Specification.** `http://purl.org/net/p-plan#` — the PROV-Centric ontology for representing scientific workflows and plans. P-PLAN extends PROV-O so a `p-plan:Activity` *is a* `prov:Activity` and a `p-plan:Plan` *is a* `prov:Plan`. It adds the layer PROV-O lacks: a **process model** that says "these are the steps, in this order, with these input variables" — separate from any single execution of that plan.

**Role in `flexo-rtm`.** P-PLAN gives us the **prospective process model** of the oracle's pipeline: one `p-plan:Step` per pipeline stage (assembly, structural materialization, evidence binding, attestation collection, closure-rule validation, audit, certification emission). Each oracle run produces one `p-plan:Activity` per stage, linked to its `p-plan:Step` via `p-plan:correspondsToStep`. The plan TTL is content-addressed; the activities are timestamped executions. This makes the construction process **itself queryable** — a reviewer can ask "did this cert artifact follow plan v3 or v4?" and get a deterministic answer.

**Classes used (parsimony target: ~5).**

- `p-plan:Plan` — the named process model (e.g., `rtm:OraclePlanV1`)
- `p-plan:Step` — a step in the plan (one per pipeline stage)
- `p-plan:Activity` — an execution of a step (subclass of `prov:Activity`)
- `p-plan:Variable` — typed input / output slot in the plan
- `p-plan:Bundle` — for grouping activities of one plan execution

**Properties used (parsimony target: ~5).**

- `p-plan:isStepOfPlan` (Step → Plan) — step membership
- `p-plan:hasInputVar`, `p-plan:hasOutputVar` (Step → Variable) — step interface
- `p-plan:correspondsToStep` (Activity → Step) — execution back-reference
- `p-plan:isPrecededBy` (Step → Step) — step ordering
- `p-plan:hasInputVarBinding` (Activity → Variable) — execution-time variable resolution

**Why P-PLAN and not just PROV.** PROV-O has `prov:Plan` but no notion of a *step* in a plan that an activity *corresponds to*. The ADCS prototype's `plan.ttl` already uses P-PLAN; v0.1 adopts it so the same tooling reads both. P-PLAN is the smallest standardized addition that closes the prospective-vs-retrospective gap.

## 5. How these compose in `flexo-rtm`

The four vocabularies are designed to overlay cleanly. A single fact in the cert artifact typically touches three of the four:

- **Every oracle run is a `prov:Activity` typed as `p-plan:Activity`** linked to its `p-plan:Step` in the plan. The `prov:wasAssociatedWith` edge points at the engine (`rtm:ComputationEngine`, an `rdfs:subClassOf prov:SoftwareAgent`). The `prov:used` edges point at the input entities. The `prov:wasGeneratedBy` edges from output entities point back. This is the PROV / P-PLAN layer.
- **Every attestation is a `rtm:Attestation` typed as `earl:Assertion`** with mandatory `earl:assertedBy` (a `rtm:Engineer`, `rdfs:subClassOf earl:Assertor + prov:Agent`), `earl:subject` (the `rtm:satisfies` triple under attestation, or a guidance criterion), `earl:test` (the criterion being evaluated), and `earl:result` carrying an `earl:outcome` from the five-valued lattice. The attestation is **also** a `prov:Entity` and `prov:wasGeneratedBy` an attestation `prov:Activity` (the moment the human clicked "approve"), giving it full provenance.
- **Adequacy and sufficiency claims use the GSN Solution + Justification pattern.** `rtm:AdequacyAttestation` is `rdfs:subClassOf gsn:Solution` and carries a `gsn:byJustification` link to the engineer's stated rationale. `rtm:SufficiencyAttestation` carries a `gsn:byAssumption` link to the engineer's stated modeling assumptions. Per [[Design Spec]] §4.3 and [[GSN Integration]], the prototype's encoding becomes the v0.1 normative pattern.
- **All of it wrapped in PROV provenance.** Each activity has a `prov:startedAtTime`, `prov:atLocation` (git commit + OCI digest), `prov:hadPlan` (the SOP the engineer followed), and `prov:wasAssociatedWith` (the named approver IRI, evaluated against the identity projection of [[Design Spec]] §4.4).

**Net effect.** A single `rtm:AdequacyAttestation` carries up to four standard-vocabulary type tags: `earl:Assertion`, `gsn:Solution`, `prov:Entity`, plus the `rtm:` subclass. Any EARL, GSN, or PROV consumer can read the cert artifact correctly without knowing anything about `rtm:`.

## 6. Parsimony approach

The vocabularies above are not loaded wholesale at runtime. The pipeline is:

1. **Vendored full TBox files in `ontology/imports/`** (read-only). One file per vocab: `prov-o.ttl`, `earl.ttl`, `ontogsn.ttl`, `p-plan.ttl`. Pinned by content hash; never modified in place. Used for build-time validation and offline reproducibility.
2. **Build-time extraction.** Either SPARQL `CONSTRUCT` (Python path, `rdflib`, default) or ROBOT `extract --method MIREOT` (Java path, opt-in via `make ontology-robot`) produces a minimal subset per vocab: `ontology/parsimony/extracts/<vocab>-subset.ttl`. The extraction is deterministic given the same TBox + same kept-term list.
3. **`manifest.yaml` documents exactly which classes / properties are kept and why.** This is the audit trail: every external term in the assembled ontology has a justification row in `manifest.yaml`. Reviewers reproduce the build, diff `manifest.yaml`, and see what the parsimony review approved.
4. **Combined extract subsets contribute ≤ ~1000 triples to the assembled `rtm.ttl`.** Targets per vocab: PROV ~400, EARL ~150, OntoGSN ~300, P-PLAN ~150. The remaining headroom (assembled `rtm.ttl` ≤ 2000 triples per X5 in [[Design Spec]] §9.A.5) is for the `rtm:` core, alignment, and OSLC bindings.

**X5 enforcement.** `tests/conformance/test_ontology_parsimony.py` counts triples in the built `rtm.ttl` and fails the build if the total exceeds 2000. Anything that pushes us close triggers a parsimony review of `manifest.yaml`. The discipline is structural, not aspirational. See [[Parsimony Policy]] for the review process and [[Attestation Infrastructure in v0.1]] for what the kept terms actually enable.

## Cross-references

- [[Parsimony Policy]] — the parsimony review process and the X5 ceiling
- [[Alignment Strategy]] — how external vocabularies map to `rtm:` and to each other
- [[GSN Integration]] — the Solution / Justification pattern for adequacy / sufficiency
- [[Layered Ontology]] — directory layout (`imports/`, `parsimony/`, `core/`, `alignment/`, `profiles/`, `shapes/`)
- [[Attestation Infrastructure in v0.1]] — what the EARL + GSN + PROV composition delivers in v0.1
- [[Design Spec]] — §4.3 (attestation model), §4.4 (identity), §6 (ontology architecture), §9.A.5 (X5)
