<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Flexo Git Coexistence

> Synthesises the conflict-resolution research (`flexo-conflict-resolution-policy-research`) for the `flexo-rtm` storage layer. Elaborates [[Design Spec]] §5 (three-layer architecture) and §5.2 (storage layer Flexo). The interface contract F1–F6 in §9.A.1 is normative for what is said here. Cross-reads with [[Three-Layer Architecture]] and [[Storage Layer Flexo Conventions]].

`flexo-rtm` runs on two version control systems at once. Git versions the operational state — working files, Pydantic and TTL serialisations, simulation code, references to experimental datasets. Flexo MMS versions the authoritative graph state — named graphs, branches, and commits expressed as SPARQL UPDATE patches over the RDF model. The two are not redundant; they sit at different layers of the architecture, carry different artifacts, and are coordinated per-commit by metadata in the git working tree that identifies which Flexo branch and commit are active.

This page distils the conflict-resolution research's conclusions for our storage layer. The full mathematical treatment lives in `flexo-conflict-resolution-policy-research`.

## Why both VCS, and why not just one

Git is excellent at versioning text-like content addressed by hash. Its merge model is line-oriented, order-insensitive in the common case, and self-certifying: if the diff applies cleanly, the merged file *is* the merge. This works because text has no constraints beyond being a sequence of bytes.

Flexo MMS versions structured RDF data. Models are graphs of typed elements with relational, aggregate, coupling, and behavioural constraints layered on top. The merge endpoint defined in the SysML v2 API gives the right *signature* for merging models, but the implementation logic — find a common ancestor, compute a three-way diff, detect conflicts, apply resolutions — is what the conflict-resolution research is about.

The architectural choice in `flexo-rtm` is to use each VCS for what it is good at:

- **Git** versions the operational layer: Pydantic and TTL serialisations of the in-memory working set, simulation scripts, references to large evidence files, ADRs, the wiki. Anything that is content-addressable text or near-text.
- **Flexo** versions the storage layer: authoritative named graphs (model triples, requirements, attestations, transcripts, guidance, audit), branched to isolate concurrent engineering streams, with commits stored as SPARQL UPDATE patches.

The two are coordinated by atomic commit (see below): when `flexo-rtm commit` runs, git captures the operational state at exactly the moment Flexo captures the authoritative graph state, and the git commit's metadata records the Flexo branch and commit identifier that pair with it. Either side alone is insufficient — git cannot enforce graph-level constraints; Flexo does not see the working files that drove the change.

## Five conflict-resolution policies

The conflict-resolution research defines a family of merge policies parameterised by which constraints are evaluated, how aggressively automated resolution is attempted, and where the machine–human boundary falls. Five concrete instances are named, ordered from least to most information produced:

- **Last-writer-wins.** No constraints evaluated. The most recent commit by timestamp is accepted; the other is dropped. No validity guarantee, no conflict report. Appropriate only for exploratory, low-stakes work.
- **Source-wins / target-wins.** A priority rule replaces optimisation: conflicts resolve in favour of one branch regardless of which constraint is at stake. Natural for asymmetric workflows where `main` is authoritative. Blanket, not per-constraint.
- **Union-with-constraint-check.** Compose both commits, evaluate the active constraint set on the result, accept if clean, otherwise emit a conflict report and escalate. A diagnostic policy: it tells you what is wrong but does not propose a fix. The natural starting point when adopting constraint-aware merging because it requires only the predicate compliance oracle, not an optimiser.
- **Constraint-aware synthesis.** The full constrained optimisation. When conflicts exist, the policy synthesises a resolution by minimising deviation from the intended composition subject to all active constraints. Produces shadow prices attributing each deviation to binding constraints, and requirement prices tracing those constraints back to stakeholder needs. This is the policy `flexo-rtm` adopts.
- **Escalation-only.** Any conflict, even a recoverable one, rejects the merge and surfaces the structured conflict report for human review. Synthesis disabled by configuration. Used in safety-critical contexts where no machine may resolve a merge.

