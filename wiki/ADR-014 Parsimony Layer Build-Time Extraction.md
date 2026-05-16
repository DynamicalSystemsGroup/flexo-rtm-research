<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# ADR-014: Parsimony Layer Build-Time Extraction

**Status:** Accepted
**Date:** 2026-05-16
**Deciders:** Michael Zargham
**Related:** [[ADR-002 SysMLv2 Anchoring]]; [[ADR-015 GSN Adoption for Adequacy and Sufficiency]]; [[ADR-020 Vocabulary Alignment with Zargham 2026]]; [[Parsimony Policy]]; [[Layered Ontology]]; [[Design Spec]]

## Context

`flexo-rtm` imports vocabulary from multiple upstream ontologies: SysMLv2 (see [[ADR-002 SysMLv2 Anchoring]]), PROV-O, EARL, GSN (see [[ADR-015 GSN Adoption for Adequacy and Sufficiency]]), OSLC-RM and OSLC-QM (see [[ADR-010 OSLC-RM and OSLC-QM in v0.1]]), and the Zargham 2026 vocabulary (see [[ADR-020 Vocabulary Alignment with Zargham 2026]]). Importing each upstream ontology in full bloats the v0.1 working ontology with thousands of triples — many of them irrelevant to RTM — and makes reasoning slow, validation noisy, and provenance opaque. The alternative is to extract only the minimum vocabulary needed (MIREOT, SLME) at build time and check the extracts into version control with a documented provenance trail. See [[Design Spec]] §6.5 and [[Parsimony Policy]].

## Decision

`flexo-rtm` v0.1 uses a **parsimony layer**: MIREOT / SLME extracts from upstream ontologies are computed at **build time**, checked into the repo, and loaded as the working ontology. Target size for v0.1 is approximately **2k triples** total across all upstream imports. Every imported triple's provenance (source ontology, extraction date, MIREOT/SLME parameters) is recorded for audit.

## Consequences

### Positive

- Performance: ~2k working triples is small enough that SHACL validation, SPARQL coverage queries, and derived-view CONSTRUCTs all run in single-digit seconds on the v0.1 graph scale
- Clarity: the working ontology contains only vocabulary actually referenced by `flexo-rtm`; adopters reading the ontology see exactly what's relevant
- Auditable provenance: every imported triple has a documented source and extraction provenance — adopters can verify that the extract correctly represents the upstream ontology
- Build-time extraction is reproducible: the extraction script (or `robot` invocation) is version-controlled, and re-running it produces the same extract from the same upstream version

### Negative / Tradeoffs

- Build-time extraction means upstream ontology updates require a manual re-extraction step — automatic upstream sync is not free
- MIREOT/SLME extraction can miss vocabulary that is technically needed but not directly referenced (e.g., transitive subclass parents); mitigated by SHACL validation catching missing-vocabulary errors at CI time
- The ~2k-triple target is a soft cap; v0.1 may bust it slightly without failing acceptance, but maintaining the cap requires periodic parsimony review

### Neutral

- The parsimony layer is the **lowest layer** of the layered ontology (see [[Layered Ontology]]); the project-specific RTM ontology sits on top and imports parsimony-extracted upstream concepts

## Alternatives Considered

- **Runtime ontology loading:** Load full upstream ontologies at runtime from their canonical URLs. Rejected: catastrophic for performance (millions of triples loaded for each cert run), opaque for audit (which triples were imported when?), and fragile (upstream URL availability, upstream version drift). Build-time extraction with checked-in artifacts is the only practical option for institutional adoption.

## Implementation Notes

- Build-time extraction script in `ontology/extract/` invokes `robot` (the ROBOT ontology tool) with documented MIREOT / SLME parameters per upstream
- Extracted artifacts are checked into `ontology/imports/` with one file per upstream source
- Provenance manifest in `ontology/imports/provenance.ttl` records source URL, source version, extraction date, MIREOT/SLME parameters per import
- CI gate verifies the working ontology size against the ~2k-triple target; busts trigger a parsimony review
- See [[Parsimony Policy]] for the policy and [[Layered Ontology]] for how the parsimony layer composes with project-specific RTM vocabulary

## References

- [[Design Spec]] §6.5 (Parsimony Layer), §6.6 (Build-Time Extraction)
- [[Parsimony Policy]] — the canonical parsimony-policy documentation
- [[Layered Ontology]] — how parsimony composes into the layered model
- [[ADR-002 SysMLv2 Anchoring]] — SysMLv2 is the primary parsimony source
- ROBOT (OBO Tool): http://robot.obolibrary.org/
- MIREOT: doi.org/10.1186/2041-1480-2-S2-S1
