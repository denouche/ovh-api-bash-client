#!/usr/bin/env bash
HERE=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
source ${HERE}/../ovh-api-lib.sh || exit 1

OvhRequestApi /me

if [ ${OVHAPI_HTTP_STATUS} -ne 200 ]; then
  echo "profile error:"
  getJSONValues
  exit
fi

echo "-- all fields --"
getJSONValues
echo "-- only some fields --"
getJSONValue "email"
getJSONValue "currency.code"
getJSONValue "currency.symbol"
