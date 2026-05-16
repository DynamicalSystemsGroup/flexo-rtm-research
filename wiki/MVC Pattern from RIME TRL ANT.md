<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# MVC Pattern from RIME TRL ANT

> **Status:** Synthesis of the operational MVC pattern shared by three reference implementations — `RIME-product-docs`, `trl-knowledgebase`, and `ant-rdf` — and how `flexo-rtm` inherits, adapts, and extends it. This page makes the inheritance explicit so v0.1 reuses what works and consciously diverges where Flexo storage demands it. See [[Design Spec]] §5.1.

The three reference repos converged on a stable shape independently: a thin Pydantic-mediated CLI on top of a deterministic RDF serializer, driven by role-scoped Claude Code skills with path-globbed permissions, human in the loop at every validation moment. That shape is what `flexo-rtm` reuses for its [[Operational Layer UX Discipline]] critical path. The place it must diverge — storage to Flexo MMS rather than git-tracked TTL files — is the deliberate tension called out below.

## The MVC flow (canonical pattern)

```
human operator → skill (with frontmatter constraints)
               → cli_write (Pydantic → RDF deterministic Turtle)
               → quadstore (local TTL files in these examples)
               → cli_read (Pydantic facade over RDF)
               → edited_content (markdown brief compiled from RDF)
               → human review → cli_commit (skill orchestrates git)
```

Read this as a single round-trip per user intent. The human speaks plain language; the skill walks the catechism appropriate to the role and emits structured CLI calls; the CLI is the *only* mutator of the RDF; the RDF is recompiled to Markdown; the human reviews; if accepted, the skill (not the CLI) orchestrates the commit. The human never hand-edits TTL — that discipline is what makes the determinism invariant trustworthy.

The "M" is the Pydantic models and their RDF-shape duals; the "V" is the compiled Markdown brief; the "C" is the skill + CLI pair — skill as human-facing controller (natural language → CLI invocation), CLI as machine-facing controller (CLI invocation → RDF write). MVC is loose here; the point is explicit separation of authoring surface, persistent state, and presented projection, mediated by skill-and-CLI rather than direct keystrokes against TTL.

## Skill structure conventions

Each repo ships a small number of role-scoped skills in `.claude/skills/`:

- **One directional skill per role.** RIME has four (`rime-mgmt`, `rime-gvrn`, `rime-pm`, `rime-reconcile`). ANT has three (`ant-mgmt`, `ant-gvrn`, `ant-ingest`). TRL ships a single monolithic `trl-cli` — the less-granular extreme of the same pattern.
- **Frontmatter declares the role surface.** Every skill carries `name:`, `description:` (with explicit Triggers — phrases the user might say that should invoke this skill), and crucially `allowed-paths:` / `forbidden-paths:` globs that scope what the skill can write. Example from `rime-mgmt`: `allowed-paths: ["instances/**"]`, `forbidden-paths: ["ontology/**", "src/**", ".github/**", ".claude/**"]`. The globs are the skill's effective surface — they keep an authoring skill out of the ontology and a governance skill out of instance data.
- **The skill is the human's natural-language interface.** It never edits TTL by hand. It walks the catechism (plain-language questions whose answers map to required fields on the relevant shape), then emits a CLI call. ANT's `ant-mgmt` puts it bluntly: "Claude is the translator between natural language and CLI invocations — it does not arbitrate field truth."
- **Skill routes to skill at role boundaries.** When `rime-mgmt` discovers a needed ontology change, it stops and routes to `rime-gvrn`. When `rime-reconcile` resolves drift toward TTL edits, it routes back to `rime-mgmt`. No skill silently crosses its surface.

## CLI conventions

All three repos use Typer with a single binary plus subcommands:

- **One binary per repo:** `uv run rime`, `uv run ant`, `uv run trl`.
- **Stable verb set:** `verify` (SHACL gate), `compile` (RDF → Markdown brief), `new-record` (create), `edit-record` (targeted edit), plus domain-specific actions (`reconcile scan/show/apply` in RIME, `ingest notes/upload` in ANT, `new-assessment` in TRL). The verbs are shared because the shape of the work is the same: validate, project, author, edit, audit.
- **Two input modes:** flag-driven (every model field maps to a `--flag`) and interactive (prompts for every field; enums become numbered menus; cross-reference fields offer graph-backed pick-lists). Both produce the same TTL.
- **CLI writes RDF and returns content; the skill orchestrates git.** This is the load-bearing separation. The CLI never runs `git commit` — it writes a file and prints what changed. The skill decides whether to stage, compile the brief, commit, push. Commit is a deliberate audit-disciplined act distinct from the RDF write that preceded it.

