#!/usr/bin/env bash
HERE=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
source ${HERE}/../ovh-api-lib.sh || exit 1

OvhRequestApi /me

if [ ${OVHAPI_HTTP_STATUS} -ne 200 ]; then
  echo "profile error:"
  getJSONValues
  exit
fi

OvhRequestApi "/domain"

if [ "${OVHAPI_HTTP_STATUS}" -eq 200 ]; then
   domains=($(getJSONValues))
   echo "number of domains=${#domains[@]}"

   # for example, only list for first domain
   #for domain in "${domains[@]}"
   for domain in "${domains[0]}"
   do
     echo -e "\n== informations about ${domain} =="
     OvhRequestApi "/domain/${domain}"
     echo "-- single value --"
     # key can be passed with/without double quote
     getJSONValue lastUpdate
     getJSONValue '"transferLockStatus"'
     echo "-- get all values --"
     getJSONValues
   done
else
  getJSONValues
fi