The progression is a progression in information. Each step requires more infrastructure (oracle dispatch, optimisation, dual-variable computation) and produces more insight per merge.

## Why constraint-aware synthesis for RTM

Requirements-traceability content is constraint-rich and audit-critical. A merge that drops an attestation, weakens an aspect-coverage claim, or invalidates a SHACL profile can silently change the certification status of a deliverable. The cost of a quiet bad merge is high; the cost of treating every conflict as escalation-only would gut the UX. Constraint-aware synthesis is the only policy in the family that produces both a candidate resolution *and* a complete explanation of what the resolution gave up.

Shadow prices are the load-bearing artifact. At the optimum, complementary slackness pins each shadow price to either zero (the constraint was slack and did not influence the outcome) or positive (the constraint was binding and actively shaped it). The shadow price vector is a sparse, targeted summary of exactly which constraints mattered for *this particular merge*. Trace them through the satisfaction relation to requirements, and an institutional auditor inspecting a merge commit sees: which requirements were impacted, which constraints were binding under each, and what the resolution cost relative to a hypothetical conflict-free composition. No deviation is unexplained.

The mathematical machinery (Lagrange duality, complementary slackness, infeasibility certificates) is not what an engineer interacts with at merge time. It is what gives the conflict report its structure: a ranked list of binding constraints, impacted requirements with aggregated prices, and — when the merge is infeasible — a minimal subset of mutually unsatisfiable constraints.

## The verification / validation boundary at merge

The conflict spectrum from the research maps cleanly onto the V&V boundary:

- **Syntactic conflicts** (concurrent edits to the same triples) and most **structural conflicts** (metamodel and schema violations of the merged triple-set) fall in *verification* scope. They are computable: SHACL closure rules, SPARQL ASK queries, RDFC-1.0 equality checks. The predicate compliance oracle dispatches each predicate to its evaluation mechanism and returns a uniform vector. CI runs these checks at every merge.
- **Semantic conflicts** — and a residual class of structural conflicts that depend on engineering intent rather than schema — fall in *validation* scope. They require judgment: does the new evidence actually support the requirement; is the merged design configuration still coherent with the stakeholder need.

For `flexo-rtm` the rule is: verification-scope conflicts are handled automatically by constraint-aware synthesis; validation-scope conflicts are escalated. The unit of escalation is the **validation edge's approver IRI** — the named human whose attestation made the original claim. Re-attesting the claim against the merged state is the act that closes the escalation. This is consistent with the [[Verifiable Self-Certification]] thesis: every claim resolves to a named, accountable human. The interface contract in [[Design Spec]] §9.A.1 F5 captures this normatively.

## The atomic commit pattern

A `flexo-rtm` commit is a single atomic event that fans out across both VCS:

1. The operational layer accumulates model triples, evidence references, attestation triples, and transcript fragments into the working rdflib dataset. SHACL gates fire on every write — fast, because the working set is small.
2. When the user commits, `flexo-rtm commit` packages the accumulated changes into a single Flexo transaction. Either the whole transaction lands or none of it does. Partial commits are forbidden (Design Spec F1).
3. Git captures the operational state — Pydantic and TTL serialisations, simulation scripts, references — at the same moment, with metadata identifying the Flexo branch and commit just written.
4. Every triple in the Flexo transaction shares a single `prov:Activity` IRI (F2) so the commit is provenance-coherent.

Model evolution and traceability evolution therefore co-version. You cannot land a commit that updates a SysMLv2 part without simultaneously resolving the dependent attestations. The merge protocol respects the same atomicity: a merge that resolves a conflict on a model triple but fails the SHACL re-check on a downstream attestation is rejected as a whole.

## Three-way diff requirements

