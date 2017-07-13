## Embedded libs for external scripts

### jsonsh-lib.sh

#### Introduction

Wrapper for JSON.sh, enhancing output :
- action on keys : transform original key (JSON array) to a friendly format
- action on values : trim double quotes and spaces

**original JSON content**
```
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
```

**JSON.sh output**
```
["person","name"]	"Foobar1"
["person","foo1","bar"]	"baz1"
["person","child",0,"name"]	"bob1_1"
["person","child",1,"name"]	"bob1_2"
["person","name"]	"Foobar2"
["person","foo1","bar"]	"baz2"
["person","child",0,"name"]	"bob2_2"
["person","child",1,"name"]	"bob2_2"
```

**wrapper output**
```
person.name	Foobar1
person.foo1.bar	baz1
person.child[0].name	bob1_1
person.child[1].name	bob1_2
person.name	Foobar2
person.foo1.bar	baz2
person.child[0].name	bob2_2
person.child[1].name	bob2_2
```

#### Functions

- loadJSON()      : forward JSON content to JSON.sh script if JSON is set, otherwise print JSON.sh output)
- getJSONKeys()   : print JSON keys
- getJSONValue()  : print JSON key's value
- getJSONValues() : print full result (json key and value)

JSON.sh is called only one time

From your script or commandline, you can set :
- JSONSH_DIR if JSON.sh is not installed on your system path (should be set before including the lib)
- JSONSH_SEPARATOR if you want a custom separator between JSON key and value (default is ":")
- JSONSHLIB_DEBUG to 1 to enable lib debugging

#### Samples

See **test/** directory :

```
JSONSHLIB_DEBUG=1 ./test/jsonshlib_test.sh
```

### ovh-api-lib.sh

- OvhRequestApi() is wrapper for ovh-api-bash-client.sh
- use jsonsh-lib.sh ( just using loadJSON() )

**usage**
```
OvhRequestApi url [method] [post_data]
```

From your script or commandline, you can set :
- OVHAPI_BASHCLIENT_PROFILE
- OVHAPI_TARGET
- OVHAPILIB_DEBUG to 1 to enable lib debugging

This function set variables OVHAPI_HTTP_STATUS and OVHAPI_HTTP_RESPONSE

OVHAPI_HTTP_RESPONSE is forwarded to loadJSON() to avoid user to put this line each time.

#### Samples

Once you've a valid OVH API authentication, you can use the library

You can find some samples scripts in the **samples/** directory

**sample usage**

```
OVHAPI_BASHCLIENT_PROFILE=demo samples/list-domains.sh
```

See **samples/** directory for more details
