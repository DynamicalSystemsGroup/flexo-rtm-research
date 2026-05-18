<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Verifiable Self-Certification

> Elaborates [[Design Spec]] §4.8 (three-layer artifact) and §4.9 (reproducibility chain). The cross-cutting acceptance criteria X1, X2, X6, X7, X8 in §9.A.5 are normative for this page.

**Verifiable self-certification** is the core concept of `flexo-rtm`. The name compresses two independent claims:

- *Verifiable* — any party with appropriate local permissions can independently re-execute the certification computation and arrive at byte-identical results. Certification does not rest on trust in the certifier; it rests on the certifier publishing enough structural information that the result is reproducible.
- *Self-certification* — the party that owns the model and evidence is the same party that produces the certification. No external authority issues the certificate; the certifying agent attests under the names of accountable humans, and the artifact records the attestation chain rather than embedding it inside a sealed certificate from a third party.

This is deliberately not the same shape as:

- **Third-party certification** (a CB or notified body inspects and grants a certificate). `flexo-rtm` does not preclude this, but the certification act is performed by the owner of the model.
- **Audit-on-demand** (the auditor re-derives the result from raw inputs each time). Verifiable self-certification persists the derivation as the artifact; re-derivation compares hashes rather than re-running judgment.
- **Signed-attestation-only** (a signed claim with no replayable computation behind it). The signature is necessary but not sufficient; the transcript is what makes the claim verifiable rather than merely authenticated.

The remainder of this page decomposes each half of the term into three components, then states the locality / federation principle that makes the result usable in multi-party institutional audits.

## Three components of *verifiability*

### 1. Deterministic computation

Every step in the certification is a SPARQL query or a SHACL shape evaluation, executed under a deterministic regime: solution ordering is canonical, shape evaluation order is recorded, and engines (pyshacl, rdflib SPARQL) run with deterministic options. There is no use of clocks, random seeds, network calls, or external state inside the computation itself — external URIs are dereferenced *out of band* into hashed, immutable inputs, and only the hashes flow into the computation. This is acceptance criterion X1 in [[Design Spec]] §9.A.5.

### 2. Canonical inputs

RDF allows the same graph to be serialized in many byte-different ways (blank node labels, prefix declarations, triple order). Verifiability requires that "the same input" mean exactly one thing. The oracle uses **RDFC-1.0 canonicalization** (W3C RDF Dataset Canonicalization) to normalize the input, then takes a content-hash over that canonical serialization. The hash algorithm itself comes from the active cryptographic suite, not from a hardcoded constant: v0.1's default is SHA-256 because that is the W3C Data Integrity 2.0 default for the `ecdsa-rdfc-2019` / `eddsa-rdfc-2022` cryptosuites and the cosign default; the system rotates by changing suite ID, not by code surgery. See [[ADR-026 Cryptographic Agility via Algorithm Profiles]]. This input hash is the load-bearing identity of "what was certified." Two parties holding the same RDF graph — independent of serialization choice, and using the same active suite — compute identical input hashes. See [[RDFC-1.0 Canonicalization]].

### 3. Replayable transcript

Each query and shape executed is logged as a `prov:Activity` with the IRI of the SPARQL query or SHACL shape (content-addressed), the canonical input hash, the canonical result hash, and a `prov:wasInformedBy` linkage to the step that produced its inputs. A verifier with the canonical input and the transcript can re-execute each step in order, compute their own result hash, and compare. If every step matches, the transcript replays; if any step mismatches, the verifier knows exactly where the divergence began. This is acceptance criterion X2. See [[Transcript Replay Semantics]].

These three components — deterministic computation, canonical inputs, replayable transcript — are jointly sufficient: anyone with read access to the canonical input subgraph and the transcript can re-derive the result independently.

## Three components of *self-certification*

### 1. The certifying agent attests to the model and evidence

The party operating `flexo-rtm` is the same party that owns the SysMLv2 model and the supporting evidence. The oracle runs in their environment, against their data, and the resulting cert artifact is published by them. No external certifying body sits between the engineer and the cert artifact. The trust mechanism is not an inspector's signature on a sealed certificate; it is the structural reproducibility of every step the certifier performed.

### 2. Named human accountability

Self-certification without named accountability would degrade into machine self-assertion. `flexo-rtm` requires that every attestation — satisfaction, adequacy, sufficiency — carry an `rtm:approvedBy` IRI pointing at a specific human identity, projected from the adopter's institutional identity provider (see [[Identity Boundaries and Policy Projections]]). The IRI is bound to a GPG/SSH-signed git commit at the moment the attestation is written, so "this person, at this time, attested this claim" is verifiable via standard public-key infrastructure. See [[Approver Binding via Git]].

SHACL gates this binding at write time. An attestation without an approver IRI is structurally impossible. This is the "by construction" mechanism in [[Mission and Thesis]]: accountability is not a post-hoc audit check, it is a precondition for the data existing at all.