The research identifies three-way diff as the minimum apparatus required for any non-trivial merge: a diff from the common ancestor to each branch head, correlated to identify where both branches modified the same content. The current Flexo Layer 1 service supports two-way diffs but not three-way; extending it requires the commit DAG to support multiple parents, which today is single-parent linked-list.

Three-way diff is what enables conflict classification across the spectrum: *syntactic* (triples in the modification sets of both per-side diffs), *structural* (the unioned merged state fails a domain constraint that neither side individually fails), and *semantic* (the unioned state is syntactically and structurally valid but is judged by a human oracle to violate intent). Without three-way diff, structural conflicts are invisible and semantic-conflict detection has nowhere to land its judgments.

## Patch semantics

Flexo stores each commit's delta as a SPARQL UPDATE literal (`mms-datatype:SPARQL`, gzip-compressed when large) in the metadata graph. Snapshots are materialised at branch heads; intermediate states are reconstructed by traversing ancestry to the nearest materialised snapshot and replaying patches forward. This is procedural delta storage, not declarative set-of-changes storage. The same net triple-level change can be expressed by different SPARQL UPDATE sequences, and the order of operations within a patch is meaningful to the engine. For `flexo-rtm` we adopt the patch representation as-is and rely on the predicate compliance oracle to evaluate the *materialised state* after replay.

## Open questions inherited from the research

The conflict-resolution research is explicit that several problems remain open. We carry them forward as known frontiers, not blockers for v0.1:

- **Patch ordering semantics.** Whether the order of SPARQL operations within a single commit's patch is semantically significant beyond the net set of triple changes, and what it means for two patches to commute. Not blocking for v0.1, where commits are produced by the `flexo-rtm` toolchain under a single provenance activity.
- **Completeness of triple-level representation.** Some higher-order operations (rename, move, retype) may be lost when reduced to triple-level INSERT/DELETE. For RTM this is mitigated because element identity is anchored by external dereferenceable URIs (see [[OSLC RM Adapter Contract]]), so a rename is a triple-level relabel against a stable IRI rather than a structural mutation.
- **Delta composition for >2-way merges.** The formalism handles two commits from a common ancestor; extending to *n*-way merges multiplies the orderings combinatorially. v0.1 sidesteps this by serialising merges; the question becomes interesting only when federation scales.

These are tracked in §7 of the Conflict Resolution Problem Statement.

## What this means concretely for `flexo-rtm`'s storage layer

Translating the synthesis into operating rules for [[Storage Layer Flexo Conventions]]:

- **One named graph per logical partition.** The Design Spec §5.2 partitioning (model, requirements, attestations, guidance, transcripts, audit) gives merge a clean unit of localisation. Most conflicts will be confined to a single partition; cross-partition coupling is the exception, detected by relational and aggregate constraints in the oracle.
- **Branches isolate engineering streams.** The convention is `main` / `engineering/<team>` / `cert/<run-id>` (Design Spec F6). Engineering streams develop in parallel; certification runs branch from `main` at a recorded state; merges flow back along well-defined paths.
- **Constraint-aware synthesis at merge.** Verification-scope conflicts are resolved automatically when feasible. Validation-scope conflicts — and any infeasible synthesis — escalate to the named approver IRI on the validation edge. CI gates the verification portion; humans handle the rest.
- **V&V boundary informs the gate hierarchy.** SHACL gates fire at three points: at operational write (every Pydantic-mediated edit), at commit (the atomic transaction is rejected if shapes do not close), and at merge (the merged state is re-checked against the active constraint set before the merge commit lands). The third gate is where the conflict-resolution machinery lives.

These rules are testable; the acceptance criteria in [[Design Spec]] §9.A.1 (F1 atomic transactions, F2 provenance integrity, F3 named-graph layout, F5 merge policy, F6 branch conventions) operationalise them, and conformance is checked by the live-skippable test suite (F7).

The shorter form: git holds what we read and edit, Flexo holds what we trust and audit, and constraint-aware synthesis is the bridge that makes the two safe to use together.
