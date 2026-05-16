<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Approver Binding via Git

> The mechanism that connects an `rtm:approvedBy` IRI inside the RDF graph to the human being who actually authored the commit that wrote that triple. Schema enforcement ([[Attestation Infrastructure in v0.1]]) guarantees that every attestation carries an approver IRI; this page specifies how the engineer's identity at commit time is verified to match that IRI. Normative source: [[Design Spec]] §4.3 (attestation infrastructure + git pre-commit hook) and §4.6 (signed envelopes — git GPG/SSH signing). Acceptance criteria: §9.A.3 **I1** (schema-enforced approver), **I7** (git approver binding under `signed-commits` profile), **I8** (local & federated reproducibility of identity facts).

## Why this page exists

`rtm:Attestation` already requires `rtm:approvedBy <IRI>` by SHACL — that is **I1** from [[Design Spec]] §9.A.3 and the structural guarantee detailed in [[Attestation Infrastructure in v0.1]]. The schema gate rejects any attestation without a named approver. But the schema alone cannot tell whether the engineer who typed `rtm:approvedBy :alice` into a turtle file is actually `:alice`. That second question — *did the named approver actually approve?* — is what the git binding answers, and it answers it without inventing crypto or running its own identity service. The mechanism composes two facts that already exist in any normal engineering workflow: git knows who authored a commit, and the identity projection ([[Identity Boundaries and Policy Projections]]) knows how to dereference an approver IRI to a person with a GitHub handle, an email, and (under the `signed-commits` profile per [[Signed Envelopes and Established Standards]]) a published signing-key fingerprint. The binding compares the two.

## The binding chain — four steps

The full chain from "an attestation triple exists in the graph" to "the audit can name the human who approved it" runs as follows:

1. **Schema gate.** Every `rtm:Attestation` instance has `rtm:approvedBy <IRI>` because SHACL refuses to accept it otherwise (`sh:minCount 1`, `sh:nodeKind sh:IRI`). This is **I1**. See [[Attestation Infrastructure in v0.1]] for the shape and the rationale that the gate is structural rather than advisory.
2. **Identified commit.** The git commit that introduces the attestation triple into the graph is authored under the engineer's identified git identity. At baseline (`signed-commits` profile inactive), "identified" means `git config user.email` matches the approver IRI's projection. Under the `signed-commits` profile (per [[Design Spec]] §4.6), the commit must additionally carry a valid GPG or SSH signature whose key fingerprint matches the approver's published key.
3. **Pre-commit hook verification.** A local pre-commit hook reads the working diff, finds any new `rtm:Attestation` subjects with their `rtm:approvedBy` triple, dereferences each approver IRI to the recorded identity projection, extracts the expected committer identity (GitHub handle and/or email; key fingerprint under `signed-commits`), and compares to the actual committer that git is about to record. On mismatch the hook rejects the commit with a message naming the specific attestation and the mismatch.
4. **GitHub Actions defense-in-depth.** A required GitHub Actions check re-runs the same verification at PR time against the PR's diff. The hook is convenience-and-fast-feedback; the Actions check is the gate that cannot be bypassed by skipping the hook or pushing from a workstation where it was never installed. This is **I7** as stated in §9.A.3.

The four steps form a single chain: SHACL guarantees the field exists, the committer's identity carries who wrote the change, the local hook compares them eagerly, and the CI check compares them again where it cannot be skipped.

## Identity resolution: from approver IRI to expected committer

The IRI in `rtm:approvedBy` is not magic — it dereferences inside the identity projection vocabulary documented in [[Design Spec]] §4.4 and elaborated in [[Identity Boundaries and Policy Projections]]. The dereference yields either a `foaf:Person` directly or an `org:Membership` whose `org:member` is a `foaf:Person`. The person profile carries the fields the binding compares against:

