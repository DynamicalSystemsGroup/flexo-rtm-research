<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Profile Mechanism

A **profile** in `flexo-rtm` is a named SHACL file (or composable bundle of SHACL files) that the oracle loads on demand via `--profile=<name>` and applies as additional constraints at certification time. Profiles let adopters dial constraint strictness up or down without forking the ontology, without rewriting their data, and without re-issuing previously valid certifications. They are the single knob by which the oracle goes from "minimal structural check" to "publish-ready interop bundle with full attestation hygiene."

## What a profile is

Mechanically, a profile is:

- A `.shacl.ttl` file living at `ontology/profiles/<name>.shacl.ttl`
- Loaded by the oracle when `--profile=<name>` is supplied on the CLI
- Combined with the always-on core SHACL shapes (the ones that gate writes at the storage layer and that define the [[Certification Predicate]])
- Reported by name and version into the certification transcript so a verifier can reproduce the exact constraint set used

If a profile is not requested, none of its shapes are evaluated. Profile shapes never silently apply; the transcript records which profiles were active, and re-running the oracle without them is a different (and recorded) check.

## Orthogonal to Scope

Profiles are deliberately separate from **Scope** (see [[Analysis Layer Scope Algebra]]):

- **Scope = data selection.** Which named graphs and which subset of triples does the oracle reason over?
- **Profile = constraint selection.** Which SHACL shapes apply to that data?

The two axes vary independently. The same Scope can be evaluated under several different profiles in a single CI run, and the same profile can be applied to several Scopes (e.g., per-subsystem rollups versus whole-system). This orthogonality keeps profiles from leaking into the data model and keeps Scope from leaking into the contract model. Both choices appear in the transcript; neither is implicit.

## Profile composition

The oracle accepts a comma-separated list:

```
flexo-rtm certify --scope=subsystem-A --profile=oslc-rm-roundtrip,sysmlv2-anchored,attested-satisfies
```

All shapes from all listed profiles are loaded and applied **conjunctively**: every shape must pass. SHACL semantics resolve overlap naturally — if two profiles constrain the same node, the most restrictive shape wins because the conjunction is what the oracle reports. There is no ordering effect and no precedence rule to memorize; profiles are sets, not stacks.

This composability is what makes the mechanism worth its weight. Adopters do not need to maintain a combinatorial matrix of profiles for every workflow stage; they compose the small set they need at the moment of certification.

## Profiles `flexo-rtm` ships in v0.1

Two families ship in v0.1: **interop / structural** profiles and **attestation / supply-chain** profiles.

**Interop and structural profiles**

- `oslc-rm-roundtrip` — the SHACL contract that must hold for the active graph to losslessly round-trip through the [[OSLC RM Adapter Contract]]. Enumerates required predicates, link types, and identity preservation rules.
- `oslc-qm-roundtrip` — same property, but for the [[OSLC QM Adapter Contract]].
- `sysmlv2-anchored` — every `rtm:Artifact` (and every typed requirement) dereferences to a corresponding `omg-sysml:` IRI within scope; sufficient for SysMLv2 anchoring claims (see [[OMG SysMLv2]] and [[External URI References]]).
- `incose-aligned` — informative shapes that flag missing INCOSE concept alignment (non-blocking by default; reports as warnings unless escalated).

**Attestation and supply-chain profiles**

These are described in detail in [[Attestation Infrastructure in v0.1]] and [[Signed Envelopes and Established Standards]]; they are toggleable so adopters can adopt them as their workflow matures:

