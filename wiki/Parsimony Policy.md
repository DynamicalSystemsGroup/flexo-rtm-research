<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Parsimony Policy

> **Normative source:** [[Design Spec]] §6.2 (parsimony policy) and §9.A.5 X5 (assembled `rtm.ttl` ≤ 2000 triples; build fails if exceeded). This page is the practitioner-facing explanation of how `flexo-rtm` keeps its ontology surface small, auditable, and reproducible.

## Why parsimony

External vocabularies are large. PROV-O alone defines dozens of classes and properties; SysMLv2's KerML core is larger still; OntoGSN, P-PLAN, EARL, OSLC-RM, OSLC-QM each add their own axiomatization. If `flexo-rtm` loaded all of them wholesale, the working ontology would balloon past ten thousand triples, most of which `flexo-rtm` never references. Three concerns drive the discipline:

- **Performance.** Every triple loaded is a triple traversed during SPARQL evaluation and SHACL validation. The Oracle hot path (workspace, checkout, author, batch, commit — see [[Three-Layer Architecture]]) executes shape validation on every author step. A 2000-triple working ontology validates in milliseconds; a 10,000-triple one does not.
- **Auditability.** Every imported triple is a claim the ontology makes. Importing all of PROV-O means claiming every PROV-O axiom — including ones we do not use, do not understand, and have not validated for our case. A minimal surface keeps every claim deliberate; [[Alignment Strategy]] gets brittle when bound to unused vocabulary.
- **Maintenance.** Vocabularies evolve. Carrying an entire external ontology forward across versions forces us to track changes in terms we never use. A minimal extract is also a minimal upgrade surface.

## Module extraction methods

The ontology community has converged on a handful of techniques for extracting reusable subsets ("modules") from large ontologies. `flexo-rtm` uses three of them in concert.

### MIREOT (Minimum Information to Reference an External Ontology Term)

MIREOT is a term-driven extraction protocol. Given a specified signature — a set of class and property IRIs — MIREOT keeps each term plus a configurable amount of structural context: typically direct superclasses and annotation properties (labels, definitions). It does **not** attempt to preserve logical entailments; it gives you "just enough" of the external ontology to reference its terms meaningfully. Implemented in `robot extract --method MIREOT`. The result is small, readable, and human-checkable, but two entailments that held in the source ontology may not hold in the MIREOT extract.

### SLME (Syntactic Locality-based Module Extraction)

SLME computes a logical module: the smallest subset of axioms that preserves every entailment over the specified signature. The mathematical guarantee — locality-based reasoning is conservative — is what makes SLME suitable when downstream reasoning depends on inherited structure. Two flavors exist:

- **Bottom SLME** preserves entailments about subclasses of signature terms (useful when you import a term and want to reason about its specializations).
- **Top SLME** preserves entailments about superclasses (useful when you import a term and want to reason about its generalizations).

Implemented in `robot extract --method BOT` and `--method TOP`. SLME extracts are typically larger than MIREOT extracts over the same signature, because preserving entailments pulls in more axioms.

### STAR

STAR composes BOT and TOP, iterating to a fixed point. The result is the smallest module that is conservative in both directions over the signature. Implemented in `robot extract --method STAR`. Most rigorous but largest of the OWL-aware methods.

### Plain SPARQL CONSTRUCT

For vocabularies without rich OWL axiomatization — or where we want hand-specified control over which triples survive — a SPARQL `CONSTRUCT` query is the simplest extractor: "keep these triples; discard the rest." No logical guarantees, but full transparency. Useful when ROBOT's methods drag in unexpected axioms or when the source is RDFS-only.

## What `flexo-rtm` uses

The choice of method per vocab is recorded in `ontology/parsimony/manifest.yaml`:

- **SLME** for vocabularies where logical preservation matters. The clearest case is **GSN** (see [[PROV EARL GSN P-PLAN]]): the Solution / Strategy / Goal / Justification hierarchy is what makes adequacy and sufficiency claims well-typed. Losing entailments about the GSN hierarchy would break shape validation.
- **MIREOT** for vocabularies where we want minimal surface and use only a handful of terms. The clearest case is **PROV-O**: `flexo-rtm` uses `prov:Activity`, `prov:Agent`, `prov:Entity`, `prov:wasGeneratedBy`, `prov:wasAttributedTo` and a few more. We do not need PROV-O's full axiomatization about generation/usage/derivation chains; we need the names and their direct parents. **EARL** is similar — we use the result vocabulary and the assertion structure, not EARL's deeper modal claims.
- **Plain SPARQL CONSTRUCT** as a fallback for **P-PLAN** (light RDFS, no significant OWL axiomatization to preserve) and for hand-curated subsets of OSLC vocabularies where the source is XML-shaped and ROBOT's OWL methods do not apply cleanly.

## The manifest

`ontology/parsimony/manifest.yaml` is the declarative spec. A simplified excerpt:

