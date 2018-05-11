#!/bin/bash
set -eu

SCRIPTPATH="$(cd "$(dirname "$0")" && pwd -P)"
OUTDIR="/srv/www/docs.opencast.org"
MSGFILE="${SCRIPTPATH}/update"

cd "${SCRIPTPATH}"

# Check if we need to build the docs
if [ "${1:-}" != "--force" ] && [ ! -f "${MSGFILE}" ]; then
    exit
fi
rm -f "${MSGFILE}"

# Check out the Opencast repository
if [ ! -d opencast ]; then
    git clone https://github.com/opencast/opencast.git &> /dev/null
fi

# Make sure to update the repository
cd "${SCRIPTPATH}/opencast"
git fetch --prune &> /dev/null

# Get the branches
BRANCHES="develop
$(git branch -a |
    sed -e 's#^.*remotes/origin/\(r/[2-9]*\.*[0-9]*\.x\).*$#\1#;tx;d;:x' |
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
        pushd "${SCRIPTPATH}/opencast/docs/guides/${target}" > /dev/null
        mkdocs build > /dev/null
        mkdir -p "${OUTDIR}/${branch}" > /dev/null
        rm -rf "${OUTDIR:?}/${branch}/${target}" > /dev/null
        mv site "${OUTDIR}/${branch}/${target}" > /dev/null
        popd > /dev/null
    done

    # Add build hash
    echo "${HASH}" > "${OUTDIR}/${branch}/hash"

    # Add index page
    if [ "${branch}" == 'develop' ]; then
        cp "${SCRIPTPATH}/opencast/docs/guides/index.html" \
            "${OUTDIR}/index.html"
    fi
done

echo "${VERSIONS}];" > "${OUTDIR}/versions.js"

BRANCHES_ARR=($BRANCHES)
cat /dev/null > "${OUTDIR}/robots.txt"
#Magic number is 4.  Array has develop, current dev branch, stable, legacy, and then the ones we want to block.
#Worst case we have one extra older branch excluded from the robots.txt when there isn't a current dev branch.
for ((i=4; i<${#BRANCHES_ARR[*]}; i++));
do
    echo -e "USER-agent: *\nDisallow: /${BRANCHES_ARR[i]}\n" >> "${OUTDIR}/robots.txt"
done
