<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Operational Layer UX Discipline

> **Status:** The UX commitments the operational layer of `flexo-rtm` must hold to in v0.1. These are not aspirational polish notes — they are load-bearing constraints because attestation is voluntary work and the system only earns the audit trail if engineers actually use it. Companion to [[Design Spec]] §5.1 and the inherited shape described in [[MVC Pattern from RIME TRL ANT]].

## The UX principle: latency drives adoption

If attesting to a satisfaction claim costs an engineer ten seconds of waiting on a SHACL gate or a network round-trip, the engineer will not author the attestation. They will defer. They will skip. They will accept the SHACL warning. They will paste a name into a field instead of binding a verifiable approver IRI. The audit trail then becomes a polite fiction — present in the database, hollow in the field.

Every other discipline on this page defends a single property: **the authoring loop must feel weightless.** The named-approver discipline of [[Human-AI Accountability]] survives only if the operational layer does not punish the named approver with friction. Determinism, atomicity, offline support, working-set scoping — four sides of one budget: the latency budget that decides whether attestation actually happens.

## Working-set semantics

`flexo-rtm checkout --scope <iri>` is the only blocking network event at the start of an authoring session. It resolves the scope IRI to the union of named graphs it covers (per [[Design Spec]] §5.3), pulls those graphs from Flexo at the head of the checked-out branch, and hydrates them into a local `rdflib.Dataset` in memory. The result is on the order of hundreds of triples for a typical scope — small enough that every subsequent SHACL gate runs in the same memory and returns in sub-second time.

The complex induced by the working set is itself a fragment of the full assurance complex (see [[Vertices Edges Faces]]). Adding a validation edge in the working set means adding a face-closure that is *locally* coherent. Global coherence against the rest of the complex is decided at commit time, when the Flexo transaction validates the diff against the authoritative shapes. The split — locally coherent during authoring, globally validated at commit — is what makes both phases fast.

SHACL closure rules are loaded into the working set once at checkout. Subsequent writes validate against the in-memory shapes graph; there is no reload, no fetch, no recompile. If the shapes themselves change upstream, the engineer sees that the next time they `checkout`. Mid-session, the rules are stable.

## What is local vs. what is authoritative

The distinction is sharp and the engineer must feel it:

- **Local state:** the working-set triples loaded at checkout, plus uncommitted edits, plus skill scratch state, plus the Pydantic-serialized TTL on disk in the git working tree. None of this is authoritative. It can be discarded, re-checked-out, edited freely.
- **Authoritative state:** Flexo MMS named graphs at the commit that `checkout` pinned. Nothing in the working set is authoritative until `commit` lands a transaction. The engineer is editing a copy.

This is the same mental model git already trains: working tree vs. last commit vs. remote. `flexo-rtm` reuses it deliberately so engineers do not learn a new mental model for state.

## Skill prompts at judgment moments

The operational shape inherited from [[MVC Pattern from RIME TRL ANT]] insists that the skill never picks the judgment call. In `flexo-rtm` that turns into a specific set of prompts the skill must stop and ask:

- **On a new evidence claim** — adequacy and sufficiency questions per [[Aspect Coverage with Adequacy and Sufficiency]]. Is this evidence the right *kind* (adequacy)? Is there enough of it (sufficiency)? The skill asks; the named approver answers; the answer is written verbatim into the attestation triples.
- **On approver attribution** — SHACL-gated validation of the approver IRI against the working set's approver-registry shape. The skill never invents an approver. If the engineer types a name, the skill resolves it to an IRI through the registry and surfaces the resolution for confirmation; if resolution fails, it stops and asks rather than guessing.
- **On commit** — a pre-commit hook verifies the approver IRI attached to attestation triples matches the committer identity (git signing key + registry binding). If they disagree, the hook blocks the commit. The check is local and runs against the registry snapshot in the working set.

The prompts share a shape: they happen at moments where the SHACL graph leaves a hole the system *cannot* fill from the available triples. The hole is a judgment. A human fills it. See [[Attestation Infrastructure in v0.1]] for the SHACL shapes that gate these moments.

## Three responses to a judgment prompt

When the skill stops and asks, the engineer has exactly three legal replies:

- **Attest yes.** The face closes. The skill emits the validation edge plus attestation triples (approver IRI, timestamp, verbatim justification, binding evidence reference). The working set now contains a locally-coherent positive judgment.
- **Refine.** The skill returns to the edit loop without writing any triples. The engineer adjusts the model, gathers more evidence, or sharpens the claim, then re-enters the prompt. Refinement is not failure — it is the loop doing its job.
- **Defer.** The skill writes a `rtm:DeferredJudgment` triple with the engineer's verbatim reason for deferring. This is borrowed directly from ANT's waiver pattern (see [[MVC Pattern from RIME TRL ANT]] §"From ANT — the waiver / deferred-judgment pattern"). The deferral is *not* a yes. It surfaces in the next audit as a known open judgment, attributable to the engineer who deferred, with the reason on record.

