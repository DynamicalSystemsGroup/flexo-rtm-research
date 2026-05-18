<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-032: Methodology Agnosticism as Foundational Axiom

**Status:** Accepted
**Date:** 2026-05-18
**Deciders:** Michael Zargham
**Related:** [[ADR-003 Topological Framework Documented as Future Work]]; [[ADR-020 Vocabulary Alignment with Zargham 2026]]; [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]]; [[ADR-030 Polycentric ASOT Authority Model]]; [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]; [[Mission and Thesis]]; [[Topological Framework Future Work]]; [[Design Spec]]

## Context

Several locked decisions in v0.1 — the polycentric ASOT model ([[ADR-030 Polycentric ASOT Authority Model]]), the optional lifecycle vocabulary ([[ADR-029 Engineering Lifecycle Stages as Scope Metadata]]), the attestation status that handles regression locally ([[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]) — share a common underlying principle: `flexo-rtm` is **methodology-agnostic**. Different programs use different assurance methodologies (INCOSE / ISO 15288, DO-178C, NASA Phase A–F, ISO 9001, Agile, MIL-STD-498, customer-program-specific milestones, or no formal methodology at all), and the framework should support all of them on the same footing rather than privileging any one.

The methodology-agnosticism axiom has not been stated as a first-tier design principle in its own right. As a result, accumulated wiki drift has subtly positioned the **topological framework** articulated in Zargham (2026) as the planned future of `flexo-rtm` — "what v0.1 defers until the registry conversation happens." That framing overstates the relationship. The topological framework is a related research line with shared philosophical kinship (named-approver discipline, structural accountability, V&V distinction); it is not what `flexo-rtm` is for. By definition, any topological audit operates **downstream** on data `flexo-rtm` produces; the audit does not produce the data.

This ADR makes the axiom explicit, names what `flexo-rtm` IS, and clarifies the relationship to the topological framework so future contributions do not drift back into "topology is the eventual goal" framing.

## Decision

**Methodology agnosticism is a foundational design axiom for `flexo-rtm`.** Concretely:

1. **What `flexo-rtm` IS.** A working tool for **bidirectional requirements traceability that is reduced to practice**, plus a **record of human signers where judgment is rendered**. Both halves are settled: forward and backward traces with coverage statistics are decades of established RTM practice (Doors, Jama, Polarion, OSLC-RM); structural enforcement of named approvers via SHACL is settled engineering practice grounded in W3C Verifiable Credentials Data Integrity, SLSA in-toto attestations, Sigstore + Fulcio, git GPG/SSH commit signing, NIST SP 800-63, and W3C SHACL. `flexo-rtm` composes these into RDF + named graphs for the SysMLv2 use case. Nothing in this scope requires a new research result.

2. **What `flexo-rtm` does NOT commit to.** Any specific assurance methodology beyond the bidirectional-traceability + named-signers floor. INCOSE / ISO 15288 stages are one example of an engineering lifecycle vocabulary (see [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]] for the methodology-neutral framing); DO-178C, NASA Phase A–F, ISO 9001, Agile, MIL-STD-498, and custom phasing participate on equal footing. The topological framework is one example of an assurance methodology that some adopters may find useful; the framework is not required and the framework is not what `flexo-rtm` is for.

3. **The topological framework's relationship to `flexo-rtm`.** Zargham (2026), *Formalizing Document Assurance: A Topological Framework for Verification, Validation, and Human Accountability*, articulates a typed simplicial complex framework for assurance that shares philosophical elements with v0.1's accountability discipline — both treat named-human approval as structurally load-bearing rather than recommendation-level. The framework is a **separate, related line of inquiry**, not yet reduced to practice (the registry-of-pre-approved-types question, the alternative-invariants question, and the recursive-completeness question are all open research). If the framework matures, it operates as **downstream analysis** on data `flexo-rtm` captures — taking the traceability and attestation graph as input and computing additional structural properties over it. `flexo-rtm` provides the substrate; the framework would consume the substrate. The two are not the same thing, and the substrate does not depend on the analysis.

4. **Vocabulary that aligns with the topological framework remains in v0.1 ontology** (per [[ADR-020 Vocabulary Alignment with Zargham 2026]]) because the alignment is cheap, the philosophical kinship makes some shared terms useful (Guidance, AdequacyCriteria, SufficiencyCriteria, Aspect), and adopters who want to feed their data into a topological analysis later can do so without translation. This is **forward compatibility for an optional analysis path**, not "carrying forward the v0.1 vocabulary to its eventual destination."

5. **Other methodologies receive the same forward-compatibility treatment.** An adopter wiring `flexo-rtm` to a SLSA supply-chain audit pipeline, a Goal Structuring Notation assurance case builder, an ARP4754A airborne-systems audit, or a custom in-house analysis layer benefits from the same substrate. `flexo-rtm` does not privilege one downstream-analysis target over another.

## Consequences

### Positive

