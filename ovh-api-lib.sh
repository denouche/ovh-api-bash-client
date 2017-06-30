#!/usr/bin/env bash


readonly OVHAPI_BASHCLIENT_DIR=$(dirname "${BASH_SOURCE[0]}")
readonly OVHAPI_BASHCLIENT_BIN="${OVHAPI_BASHCLIENT_DIR}/ovh-api-bash-client.sh"
readonly OVHAPI_BASHCLIENT_LIB="${OVHAPI_BASHCLIENT_DIR}/libs"

OVHAPI_HTTP_STATUS=
OVHAPI_HTTP_RESPONSE=

# ensure the client is available
if [ ! -f "${OVHAPI_BASHCLIENT_BIN}" ]; then
  echo "${OVHAPI_BASHCLIENT_BIN} not found"
  exit 1
fi

# to set a profile, define value in the variable OVHAPI_BASHCLIENT_PROFILE
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
  local quote=

  local cmd=(${OVHAPI_BASHCLIENT_BIN})

  if [ -n "${OVHAPI_BASHCLIENT_PROFILE}" ]; then
    cmd+=(--profile ${OVHAPI_BASHCLIENT_PROFILE})
  fi
  if [ -n "${url}" ]; then
    cmd+=(--url ${url})
  fi
  if [ -n "${method}" ]; then
    cmd+=(--method ${method})
  fi

  if [ "${method}" == "POST" ]; then
      local cmdfile=$(mktemp "/tmp/OvhRequestApi.postcmd.sh.XXXXXX")
      # best way found to correctly pass quoted argument to a command called via a function

      # if json content has single or double quotes inside, to use the opposite
      if echo ${data} | grep -q '"'; then
        quote=\'
      elif echo ${data} | grep -q "'"; then
        quote=\"
      fi

      cmd+=(--data ${quote}${data}${quote})
      # inject all command to a temp file, execute and drop the file
      echo ${cmd[@]} > ${cmdfile}
      client_response=$(bash ${cmdfile})
      rm ${cmdfile}
  else
    client_response=$(${cmd[@]})
  fi

  OVHAPI_HTTP_STATUS=$(echo ${client_response} | cut -d ' ' -f1)
  OVHAPI_HTTP_RESPONSE="$(echo ${client_response} | cut -d ' ' -f2-)"

  # debug information, go to stderr
  echo http_status=${OVHAPI_HTTP_STATUS} >&2

}

## vendors's JSON parsing

# usage : getJSONString "json" field
# remove quotes (first and last character) from wanted field
getJSONString()
{
    local json="$1"
    local field="$2"
    local result=$(getJSONValue "${json}" "${field}")
    echo ${result:1:-1}
}

# usage : getJSONValue "json" field
getJSONValue()
{
    local json="$1"
    local field="$2"
    echo ${json} | ${OVHAPI_BASHCLIENT_LIB}/JSON.sh -l | grep "\[${field}\]" | sed -r "s/\[${field}\]\s+(.*)/\1/"
}

# usage : getJSONValues "json"
# return one value per line
getJSONValues()
{
  local json="$1"
  local i=0
  local length=$(getJSONArrayLength "${json}")

  while [ $i -lt ${length} ];
  do
    getJSONValue "$json" $i
    let i+=1
  done

}

# usage : getJSONArrayLength "json"
# return the size of json array
getJSONArrayLength()
{
    local json="$1"
    echo ${json} | ${OVHAPI_BASHCLIENT_LIB}/JSON.sh -l | wc -l
}
