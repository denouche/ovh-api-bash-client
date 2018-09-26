#!/usr/bin/env bash

readonly OVHAPI_BASHCLIENT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}")/.." && pwd)
readonly OVHAPI_BASHCLIENT_BIN="${OVHAPI_BASHCLIENT_DIR}/ovh-api-bash-client.sh"
readonly OVHAPI_BASHCLIENT_CONTRIB_DIR="${OVHAPI_BASHCLIENT_DIR}/contrib"

JSONSH_DIR="${OVHAPI_BASHCLIENT_DIR}/libs/"
. "${OVHAPI_BASHCLIENT_CONTRIB_DIR}/jsonsh-lib.sh" || exit 1

OVHAPI_HTTP_STATUS=
OVHAPI_HTTP_RESPONSE=

# debug output: should be setted to 1 from external script
OVHAPILIB_DEBUG=${OVHAPILIB_DEBUG:-0}

# use ovh-api-bash-client default target if not set
OVHAPI_TARGET=${OVHAPI_TARGET:-}


# ensure the client is available
if [ ! -f "${OVHAPI_BASHCLIENT_BIN}" ]; then
  echo "${OVHAPI_BASHCLIENT_BIN} not found"
  exit 1
fi

# debug output if wanted
_ovhapilib_echo_debug()
{
  if [ "${OVHAPILIB_DEBUG}" == "1" ]; then
    echo "[debug:${FUNCNAME[1]}] $*" >&2
  fi
}

# to override profile, define value in the variable OVHAPI_BASHCLIENT_PROFILE
# to override target, define value in the variable OVHAPI_TARGET
# OvhRequestApi url [method] [post_data]
#
# default method: get
# return response code in OVHAPI_HTTP_STATUS and content in OVHAPI_HTTP_RESPONSE
OvhRequestApi()
{
  local url=$1
  local method=$2
  local data=$3

  local client_response=
  local cmd_profile=
  local cmd=("${OVHAPI_BASHCLIENT_BIN}")

  ## construct arguments array
  if [ -n "${OVHAPI_BASHCLIENT_PROFILE}" ]; then
    cmd+=(--profile "${OVHAPI_BASHCLIENT_PROFILE}")
  fi
  cmd_profile=${cmd[*]}

  if [ -n "${url}" ]; then
    cmd+=(--url "${url}")
  fi

  if [ -n "${method}" ]; then
    cmd+=(--method "${method}")
  fi

  if [ -n "${OVHAPI_TARGET}" ]; then
    cmd+=(--target "${OVHAPI_TARGET}")
  fi

  if [ "${method}" == "POST" ] || [ "${method}" == "PUT" ]; then
      # double-quote data content for bash input
      data=$(printf "%q" "${data}")
      cmd+=(--data "${data}")
  fi

  _ovhapilib_echo_debug "command: ${cmd[*]}"

  # best way found to correctly pass quoted arguments to a command called from a function
  client_response=$(echo "${cmd[*]}" | bash)

  OVHAPI_HTTP_STATUS=$(echo "${client_response}" | cut -d ' ' -f1)
  OVHAPI_HTTP_RESPONSE="$(echo "${client_response}" | cut -d ' ' -f2-)"

  # catch profile error
  if [[ ! ${OVHAPI_HTTP_STATUS} =~ ^[0-9]+$ ]] && [[ ${OVHAPI_HTTP_RESPONSE} == *$'\n'* ]]; then
    OVHAPI_HTTP_STATUS=500
    OVHAPI_HTTP_RESPONSE=$(cat <<EOF
["more than one line returned, check your profile : ${cmd_profile}"]
EOF
)
  fi
  _ovhapilib_echo_debug "http_status=${OVHAPI_HTTP_STATUS}"

  # forward result to JSON.sh to be usable with JSONSH functions
  # (avoid user to put this line each time)
  loadJSON "${OVHAPI_HTTP_RESPONSE}"

}
