<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Licensing

This repository contains three classes of artifact, each licensed appropriately. The split is deliberate — every file (in this repo AND in the companion GitHub wiki) carries an SPDX-License-Identifier header naming which clause applies. When in doubt, check the header on the specific file.

| Artifact class | License | File |
|---|---|---|
| **Code** (any Python helpers, scripts, CI workflows) | **Apache License 2.0** | [LICENSE-CODE](LICENSE-CODE) |
| **Ontology** (any `*.ttl` example fixtures, SHACL shapes, alignment modules) | **Creative Commons Zero v1.0 Universal (CC0-1.0)** | [LICENSE-ONTOLOGY](LICENSE-ONTOLOGY) |
| **Documentation & briefs** (this README, all wiki markdown, ADRs, the design spec) | **Creative Commons Attribution 4.0 International (CC-BY-4.0)** | [LICENSE-DOCS](LICENSE-DOCS) |

## What this repo holds today

`flexo-rtm-research` is the design-and-rationale companion to the forthcoming `flexo-rtm` standards + software repo. The substantive content lives canonically in [`wiki/`](wiki/) in this repo and is published via the [GitHub wiki](https://github.com/dynamicalsystemsgroup/flexo-rtm-research/wiki) — see [CONTRIBUTING.md](CONTRIBUTING.md) for the source-of-truth + sync operational model.

Today's contents fall into two of the three artifact classes:

- **Documentation** (`wiki/`, `README.md`, `CONTRIBUTING.md`, `LICENSE.md`) — CC-BY-4.0
- **Code** (`scripts/sync-wiki.sh`) — Apache-2.0

No ontology files live in this repo yet — those are reserved for the future `flexo-rtm` implementation repo. The CC0-1.0 license body is nonetheless present so the licensing strategy is already in place if illustrative ontology fragments are added to a wiki page.

## Why three licenses?

- **Apache-2.0 for code** — standard permissive license with explicit patent grant; broadly compatible with downstream use.
- **CC0 for the ontology** — the linked-data norm for shared vocabularies (see [LOV](https://lov.linkeddata.es/)). No attribution burden on consumers who import the IRIs; vocabulary terms work like punctuation.
- **CC-BY-4.0 for documentation** — narrative content carries authorship; contributors get credit. Reuse permitted with attribution.

## SPDX headers

Every file across both this main repo and the wiki carries an SPDX-License-Identifier comment so license-scanning tools and humans can quickly see which terms apply:

```
# SPDX-License-Identifier: Apache-2.0          # Python files
# SPDX-License-Identifier: CC0-1.0             # Turtle ontology / shapes
<!-- SPDX-License-Identifier: CC-BY-4.0 -->    # Markdown (wiki + main repo)
```

If you find a file without a header, please flag it as an issue or PR.

## Contributions

By contributing you agree that your contributions are licensed under the same terms as the artifact class they belong to (per the table above). No CLA is required.
