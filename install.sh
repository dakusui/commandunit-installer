#!/usr/bin/env bash

set -eu -o pipefail -o errtrace
shopt -s inherit_errexit nullglob compat"${BASH_COMPAT=42}"

# Reads standard streams (stdout and stderr) and assign the content of them to variables specified by the first and
# second parameters respectively.
# Note that this function doesn't declare variables specified by the parameters.
# They need to be defined in the caller side if necessary.
# Also note that the behavior is undefined, when a variable name which starts with `__read_std_` is specified.
# 1:  A variable name to which stdout from the parameter 3- will be assigned.
# 2:  A variable name to which stderr from the parameter 3- will be assigned.
# 3-: A command line to be executed by this function.
function read_std() {
  local __read_std_stdout_varname __read_std_stderr_varname
  local __read_std_tmpfile_stderr __read_std_stdout_content __read_std_stderr_content __read_std_exit_code=0
  __read_std_stdout_varname="$(printf '%q' "${1}")"
  __read_std_stderr_varname="$(printf '%q' "${2}")"
  shift; shift
  __read_std_tmpfile_stderr="$(mktemp)"
  __read_std_stdout_content="$("${@}" 2> "${__read_std_tmpfile_stderr}")" || {
    __read_std_exit_code=$?
  }
  __read_std_stdout_content="$(printf '%q' "${__read_std_stdout_content}")"
  __read_std_stderr_content="$(cat "${__read_std_tmpfile_stderr}")"
  __read_std_stderr_content="$(printf '%q' "${__read_std_stderr_content}")"

  eval "${__read_std_stdout_varname}=${__read_std_stdout_content}"
  eval "${__read_std_stderr_varname}=${__read_std_stderr_content}"

  rm -f "${__read_std_tmpfile_stderr}"
  return "${__read_std_exit_code}"
}

function read_std_thru() {
  read_std "${@}"
  local __readthrough_std_stdout_varname="${1}"
  __readthrough_std_stdout_varname="$(printf '%q' "${__readthrough_std_stdout_varname}")"
  local __readthrough_std_stderr_varname="${2}"
  __readthrough_std_stderr_varname="$(printf '%q' "${__readthrough_std_stderr_varname}")"
  shift
  shift

  eval 'echo $'"${__readthrough_std_stdout_varname}"
  eval 'echo $'"${__readthrough_std_stderr_varname}" >&2
}

function __install_commandunit__clean_installation_reportdir() {
  local _installation_reportdir="${1}"
  echo "Removing ${_installation_reportdir}" >&2
  rm -fr "${_installation_reportdir:?}"
}

function __install_commandunit__perform_checks() {
  local _installation_reportdir="${1}" _session_name="${2}"
  local _failed=0
  local _stdout _stderr _session_dir="${1}/${_session_name}"
  shift
  shift
  mkdir -p "${_session_dir}"
  for _i in "${@}"; do
    mkdir -p "${_session_dir}/${_i}"
    read_std _stdout _stderr "${_i}" || {
      echo "${_stdout}" > "${_session_dir}/${_i}/stdout"
      echo "${_stderr}" > "${_session_dir}/${_i}/stderr"
      echo "FAIL: <${_i}>" >&2
      _failed=$((_failed + 1))
      continue
    }
    echo "${_stdout}" > "${_session_dir}/${_i}/stdout"
    echo "${_stderr}" > "${_session_dir}/${_i}/stderr"
    echo "pass: <${_i}>" >&2
  done
  echo "----"
  echo "FAILED CHECKS: ${_failed}" >&2
  [[ 0 == "${_failed}" ]] || return 1
}

function __install_commandunit__checkenv() {
  local _dest_dir="${1}" _installation_reportdir="${2}"
  # Check $HOME/bin is in PATH environment variable.
  function is_HOME_bin_in_PATH() {
    [[ "${PATH}" == *"${_dest_dir}"* ]] || return 1
  }
  # Check $HOME/bin exists
  function does_HOME_bin_exists() {
    [[ -d "${_dest_dir}" ]] || return 1
  }
  function is_gnused_installed() {
    which sed
    local _o _e
    read_std_thru _o _e sed --version
    echo "${_o}" | grep 'GNU sed'
  }
  function is_yaml2json_installed() {
    which yaml2json
  }
  function is_docker_installed() {
    which docker
  }
  function is_jq_installed() {
    which jq
  }
  function is_bash_installed() {
    which bash
  }
  function is_bash_modern_enough() {
    # shellcheck disable=SC2034
    local _o _e _v _a
    read_std_thru _o _e bash --version
    readarray -t _a < <(echo "${_o}")
    _v="$(echo "${_a[0]}"|sed -E 's/.+version ([^\s]+)/\1/' | sed -E 's/([^\s]+)( [^\s]+)+$/\1/')"
    echo "_v=<${_v}>"
    [[ "${_v%%.*}" -ge 5 ]]
  }
  function docker_run_helloworld_works() {
    docker run hello-world
  }
  function docker_run_mktemp_works() {
    docker run --env TMPDIR=/tmp -it ubuntu mktemp
  }
  __install_commandunit__perform_checks \
    "${_installation_reportdir}" \
    "pre-check" \
    is_HOME_bin_in_PATH does_HOME_bin_exists \
    is_gnused_installed is_yaml2json_installed is_jq_installed \
    is_docker_installed docker_run_helloworld_works docker_run_mktemp_works \
    is_bash_installed is_bash_modern_enough
}



