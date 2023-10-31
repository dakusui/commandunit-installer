source "$(dirname "${BASH_SOURCE[0]}")/commandunit.rc"

function main() {
  if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    # If being executed.
    rm -fr target commandunit-out
    commandunit --commandunit-dir=. -- "${@}"
  else
    # If being sourced.
    export -f commandunit
    echo "This file was sourced. Try 'commandunit --help' to see usage." >&2
  fi
}

main "${@}"
