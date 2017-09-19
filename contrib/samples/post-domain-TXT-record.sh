#!/usr/bin/env bash
HERE=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
source ${HERE}/../ovh-api-lib.sh || exit 1

OvhRequestApi /me

if [ ${OVHAPI_HTTP_STATUS} -ne 200 ]; then
  echo "profile error:"
  getJSONValues
  exit
fi

if [ -z "${OVH_DOMAIN}" ]; then
  echo -e "please set one of your domains with :\nOVH_DOMAIN=your_domain.tld"
  echo -e "choose in :\n"

  OvhRequestApi "/domain"
  getJSONValues
  exit 1
fi

txt_field="ovhapilib"

txt_value="test1: text with space and quo't'es"

# avoid backslashes :-) :
CUSTOMDATA=$(cat <<EOF
{"fieldType":"TXT","subDomain":"${txt_field}","target":"${txt_value}","ttl":0}
EOF
)

OvhRequestApi "/domain/zone/${OVH_DOMAIN}/record/" POST "${CUSTOMDATA}"
echo ${OVHAPI_HTTP_STATUS}
getJSONValues

txt_value="test2: text with space and quo't'es"
CUSTOMDATA="{\"fieldType\":\"TXT\",\"subDomain\":\"${txt_field}\",\"target\":\"${txt_value}\",\"ttl\":0}"

OvhRequestApi "/domain/zone/${OVH_DOMAIN}/record/" POST "${CUSTOMDATA}"

echo ${OVHAPI_HTTP_STATUS}
getJSONValues
