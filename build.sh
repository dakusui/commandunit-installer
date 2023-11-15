#!/usr/bin/env bash

set -eu -o pipefail -o errtrace
shopt -s inherit_errexit nullglob compat"${BASH_COMPAT=42}"

function main() {
  [[ -e "./commandunit" ]] || {
    cat <(curl https://raw.githubusercontent.com/dakusui/commandunit/wrapper-verified/commandunit) >commandunit
    chmod 755 ./commandunit
  }
  if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    ./commandunit --clean -- "${@}"
  else
    echo "commandunit's wrapper script was downloaded to $(pwd)/commandunit. Place it under a directory on PATH environment variable." >&2
  fi
}

main "${@}"