- `attested-satisfies` — every `rtm:satisfies` triple must carry a corresponding `rtm:SatisfactionAttestation`.
- `attested-adequacy` — every `rtm:satisfies` triple must additionally carry an `rtm:AdequacyAttestation` for the satisfying artifact.
- `attested-sufficiency` — same for sufficiency (per [[Aspect Coverage with Adequacy and Sufficiency]]).
- `aspect-coverage` — multi-aspect requirements must carry attestations for every declared aspect.
- `signed-commits` — every attestation triple must originate from a GPG/SSH-signed git commit.
- `data-integrity-attestations` — every `rtm:Attestation` must carry a valid `sec:proof`.
- `dsse-activities` — every `rtm:Activity` that emits attestations references a DSSE-enveloped in-toto attestation.
- `cosign-images` — every `rtm:hasOCIImage` reference carries a verifying `rtm:cosignBundle`.
- `rekor-transparency` — every attestation has a corresponding Sigstore Rekor transparency-log entry.
- `strict-provenance` — upgrades activity-provenance warnings (missing `rtm:hasGitCommit` or `rtm:hasOCIImage`) to errors.

## Use case examples

A few canonical compositions show how the algebra works in practice:

- **"Certify with OSLC-RM compatibility"** → `--profile=oslc-rm-roundtrip`. The smallest contract that guarantees a downstream OSLC-RM consumer can pull the certified bundle without information loss.
- **Pre-publication composite** → `--profile=oslc-rm-roundtrip,oslc-qm-roundtrip,sysmlv2-anchored,attested-satisfies,signed-commits`. Everything an external reviewer would want before the artifact leaves the organization: structural interop on both adapter sides, SysMLv2 anchoring, attested satisfactions, and signed git provenance.
- **Internal-only minimal check** → `--profile=sysmlv2-anchored`. A team running daily CI on an internal model does not need OSLC roundtrip or attestation hygiene; they only want to know their requirements are anchored to the SysMLv2 model.
- **Maturing a workflow** → start with `oslc-rm-roundtrip`, add `attested-satisfies` once approvers are in place, then add `signed-commits` once the team has GPG/SSH keys provisioned, then add `data-integrity-attestations` once the VC tooling is wired up. Each step is one shape file and a flag change.

## Authoring profiles

Authoring a profile **is** authoring SHACL. There is no DSL above SHACL, no profile metalanguage, and no compilation step. To add a new profile:

1. Write the SHACL file at `ontology/profiles/<name>.shacl.ttl`.
2. Co-locate a brief README in the same directory documenting what the profile enforces, what gap codes it can surface, and what its intended use case is.
3. Register the profile in the oracle's profile registry (a single Turtle file listing profile IRIs and their source files).
4. Add at least one passing fixture and one failing fixture under `tests/conformance/profiles/<name>/`.

Because profile content is SHACL, the same authoring tools, the same linting, and the same reasoning apply uniformly. There is nothing profile-specific to learn beyond the file-system convention. See [[Layered Ontology]] for where profiles sit in the overall ontology stack.

## Profile versioning

Profile IRIs include a version segment: `rtm:profile/oslc-rm-roundtrip/1.0`. The version is recorded in the certification transcript alongside the profile name, so a verifier reproducing a certification reproduces the exact shape set that was active.

The versioning rule is conservative: a profile author can publish `oslc-rm-roundtrip/1.1` whenever they want, but `1.1` is a **new IRI** and does not invalidate any certification artifact that was issued against `1.0`. Old certifications continue to verify against the SHACL bundle they recorded; new certifications opt in to the new version when their workflow is ready. This avoids the failure mode where a profile patch silently invalidates a published certification.

For breaking changes (a shape becomes strictly stronger), the author bumps the major segment: `oslc-rm-roundtrip/2.0`. The 1.x line can be archived but remains resolvable; the transcript continues to point to it for historical certifications.

## Cross-references

- [[Layered Ontology]] — where profiles live in the ontology stack
- [[OSLC RM Adapter Contract]] — what `oslc-rm-roundtrip` enforces
- [[OSLC QM Adapter Contract]] — what `oslc-qm-roundtrip` enforces
- [[Analysis Layer Scope Algebra]] — the orthogonal data-selection axis
- [[Attestation Infrastructure in v0.1]] — the attestation profile family
- [[Signed Envelopes and Established Standards]] — the supply-chain profile family
- [[External URI References]] — how profile-gated dereferenceability is recorded
- [[Design Spec]] §6.4 — normative reference for the mechanism
