 OVH API Bash client
================

A bash client for OVH API (https://api.ovh.com/)

Initialize
----------

### Retrieve dependency

First in order to retrieve needed dependency, run:
```
    make
```

### Create an OVH API Application

In order to create a new OVH API application, run:
```
    ./ovh-api-bash-client.sh --initApp
```

### Create a Consumer Key

In order to create a new consumer key, run:
```
    ./ovh-api-bash-client.sh --init
```

Options
-------

### Show help
```
    ./ovh-api-bash-client.sh --help
```

Possible arguments are:
```
  --url <url>             : the API URL to call, for example /domains (default is /me)
  --method <method>       : the HTTP method to use, for example POST (default is GET)
  --data <JSON data>      : the data body to send with the request
  --target <CA|EU>        : the target API (default is EU)
  --init                  : to initialize the consumer key
  --initApp               : to initialize the API application
  --list-profile          : list available profiles in profile/ directory
  --profile <value>
            * default : from script directory
            * <dir>   : from profile/<dir> directory
```

Usage
-----

### Just some examples:

To make a basic call on GET /me just run:
```
    ./ovh-api-bash-client.sh
```

To retrieve your domain list, run:
```
    ./ovh-api-bash-client.sh --url "/domain"
```

To activate the monitoring on your dedicated server, run:
```
    ./ovh-api-bash-client.sh --method PUT --url "/dedicated/server/ns00000.ovh.net" --data '{"monitoring": true}'
```

To create a Consumer key for different account or usage (profile is created if missing)
```
    ./ovh-api-bash-client.sh --profile demo1 --init
    ./ovh-api-bash-client.sh --profile demo2 --init
```


Embedded lib for external scripts
----------

### ovh-api-lib.sh

#### OvhRequestApi

- OvhRequestApi() : wrapper to ovh-api-bash-client.sh

```
    OvhRequestApi url [method] [post_data]
```

return values in OVHAPI_HTTP_STATUS and OVHAPI_HTTP_RESPONSE


#### JSon stuff
- getJSONString() : unquote string value
- getJSONValue() : get JSON value as is
- getJSONValues() : get all JSON values at once
- getJSONArrayLength() : count array elements

### sample usage

Once you've an available OVH API authentication, you can use the library :

To set a profile, define value OVHAPI_BASHCLIENT_PROFILE (can be used inside or outside your script)

**sample-script.sh**

```
    source path/to/ovh-api-bash-client/ovh-api-lib.sh || exit 1
    OvhRequestApi /me
```

**sample**


OVHAPI_BASHCLIENT_PROFILE=demo samples/list-domains.sh
