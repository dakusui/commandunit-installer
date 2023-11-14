source "$(dirname "${BASH_SOURCE[0]}")/commandunit"

function main() {
  # app="commandunit"
  # rc="$HOME/.${app}rc" && \
  # target="$HOME/.bashrc" && \
  # tag="#-${app^^}" && \
  # cat <(curl "https://raw.githubusercontent.com/dakusui/commandunit/main/src/site/adoc/resources/examples/function_definition.rc") > "${rc}" && \
  # sh -c 'grep "$4" "$1" >& /dev/null || printf "source $3$2$3 $4\n" >> "$1"' - "${target}" "${rc}" '"' "${tag}"

  cat <(https://dakusui.github.io/commandunit/resources/examples/commandunit) > commandunit
    if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    # If being executed.
    rm -fr target commandunit-out
    commandunit --clean -- "${@}"
  else
    # If being sourced.
    export -f commandunit
    echo "This file was sourced. Try 'commandunit --help' to see usage." >&2
  fi
}

main "${@}"
