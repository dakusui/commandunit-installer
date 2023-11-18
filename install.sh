#!/usr/bin/env bash

set -eu -o pipefail -o errtrace
shopt -s inherit_errexit nullglob compat"${BASH_COMPAT=42}"

function __install_commandunit__checkenv() {
  # Check $HOME/bin exists
  :
}

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

function test_block_3() {
  local _out _err

  _err=$(readarray -t _out < <(echo hello && cat notFound 2>&1)) || {
    local _c=$?
    echo "ERR: <${_err}>" >&2
    return $_c
  }
  echo "exitCode: $?"
  echo "ERR: <${_err}>" >&2
  echo "OUT: <${_out}>" >&2
}

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

function test_block_3() {
  local _err _out _cc=0
  _err=$(_out="$(cat -n $0)" || {
    local _c=$?
    echo "ERROR::<${_err}>"
    return "${_c}"
  } 2>&1
  echo "INFO:<$_out>"
  )
    echo "${_err}"
}

function func() {
  local _varname="${1}"
  _varname="$(printf '%q' "${_varname}")"
  echo "_varname=${_varname}"
  eval "${_varname}=Hello"
}

function test_block_4() {
  local _var
  func _var
  echo "${_var}"
}


function read_exec() {
  local _stdout_varname _stderr_varname
  local _tmpfile_stderr _stdout _stderr _exit_code=0
  _stdout_varname="$(printf '%q' "${1}")"
  _stderr_varname="$(printf '%q' "${2}")"
  shift; shift
  _tmpfile_stderr="$(mktemp)"
  _stdout="$("${@}")" 2> "${_tmpfile_stderr}" || {
    _exit_code=$?
    echo "path-1" >&2
  }
  echo "path-2" >&2
  echo "path-2:stdout: [${_stdout}]" >&2
#  echo "path-2:stderr: [${_stderr}]" >&2
  _stdout="$(printf '%q' "${_stdout}")"
  _stderr="$(printf '%q' "$(cat "${_tmpfile_stderr}")")"
  echo "path-3" >&2

  eval "${_stdout_varname}='${_stdout}'"
  eval "${_stderr_varname}='${_stderr}'"
  echo "path-4" >&2
  return "${_exit_code}"
}

function main() {
  local _stdout="" _stderr=""
  read_exec _stdout _stderr echo HelloHello || {
    :
  }
  echo "stdout=<${_stdout}>"
  echo "stderr=<${_stderr}>"
}

test_block_4