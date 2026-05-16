<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Lossless Roundtrip Definition

This page gives the formal definition of "lossless roundtrip" as used by the v0.1 OSLC adapter (see [[Design Spec]] §9). It exists because the phrase "lossless roundtrip" is too vague to be testable on its own — different stakeholders mean different things by it — and because institutional adoption of `flexo-rtm` depends on a precise, demonstrable criterion. Locked decision D11 fixes the criterion as **Layer A + Layer C**: rigorous canonical-form equivalence for the OSLC-RM/QM core, opaque carry-through for everything vendor-specific.

## What "lossless" means here

"Lossless" is defined as the conjunction of two independent conditions on the parse → serialize roundtrip:

- **Layer A — Core equivalence.** Triples whose predicate is in the OSLC-RM 2.1 or OSLC-QM 2.1 core vocabulary roundtrip with RDFC-1.0 canonical-form byte-equality. This is the rigorous claim: the adapter understands these constructs and re-emits them identically up to the equivalence relation defined by W3C RDF Dataset Canonicalization 1.0.
- **Layer C — Opaque carry-through.** Triples whose predicate is outside the core vocabulary (Doors-X, Jama-Y, and any other vendor or custom predicate) are stored verbatim in a per-resource source named graph and re-emitted verbatim, with the per-resource triple count preserved across the roundtrip. The adapter does not claim to understand these triples — only that it does not drop, rename, or mutate them.

Layer A is what makes the adapter interoperable with the OSLC standard. Layer C is what makes it survive contact with real vendor exports, where 30–60% of the triples in a Doors or Jama export are vendor extensions that no standards body has blessed. Without Layer A, institutional users cannot trust the conformance claim; without Layer C, the adapter would either crash or silently corrupt real-world data on the first import.

The certification predicate (see [[Certification Predicate]]) does NOT certify content inside Layer C subgraphs — they are carried, not interpreted.

## Layer A — Formal definition

Let $G_\text{in}$ be the input RDF graph as parsed from an OSLC source (RDF/XML, Turtle, or JSON-LD; serialization is immaterial). Let $\text{core}$ be the set of triples whose predicate is in OSLC-RM 2.1 core or OSLC-QM 2.1 core, as enumerated normatively in `spec/oslc-roundtrip-acceptance.md` (per [[Design Spec]] §9.A.2 O3). Let $C(G)$ denote the RDFC-1.0 canonical form of $G$ (W3C Recommendation 2024) — a deterministic, blank-node-label-independent serialization that is byte-stable across implementations.

The roundtrip is:

$$
G_\text{in} \xrightarrow{\text{parse}} G_\text{internal} \xrightarrow{\text{serialize}} G_\text{out}
$$

**Layer A holds iff:**

$$
C(G_\text{in} \cap \text{core}) = C(G_\text{out} \cap \text{core})
$$

This is **byte-equality** of canonical-form output, not graph isomorphism by some other measure. RDFC-1.0 already handles blank-node relabeling, triple ordering, and namespace-prefix variation, so the test reduces to `H(C(G_in_core)) == H(C(G_out_core))` where `H` is the active cryptographic suite's content-hash algorithm (SHA-256 by default per [[ADR-026 Cryptographic Agility via Algorithm Profiles]]; the algorithm rotates with the suite, not with code surgery). This is checked by `tests/integration/oslc-roundtrip/test_layer_a_rm.py` and `test_layer_a_qm.py` (per [[Design Spec]] §9.A.2 O1).

## Layer C — Formal definition

Let $\text{nonCore}(G) = \{(s, p, o) \in G : p \notin \text{core}\ \land\ s \in \text{scope}\}$, where "in scope" means $s$ is the subject of some Layer A triple (i.e., the carry-through is anchored to a resource the adapter actually knows about). Every such triple is stored in the per-resource named graph $\langle\text{oslc-rm:source}/\{id\}\rangle$ at import.

**Layer C holds iff** both of the following:

1. **Verbatim re-emission.** For every triple $(s, p, o) \in \text{nonCore}(G_\text{in})$, exactly the same triple $(s, p, o)$ appears in $G_\text{out}$. No predicate rewriting, no object normalization, no datatype inference.
2. **Structural count preservation.** For every resource IRI $r$ that is the subject of any non-core triple, $|\text{nonCore}(G_\text{in})|_r = |\text{nonCore}(G_\text{out})|_r$. This catches silent drops that would survive a sampled verbatim check.