### 3. The artifact *is* the certification

There is no separate certificate document. The audit-graph plus transcript plus attestation graph — the three-layer artifact described below — *is* the certification. It carries the input hashes, the step hashes, the attestations with named approvers, the external URI references, and the audit report's coverage statistics and gap enumeration. A third party who wants "the certificate" is handed the artifact and an entry point IRI; the artifact admits independent re-derivation of every answer it carries, which a conventional certificate would not. See [[Certification Predicate]] for how PASS/FAIL is defined as a predicate over the artifact rather than a verdict stamped onto it.

## Two regimes of reproducibility: bit-exact vs tolerance-aware

The verifiability story above speaks consistently about **byte-identical** reproduction. That language is correct for the **RDF-internal** layer and incomplete — in a load-bearing way — for **delegated, numerical** computation. v0.1 carries both regimes as first-class, dispatched by the kind of computation a step records. The locked decision is [[ADR-027 Bit-Exactness vs Numerical Tolerances Are Both First-Class]].

### Regime 1 — RDF-internal computation: bit-exact, mandatory

RDFC-1.0 canonicalization plus canonical SPARQL solution-set ordering plus deterministic SHACL evaluation produces **byte-identical canonical bytes** for the same canonical input across runs, libraries, platforms, and times. The transcript's `inputs_hash → result_hash` chain commits to this: same canonical input, same recorded result hash, every time. This is the §9.A.5 **X1+X2** commitment, and it is mechanically enforced — the hash of the canonical bytes either matches the recorded hash or it does not. There is no slack. Any RDF-internal divergence pinpoints the first step at which the hashes parted ways. See [[RDFC-1.0 Canonicalization]] and [[Transcript Replay Semantics]] for the algorithms; see acceptance criteria X1 and X2 in [[Design Spec]] §9.A.5.

### Regime 2 — Delegated / numerical computation: tolerance-aware, evidence-type-defined

When the activity that produces an artifact is numerical — a Monte Carlo simulation, a finite-element analysis, a time-series simulation or ODE/PDE solve, a regression fit, a symbolic proof with a numerical fallback step — bit-identical reproduction across runs and platforms is often **physically impossible**. Floating-point addition is non-associative; BLAS and LAPACK kernels select different code paths depending on CPU microarchitecture and parallel-reduction strategy; library minor-version updates alter rounding in edge cases. Demanding byte-equal numerical output across machines is unrealistic.

The right framing is the same one v0.1 already uses for evidence-type-specific guidance ([[Aspect Coverage with Adequacy and Sufficiency]]): the **tolerance** that defines acceptable reproduction is part of the **sufficiency criteria** for that kind of evidence. Examples: "Monte Carlo with N ≥ 10⁵ trials, sample-mean within ±0.5% of the recorded value"; "FEA residual within 1e-6 of the recorded residual under the same mesh and solver-tolerance settings"; "time-series RMSE between the replay and the recorded trace below 1e-4 over the integration window." The **adequacy criteria** specify what the tolerance must *mean*: why is this tolerance enough for the claim being made (e.g., "the rigid-body assumption is adequate if the numerical residual is < 1e-6 in the slew-rate regime")? Both criteria are first-class RDF; tolerance values live in the criteria data, not in code (see [[Aspect Coverage with Adequacy and Sufficiency]] and [[GSN Integration]]).

### How the certification artifact carries both

The audit pipeline dispatches:

- **For every TranscriptStep recording an RDF-internal operation** — SPARQL, SHACL, RDFC-1.0 canonicalization, knowledge-curation operation — the replay path of [[Transcript Replay Semantics]] §3 enforces bit-exact equality on the `inputs_hash` and `result_hash` chain. Any divergence names the step.
- **For every TranscriptStep recording a delegated numerical computation** (`rtm:stepKind = "delegated-numerical"` per [[Transcript Replay Semantics]]), replay fetches the activity's recorded numerical result via the external URI references ([[External URI References]] **U2**), looks up the sufficiency criteria referenced by the step, and checks that the recorded result is within the criteria's recorded tolerance of the recorded expected outcome. The check is mechanical; the tolerance is declared, not implicit.

Both step kinds are first-class in the transcript and in the audit report. The certification artifact therefore carries a complete reproducibility commitment in each regime — bit-exact where it must be, tolerance-bounded where the evidence type demands it.

### Bit-exactness remains the default

Tolerance is an **explicit, evidence-type-specific opt-in** declared in the sufficiency criteria of the relevant evidence type. A claim made without an explicit tolerance declaration is verified bit-exact. The dispatch is determined by the step kind in the transcript and by the criteria the step references, not by a global setting. There is no tolerance "leakage" between regimes: an attestation whose evidence is RDF-internal is held to bit-exact reproduction, full stop; an attestation whose evidence is delegated-numerical is held to the tolerance it explicitly declares.