- **The framework's relationship is honest.** Adopters reading the wiki understand that `flexo-rtm` is a working tool that stands on settled practice, not a half-built prototype on the way to a topological audit. The topological work is one related research line with philosophical kinship, not the destination.
- **Methodology choice is the adopter's, not the framework's.** Programs already running DO-178C, NASA Phase A–F, ISO 9001, Agile, MIL-STD-498, or custom phasing adopt `flexo-rtm` without translating their methodology into a privileged one. This is consistent with the polycentric ASOT model ([[ADR-030 Polycentric ASOT Authority Model]]) and the attestation-status mechanism ([[ADR-031 Attestation Status Pass Fail Deferred Deprecated]]).
- **The research line is unburdened.** The topological framework progresses on its own honest timeline (the registry question, the invariant question, the recursive-completeness termination) without `flexo-rtm` adoption depending on its readiness, and without `flexo-rtm`'s release schedule pressuring the research.
- **Vocabulary alignment is preserved.** Guidance, AdequacyCriteria, SufficiencyCriteria, and Aspect remain in v0.1 ontology as forward-compatible alignment to the topological framework's vocabulary (per [[ADR-020 Vocabulary Alignment with Zargham 2026]]); adopters who later run topological analysis benefit from the alignment, and adopters who never do are unaffected.

### Negative / Tradeoffs

- **Some readers may have expected `flexo-rtm` to be "the topological framework, eventually."** The wiki has occasionally implied that framing; this ADR makes the actual scope explicit. Readers expecting an eventual topology-first product will need to recalibrate.
- **A lower-ambition framing.** "Bidirectional traceability + named signers" is a deliberately modest scope. The user-facing tradeoff: a more ambitious scope claim would be more rhetorically impressive but would not be honest about what `flexo-rtm` actually delivers in v0.1 (or what it needs to deliver to be useful in practice).

### Neutral

- **The existing locked decisions (ADRs 029, 030, 031) are all specific applications of this axiom.** This ADR names the underlying principle they share; it does not change any of them.
- **The [[Topological Framework Future Work]] page remains in the wiki** as the canonical reference for the related research line. Its framing is updated to match this ADR: the page documents the topological framework as a related line of inquiry, not as flexo-rtm's planned destination.

## Alternatives Considered

- **Leave the axiom implicit.** Rejected. The wiki has accumulated drift implying topology is the planned destination of `flexo-rtm`; without an explicit axiom, that drift recurs.
- **Commit `flexo-rtm` to the topological framework as the eventual audit primitive.** Rejected. The framework has open research questions (registry governance, alternative invariants, recursive-completeness termination) that are not on `flexo-rtm`'s critical path. Coupling the framework's research timeline to `flexo-rtm`'s release timeline harms both.
- **Drop vocabulary alignment with Zargham 2026.** Rejected. The alignment is cheap (a handful of class names), the philosophical kinship makes some shared terms useful (Guidance, AdequacyCriteria, SufficiencyCriteria), and adopters who later run topological analysis benefit from the forward compatibility. Dropping the alignment would pay no benefit and would lose the easy interop with that research line.
- **Commit to a different specific methodology** (DO-178C, NASA, ISO 9001, etc.). Rejected for the same reason: privileging any one methodology shrinks the adopter set unnecessarily. Methodology-agnostic substrate + adopter-specific downstream analysis is the right cut.

## Implementation Notes

This ADR is a framing decision rather than a code change. Its consequences land as wiki edits across many pages, removing language that positions the topological framework as `flexo-rtm`'s eventual destination and replacing it with language that names it as one related line of inquiry. Specifically:

- [[Mission and Thesis]] Proposition 6 reframed to lead with methodology agnosticism; the topological framework moves from "future work, not v0.1" to "one example of an assurance methodology `flexo-rtm` does not commit to."
- [[Topological Framework Future Work]] opening reframed: the "original aspiration was to make the typed simplicial complex the primary audit primitive" statement is excised (it was a misinterpretation; that was never the aspiration). The page is repositioned as the canonical reference for the related research line.
- Map of Content, Gap Taxonomy, ADR-005, ADR-017, ADR-020, ADR-021, ADCS Prototype Lessons, External URI References, Verifiable Self-Certification, and similar pages sweep-updated: "future framework" → "topology line of inquiry / downstream analysis"; "when the framework lands" → "if the framework matures, as one downstream analysis path."
- v0.1 ontology continues to carry the Guidance / AdequacyCriteria / SufficiencyCriteria / Aspect / AssuranceComplex / AssuranceFace / AssuranceTriple vocabulary, framed as forward-compatible alignment to the topological framework should adopters choose to run downstream analysis under it.

## References

- [[Design Spec]] §1 (Mission), §3 (Scope-reducing assumption), §4.10 (Topological framework as related research line, not flexo-rtm's destination)
- [[Mission and Thesis]] — Proposition 6 reframed per this axiom
- [[Topological Framework Future Work]] — the canonical reference for the related research line, reframed per this ADR
- [[ADR-003 Topological Framework Documented as Future Work]] — the deferral ADR; consistent with this axiom (defers a related line of inquiry, does not promise to converge on it)
- [[ADR-020 Vocabulary Alignment with Zargham 2026]] — vocabulary alignment as forward-compatible interop, not as commitment to the framework
- [[ADR-029 Engineering Lifecycle Stages as Scope Metadata]] — methodology-neutral lifecycle stages; specific application of this axiom
- [[ADR-030 Polycentric ASOT Authority Model]] — polycentric institutional topology; the framework cooperates across methodologies
- [[ADR-031 Attestation Status Pass Fail Deferred Deprecated]] — methodology-neutral regression handling; specific application of this axiom
- Zargham (2026), *Formalizing Document Assurance: A Topological Framework for Verification, Validation, and Human Accountability* — one related line of inquiry; philosophically aligned with v0.1's accountability discipline; not `flexo-rtm`'s destination
