#!/usr/bin/env bash
# Rebuild the `eclix` branch on top of an upstream Chatwoot release tag and
# push a `<tag>-eclix<N>` tag, which triggers eclix-build.yml.
#
#   eclix/sync.sh v4.19.0          # first Eclixtech build of v4.19.0 -> v4.19.0-eclix1
#   eclix/sync.sh v4.19.0 2        # rebuild after changing a patch   -> v4.19.0-eclix2
#
# The branch is always: upstream tag + ONE commit holding eclix/, our
# workflows, upstream's workflows removed, and eclix/patches/*.patch applied.
# So "what did we change?" is always `git show eclix`.
set -euo pipefail

TAG=${1:?usage: eclix/sync.sh <upstream tag, e.g. v4.19.0> [build number]}
N=${2:-1}
OURS="eclix/ .github/workflows/eclix-*.yml"

cd "$(git rev-parse --show-toplevel)"
[ -z "$(git status --porcelain)" ] || { echo "working tree not clean"; exit 1; }
git remote get-url upstream >/dev/null 2>&1 \
  || git remote add upstream https://github.com/chatwoot/chatwoot.git
git fetch -q upstream "refs/tags/$TAG:refs/tags/$TAG" --no-tags
git fetch -q origin eclix

stash=$(mktemp -d)
git archive origin/eclix $OURS | tar -x -C "$stash"

git checkout -q -B eclix "$TAG"
git rm -q -r --ignore-unmatch .github/workflows
cp -a "$stash"/. .
for p in eclix/patches/*.patch; do
  git apply --3way "$p" || { echo "patch $p no longer applies to $TAG — fix it, then re-run"; exit 1; }
done
git add -A
git commit -q -m "Eclixtech build of Chatwoot $TAG

$(ls eclix/patches)"
git tag -f "$TAG-eclix$N"
git push -q --force origin eclix
git push -q --force origin "refs/tags/$TAG-eclix$N"
echo "pushed eclix + $TAG-eclix$N — image: ghcr.io/eclix-web/chatwoot:$TAG-eclix$N"
