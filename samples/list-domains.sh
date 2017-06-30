#!/usr/bin/env bash
HERE=$(dirname "${BASH_SOURCE[0]}")
source ${HERE}/../ovh-api-lib.sh || exit 1

OvhRequestApi "/me"
if [ "${OVHAPI_HTTP_STATUS}" != "200" ]; then
  echo "profile error:"
  echo  ${OVHAPI_HTTP_RESPONSE}
  exit
fi

OvhRequestApi "/domain"

if [ ${OVHAPI_HTTP_STATUS} -eq 200 ]; then
   domains=$(getJSONValues "${OVHAPI_HTTP_RESPONSE}")
   for domain in ${domains}
   do
     echo "- ${domain}"
   done
fi
