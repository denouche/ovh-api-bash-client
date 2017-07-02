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

OvhRequestApi() is wrapper to ovh-api-bash-client.sh

```
    OvhRequestApi url [method] [post_data]
```

return values in OVHAPI_HTTP_STATUS and OVHAPI_HTTP_RESPONSE


#### wrappers for JSON.sh

- getJSONKeys()   : get JSON keys, remove first/last double quotes if present
- getJSONValue()  : get a JSON key value, remove first/last double quotes if present
- getJSONValues() : get all JSON values at once

### sample usage

Once you've an available OVH API authentication, you can use the library :

- To override profile, set OVHAPI_BASHCLIENT_PROFILE
- To override target, set OVHAPI_TARGET
- For **ovh-api-lib.sh** debug output, set OVHAPILIB_DEBUG to 1

This variables can be set in your script or exported from commandline

You can find some samples scripts in the **samples/** directory

**sample usage**

```
  OVHAPI_BASHCLIENT_PROFILE=demo samples/list-domains.sh
```
