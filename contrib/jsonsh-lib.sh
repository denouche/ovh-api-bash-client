#!/usr/bin/env bash

#
# Lib for parsing https://github.com/dominictarr/JSON.sh output
#

JSONSH_CACHE=
JSONSH_SOURCE_MD5=
JSONSH_SEPARATOR=

JSONSHLIB_DEBUG=${JSONSHLIB_DEBUG:-0}

### detect JSON.sh location
# JSON.sh searched in system path
readonly JSONSH_SYSTEM_DIR=$(dirname "$(which JSON.sh 2>/dev/null)" )

# can be overrided
JSONSH_DIR=${JSONSH_DIR:-"${JSONSH_SYSTEM_DIR}"}

if [ -z "${JSONSH_DIR}" ]; then
  echo "JSONSH_DIR should be set" >&2
  exit 1
else
  # to get absolte path
  JSONSH_DIR=$(cd "${JSONSH_DIR}" && pwd)
  if [ ! -f "${JSONSH_DIR}/JSON.sh" ]; then
    echo "${JSONSH_DIR}/JSON.sh not found" >&2
    exit 1
  fi
fi

readonly JSONSH_DIR

# debug output if wanted
_jsonshlib_echo_debug()
{
  if [ "${JSONSHLIB_DEBUG}" == "1" ]; then
    echo "[debug:${FUNCNAME[1]}] $*" >&2
  fi
}

#
# single entry point with JSON.sh
# load json defined as argument, and set result to JSONSH_CACHE
#
# keep result in cache to avoid useless calls to JSON.sh
#
# usage :
# to set source json : loadJSON "json content"
# to get JSON.sh output, don't set argument
#
loadJSON()
{
  local json_source="$1"
  local current_md5=

  if [ -z "${json_source}" ]; then
    if [ -z "${JSONSH_CACHE}" ]; then
      echo "JSON content is empty" >&2
      exit 1
    fi
    _jsonshlib_echo_debug "get JSON.sh result from cache"
    echo "${JSONSH_CACHE}"
  else
    # only follow to JSON.sh if JSon content differs
    current_md5=$(echo "${json_source}" | md5sum | cut -d ' ' -f1)
    if [ "${JSONSH_SOURCE_MD5}" != "${current_md5}" ]; then
      _jsonshlib_echo_debug "new JSON source, build JSON.sh cache"
      JSONSH_SOURCE_MD5=${current_md5}
      JSONSH_CACHE=$("${JSONSH_DIR}/JSON.sh" -l <<< "${json_source}")
    fi
  fi

  return 0

}

#
# convert JSON.sh key output format (JSON array) and trim value, through pipe
#
# sample :
# json.sh output : ["foo","bar",0,"baz"] " json value  "
# new output : foo.bar[0].baz json value
#
# for each value, outside double quotes and spaces are removed
#
# _JSonSH_rewrite_output getKeys           : print only keys
# _JSonSH_rewrite_output getValue <field>  : print only value for the field
# _JSonSH_rewrite_output getFull           : print pair of key/value
#
# separator between key and value can be overrided if JSONSH_SEPARATOR is set (default = ":")
#
_JSonSH_rewrite_output()
{
    local action=$1
    local wanted_key=$2

    if [[ "${action}" == "getValue" ]] && [[ -z "${wanted_key}" ]]; then
      echo "key is required" >&2
      exit 1
    fi

    JSONSH_SEPARATOR=${JSONSH_SEPARATOR:-":"}

    awk -F '\t' \
        -v action="${action}" \
        -v wanted_key="${wanted_key}" \
        -v separator="${JSONSH_SEPARATOR}" \
     '{
       json_key = $1
       # drop the key from the line
       $1 = ""
       json_value=$0

       ## Actions on json key :
       # 1) remove some chars : brackets and double quotes
       gsub(/\[|\]|\"/,"",json_key)
       # 2) detect array index between comma, put digits between brackets
       json_key = gensub(/(,([[:digit:]]+)(,|))/,"[\\2]\\3","g",json_key)
       # 3) replace each comma with dot
       gsub(/,/,".",json_key)

       ## Actions on json value :
       #  remove first/last double quotes if present
       json_value = gensub(/"(.*)"$/,"\\1","g",json_value)
       # trim first/last spaces of value
       gsub(/^\s+|\s+$/,"",json_value)

       switch (action) {
         case "getKeys":
           print json_key
           break
         case "getValue":
           #  remove first/last double quotes if present
           wanted_key = gensub(/"(.*)"$/,"\\1","g",wanted_key)
           # the value for a key is wanted
           if (json_key == wanted_key)
           {
             # display value if found and stop
             print json_value
             exit 0
           }
           break
         case "getFull":
           if (json_key ~ /^[0-9]+$/ )
           {
             # the key is a number, only value is needed
             print json_value
           } else {
             # the key is a string, display key and value
             print json_key separator json_value
           }
           break
         default:
          print "Bad action !" >"/dev/stderr"
          exit 1
          break
       }
     }' </dev/stdin

}

#
# print JSON keys
#
# usage : getJSONKeys
#
getJSONKeys()
{
  local json=

  json=$(loadJSON) || exit 1
  echo "${json}" | _JSonSH_rewrite_output getKeys
  return $?

}

#
# print the value for a defined field
#
# usage : getJSONValue field
#
getJSONValue()
{
    local field="$1"
    local json=

    _jsonshlib_echo_debug "key : ${field}"

    json=$(loadJSON) || exit 1
    echo "${json}" | _JSonSH_rewrite_output getValue "${field}"
    return $?
}

#
# usage : getJSONValues
#
# print full result (json key and value)
#
getJSONValues()
{
  local json=

  json=$(loadJSON) || exit 1
  echo "${json}" | _JSonSH_rewrite_output getFull
  return $?
}

_jsonshlib_echo_debug "JSONSH_DIR=$JSONSH_DIR"