The third response is the load-bearing one. Without it, the operational pressure of "just clear the prompt" pushes engineers toward fake attestation. With it, declining-for-now has a first-class, audit-visible form — a refusal to attest, named and reasoned, rather than the absence of one.

## Batch commit semantics

`flexo-rtm commit` packages the working-set diff and pushes it as **one** Flexo transaction. All-or-nothing: model edits, evidence references, attestation triples, transcript fragments, scope metadata, and provenance activity IRIs all land together or none of them do. Partial commits are forbidden by interface contract F1 ([[Design Spec]] §5.2).

The same operation produces a git commit capturing the operational serialization of the working set, plus any out-of-band data references (simulation results, CAD exports) as git-tracked artifacts. If the Flexo transaction fails, the git commit is not made; if the git commit fails — a signing failure, the pre-commit approver-IRI hook blocking — the Flexo transaction is rolled back. Both stores stay co-versioned because the operational layer treats them as one transactional boundary, per [[Flexo Git Coexistence]] and Storage Layer Flexo Conventions.

There is no commit in which the model says one thing and the attestation graph says another about that same model state — the boundary makes them inseparable.

## Offline use

Between `checkout` and `commit`, no operation in the authoring loop requires Flexo to be reachable. SHACL validation runs against the in-memory working set. The skill catechisms run locally. Pydantic serialization and TTL writes are local file operations. The pre-commit hook reads the local registry snapshot. The git operations are local.

This matters because the institutional contexts `flexo-rtm` targets — defense, aerospace, regulated industry — routinely involve intermittent connectivity, air-gapped review sessions, and offsite reviews. An engineer can `checkout` before a flight, edit and draft attestations on a plane, and `commit` when they land. The commit is the same commit regardless of when in wall-clock time it lands relative to the work. The constraint is that SHACL shapes and the approver registry must ship with checkout — both are scoped named graphs by design.

## Determinism on the operational write path

Every operational write follows the stack inherited from [[MVC Pattern from RIME TRL ANT]]: Pydantic models in memory → RDFLib graph builder → deterministic Turtle on disk. Same model instances produce byte-identical Turtle. The CI gate diffs `git status` after recompiling from the Pydantic state; any non-empty diff is a determinism regression and fails the build.

Without this, the working-set TTL drifts every time it is recompiled and the engineer cannot tell whether a diff reflects a real edit or a serializer reorder. With it, the diff is *zero or meaningful*. The CI check on the operational serialization is the invariant that keeps the operational layer trustworthy as the substrate for the storage layer's atomic commits.

## A natural workflow

What this discipline buys, in practice, is a workflow native to the engineer's existing tools:

1. The engineer opens their SysMLv2 modeling environment and edits a Part definition — say, refining the mass budget on an ADCS reaction wheel.
2. They run a simulation. The result is written to the working tree as a file plus a triple referencing it.
3. They draft an evidence note — a short markdown block plus a reference to the simulation result and the Part it validates.
4. They invoke `flexo-rtm commit`. The skill walks the catechism: *Is this evidence adequate for a torque-margin claim? Is it sufficient given the worst-case maneuver envelope? Who is approving?* The engineer answers each prompt and signs as themselves.
5. A single transaction lands: the model edit, the simulation result reference, the evidence note, the adequacy and sufficiency attestations with verbatim justifications, the named-approver binding, the scope metadata, and the provenance activity — all co-versioned, locally on git and authoritatively on Flexo, atomically.

The engineer did not learn a new database. They did not wait on a remote validation. They did not type an approver name into a free-text field. The model and the audit trail moved together because the operational layer enforced — invisibly — that they could not move apart.

## See also

- [[Design Spec]] §5.1 — the operational layer in the three-layer architecture
- [[MVC Pattern from RIME TRL ANT]] — the inherited skill + CLI + deterministic-Turtle pattern
- [[Human-AI Accountability]] — why the skill never picks the judgment call
- [[Aspect Coverage with Adequacy and Sufficiency]] — the substance of the adequacy/sufficiency prompts
- [[Attestation Infrastructure in v0.1]] — SHACL shapes that gate the judgment moments
- [[Flexo Git Coexistence]] — why the commit step writes to both stores atomically
