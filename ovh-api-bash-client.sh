#!/usr/bin/env bash

# DEFAULT CONFIG
OVH_CONSUMER_KEY=""
OVH_APP_KEY=""
OVH_APP_SECRET=""

readonly CONSUMER_KEY_FILE=".ovhConsumerKey"
readonly OVH_APPLICATION_FILE=".ovhApplication"
readonly LIBS="libs"

readonly TARGETS=(CA EU US)

declare -A API_URLS
API_URLS[CA]="https://ca.api.ovh.com/1.0"
API_URLS[EU]="https://api.ovh.com/1.0"
API_URLS[US]="https://api.ovhcloud.com/1.0"

declare -A API_CREATE_APP_URLS
API_CREATE_APP_URLS[CA]="https://ca.api.ovh.com/createApp/"
API_CREATE_APP_URLS[EU]="https://api.ovh.com/createApp/"
API_CREATE_APP_URLS[US]="https://api.ovhcloud.com/createApp/"

readonly API_URLS
readonly API_CREATE_APP_URLS

## https://gist.github.com/TheMengzor/968e5ea87e99d9c41782
# resolve $SOURCE until the file is no longer a symlink
SOURCE="${BASH_SOURCE[0]}"
while [[ -h "${SOURCE}" ]]
do
  DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
  SOURCE="$(readlink "${SOURCE}")"
  # if $SOURCE was a relative symlink,
  # we need to resolve it relative to the path where the symlink file was located
  [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
BASE_PATH=$( cd -P "$( dirname "${SOURCE}" )" && pwd )

readonly LEGACY_PROFILES_PATH="${BASE_PATH}/profile"
readonly PROFILES_PATH="${HOME}/.ovh-api-bash-client/profile"

HELP_CMD="$0"

_echoWarning()
{
  echo >&2 "[WARNING] $*"
}

# join alements of an array with a separator (single char)
# usage:
# _arrayJoin "|" "${my_array[@]}"
#
_arrayJoin()
{
    local IFS="$1"
    shift
    echo "$*"
}

_StringToLower()
{
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

_StringToUpper()
{
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

# verify if an array contains an item
# _in_array "wanted" "${array[@]}"
# _in_array "wanted_key" "${!array[@]}"
_in_array()
{
    local item wanted
    wanted="$1"
    shift
    for item; do
        [[ "${item}" == "${wanted}" ]] && return 0
    done
    return 1
}

isTargetValid()
{
    if ! _in_array "${TARGET}" "${TARGETS[@]}"; then
        help "'${TARGET}' is not a valid target, accepted values are: ${TARGETS[*]}"
        exit 1
    fi
}

createApp()
{
    local answer

    echo "For which OVH API do you want to create a new API Application? ($( _arrayJoin "|" "${TARGETS[@]}"))"
    while [[ -z "${answer}" ]]
    do
        read -r answer
    done
    TARGET=$( _StringToUpper "${answer}" )
    isTargetValid

    echo
    echo -e "In order to create an API Application, please visit the link below:\\n${API_CREATE_APP_URLS[${TARGET}]}"
    echo
    echo "Once your application is created, we will configure this script for this application"
    echo -n "Enter the Application Key: "
    read -r OVH_APP_KEY
    echo -n "Enter the Application Secret: "
    read -r OVH_APP_SECRET
    echo "OK!"
    echo "These informations will be stored in the following file: ${CURRENT_PATH}/${OVH_APPLICATION_FILE}_${TARGET}"
    echo -e "${OVH_APP_KEY}\\n${OVH_APP_SECRET}" > "${CURRENT_PATH}/${OVH_APPLICATION_FILE}_${TARGET}"

    echo
    echo "Do you also need to create a consumer key? (y/n)"
    read -r answer
    if [[ -n "${answer}" ]] && [[ "$( _StringToLower "${answer}")" == "y" ]]; then
        createConsumerKey
    else
        echo -e "OK, no consumer key created for now.\\nYou will be able to initalize the consumer key later calling:\\n${HELP_CMD} --init"
    fi
}

createConsumerKey()
{
    local answer

    # ensure an OVH App key is set
    initApplication
    hasOvhAppKey || exit 1

    # condition keeped for retro-compatibility, to always allow post accessRules from --data
    if [[ -z "${POST_DATA}" ]]; then
      buildAccessRules
    fi

    answer=$(requestNoAuth "POST" "/auth/credential")

    getJSONFieldString "${answer}" 'consumerKey' > "${CURRENT_PATH}/${CONSUMER_KEY_FILE}_${TARGET}"
    echo "In order to validate the generated consumerKey, visit the validation url at:"
    getJSONFieldString "${answer}" 'validationUrl'
}

initConsumerKey()
{
    if cat "${CURRENT_PATH}/${CONSUMER_KEY_FILE}_${TARGET}" &> /dev/null; then
        OVH_CONSUMER_KEY="$(cat "${CURRENT_PATH}/${CONSUMER_KEY_FILE}_${TARGET}")"
    fi
}

initApplication()
{
    if cat "${CURRENT_PATH}/${OVH_APPLICATION_FILE}_${TARGET}" &> /dev/null; then
        OVH_APP_KEY=$(sed -n 1p "${CURRENT_PATH}/${OVH_APPLICATION_FILE}_${TARGET}")
        OVH_APP_SECRET=$(sed -n 2p "${CURRENT_PATH}/${OVH_APPLICATION_FILE}_${TARGET}")
    fi
}

updateTime()
{
    # use OVH API's timestamp instead of user's one to bypass misconfigured host.
    curl -s "${API_URL}/auth/time"
}

# usage:
# updateSignData "method" "url" "post_data" "timestamp"
# return: print signature
updateSignData()
{
    local sig_data
    local method=$1
    local url=$2
    local post_data=$3
    local timestamp=$4

    sig_data="${OVH_APP_SECRET}+${OVH_CONSUMER_KEY}+${method}+${API_URL}${url}+${post_data}+${timestamp}"
    echo "\$1\$$(echo -n "${sig_data}" | sha1sum - | cut -d' ' -f1)"
}

help()
{
  # print error message if set
  [[ -n "$1" ]] && echo -e "Error: $1\\n"

cat <<EOF
Help: possible arguments are:
  --url <url>             : the API URL to call, for example /domains (default is /me)
  --method <method>       : the HTTP method to use, for example POST (default is GET)
  --data <JSON data>      : the data body to send with the request
  --target <target>       : the target API [$( _arrayJoin "|" "${TARGETS[@]}")] (default is EU)
  --init                  : to initialize the consumer key, and manage custom access rules file
  --initApp               : to initialize the API application
  --list-profile          : list available profiles in ~/.ovh-api-bash-client/profile directory
  --profile <profile>
            * default : from ~/.ovh-api-bash-client/profile directory
            * <dir>   : from ~/.ovh-api-bash-client/profile/<dir> directory

EOF
}

buildAccessRules()
{
  local access_rules_file="${CURRENT_PATH}/access.rules"
  local method path
  local json_rules
  local answer

  if [[ ! -f "${access_rules_file}" ]]; then
    echo "${access_rules_file} missing, created full access rules"
    echo -e "GET /*\\nPUT /*\\nPOST /*\\nDELETE /*" > "${CURRENT_PATH}/access.rules"
  fi

  echo -e "Current rules for that profile\\n"
  cat "${access_rules_file}"
  echo -e "\\nDo you need to customize this rules ?"
  read -n1 -r -p  "(y/n)> " answer
  echo -e "\\n"

  case ${answer} in
    [Yy]) echo "Operation canceled, please edit ${access_rules_file}"; exit;;
    [Nn]) echo  "Now generating POST JSON Data for accessRules";;
    *) echo "bad choice"; exit 1;;
  esac

  while read -r method path;
  do
    if [[ -n "${method}" ]] && [[ -n "${path}" ]]; then
      json_rules+='{ "method": "'${method}'", "path": "'${path}'"},'
    fi
  done < "${access_rules_file}"
  json_rules=${json_rules::-1}
  if [[ -z "${json_rules}" ]]; then
    echoWarning "no rule defined, please verify your file '${access_rules_file}'"
    exit 1
  fi

  POST_DATA='{ "accessRules": [ '${json_rules}' ] }'

}
parseArguments()
{
    # an action launched out of this function
    INIT_KEY_ACTION=

    while [[ $# -gt 0 ]]
    do
        case $1 in
        --data)
            shift
            POST_DATA=$1
            ;;
        --init)
            INIT_KEY_ACTION="ConsumerKey"
            ;;
        --initApp)
            INIT_KEY_ACTION="AppKey"
            ;;
        --method)
            shift
            METHOD=$1
            ;;
        --url)
            shift
            URL=$1
            ;;
        --target)
            shift
            TARGET=$1
            isTargetValid
            ;;
        --profile)
            shift
            PROFILE=$1
            ;;
        --list-profile)
            listProfile
            exit 0
            ;;
        --help|-h)
            help
            exit 0
            ;;
        *)
            help "Unknow parameter $1"
            exit 0
            ;;
        esac
        shift
    done

}

