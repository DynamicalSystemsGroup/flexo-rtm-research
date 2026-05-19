#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# sync-issues-to-wiki.sh
#
# Pull open issues from both flexo-rtm-research (this repo, the design
# side) and flexo-rtm (the impl side), and write two wiki dashboard
# pages mirroring them:
#
#   wiki/Open Issues - Research.md
#   wiki/Open Issues - Implementation.md
#
# Modelled on the RIME-product-docs dashboard pattern (Issues-Gvrn /
# Issues-Mgmt) — split by track-equivalent. Here the natural split is
# repo, not track: research vs implementation work happens in
# different repos.
#
# The generated pages are deterministic: the same `gh` JSON input
# produces byte-identical output. Re-run any time issues are filed,
# updated, or closed.
#
# Wiki publication still goes through scripts/sync-wiki.sh as usual
# after this script writes the markdown.
#
# Usage:
#   scripts/sync-issues-to-wiki.sh            # write both pages
#   scripts/sync-issues-to-wiki.sh --dry-run  # print to stdout instead

set -euo pipefail

DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            sed -n '3,/^set/p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "Unknown arg: $arg" >&2; exit 2 ;;
    esac
done

MAIN_REPO="$(git rev-parse --show-toplevel)"
WIKI_DIR="${MAIN_REPO}/wiki"

if [[ ! -d "$WIKI_DIR" ]]; then
    echo "Wiki source dir not found: $WIKI_DIR" >&2
    exit 1
fi

# Render one repo's open issues as a markdown dashboard page.
# Args:
#   $1 — GitHub repo slug (owner/name)
#   $2 — Page heading (e.g. "Open issues — Research")
#   $3 — One-line subtitle / pointer (e.g. "Spec / design tickets.")
render_page() {
    local repo="$1"
    local heading="$2"
    local subtitle="$3"

    local issues_json
    issues_json="$(gh issue list \
        --repo "$repo" \
        --state open \
        --limit 200 \
        --json number,title,labels,url \
        --jq '. | sort_by(.number)')"

    local count
    count="$(echo "$issues_json" | jq 'length')"

    {
        echo "<!-- SPDX-License-Identifier: CC-BY-4.0 -->"
        echo ""
        echo "# ${heading}"
        echo ""
        echo "> Generated dashboard. ${subtitle} **${count} open** in"
        echo "> [\`${repo}\`](https://github.com/${repo}/issues). Edit issues on"
        echo "> GitHub; this page regenerates from \`scripts/sync-issues-to-wiki.sh\`."
        echo ""

        if [[ "$count" == "0" ]]; then
            echo "_No open issues._"
        else
            echo "| # | Title | Labels |"
            echo "|---|---|---|"
            echo "$issues_json" | jq -r '
                .[] |
                "| [#\(.number)](\(.url)) | \(.title) | \(
                    if (.labels | length) == 0 then ""
                    else (.labels | map("`" + .name + "`") | join(", "))
                    end
                ) |"
            '
        fi

        echo ""
        echo "---"
        echo ""
        echo "_Last regenerated from \`gh issue list --repo ${repo} --state open\`._"
    }
}

write_or_dryrun() {
    local target="$1"
    local content="$2"
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "==> Would write to $target:"
        echo "$content"
        echo ""
        echo "==> End preview ($target)"
        echo ""
    else
        echo "$content" > "$target"
        echo "Wrote $target"
    fi
}

RESEARCH_CONTENT="$(render_page \
    "DynamicalSystemsGroup/flexo-rtm-research" \
    "Open issues — Research" \
    "Spec / ontology / design decisions tracked on the research repo.")"

IMPL_CONTENT="$(render_page \
    "DynamicalSystemsGroup/flexo-rtm" \
    "Open issues — Implementation" \
    "Code / CLI / test work tracked on the implementation repo.")"

write_or_dryrun "${WIKI_DIR}/Open Issues - Research.md" "$RESEARCH_CONTENT"
write_or_dryrun "${WIKI_DIR}/Open Issues - Implementation.md" "$IMPL_CONTENT"

if [[ $DRY_RUN -eq 0 ]]; then
    echo ""
    echo "Done. Next: review the diff, then run scripts/sync-wiki.sh to publish."
fi