This split is what makes v0.1's certification honest: it promises what it can deliver (bit-exact for RDF; tolerance-bounded for numerical), and it makes the dispatch explicit so audit machinery can mechanically check each step under the right regime.

## The reproducibility principle: structural and local, not global

Per locked decision D26 (ADR-025) and [[Design Spec]] §4.9, reproducibility is **structural and local**, not global. This is what makes `flexo-rtm` cert artifacts usable in multi-party institutional audits. It has three pillars.

### Structural completeness

Each fact in the cert artifact is **structurally complete for its own local context**: the RDF neighborhood of the fact, the external URIs it references, the projection-at-cert-time of the identity / policy slice it depends on, and the signatures attached to it are all present in the artifact and sufficient to reproduce *that fact* in isolation. The artifact does not assume a verifier will have access to the rest of the graph; each fact carries its own locality.

Structural completeness is checkable without dereferencing — a verifier can confirm that every external URI is well-formed, every approver IRI resolves within the projection, every signature has the metadata needed to verify it, and every policy referenced is present — by reading the RDF alone. This is acceptance criterion X8.

### Locality

Verification of a single fact requires only access to that fact's **local neighborhood** plus the external URIs it references. There is no requirement to re-dereference the whole graph, and no requirement that a verifier hold universal permissions. A verifier with safety-aspect permissions verifies safety-aspect facts. A verifier with structural-only access verifies structural integrity. Each verification is a local operation against a local slice. This is acceptance criterion X6.

### Federation

Reproduction **composes across parties**. Federation has two axes:

- **Computational federation**: different parties run different fact-subsets. Each computes hashes for their slice; the union of slices covers the artifact.
- **Organizational federation**: different parties hold different permission slices — safety, design, regulator-structural-only — each reviews what they are entitled to see. The union of their per-fact PASS results equals a global PASS over the union of their permission subsets. This is acceptance criterion X7.

This is what makes the cert usable in real institutional audits where the auditing parties have asymmetric access rights. Conventional certification breaks down here because the certificate is monolithic. The three-layer artifact carries enough locality that partial-permission audits compose to a complete audit without any single party seeing the whole.

### Federated audit as the operational primitive

The X6/X7 commitments above presuppose a verification model that **federates** — they say the cert artifact admits local fact reproducibility and that multiple verifying parties' partial passes compose into a global pass. [[Federated Audit and Composition]] is the v0.1 operationalization of that commitment as a first-class analytical primitive. Self-certification at the component or subsystem level (this page) remains the floor; reproducibility audits, qualified-role audits, and composition certifications **stack on top** as additional named-approver attestations whose subjects are scopes and composed scopes rather than individual `rtm:satisfies` triples. The vocabulary makes these federation-level attestations first-class so the audit report can enumerate exactly which scope has which level of certification, and which slices of the cert artifact rely on self-certification alone versus independent reproduction.

### Scope-level adequacy and sufficiency at composition scale

The same adequacy and sufficiency framing v0.1 ships at the evidence level ([[Aspect Coverage with Adequacy and Sufficiency]]) lifts cleanly to the composition scale. **Adequacy** at composition scale is **composed scope coverage of the system-of-interest** — does the patchwork of constituent scopes cover the system-of-interest's requirements? **Sufficiency** at composition scale is **the number and nature of the orgs providing scope-level certifications** — does the signing pattern across the composition meet the program's qualified-role and signer-count criteria? Both criteria are RDF, SPARQL-evaluable, profile-toggleable. Composition-adequacy and composition-sufficiency criteria are first-class `rtm:AdequacyCriteria` / `rtm:SufficiencyCriteria` instances with `rtm:appliesToSystemOfInterest` scoping. See [[Federated Audit and Composition]] for the new attestation subjects (`rtm:ScopeCertificationAttestation`, `rtm:CompositionCoverageAttestation`, `rtm:CompositionSufficiencyAttestation`) and the three composable profiles (`composition-adequacy`, `composition-sufficiency`, `qualified-audit-per-scope`).

## The three-layer artifact

The artifact has three layers, each contributing to locality of reproduction. See [[Three-Layer Architecture]] and [[Design Spec]] §4.8.