# usage:
# requestNoAuth "method" "url"
requestNoAuth()
{
    local method=$1
    local url=$2

    local timestamp
    timestamp=$(updateTime)

    curl -s -X "${method}" \
        --header 'Content-Type:application/json;charset=utf-8' \
        --header "X-Ovh-Application:${OVH_APP_KEY}" \
        --header "X-Ovh-Timestamp:${timestamp}" \
        --data "${POST_DATA}" \
        "${API_URL}${url}"
}

request()
{
    local response response_status response_content sig timestamp

    timestamp=$(updateTime)
    sig=$(updateSignData "${METHOD}" "${URL}" "${POST_DATA}" "${timestamp}")

    response=$(curl -s -w '\n%{http_code}\n' -X "${METHOD}" \
    --header 'Content-Type:application/json;charset=utf-8' \
    --header "X-Ovh-Application:${OVH_APP_KEY}" \
    --header "X-Ovh-Timestamp:${timestamp}" \
    --header "X-Ovh-Signature:${sig}" \
    --header "X-Ovh-Consumer:${OVH_CONSUMER_KEY}" \
    --data "${POST_DATA}" \
    "${API_URL}${URL}")

    response_status=$(echo "${response}" | sed -n '$p')
    response_content=$(echo "${response}" | sed '$d')
    echo "${response_status} ${response_content}"
}

