<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# flexo-rtm-research

Design, research synthesis, and decision rationale for the **`flexo-rtm`** standards + software repo — verifiable self-certification of bidirectional requirements traceability of SysMLv2 models, anchored in open source and self-hostable on Flexo MMS.

## Where to read

**The research is published as a GitHub wiki** — browser-readable, no clone required:

→ **[`flexo-rtm-research` wiki](https://github.com/dynamicalsystemsgroup/flexo-rtm-research/wiki)** ←

Start at the wiki's [Home page](https://github.com/dynamicalsystemsgroup/flexo-rtm-research/wiki/Home), or jump to the [Map of Content](https://github.com/dynamicalsystemsgroup/flexo-rtm-research/wiki/Map-of-Content) for the comprehensive index.

## Where to edit

**This repo is the source of truth.** The published wiki is a generated mirror.

- All wiki pages live in [`wiki/`](wiki/) here. Edit those files and open a PR.
- The wiki repo at `flexo-rtm-research.wiki.git` is never edited directly.
- A maintainer (or CI) runs [`scripts/sync-wiki.sh`](scripts/sync-wiki.sh) to publish.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full operational model and conventions.

## What this repo holds

| Path | Purpose |
|---|---|
| `wiki/` | Canonical source of every wiki page (`Home.md`, `_Sidebar.md`, content docs, ADRs, the Design Spec). |
| `scripts/sync-wiki.sh` | Publishes `wiki/` into the GitHub wiki repo. Idempotent. |
| `CONTRIBUTING.md` | Operational model + edit conventions. |
| `LICENSE.md` | Three-license strategy (Apache-2.0 / CC-BY-4.0 / CC0-1.0; per [ant-rdf](https://github.com/mzargham/ant-rdf)'s pattern). |
| `LICENSE-CODE`, `LICENSE-DOCS`, `LICENSE-ONTOLOGY` | Full license texts. |

## Status

**Design phase complete.** 78 wiki pages (4 nav/foundation + 42 content docs + ADR template + 31 ADRs) ready for in-depth review before `flexo-rtm` implementation begins. No software is built here. The implementation repo (`flexo-rtm`) follows after this research is reviewed. Browse online via the [wiki](https://github.com/dynamicalsystemsgroup/flexo-rtm-research/wiki).

## Citation

(Citation block for INCOSE IS 2026 paper to be added once the paper's published.)
