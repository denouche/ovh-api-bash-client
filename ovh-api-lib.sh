#!/usr/bin/env bash


readonly OVHAPI_BASHCLIENT_DIR=$(dirname "${BASH_SOURCE[0]}")
readonly OVHAPI_BASHCLIENT_BIN="${OVHAPI_BASHCLIENT_DIR}/ovh-api-bash-client.sh"
readonly OVHAPI_BASHCLIENT_LIB="${OVHAPI_BASHCLIENT_DIR}/libs"

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


# remove first and last double quote from string
_trimDoubleQuotes()
{
  local value="$1"

  [ -z "${value}" ] && return

  value="${value%\"}"
  value="${value#\"}"
  echo "${value}"
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

  local cmd=(${OVHAPI_BASHCLIENT_BIN})

  ## construct arguments array
  if [ -n "${OVHAPI_BASHCLIENT_PROFILE}" ]; then
    cmd+=(--profile ${OVHAPI_BASHCLIENT_PROFILE})
  fi

  if [ -n "${url}" ]; then
    cmd+=(--url ${url})
  fi

  if [ -n "${method}" ]; then
    cmd+=(--method ${method})
  fi

  if [ -n "${OVHAPI_TARGET}" ]; then
    cmd+=(--target ${OVHAPI_TARGET})
  fi

  if [ "${method}" == "POST" ]; then
      # double-quote data content for bash input
      data=$(printf "%q" "${data}")
      cmd+=(--data ${data})
  fi

  _ovhapilib_echo_debug "command: ${cmd[*]}"

  # best way found to correctly pass quoted arguments to a command called from a function
  client_response=$(echo "${cmd[*]}" | bash)

  OVHAPI_HTTP_STATUS=$(echo "${client_response}" | cut -d ' ' -f1)
  OVHAPI_HTTP_RESPONSE="$(echo "${client_response}" | cut -d ' ' -f2-)"

  _ovhapilib_echo_debug "http_status=${OVHAPI_HTTP_STATUS}"

}



## vendor's JSON.sh parsing functions

# usage : getJSONKeys "json"
#
# return JSON keys list without double quote if present
getJSONKeys()
{
  local json="$1"
  local json_key=

  echo "${json}" \
    | "${OVHAPI_BASHCLIENT_LIB}/JSON.sh" -l \
    | sed -r "s/\[(.+)\]\s+(.*)/\1/" \
    | while read -r json_key
  do
    # replacement for key with nested object
    json_key=${json_key/\",\"/.}
    _trimDoubleQuotes "${json_key}"
  done
}


# usage : getJSONValue "json" field
#
# if field is a string, it can be set with/without double quotes
# if the result is between double quote, only get the value inside
getJSONValue()
{
    local json="$1"
    local field="$2"
    local result=

    # if field is not a number and has double quotes remove them, and always add
    if [[ ! ${field} =~ ^[0-9]+$ ]]; then
      # replacement for key with nested object
      field=${field/./\",\"}
      field="$(_trimDoubleQuotes "${field}")"
      field="\"${field}\""
      _ovhapilib_echo_debug "field: ${field}"

    fi

    result=$(echo "${json}" | "${OVHAPI_BASHCLIENT_LIB}/JSON.sh" -l | grep -F "[${field}]" | sed -r "s/\[${field}\]\s+(.*)/\1/")

    # when result is between double quotes, remove first and last
    result=$(_trimDoubleQuotes "${result}")
    if [ -n "${result}" ]; then
      echo "${result}"
    fi
}

# usage : getJSONValues "json"
#
# if key is a number, return only values
# if key is a string, return pair of key:value per line
getJSONValues()
{
  local json="$1"
  local json_keys=
  local json_key=
  local json_value=

  json_keys=$(getJSONKeys "${json}")

  for json_key in ${json_keys}
  do
    json_value=$(getJSONValue "${json}" "${json_key}")
    # if key is a number, only value is wanted
    if [[ ${json_key} =~ ^[0-9]+$ ]]; then
      echo "${json_value}"
    else
      # key is a field, show with value
      echo "${json_key}:${json_value}"
    fi
  done
}