- `foaf:name` — human-readable name (used in error messages and audit reports)
- `rtm:hasExternalIdentity "github:<handle>"` — the GitHub username
- `rtm:hasExternalIdentity "mailto:<email>"` (or equivalent OIDC-projected email) — the email git uses
- `foaf:openPgpFingerprint` / `rtm:hasSshKeyFingerprint` — the signing-key fingerprints (consulted only when `signed-commits` is active)
- One or more `org:hasMembership` links to `org:Membership` records carrying role and scope assignments (these matter for policy evaluation **I2–I4**, not for the binding itself, but they show up in the audit's "who is this person and what authority did they hold?" rendering)

The projection is a thin RDF view of facts the institution's identity provider already owns; `flexo-rtm` does not authenticate, does not store credentials, does not arbitrate group membership. The git binding's only job is the comparison — *given that the projection says approver IRI X expects committer identity Y, does the current commit's identity equal Y?* This is the same composition discipline described for cryptography in [[Signed Envelopes and Established Standards]]: trust the standards-grade external system; integrate at well-defined seams.

## The pre-commit hook

The hook reads the working diff (the changes the engineer is about to commit) and isolates added or modified triples whose subject is typed `rtm:Attestation` and whose predicate is `rtm:approvedBy`. For each such attestation:

- Resolve the approver IRI against the projection bundled in the repository (or against the projection-cache that the oracle's identity-adapter populated at last refresh per **I5**).
- Read the expected committer identity: GitHub handle from `rtm:hasExternalIdentity`, email from the email-form external identity, and — under `signed-commits` — the published key fingerprints.
- Compare against the current committer from `git config user.email`, the GitHub handle if the local git config records one, and the active GPG/SSH signing key (signature verification under `signed-commits`).
- On mismatch, reject the commit with an explicit error: which attestation subject failed, which approver IRI was asserted, which committer identity was found, and exactly what would need to change for the commit to succeed (set git config, switch signing key, change the approver IRI to the actual reviewer, etc.).

The hook is engineered to be *helpful in the failure path*. Quiet rejection is a failure mode; the surfacing-judgment discipline of [[Operational Layer UX Discipline]] applies — the engineer must be able to read the error and act on it without guessing.

## The GitHub Actions check

At PR time a required check re-runs the same verification against the PR's full diff. The check reads each commit individually (so a PR that touches multiple attestations across multiple commits is verified end-to-end, not just at the merge boundary), resolves the approver IRI against the projection-cache committed to the repository, and confirms identity match. The Actions check additionally:

- Cross-checks GitHub organization membership — the committer's GitHub identity is asked the GitHub API whether they are still a member of the organization recorded in the approver's `org:Membership` (optional but recommended; cheap when the runner is GitHub-hosted with default `GITHUB_TOKEN` permissions).
- Validates that the projection used by the hook is the same projection committed to the repository (no local-only divergence).
- Blocks merge on any mismatch and renders a clear comment naming the attestation, the approver IRI, and the committer identity.

The Actions check is the actual gate — the local hook is fast feedback. **I7** specifies that both verify; both are mandatory under the `signed-commits` profile.

## What happens when AI assists the authoring

LLM-assisted drafting is now routine, and [[Human-AI Accountability]] is the page that says how `flexo-rtm` handles it. The git binding is half the mechanism. The other half is the schema; together they make the human responsibility structural rather than advisory.

The skill ([[Operational Layer UX Discipline]]) helps the engineer draft the attestation — searches related artifacts, drafts the justification, surfaces aspect tags, flags missing references. **The skill cannot author the attestation triple itself.** The triple is committed by the engineer, under the engineer's git identity, and the binding mechanism here verifies that fact every time. Under PROV (per [[PROV EARL GSN P-PLAN]]), the resulting `rtm:Attestation` carries `prov:wasInformedBy` pointing to the AI tool used and `prov:wasAttributedTo` pointing to the human approver IRI — the audit graph records that an AI was consulted, *and* records the named human responsible for the approval. The git binding is what makes the second part non-spoofable: an LLM cannot type `rtm:approvedBy :alice` and have it stick unless the commit actually came from `:alice`'s identified git environment.

## Failure modes — by design, surfaced loudly

The binding is designed so that the failure cases are visible to the engineer and impossible to silently bypass:

- **Engineer has no git identity configured.** Hook fails immediately with setup instructions; Actions check fails with the same. There is no "default to no-identity" path.
- **Engineer commits under a different identity than the approver they typed.** Hook fails with the specific mismatch (asserted approver vs. actual committer). The engineer either changes the approver IRI to themselves (if they really are approving) or stops the commit (if they were drafting on behalf of someone else who must do their own commit).
- **Engineer disables the hook locally.** Actions check still catches it at PR time; merge is blocked. The hook being skippable locally is fine because the gate is the CI check, not the hook.
- **Engineer's git environment is correctly identified but the projection has been tampered with locally.** Actions check compares against the repository-committed projection; local tampering does not pass CI.
- **Engineer uses someone else's signing key (under `signed-commits`).** This is a real security problem outside `flexo-rtm`'s remit — `flexo-rtm` does not arbitrate key custody, it composes the standards (GPG/SSH/Sigstore). Recovery is institutional, not oracular.

In every case the failure is named, attributed, and actionable — not silent.

## What this is NOT

The binding is deliberately scoped narrower than several adjacent things it resembles:

- **Not cryptographic-quality non-repudiation unless `signed-commits` is active.** At baseline, the binding verifies that the committer's git identity matches the approver IRI's projection. This is sufficient for accountability in an institutional setting (the engineer's git identity is institutionally bound). When stronger guarantees are needed, the `signed-commits` profile adds GPG/SSH signature verification per [[Signed Envelopes and Established Standards]]. The profile is composable, not always-on, because not every adopter needs cryptographic-grade signing in v0.1.
- **Not external authority verification.** `flexo-rtm` does not phone the institution's IdP to ask "is `:alice` still authorized?" It compares against the recorded projection-at-cert-time. Authority over identity facts lives in the IdP; [[Identity Boundaries and Policy Projections]] is the page that says why this projection-and-trust discipline is correct rather than insufficient.
- **Not revocation-aware in v0.1.** If an approver leaves the organization the day after attesting, the past attestation is not retroactively invalidated. **I8** is explicit on this: reproduction operates against the recorded projection-at-cert-time, not the live identity provider. Defeaters and SACM-style revocation are v0.2+ work — see [[Topological Framework Future Work]].
- **Not a replacement for the schema gate.** The git binding does not check that the attestation has an approver IRI at all — that is **I1**'s job, enforced by SHACL at write time before git ever sees the change. The binding only checks the *match*; the *existence* is upstream.
- **Not in scope for non-attestation triples.** The binding only fires when the diff introduces an `rtm:Attestation` with `rtm:approvedBy`. Edits to documentation, configuration, vocabulary, or non-attestation triples follow ordinary git review discipline.

## Reading the audit side

The mirror image of the binding is what the audit produces. Every attestation in the certification artifact ([[Verifiable Self-Certification]], [[Storage Layer Flexo Conventions]]) has an approver IRI; every approver IRI resolves inside the bundled projection; every projection entry names the human and their roles and attributes at certification time. The audit report names approvers — by name, not by opaque IRI — and renders the role and scope context the policy evaluation used. Whether the approver had authority at attestation time is answered by re-evaluating policy **I2–I4** against the recorded projection-at-cert-time; this is the projection-as-of-cert-time discipline that X8 in §9.A.5 calls "structural completeness without dereferencing" and that **I8** generalizes to "local & federated reproducibility of identity facts." Identity changes after cert do not invalidate past attestations because the audit reproduces against what was recorded, not against the live IdP — a federation of verifiers, each with read access to subsets of the projection, can each confirm their portion of the audit and the union of their confirmations equals the global one. The git binding is the runtime mechanism; the audit-side reading is the certification-time deliverable that makes the runtime mechanism legible to anyone reading the cert.

## Cross-references

- [[Attestation Infrastructure in v0.1]] — the SHACL shape and the three typed attestation subclasses this binding protects
- [[Human-AI Accountability]] — why named human accountability is structural rather than advisory under AI-assisted authoring
- [[Operational Layer UX Discipline]] — the AI-skill behavior that ensures the human, not the AI, commits the attestation
- [[Verifiable Self-Certification]] — the certification artifact that ships the projection-at-cert-time the binding refers to
- [[Storage Layer Flexo Conventions]] — how the projection and attestations round-trip through Flexo
- [[Signed Envelopes and Established Standards]] — the `signed-commits` profile and the broader principle of composing battle-tested crypto
- [[Identity Boundaries and Policy Projections]] — the four-property boundary discipline, adapter contract, refresh policy, and policy evaluation that this binding sits next to
- [[Design Spec]] — normative source, §4.3 and §4.6 governing this page; §9.A.3 **I1** + **I7** + **I8** as the acceptance criteria