## Deterministic Turtle

All three repos share one serialization stack: Pydantic v2 models in `models.py`, an RDFLib graph builder in `serialize.py` (with `_add_*` per-class dispatch helpers), and a loader in `graph.py` that merges shared entities and resolves cross-graph references. The serializer is byte-deterministic — same model instances produce byte-identical Turtle. CI verifies by recompiling and diffing.

This is RIME's D15, TRL's "determinism invariant," and the unstated baseline of ANT. Without determinism the round-trip TTL → Markdown → human edit → CLI re-write → TTL silently drifts and the CI gate oscillates; with it, the diff between "what's checked in" and "what re-compiles" is *zero or meaningful* — never noise. The CI rule "commit source and compiled together" depends on it.

Atomicity rides on the same stack: every new OWL class implies a matching Pydantic model and a `serialize.py` dispatch update, all in one commit. The Pydantic class, the OWL class, and the serializer dispatch entry are three views of the same thing and they must move together.

## Quadstore in the examples — and the deliberate tension with `flexo-rtm`

In all three reference repos, the **quadstore is local TTL files**. No HTTP. No external store. `instances/**/*.ttl` is the canonical state; rdflib loads the union on demand; SHACL gates run against the in-memory graph; the git working tree is the persistent backing store and `git commit` is the persistence event.

This is the most important variation `flexo-rtm` must reckon with. Flexo MMS is an authoritative HTTP-backed quadstore with named graphs, branching, and versioning — fundamentally a different storage substrate. The operational shape survives the substitution because the *working set* is still a local rdflib in-memory dataset; the difference is what "commit" means at the end. **In RIME/ANT/TRL, commit is `git add && git commit`. In `flexo-rtm`, commit is a Flexo transaction + a git commit, atomically.**

This is a deliberate tension. The reference repos teach the operational shape; Flexo storage is the production reality. [[Design Spec]] §5.1 is where the inherited pattern lives unchanged; §5.2 is where Flexo extends it.

## How `flexo-rtm` adapts the pattern

The adaptation is targeted, not a rewrite. The operational layer keeps the pattern intact; only the storage layer extends.

