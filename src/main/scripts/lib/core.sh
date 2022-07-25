[[ "${_SHARED_SH:-""}" == "yes" ]] && return 0
_SHARED_SH=yes

# shellcheck disable=SC1090
# source = lib/logging.sh
source "${JF_BASEDIR}/lib/logging.sh"

function join_by() {
  local IFS="$1"
  shift
  echo "$*"
}

function trim() {
  local _data="${1}" _length="${2:-40}"
  if [[ "${#_data}" -gt "${_length}" ]]; then
    echo "${_data}"
    return 0
  fi
  echo "${_data:0:40}..."
}

function message() {
  local IFS=" "
  local _o
  _o="${1}"
  shift
  echo -e "${_o}" "$*" >&2
}

function abort() {
  print_stacktrace "ERROR:" "${@}"
  exit 1
}

function print_stacktrace() {
  local _message="${1}"
  shift
  message "${_message}" "${@}"
  local _i=0
  local _e
  while _e="$(caller $_i)"; do
    message "  at ${_e}"
    _i=$((_i + 1))
  done
}
