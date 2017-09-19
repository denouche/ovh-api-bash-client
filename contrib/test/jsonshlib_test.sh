#!/usr/bin/env bash
HERE=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

JSONSH_DIR=${HERE}/../../libs/
source ${HERE}/../../contrib/jsonsh-lib.sh || exit 1

# optional output separator
JSONSH_SEPARATOR="\t:\t"

_pause()
{
  echo -e "\n== $1 ==\n"
  read -p "-- Press ENTER --"
}

_pause "demo file"
JSON=$(cat <<EOF
{
  "person": {
    "name": "Foobar1",
    "foo1": { "bar": "baz1" },
    "child": [ {"name":"bob1_1"}, {"name":"bob1_2"} ]
  },
  "person": {
    "name": "Foobar2",
    "foo1": { "bar": "baz2" },
    "child": [ {"name":"bob2_2"}, {"name":"bob2_2"} ]
  }
}
EOF
)

loadJSON "$JSON"
echo "-- JSON.sh output --"
loadJSON
echo "-- wrapper output --"
getJSONValues


##### testing JSON.sh package.json #####
_pause "simple test with official JSON.sh package.json file"
if [ ! -f "${HERE}/package.json" ]; then
  curl -L -o "${HERE}/package.json" https://github.com/dominictarr/JSON.sh/raw/master/package.json
fi

JSON=$(<${HERE}/package.json)
loadJSON "${JSON}"

_pause "Get only keys"
getJSONKeys
_pause "Get a value"
getJSONValue repository.url
getJSONValue "author"

_pause "Get all items"
getJSONValues

_pause "== simple test with a JSON array"
JSON='["foo","bar"]'
loadJSON "${JSON}"

_pause "Get only keys"
getJSONKeys

_pause "Get value for an id (array index)"
getJSONValue 1

_pause "Get all items"
getJSONValues

##### performance test with bigger JSON file :-) #####
echo "== test with a bigger JSON =="

if [ ! -f "${HERE}/earthporn.json" ]; then
  # if you have the "Too Many Requests" message, download from your browser
  curl -o "${HERE}/earthporn.json" https://www.reddit.com/r/earthporn.json
fi

JSON=$(<${HERE}/earthporn.json)
time loadJSON "${JSON}"

_pause "Get only keys"

time getJSONKeys

_pause "Get some values"

time getJSONValue "data.children[10].data.ups"
time getJSONValue "data.after"
time getJSONValue "data.children[19].data.preview.images[0].resolutions[3].url"

_pause "Get all values"

time getJSONValues
