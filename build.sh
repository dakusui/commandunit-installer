source "$(dirname "${BASH_SOURCE[0]}")/commandunit.rc"

function main() {
  if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    # If being executed.
    rm -fr target commandunit-out
    commandunit --commandunit-dir=. -- "${@}"
  else
    # If being sourced.
    export -f commandunit
    __commandunit_refresh_cloned_commandunit "--branch ${COMMANDUNIT_VERSION}" "" || return "${?}"
    echo "This file was sourced. Try 'commandunit --help' to see usage." >&2
  fi
}

export PROJECT_BASE_DIR="${PWD}"
export COMMANDUNIT_SOURCE_DIR="${PROJECT_BASE_DIR}/src/dependencies/commandunit"
export COMMANDUNIT_MINOR_VERSION="22"
export COMMANDUNIT_VERSION="v1.${COMMANDUNIT_MINOR_VERSION}"
export COMMANDUNIT_SNAPSHOT_VERSION="v1.$((${COMMANDUNIT_MINOR_VERSION} + 1))"
# To workaround: https://github.com/dakusui/commandunit/issues/13
export COMMANDUNIT_PWD="${PROJECT_BASE_DIR}"
main "${@}"
