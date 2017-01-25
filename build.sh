#!/bin/bash
set -eu

SCRIPTPATH="$(cd "$(dirname "$0")" && pwd -P)"
OUTDIR="/srv/www/docs.opencast.org"
MSGFILE="${SCRIPTPATH}/update"

cd "${SCRIPTPATH}"

# Check if we need to build the docs
if [ "${1:-}" != "--force" -a ! -f "${MSGFILE}" ]; then
    exit
fi
rm -f "${MSGFILE}"

# Check out the Opencast repository
if [ ! -d matterhorn ]; then
    git clone https://bitbucket.org/opencast-community/matterhorn.git &> /dev/null
fi

# Make sure to update the repository
cd "${SCRIPTPATH}/matterhorn"
git fetch &> /dev/null

# Get the branches
BRANCHES="develop
$(git branch -a |
    sed -e 's#^.*remotes/origin/\(r/[2-9]*\.[0-9]*\.x\).*$#\1#;tx;d;:x' |
    sort -r)"

VERSIONS="var versions = ['develop'"

for branch in ${BRANCHES}
do
    [ "develop" = "${branch}" ] || VERSIONS="${VERSIONS}, '${branch}'"
    git reset --hard HEAD
    git clean -fdx
    git checkout "origin/${branch}" &> /dev/null

    # Check if this state has been built already
    HASH="$(git log -n1 --format="%H" -- docs/guides)"
    if [ -f "${OUTDIR}/${branch}/hash" ]; then
        if grep -q "${HASH}" "${OUTDIR}/${branch}/hash"; then
            echo "Skipping ${branch}"
            continue
        fi
    fi

    echo "Building documentation for ${branch}"
    for target in admin developer user
    do
        pushd "${SCRIPTPATH}/matterhorn/docs/guides/${target}" > /dev/null
        mkdocs build > /dev/null
        mkdir -p "${OUTDIR}/${branch}" > /dev/null
        rm -rf "${OUTDIR}/${branch}/${target}" > /dev/null
        mv site "${OUTDIR}/${branch}/${target}" > /dev/null
        popd > /dev/null
    done

    # Add build hash
    echo "${HASH}" > "${OUTDIR}/${branch}/hash"

    # Add index page
    if [ "${branch}" == 'develop' ]; then
        cp "${SCRIPTPATH}/matterhorn/docs/guides/index.html" \
            "${OUTDIR}/index.html"
    fi
done

echo "${VERSIONS}];" > "${OUTDIR}/versions.js"