function __install_commandunit__checkinstallation() {
  local _dest="${1}" _appname="${2}" _installation_reportdir="${3}"
  local _filestem_testreport="target/commandunit/report/testreport"
  local _file_testreport_adoc="${_filestem_testreport}.adoc"
  local _file_testreport_json="${_filestem_testreport}.json"
  function installed_executable_is_found_by_which_command() {
    local _which
    _which="$(which "${_appname}")"
    [[ "${_which}" == "${_dest}" ]] || return 1
  }
  function docker_execution_exits_with_non_zero() {
    # Notice, the caller "__install_commandunit__perform_checks" function defines _stderr and _stdout local variables,
    # which are visible to this function.
    _stdout=""
    _stderr=""
    command commandunit --clean || return 0
  }
  function native_execution_exits_with_non_zero() {
    # Notice, the caller "__install_commandunit__perform_checks" function defines _stderr and _stdout local variables,
    # which are visible to this function.
    _stdout=""
    _stderr=""
    command commandunit --native --clean || return 0
  }
  function failed_test_in_tap_report_is_one() {
    local _num_failed
    _num_failed="$(echo "${_stdout}" | grep -c 'not ok')"
    [[ ${_num_failed} == 1 ]] || return 1
  }
  function testreport_json_exists() {
    [[ -f "${_file_testreport_json}" ]] || return 1
  }
  function testreport_adoc_exists() {
    [[ -f "${_file_testreport_adoc}" ]] || return 1
  }
  function testreport_json_num_failed_is_1 {
    local _num_failed
    _num_failed="$(jq .report.summary.failed "${_file_testreport_json}")"
    [[ "${_num_failed}" == 1 ]] || return 1
  }
  __install_commandunit__perform_checks "${_installation_reportdir}" "post-check" installed_executable_is_found_by_which_command \
    docker_execution_exits_with_non_zero failed_test_in_tap_report_is_one testreport_json_exists testreport_adoc_exists testreport_json_num_failed_is_1 \
    native_execution_exits_with_non_zero failed_test_in_tap_report_is_one testreport_json_exists testreport_adoc_exists testreport_json_num_failed_is_1
}

function __install_commandunit__download_commandunit() {
  local _stdout _stderr
  local _url="${1}"
  local _dest="${2}"
  echo "INSTALLING commandunit..." >&2
  read_std _stdout _stderr curl -f "${_url}" -o "${_dest}" || {
    printf 'Failed to download commandunit:\n  url: "%s"\n  dest: "%s"\n  stdout: "%s"\n  stderr: "%s"\n' "${_url}" "${_dest}" "${_stdout}" "${_stderr}">&2
    return "${_err}"
  }
  echo "DONE" >&2
  chmod 755 "${_dest}"
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

function main() {
  local _url="https://raw.githubusercontent.com/dakusui/commandunit/wrapper-verified/src/main/scripts/bin/commandunit"
  local _dest_dir="${HOME}/bin"
  local _appname="commandunit"
  local _dest="${_dest_dir}/${_appname}"
  local _installation_reportdir="target/commandunit/install"
  function clean() {
    __install_commandunit__clean_installation_reportdir "${_installation_reportdir}"
  }
  function precheck() {
    __install_commandunit__checkenv "${_dest_dir}"  "${_installation_reportdir}"
  }
  function install() {
    __install_commandunit__download_commandunit "${_url}" "${_dest}"
  }
  function postcheck() {
    __install_commandunit__checkinstallation "${_dest}" "${_appname}" "${_installation_reportdir}"
  }
  if [[ ${#} == 0 ]]; then
    return 0
  fi
  local _stage="${1}"
  shift
  if [[ "clean precheck install postcheck" != *"${_stage}"* ]]; then
    echo "Unknown subcommand: '${_stage}' was given."
    return 1
  fi
  "${_stage}" 2|& sed -E 's/(.*)/'"$(printf '%-10s' "${_stage}:")"'\1/' >&2 || {
    local _exit_code="$?"
    echo "ERROR!" "${_stage^^}" >&2
    return "${_exit_code}"
  }
  main "${@}"
}

if [[ ${#} == 0 ]]; then
  main clean precheck install postcheck
else
  main "${@}"
fi || {
  echo "INSTALLATION FAILED!"
  exit 1
}
echo "INSTALLATION SUCCEEDED"