getJSONFieldString()
{
    local json field result

    json="$1"
    field="$2"
    # shellcheck disable=SC1117
    result=$(echo "${json}" | "${BASE_PATH}/${LIBS}/JSON.sh" | grep "\[\"${field}\"\]" | sed -r "s/\[\"${field}\"\]\s+(.*)/\1/")
    echo "${result:1:${#result}-2}"
}

# set CURRENT_PATH with profile name
# usage: initProfile |set|get] profile_name
#  set: create the profile if missing
#  get: raise an error if no profile with that name
initProfile()
{
  local create_profile=$1
  local profile=$2

  if [[ ! -d "${PROFILES_PATH}" ]]; then
    mkdir -pv "${PROFILES_PATH}" || exit 1
  fi

  # checking if some profiles remains in legacy profile path
  local legacy_profiles=
  local legacy_default_profile=
  if [[ -d "${LEGACY_PROFILES_PATH}" ]]; then
    # is there any profile in legacy path ?
    legacy_profiles=$(ls -A "${LEGACY_PROFILES_PATH}" 2>/dev/null)
    legacy_default_profile=$(cd "${BASE_PATH}" && ls .ovh* access.rules 2>/dev/null)

    if [[ -n "${legacy_profiles}" ]] || [[ -n "${legacy_default_profile}" ]]; then
      # notify about migration to new location:
      _echoWarning "Your profiles were in the legacy path, migrating to ${PROFILES_PATH}:"

      if [[ -n "${legacy_default_profile}" ]]; then
          _echoWarning "> migrating default profile:"
          echo "${legacy_default_profile}"
          mv "${BASE_PATH}"/{.ovh*,access.rules} "${PROFILES_PATH}"
      fi

      if [[ -n "${legacy_profiles}" ]]; then
          _echoWarning "> migrating custom profiles:"
          echo "${legacy_profiles}"
          mv "${LEGACY_PROFILES_PATH}"/* "${PROFILES_PATH}"
      fi

    fi
  fi

  # if profile is not set, or with value 'default'
  if [[ -z "${profile}" ]] || [[ "${profile}" == "default" ]]; then
    # configuration stored in the profile main path
    CURRENT_PATH="${PROFILES_PATH}"
  else
    # ensure profile directory exists
    if [[ ! -d "${PROFILES_PATH}/${profile}" ]]; then
     case ${create_profile} in
        get)
          echo "${PROFILES_PATH}/${profile} should exists"
          listProfile
          exit 1
          ;;
        set)
          mkdir "${PROFILES_PATH}/${profile}" || exit 1
          ;;
      esac
    fi
    # override default configuration location
    CURRENT_PATH="$( cd "${PROFILES_PATH}/${profile}" && pwd )"
  fi

  if [[ -n "${profile}" ]]; then
    HELP_CMD="${HELP_CMD} --profile ${profile}"
  fi

}

listProfile()
{
  local dir=
  echo "Available profiles: "
  echo "- default"

  if [[ -d "${PROFILES_PATH}" ]]; then
    # only list directory
    for dir in $(cd "${PROFILES_PATH}" && ls -d -- */ 2>/dev/null)
    do
      # display directory name without slash
      echo "- ${dir%%/}"
    done
  fi
}

# ensure OVH App Key an App Secret are defined
hasOvhAppKey()
{
    if [[ -z "${OVH_APP_KEY}" ]] && [[ -z "${OVH_APP_SECRET}" ]]; then
        echo -e "No application is defined for target ${TARGET}, please call to initialize it:\\n${HELP_CMD} --initApp"
        return 1
    fi
    return 0
}

main()
{
    parseArguments "$@"

    # set to default value if empty
    TARGET=${TARGET:-"EU"}
    METHOD=${METHOD:-"GET"}
    URL=${URL:-"/me"}
    PROFILE=${PROFILE:-"default"}
    POST_DATA=${POST_DATA:-}

    readonly API_URL="${API_URLS[${TARGET}]}"

    local profileAction="get"

    if [[ -n "${INIT_KEY_ACTION}" ]]; then
        profileAction="set"
    fi

    initProfile "${profileAction}" "${PROFILE}"

    # user want to add An API Key
    case ${INIT_KEY_ACTION} in
      AppKey) createApp;;
      ConsumerKey) createConsumerKey;;
    esac
    ## exit after initializing any API Keys
    [[ -n "${INIT_KEY_ACTION}" ]] && exit 0

    initApplication
    initConsumerKey

    if hasOvhAppKey; then
      if [[ -z "${OVH_CONSUMER_KEY}" ]]; then
        echo "No consumer key for target ${TARGET}, please call to initialize it:"
        echo "${HELP_CMD} --init"
      else
        request "${METHOD}" "${URL}"
      fi
    fi
}

main "$@"