- **Transcript** — the deterministic SPARQL+SHACL execution log. One `prov:Activity` per step; input/result hashes per step; references to external URIs (git commits, content hashes, OCI digests — see [[External URI References]]). The load-bearing replayable primitive.
- **Attestation graph** — a named graph of `rtm:Attestation` records bound to `rtm:satisfies` triples. Each attestation carries a mandatory `rtm:approvedBy` IRI, PROV provenance, and (when the relevant profile is active) a signed envelope per [[Signed Envelopes and Established Standards]]. Each attestation is independently verifiable against the projection it references.
- **Audit report** — forward / backward coverage tables, T1–T10 gap enumeration (the v0.1 gap codes per [[Gap Taxonomy]], including T9.deprecated-attestation and T10.deferred-attestation from the four-state attestation status vocabulary in [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]), certification grade (PASS/FAIL per [[Certification Predicate]] — a graph passes iff every required attestation in scope is in `rtm:status/pass`, with profiles `--profile=accept-deferred` and `--profile=accept-deprecated` available for non-production cert runs), transcript IRI, attestation graph IRI, and a **reproducibility manifest** enumerating every external URI the cert depends on. Generated from the other two layers and itself replayable from them.

The layers compose: the audit report references the attestation graph, which references the transcript, which references the canonical inputs. Each layer is independently checkable; each fact in each layer carries the references needed to reproduce it locally.

## Verifiability chain

```mermaid
flowchart TD
    A["canonical input subgraph<br/>(local to a fact)"] -->|RDFC-1.0| B[input hash]
    B --> C[transcript references hash]
    B --> D["transcript steps<br/>(SPARQL/SHACL with result hashes)"]
    D --> E["attestation graph<br/>(earl:Assertion + PROV +<br/>recorded projection)"]
    C --> F["audit report<br/>(coverage, gaps,<br/>reproducibility manifest)"]
    D --> F
    E --> F
    F --> G["a verifier with local permissions<br/>can replay this fact in isolation"]
```

The diagram shows the chain for a *single fact*. The full artifact is a union of such chains, one per fact, each independently replayable. Locality lives in the bottom edge: a verifier holding permissions only for this fact's neighborhood can traverse the chain end-to-end without seeing any other fact.

## Federated verification scenarios

Four scenarios illustrate how the locality principle plays out. Each stands on its own as a local audit; the union composes to a complete federated audit.

- **Engineer self-certifies a subsystem.** The engineer who authored a subsystem model and gathered its evidence runs `flexo-rtm` against their slice; the resulting attestation lands in the cert artifact as the leaf-level claim. The engineer's GPG/SSH-signed commit binds their identity to the attestation.
- **Safety reviewer re-verifies safety-aspect facts.** A reviewer holding safety-aspect permissions reads the safety-aspect subgraph, dereferences the safety-aspect external URIs they are permitted to see, replays the transcript steps that produced safety-aspect attestations, and confirms result-hash equality. They never see confidential-design payloads.
- **External regulator verifies structural integrity.** A regulator with structural-only access reads the RDF, confirms every reference is present, every signature is well-formed, every projection is complete, every URI is in the reproducibility manifest — without dereferencing classified content. Per X8, this structural audit is complete on its own terms.
- **Sister-organization reproduction team.** A peer organization runs the recorded activities (per the external URIs — git commits, OCI digests) in their own environment, hashes the outputs, and compares to the recorded artifact hashes. They do not need access to the original cert's compute infrastructure; the activity definitions are content-addressed and the underlying tools are standard.

No party requires universal access for the audit to be complete.

## What this *does not* do

Verifiable self-certification does not validate the engineering judgment itself. Whether a piece of evidence is *actually adequate* to satisfy a requirement is a human-judgment call, captured in the named-approver attestation. The certification machinery does not re-judge that; it ensures:

- the structure of the attestation chain is sound (every claim has the references it needs),
- the computations the chain depends on are reproducible (every step replays byte-identically),
- the named human accountability is genuine (every approver is bound to a signed commit at attestation time).

Engineering judgment is what `flexo-rtm` surfaces and captures; it is not what `flexo-rtm` automates.

## Relationship to V&V

`flexo-rtm` keeps verification and validation distinct in the artifact:

- **Verification** is automated and produced by the oracle. It is the replayable computation: did the SPARQL queries run, did the SHACL shapes pass, are the structural invariants present, are the references complete? Verification is reproducible by anyone with the relevant local access.
- **Validation** is human-attested and bound to named approvers. It is the judgment claim: this evidence is adequate, this artifact satisfies the requirement, this evidence is sufficient. Validation is captured in the attestation graph with `rtm:approvedBy` bindings.

A verifier can confirm the verification layer by replaying the transcript; the validation layer requires reading the attestations and trusting the named humans (or escalating to them, via the public-key binding, if the claim is challenged). The split is what lets the same artifact serve both automated tooling and institutional review.

---

See also: [[Three-Layer Architecture]], [[RDFC-1.0 Canonicalization]], [[Transcript Replay Semantics]], [[Approver Binding via Git]], [[Mission and Thesis]], [[Certification Predicate]], [[External URI References]], [[Identity Boundaries and Policy Projections]], [[Signed Envelopes and Established Standards]], [[Federated Audit and Composition]], [[Aspect Coverage with Adequacy and Sufficiency]], [[Design Spec]].