- **Operational layer (unchanged shape).** Local rdflib in-memory dataset per checkout; fast SHACL gating because the working set is small (~hundreds of triples); Pydantic → RDF deterministic serialization; CLI writes locally and returns content. The engineer in `flexo-rtm` should feel the same weightlessness an ethnographer feels in ANT or a PM feels in RIME — no network latency on the authoring loop.
- **Storage layer (extended).** The "commit" step pushes the working set to Flexo MMS as a transaction, not just `git add && git commit`. The transaction is atomic across named graphs (model, attestation, transcript, evidence references). The git commit captures the operational serialization of the same state — the two version together. See [[Approver Binding via Git]] for why git-tracked signing materials still ride alongside Flexo storage.
- **Same skill structure.** `flexo-rtm-mgmt` (model + requirements authoring), `flexo-rtm-attest` (named-approver attestation capture for satisfaction / adequacy / sufficiency), `flexo-rtm-reconcile` (drift between Flexo branches and git tree, between OSLC-RM external sources and the local RDF, between attestations and the model state they witnessed). Each carries `allowed-paths:` / `forbidden-paths:` scoping.
- **Same Typer binary.** `uv run flexo-rtm <verify | compile | checkout | commit | certify | attest | reconcile | …>`. The verb set extends to cover Flexo (`checkout` pulls a branch + working-set materialization; `commit` is the atomic Flexo+git push), the certification flow (`certify` runs the oracle over a scope), and attestation capture (`attest` records a named approver's claim with binding evidence). The shape — single binary, subcommands, CLI writes and the skill commits — is preserved.

## Per-repo notable variations

The three repos differ in ways that matter for what `flexo-rtm` should and shouldn't inherit:

- **RIME** ships the most fully developed pattern: tier-branch git push allowlist (`gvrn/*`, `mgmt/*`, `ctrl/*` namespaces gate which work pushes where); ADR-0003 audit discipline (every gh write goes through a `rime issue …` wrapper that pre-validates labels and tracks); an explicit drift-reconciliation skill that surfaces options but never picks. Maximally factored.
- **TRL** ships a single monolithic skill (`trl-cli`). It works because TRL has one role (chief engineer as understudy/secretary) and a narrow verb set (`verify` / `new-assessment` / `compile`). The variation teaches that role granularity is a function of how many distinct human roles the repo serves, not a fixed convention.
- **ANT** ships a waiver model for Tier-2 governance: SHACL warnings the ethnographer wants to acknowledge get an append-only `instances/waivers/<date>-<slug>.ttl` record with a verbatim justification, via `ant waive add`. Tier-1 violations are not waivable. Structurally a deferred-judgment pattern — the system records that judgment was declined-for-now with a justification, rather than forcing a yes/no.

## What `flexo-rtm` borrows from each

- **From RIME — skill-per-role granularity and the reconcile pattern.** `flexo-rtm` has at least three distinct roles (model authoring, attestation capture, drift reconciliation against OSLC-RM external sources), so RIME's role decomposition fits better than TRL's monolith. The reconcile pattern — facilitator skill that surfaces options and captures the human's verbatim reason as `mosa:justification`, never picking — is directly applicable to OSLC-RM drift: "is OSLC right or is the model right?" is exactly the decision the skill must never make.
- **From ANT — the waiver / deferred-judgment pattern.** [[Design Spec]] already makes `rtm:DeferredJudgment` a first-class state. ANT's waiver model is the operational shape: an append-only record with a verbatim human justification, gated by tier (some constraints are not waivable). `flexo-rtm` adopts it directly — adequacy and sufficiency attestations the engineer wants to defer get a `rtm:DeferredJudgment` record with a verbatim reason, rather than a fake approval.
- **From TRL — the determinism check, not the monolithic skill.** TRL's "round-trip verification" (recompiled Markdown must match the author's intent — diff again to confirm) is the most explicit articulation of the determinism invariant. `flexo-rtm` inherits the diff-on-recompile CI gate. It does **not** inherit the single-skill structure — the role distinction between model authoring and attestation capture is too important to collapse.

## Operational UX implications for `flexo-rtm`

Inheriting the pattern locks in specific UX properties that [[Operational Layer UX Discipline]] expands on:

- **In-memory local working set per checkout.** The authoring loop never blocks on Flexo. SHACL runs against rdflib in-memory; the only network call in the loop is the eventual atomic commit.
- **SHACL gates feel instant.** Because the working set is small (~hundreds of triples, not the whole complex), evaluation is sub-second. This is what makes the gate tolerable on every write rather than a once-an-hour batch.
- **Skill prompts at judgment moments.** "Is the model adequate?" "Is the evidence sufficient?" "Who is approving?" The skill stops and asks; it never invents an approver, never assigns an adequacy claim, never silently elevates a SHACL warning into a pass. See [[Human-AI Accountability]] for why the asymmetry is structural.
- **Batch commit to Flexo + git atomically.** The commit step is the only non-local event in the loop, atomic across both stores. If the Flexo transaction fails, the git commit doesn't land; if the git commit fails (signing, hook, pre-commit verification), the Flexo transaction is not committed. Both stores stay co-versioned because the operational layer treats them as one transactional boundary.

The cumulative effect: an engineer should feel like they are editing a small, fast, locally-owned RDF graph that occasionally synchronizes to a shared authoritative store — not operating a remote database through a thin client. That phenomenology is what the three reference repos got right, and what the Flexo-storage extension must not break.

## See also

- [[Design Spec]] §5 — the three-layer architecture this pattern lives inside
- [[Operational Layer UX Discipline]] — UX commitments the inherited pattern enforces
- [[Human-AI Accountability]] — why the skill never picks the judgment call
- [[Approver Binding via Git]] — why git stays load-bearing alongside Flexo storage