```yaml
prov:
  source: ontology/imports/prov-o-2013-04-30.ttl
  method: MIREOT
  signature:
    classes:
      - prov:Activity
      - prov:Agent
      - prov:Entity
    properties:
      - prov:wasGeneratedBy
      - prov:wasAttributedTo
      - prov:used
  justification: |
    flexo-rtm uses PROV core for activity/agent/entity attribution.
    Full PROV-O axiomatization (derivation chains, plans, invalidation)
    is not used and not validated; MIREOT keeps just what we cite.

gsn:
  source: ontology/imports/ontogsn-2021.ttl
  method: SLME-BOT
  signature:
    classes:
      - gsn:Goal
      - gsn:Strategy
      - gsn:Solution
      - gsn:Justification
  justification: |
    Adequacy/sufficiency claims depend on the GSN Solution hierarchy.
    SLME preserves entailments so SHACL shapes over GSN typing remain
    sound after extraction.
```

The build pipeline (`ontology/parsimony/extract.py`) reads `manifest.yaml`, invokes ROBOT or executes the CONSTRUCT queries against the vendored sources in `ontology/imports/`, and emits the per-vocab extracts under `ontology/parsimony/extracts/`. The composite `rtm.ttl` is assembled from Core + Alignment + extracts. The build is deterministic: same manifest + same vendored sources → byte-identical extracts.

## Target metric

- **Per-vocab extract:** no hard limit, but anything over a few hundred triples for a single vocab triggers a manifest review (likely the signature is too broad or the wrong method is selected).
- **Combined extract size:** ≤ ~1000 triples across all seven vendored vocabs (PROV, EARL, GSN, P-PLAN, OSLC-RM, OSLC-QM, SysMLv2 core).
- **Total `rtm.ttl`:** ≤ ~2000 triples, comprising Core (domain TBox) + Alignment (bindings) + the combined parsimony extracts.

The 2000-triple ceiling is normative under [[Design Spec]] §9.A.5 X5: `tests/conformance/test_ontology_parsimony.py` counts triples in the assembled `rtm.ttl` and **fails the build** if the count exceeds the threshold. There is no override — exceeding the threshold means either the signature in `manifest.yaml` grew (and the justification must be updated and re-reviewed) or extraction method changed (and the rationale must be documented).

## Audit story

The manifest **is** the audit trail. For any imported triple that appears in `rtm.ttl`, the answer to "where did this come from and why is it here?" is one lookup in `manifest.yaml`:

1. Which vendored source file contributed it (named with vendor + version, e.g. `prov-o-2013-04-30.ttl`).
2. Which extraction method produced it (MIREOT / SLME-BOT / SLME-TOP / STAR / CONSTRUCT).
3. Which signature entry caused it to be kept.
4. The justification: a free-text rationale, written by a human, explaining why this vocab/term is used in `flexo-rtm`.

This is what makes the parsimony layer auditable rather than just compact. An external reviewer can read `manifest.yaml` end-to-end and see the full inventory of external commitments `flexo-rtm` makes. See [[Layered Ontology]] for how the parsimony layer composes with Core, Alignment, Profiles, and Shapes.

## Update process

To add or remove an external term:

1. Edit `ontology/parsimony/manifest.yaml`: add the IRI to the relevant signature, with a one-line justification appended to the vocab's `justification` block.
2. Run `python ontology/parsimony/extract.py` (or the equivalent `make extract`). This regenerates the per-vocab extracts deterministically.
3. Run `make ontology-check`. This rebuilds `rtm.ttl`, executes `tests/conformance/test_ontology_parsimony.py`, and enforces the X5 triple budget.
4. Commit `manifest.yaml`, the regenerated extracts, and any shape changes together. The manifest commit history is the long-term audit log of parsimony decisions.

Adding a new vocab (not a new term within an existing vocab) requires an ADR documenting why the existing seven are insufficient, and updating both [[Alignment Strategy]] and [[PROV EARL GSN P-PLAN]] as needed.

## Why vendoring

External vocabularies are vendored under `ontology/imports/` rather than dereferenced at build time. Each file is read-only, named with vendor + version (e.g. `prov-o-2013-04-30.ttl`), and committed to the repo. This buys reproducibility against frozen external versions:

- Public hosting is not guaranteed-available; a vendored copy always is.
- Public ontologies change. A non-breaking upstream edit (a tightened axiom, a renamed superclass) can silently alter SLME entailments. Vendoring freezes the source.
- Determinism under [[Design Spec]] §9.A.5 X1/X2 (determinism and replay) requires that the same input always produces the same output. A vendored vocab is part of the canonical input; a dereferenced URI is not.

When we upgrade a vendored vocab, the version bump is an explicit, reviewed commit: file added, manifest adjusted if needed, extracts regenerated, X5 triple count re-checked. The diff is visible. Compare to dereferencing-at-build: an upstream edit silently changes the build with no commit recording it.

This is the structural reason `flexo-rtm` can claim local, federated, reproducible certification ([[Design Spec]] §9.A.5 X6–X8): every external commitment is pinned, named, version-frozen, and tied via `manifest.yaml` back to its source.

## See also

- [[Layered Ontology]] — how Parsimony composes with Core, Alignment, Profiles, Shapes, and Imports.
- [[PROV EARL GSN P-PLAN]] — the four primary external vocabs `flexo-rtm` extracts from, and the term-level rationale for each.
- [[Alignment Strategy]] — the `owl:equivalentClass` / `skos:closeMatch` bindings that connect Core to the parsimony extracts.
- [[Design Spec]] §6.2 (normative parsimony policy) and §9.A.5 X5 (normative triple-budget acceptance criterion).
