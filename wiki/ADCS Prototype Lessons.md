<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# ADCS Prototype Lessons

`flexo-rtm` is not a green-field design. It is the next iteration of a working prototype — [`ADCS-lifecycle-demo`](https://github.com/DynamicalSystemsGroup/ADCS-lifecycle-demo) — which already implements end-to-end requirements traceability for a satellite Attitude Determination and Control System against a live Flexo MMS instance. The prototype answered the question "does this approach work at all?" and shipped a production-grade pipeline with 166 passing tests against a real Flexo deployment. The remaining question — "what should the **framework** look like once the ADCS-specific scaffolding is removed?" — is what `flexo-rtm` answers.

This page records what the prototype proved, what carries forward unchanged, what gets abstracted before publishing, what is genuinely new in `flexo-rtm`, what we deliberately do not replicate, and the boundary between the two repos going forward. See also [[Design Spec]] for the v0.1 vocabulary that crystallizes these lessons.

## 1. What `ADCS-lifecycle-demo` Proved

The prototype is not a toy. It is a working, tested, production-shaped system. Specifically:

- **End-to-end pipeline in eight stages** — ontology assembly → SysMLv2 structural model → SymPy symbolic analysis → scipy numerical simulation → evidence binding → RTM assembly → human attestation (CLI) → closure-rule validation → forward / backward / bidirectional audit → report generation → interrogation. Every stage is independently testable, and every stage emits a `p-plan:Activity` into a dedicated `<adcs:plan-execution>` named graph so the construction process itself is queryable.
- **166 passing tests, including live integration** against a remote Flexo MMS sandbox at `try-layer1.starforge.app`. The Flexo backend round-trips named graphs, runs SPARQL across the union, and recovers identical audit results to the local backend.
- **Named-graph dataset of eight graphs** held as an `rdflib.Dataset` with `default_union=True`, so SPARQL queries match across `<rtm:ontology>`, `<rtm:plan>`, `<adcs:structural>`, `<adcs:context>`, `<adcs:evidence>`, `<adcs:attestations>`, `<adcs:plan-execution>`, and `<adcs:audit>` without `GRAPH` clauses. This partitioning matches how Flexo MMS structures branches and is the operational answer to "how do you keep RTM layers separable while still queryable?"
- **SHACL closure-rule suite (ten invariants)** — nine SHACL shapes plus one runtime re-verification check that re-hashes every `rtm:ProofArtifact` and compares to its stored `rtm:proofHash`. Forward and backward traceability are independent shapes (8a / 8b) so error messages name the failing direction; bidirectional is the conjunction.
- **Forward, backward, and bidirectional audit** that runs orthogonally to the closure-rule suite. Audit pass/fail is the *certification outcome*; closure-rule pass/fail is *well-formedness*. The prototype distinguishes these by running each direction independently and emitting separate failure lists.
- **Backend abstraction** — the same Dataset persists losslessly to local TTL/TriG, to a bare Apache Jena Fuseki, or to a live Flexo MMS instance. The runtime computes audit locally regardless of backend; the backend is only persistence. This validates the "Flexo as one of several substrates" framing in [[Three-Layer Architecture]].

The prototype also captures per-activity **execution provenance** when computation runs in Docker — image digest, container ID, hostname, Python version are attached to the `prov:Activity` for every Stage 2 / Stage 3 run. That mechanism is the empirical seed for `flexo-rtm`'s [[External URI References]] discipline.

## 2. What `flexo-rtm` Carries Forward As-Is

Four patterns from the prototype are sound and need no reshaping. `flexo-rtm` reuses them directly:

- **Named-graph partitioning.** One graph per content layer — ontology, plan, structural, context, evidence, attestations, plan-execution, audit. SPARQL against `Dataset(default_union=True)` keeps queries simple while preserving per-layer addressability and Flexo branch alignment.
- **Vocabulary assembly approach.** `rtm:` is a thin integration ontology over PROV-O, EARL, OntoGSN, P-PLAN, OSLC RM/QM, and the openCAESAR SysMLv2 OWL rendering. The prototype introduces no novel epistemic vocabulary; it composes battle-tested standards via `owl:equivalentClass` / `rdfs:subClassOf` / `rdfs:subPropertyOf`. `flexo-rtm` keeps this composition discipline — see [[Layered Ontology]].
- **Re-hash replay for evidence reproducibility.** Every `rtm:Evidence` carries `rtm:contentHash` + `rtm:modelHash`; every `rtm:ProofArtifact` carries `rtm:proofHash`. At validation time the proof script is re-executed and the hash recomputed; any drift fails the closure rule. This pattern survives unchanged.
- **Closure-rule suite as a separate well-formedness gate.** A SHACL shape suite over the assembled dataset, with a runtime re-verification step for the one closure rule SHACL alone cannot express. `flexo-rtm` keeps this two-layer structure (declarative SHACL + runtime hash replay), and the regression corpus continues to exercise it.

## 3. What `flexo-rtm` Extracts (Abstract Before Publishing)

The prototype's ontology mixes domain-general framework terms with ADCS-specific instance vocabulary. The framework half ships in `flexo-rtm`'s core ontology; the ADCS-specific half stays in the prototype.

**Domain-general layer (lifts into `flexo-rtm`):** `rtm:Requirement`, `rtm:Evidence` (and its subclass structure), `rtm:Attestation` and its three subclasses, the GSN-based adequacy/sufficiency pattern, the audit shapes (forward / backward / bidirectional / orphans), the EARL outcome lattice (`earl:passed` / `earl:failed` / `earl:cantTell` / `earl:inapplicable` / `earl:untested`), the P-PLAN process-model pattern, and the content-addressing properties (`rtm:contentHash`, `rtm:modelHash`, `rtm:gitCommit`, `rtm:sourceFile`).

**ADCS-specific layer (stays in the prototype):** `rtm:ProofArtifact`, `rtm:SimulationResult`, `rtm:SymbolicAnalysis`, `rtm:NumericalSimulation`, the attitude-dynamics structural individuals, REQ-001..004, the satellite parameters, and the SymPy / scipy analysis scripts.

The assembly *approach* is sound and lifts as-is. The specific *ontology* — particularly the parts that bake in "evidence is a SymPy proof or a scipy simulation" — needs the new framing layered on. `flexo-rtm` introduces an [[Layered Ontology]] (core / profiles / domain) so that ADCS-style evidence becomes a profile extension, not a core commitment.

## 4. What's New in `flexo-rtm` (Not in the Prototype)

A great deal. The prototype is a pipeline that emits an RTM; `flexo-rtm` is the **framework** that any such pipeline consumes. The new surface includes:

- **Claude skill + MVC wrapper.** `flexo-rtm` ships an authoring surface — a Claude skill plus a Model/View/Controller wrapper — so RTM authoring is a guided experience, not a Python-script exercise.
- **OpenAPI service (v0.2).** A versioned HTTP API for RTM CRUD, attestation, and certification queries. The prototype has no service surface.
- **First-class `rtm:Scope` resource with composition algebra.** Certification is computed over a *scope* (a subset of requirements / artifacts / attestations) rather than the whole dataset. Scopes compose. The prototype audits the entire dataset and has no equivalent.
- **Three-layer architecture** — operational / storage / analysis split — so that Flexo MMS, local files, Fuseki, and OCI artifact stores are interchangeable substrates. See [[Three-Layer Architecture]].
- **Quantitative outcomes.** The prototype's audit is pass/fail; `flexo-rtm` emits a structured certification result (coverage metrics, gap codes, per-aspect verdicts).
- **OSLC-RM/QM lossless adapters.** The prototype publishes alignment axioms; `flexo-rtm` ships round-trip adapters with acceptance criteria for losslessness (no truncation, no drift).
- **Parsimony policy at build time.** The core ontology is small by design; profiles add capability. A build-time check prevents accidental core bloat.
- **SysMLv2 bidirectional I/O (v0.2).** `.kerml` and `.sysml.json` round-trip with the structural graph. The prototype reads SysMLv2 RDF only.
- **External URI references discipline.** Git+commit IRIs, content hashes, and OCI digests are first-class references with SHACL gating. This formalizes what the prototype's Docker compute backend already emits informally as PROV `prov:atLocation` and `rtm:imageDigest`. See [[External URI References]].
- **Signed envelopes vocabulary.** W3C VC Data Integrity, DSSE, cosign, and Rekor are composed (not invented) into a vocabulary for signing attestation envelopes. This closes the prototype's explicit "signed envelopes deferred" gap. See [[Signed Envelopes and Established Standards]].
- **Three attestation subclasses.** `rtm:SatisfactionAttestation`, `rtm:AdequacyAttestation`, `rtm:SufficiencyAttestation` as `rtm:Attestation` subtypes, with SHACL-enforced named-approver IRI on every instance. See [[Attestation Infrastructure in v0.1]] and [[Aspect Coverage with Adequacy and Sufficiency]]. The prototype implements adequacy and sufficiency as `gsn:Assumption` / `gsn:Justification` text nodes; `flexo-rtm` promotes them to typed attestations with their own named approvers.
- **Identity boundaries with thin RDF projections.** The prototype hardcodes GitHub IDs (`@mzargham`); `flexo-rtm` ships a configurable adapter pattern. GitHub, generic OIDC, and GitHub Actions OIDC are reference adapters in v0.1; SAML, LDAP/AD, Okta, Auth0, Keycloak are documented under the same contract. See [[Identity Boundaries and Policy Projections]].
- **Typed simplicial complex framing (Zargham 2026)** — *deferred to future work; not v0.1*. The v0.1 vocabulary (typed attestations, aspects, named approvers) is the data the future framework needs; v0.1 captures it without auditing it. See [[Topological Framework Future Work]].
- **TDA capability** — deferred with the topological framework.

## 5. What the Prototype Lacks That `flexo-rtm` Must Not Replicate

Four gaps in the prototype are explicit non-features. `flexo-rtm` closes them:

- **No formal certification predicate specification.** The prototype implements *an* audit, in code. The predicate "is this RTM certified?" is implicit in the audit module's procedures. `flexo-rtm` makes the predicate explicit and declarative — SHACL + SPARQL forms an executable specification, separable from any particular runtime.
- **No transcript-as-replayable-artifact.** The prototype emits `output/audit.md` and `output/audit.csv` — human-readable summaries. There is no machine-replayable log of the SPARQL queries and SHACL validations that produced the verdict. `flexo-rtm` emits a transcript that another implementation can re-execute against the same graph and confirm the same verdict.
- **No first-class scope.** The prototype audits the whole dataset, every time. There is no way to say "certify just REQ-003 and its dependencies under aspect `safety`." `flexo-rtm`'s `rtm:Scope` resource is the answer.
- **RTM data is RDF-native end-to-end.** Fine for the prototype — there is no public API. For `flexo-rtm`'s service-readiness goal, Pydantic facades at the OpenAPI boundary are required so that callers do not need to speak SPARQL.

## 6. Regression Corpus

The prototype's eight named graphs become `examples/adcs-corpus/` in `flexo-rtm`. Certification of this corpus is a regression test: the verdict computed by `flexo-rtm` v0.1 against the adopted-as-is ADCS data must match the verdict the prototype computes today. Drift is an ontology bug.

**Importantly:** the corpus already exercises adequacy and sufficiency attestations (REQ-001..004 each have both, via the GSN nodes), so v0.1 must support [[Attestation Infrastructure in v0.1]] to pass regression — it is not optional, even though v0.1 ships none of the topological audits. The corpus also includes a deliberately-declined attestation (REQ-001, `earl:failed`) so the regression covers the "well-formed-but-not-passing" case as well as the passing case.

## 7. Boundary Between Prototype and `flexo-rtm`

Going forward:

- **`ADCS-lifecycle-demo` keeps:** the ADCS-specific structural model (satellite, parameters, controllers), the SymPy proof scripts, the scipy simulation harness, the live Flexo MMS provisioning recipes, and the live integration tests. It is the canonical demo of using the framework on a real engineering problem.
- **`flexo-rtm` is:** the framework the prototype consumes. Core ontology + profiles + scope resource + certification predicate + transcript format + signed-envelope vocabulary + identity adapters + OSLC adapters + Claude skill + (v0.2) OpenAPI service.
- **Migration direction:** the prototype migrates to depend on `flexo-rtm`. It stops carrying its own copy of the framework half of the ontology; it imports `flexo-rtm` and adds the ADCS-specific profile on top. The live Flexo integration tests in the prototype become end-to-end smoke tests for the framework as well.

This boundary is what lets `flexo-rtm` ship as a domain-general framework while keeping the prototype as a continuously-running demonstration that the framework actually works on a real engineering artifact.
