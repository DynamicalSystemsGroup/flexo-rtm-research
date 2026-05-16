#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# sync-wiki.sh
#
# Sync the canonical wiki content from this main repo's `wiki/` directory
# into the sibling GitHub-wiki repo, then commit and push.
#
# Operational model:
#   - The main repo is the source of truth for all wiki content.
#   - Contributors edit files in `wiki/` and PR against the main repo.
#   - The GitHub wiki repo (`<owner>/<repo>.wiki.git`) is a published mirror
#     and is never edited directly.
#   - This script propagates the main repo's `wiki/` directory into the
#     wiki repo. Run it after every commit that touches `wiki/`.
#
# Assumptions:
#   - The wiki repo is cloned at `${MAIN_REPO}.wiki/` as a sibling directory.
#     If yours lives somewhere else, set WIKI_REPO before invoking.
#   - The wiki repo's default branch is `master` (GitHub wiki convention).
#
# Usage:
#   scripts/sync-wiki.sh            # sync, commit if changed, push
#   scripts/sync-wiki.sh --no-push  # sync, commit if changed, but do not push
#   scripts/sync-wiki.sh --dry-run  # show what would change without writing

set -euo pipefail

NO_PUSH=0
DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --no-push) NO_PUSH=1 ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            sed -n '3,/^set/p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "Unknown arg: $arg" >&2; exit 2 ;;
    esac
done

MAIN_REPO="$(git rev-parse --show-toplevel)"
WIKI_REPO="${WIKI_REPO:-${MAIN_REPO}.wiki}"
SOURCE_DIR="${MAIN_REPO}/wiki"

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Source directory not found: $SOURCE_DIR" >&2
    exit 1
fi

if [[ ! -d "$WIKI_REPO/.git" ]]; then
    cat >&2 <<EOF
Wiki repo not found at: $WIKI_REPO

Clone it as a sibling directory first:
    cd "$(dirname "$MAIN_REPO")"
    git clone https://github.com/<owner>/$(basename "$MAIN_REPO").wiki.git $(basename "$MAIN_REPO").wiki
EOF
    exit 1
fi

MAIN_SHA="$(git -C "$MAIN_REPO" rev-parse HEAD)"
SHORT_SHA="${MAIN_SHA:0:7}"

RSYNC_FLAGS=(-a --delete --exclude='.git/' --exclude='.gitignore')
if [[ $DRY_RUN -eq 1 ]]; then
    RSYNC_FLAGS+=(--dry-run -v)
    echo "==> Dry run; no files will be written. Diff preview:"
fi

rsync "${RSYNC_FLAGS[@]}" "${SOURCE_DIR}/" "${WIKI_REPO}/"

if [[ $DRY_RUN -eq 1 ]]; then
    exit 0
fi

cd "$WIKI_REPO"

if [[ -z "$(git status --porcelain)" ]]; then
    echo "Wiki already in sync at main@${SHORT_SHA}."
    exit 0
fi

git add -A
git commit -m "sync: from main repo @ ${SHORT_SHA}

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"

if [[ $NO_PUSH -eq 1 ]]; then
    echo "Committed locally; --no-push given, skipping push."
    exit 0
fi

# GitHub wiki repos default to `master`. If a contributor has reconfigured
# theirs to `main`, push to the current branch.
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
git push origin "$CURRENT_BRANCH"
echo "Wiki synced and pushed (main@${SHORT_SHA} -> wiki/${CURRENT_BRANCH})."
