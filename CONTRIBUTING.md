<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Contributing

## The operational model in one sentence

**The main repo is the source of truth; the GitHub wiki is a published mirror that is never edited directly.**

```
                  edit + PR
contributors ───────────────►  main repo (this repo)
                                    │ /wiki/*.md         (canonical content)
                                    │ /scripts/sync-wiki.sh
                                    │
                                    ▼  scripts/sync-wiki.sh
                                 wiki repo (flexo-rtm-research.wiki.git)
                                    │
                                    ▼
                            readers ◄──── github.com/.../wiki
```

## Why this split

- **Readers want the wiki.** Browser-readable, sidebar nav, no clone required.
- **Contributors want PRs.** Diff review, branch protection, status checks, signed commits — none of which the GitHub wiki supports natively.
- **Single source of truth prevents drift.** The Design Spec, ADRs, and every other wiki page exist exactly once in version control: in `wiki/` here. The wiki repo is generated from it.

## Where things live

| What | Where | Notes |
|---|---|---|
| Wiki pages (Home, content docs, ADRs) | `wiki/*.md` in this repo | All edits land here |
| Wiki sidebar | `wiki/_Sidebar.md` | Same — edited here |
| Design Spec | `wiki/Design Spec.md` | The canonical version. Update this when the design changes. |
| Sync script | `scripts/sync-wiki.sh` | Run after edits to publish |
| License strategy | `LICENSE.md` + `LICENSE-*` | Three-license split (Apache-2.0 / CC-BY-4.0 / CC0-1.0) |
| Historical brainstorming spec | `docs/superpowers/specs/2026-05-16-flexo-rtm-design.md` outside this repo | Frozen snapshot. **Not** the canonical version anymore. |

## The contributor workflow

1. **Branch + edit** files under `wiki/` in this repo.
2. **Verify** locally if you want a preview — wiki-link syntax (`[[Page Name]]`) does not render outside the GitHub wiki, but the rest of the markdown does. To preview the full rendering, run `scripts/sync-wiki.sh --no-push` against a personal wiki fork.
3. **Open a PR** against `main` in this repo. Reviewers comment, request changes, approve.
4. **Merge.** A maintainer (or a CI job, once configured) runs `scripts/sync-wiki.sh` to publish into the GitHub wiki.

## Wiki content conventions

These apply to every file under `wiki/`:

- **First line** of every markdown file: `<!-- SPDX-License-Identifier: CC-BY-4.0 -->`
- **Internal cross-references** between wiki pages: `[[Page Name]]` (GitHub-wiki syntax; auto-resolves to the corresponding page slug with hyphens)
- **External links**: standard markdown `[label](https://...)`
- **In-page anchors**: standard markdown `[label](#anchor)`
- **No subdirectories** inside `wiki/`. GitHub wiki flattens paths anyway; we mirror that.
- **No `[[Page|alias]]` form** — GitHub wiki supports it but we standardize on the simple `[[Page Name]]` form. The page title in the heading is the canonical display name.
- **ADRs are flat at the wiki root** (`wiki/ADR-NNN ...md`), not in a `decisions/` subfolder.

## Running the sync script

```bash
# Prerequisites: clone the wiki repo as a sibling directory
cd "$(git rev-parse --show-toplevel)/.."
git clone https://github.com/dynamicalsystemsgroup/flexo-rtm-research.wiki.git flexo-rtm-research.wiki

# From the main repo root:
./scripts/sync-wiki.sh             # sync, commit if changed, push
./scripts/sync-wiki.sh --dry-run   # preview the diff without writing
./scripts/sync-wiki.sh --no-push   # commit to wiki repo locally without pushing
```

The script is idempotent. Running it on a clean tree exits with "Wiki already in sync." It rsyncs `wiki/` → wiki repo, deletes pages that no longer exist in `wiki/`, commits with the main repo's short SHA in the message, and pushes.

## What about the historical brainstorming spec?

`docs/superpowers/specs/2026-05-16-flexo-rtm-design.md` (outside this repo) was the terminal artifact of the brainstorming session that produced the design. It is frozen — kept for provenance. Going forward, the canonical Design Spec is `wiki/Design Spec.md` in this repo. If the design changes, update the wiki version; do not touch the brainstorming snapshot.

## Licensing

By contributing you agree your changes are licensed under the artifact-class terms documented in [LICENSE.md](LICENSE.md). No CLA required.
