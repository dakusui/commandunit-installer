#!/usr/bin/env bash

set -eu -o pipefail -o errtrace
shopt -s inherit_errexit nullglob compat"${BASH_COMPAT=42}"


function __install_commandunit__test_installed() {
  # Execute the string in local variable _cmd.
  # shellcheck disable=SC2090
  echo "Executing: ${_cmd}" >&2
}

function __install_commandunit__execute_commandunit() {
  # Execute the string in local variable _cmd.
  # shellcheck disable=SC2090
  echo "Executing: ${_cmd}" >&2
}

function __download_commandunit() {
  curl -f https://raw.githubusercontent.com/dakusui/commandunit/wrapper-verified/src/main/scripts/bin/commandunit -o "${HOME}/bin/commandunit" 2>&1 || {
    local _err="${?}"
    message
    return "${_err}"
  }
}

function main() {
  # The command line to execute
  # shellcheck disable=SC2016
  if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    echo "WARNING: Please don't source this file. It doesn't define `commandunit` function, anymore." >&2
    return 0
  fi
  cat <(curl -f https://raw.githubusercontent.com/dakusui/commandunit/wrapper-verified/src/main/scripts/bin/commandunitX) >commandunit || {
    echo "ERROR: Download fails" >&2
    rm commandunit
    return 1
  }
  chmod 755 ./commandunit
  echo "commandunit's wrapper script was downloaded to $(pwd)/commandunit. Place it under a directory on PATH environment variable." >&2

  echo "Try '$(pwd)/commandunit --help' to show options." >&2
  echo "Also, by doing 'sudo mv $(pwd)/commandunit /usr/local/bin/commandunit', you will not need to specify the directory every time." >&2
}

# main "${@}"

function test_block() {
  local _err
  _err="$(curl -f https://raw.githubusercontent.com/dakusui/commandunit/wrapper-verified/src/main/scripts/bin/commandunitX -o "${HOME}/bin/commandunit" 2>&1)" || {
    local _c=$?
    echo "ERROR::<${_err}"
    return "${_c}"
  }
  echo "INFO"
  chmod 755 "${HOME}/bin/commandunit"
}

function test_block_2() {
  local _err _out _cc=0
  _err="$(curl -f https://raw.githubusercontent.com/dakusui/commandunit/wrapper-verified/src/main/scripts/bin/commandunitX -o "${HOME}/bin/commandunit" 2>&1)" || {
    local _c=$?
    echo "ERROR::<${_err}"
    return "${_c}"
  }
  echo "INFO:<$_out>"
  chmod 755 "${HOME}/bin/commandunit"
}

test_block_2
