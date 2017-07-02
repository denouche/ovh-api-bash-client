#!/usr/bin/env bash
HERE=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
source ${HERE}/../ovh-api-lib.sh || exit 1

OvhRequestApi /me

if [ "${OVHAPI_HTTP_STATUS}" != "200" ]; then
  echo "profile error:"
  echo "${OVHAPI_HTTP_RESPONSE}"
  exit
else
  echo "-- all fields --"
  getJSONValues "${OVHAPI_HTTP_RESPONSE}"
  echo "-- only some fields --"
  getJSONValue "${OVHAPI_HTTP_RESPONSE}" "email"
  getJSONValue "${OVHAPI_HTTP_RESPONSE}" "currency.code"
  getJSONValue "${OVHAPI_HTTP_RESPONSE}" "currency.symbol"
fi