Semantic checks on Layer C content are **not performed**: we do not validate, normalize, or interpret vendor predicates. This is enforced by `tests/integration/oslc-roundtrip/test_layer_c_carrythrough.py` (per [[Design Spec]] §9.A.2 O2).

## What is excluded

The lossless criterion does **not** preserve, and is not required to preserve:

- **Serialization-level choices.** RDF/XML vs. Turtle vs. JSON-LD; namespace prefix abbreviations; whitespace; element ordering. These are properties of the byte stream, not the graph, and RDFC-1.0 explicitly equates graphs that differ only in such choices.
- **Blank node labels.** RDFC-1.0 canonicalizes blank node identifiers; two graphs that differ only in blank node naming are canonically equivalent. Round-tripped output may use different blank node labels than the input and still be lossless.
- **Inferred triples.** If internal processing adds entailments (e.g., RDFS subclass closure for validation), those derived triples are NOT written back. Only the explicitly-stored set roundtrips. This keeps Layer A honest: the adapter cannot "win" the equivalence test by inferring missing triples on the input side.

## Carry-through registry

`examples/oslc-fixtures/vendor-registry.yaml` enumerates known vendors (Doors, Jama, Polarion, codeBeamer, …) and their known extension namespaces. The registry is **informational** — Layer C carry-through works for unknown vendors too; the registry exists to document known patterns, support targeted vendor-fixture testing, and surface which vendors have been validated against. Adding a new vendor requires only a registry entry, not a code change (per [[Design Spec]] §9.A.2 O7).

See [[Vendor Extension Carry-Through]] for the storage mechanics and [[OSLC RM Adapter Contract]] / [[OSLC QM Adapter Contract]] for the parse/serialize interface.

## Validation

The criterion is validated by integration tests at four levels (per [[Design Spec]] §9.A.2):

- **O1 — Layer A core equivalence.** Synthetic graphs constructed to exercise every core construct in `spec/oslc-roundtrip-acceptance.md` roundtrip with $C(G_\text{in} \cap \text{core}) = C(G_\text{out} \cap \text{core})$.
- **O2 — Layer C carry-through.** Synthetic graphs with vendor extensions roundtrip verbatim with structural counts preserved.
- **O4 — Canonical fixtures roundtrip.** Every fixture in `examples/oslc-fixtures/canonical/` (W3C and OASIS OSLC spec examples) passes Layer A.
- **O5 — Vendor fixtures roundtrip.** Sanitized Doors and Jama exports in `examples/oslc-fixtures/vendor/` pass Layer A on core and Layer C on extensions.

A v0.1 release is gated on all four passing. See also [[RDFC-1.0 Canonicalization]] for the canonical-form mechanics.

## What we lose in practice

The criterion is precise about what it covers, and equally precise about what it does not:

- **Vendor-specific service catalog negotiation.** OSLC service providers advertise capabilities via runtime OSLC Service Catalog and Resource Shape documents. v0.1 ships the **adapter** (parse, serialize, roundtrip against fixtures), not **live connectors** that negotiate with running Doors / Jama instances. Live connectors are v0.2 and plug into the v0.1 adapter without modification.
- **Vendor UI delegate URIs.** Doors and Jama emit URIs that, when dereferenced by a user agent, return interactive UI for picking or creating linked resources. These URIs are preserved verbatim by Layer C — they roundtrip — but `flexo-rtm` does not interpret them, render them, or follow them. A downstream tool that needs the UI delegate behavior must consume the carried-through triples directly.

Both of these are deliberate scope cuts, not gaps. The lossless criterion is about **the data**, not about reproducing every interactive surface of the source tool. Reproducing the data losslessly is what gate-keeps institutional adoption; reproducing the interactive surfaces is product surface area that belongs in v0.2+.

## Cross-references

- [[Design Spec]] §9, §9.A.2 (O1–O7 acceptance criteria), locked decision D11
- [[RDFC-1.0 Canonicalization]] — the canonical form $C(\cdot)$ used in the Layer A definition
- [[Vendor Extension Carry-Through]] — Layer C storage mechanics and named-graph layout
- [[OSLC RM Adapter Contract]] — parse/serialize contract for OSLC-RM 2.1
- [[OSLC QM Adapter Contract]] — parse/serialize contract for OSLC-QM 2.1
