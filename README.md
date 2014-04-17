ovhApiBashClient
================

A bash client for OVH API (https://api.ovh.com/)

Initialize
----------

### Create an OVH API Application

In order to create a new OVH API application, run:
```
    ./ovhApiBashClient.sh --initApp
```

### Create a Consumer Key

In order to create a new consumer key, run:
```
    ./ovhApiBashClient.sh --init
```

Options
-------

Possible arguments are:
```
    --url <url>         : the API URL to call, for example /domains (default is /me)
    --method <method>   : the HTTP method to use, for example POST (default is GET)
    --data <JSON data>  : the data body to send with the request
    --init              : to initialize the consumer key
    --initApp           : to initialize the API application
```

Usage
-----

### Just some examples:

To make a basic call on GET /me just run:
```
    ./ovhApiBashClient.sh
```

To retrieve your domain list, run:
```
    ./ovhApiBashClient.sh --url "/domain"
```

To activate the monitoring on your dedicated server, run:
```
    ./ovhApiBashClient.sh --method PUT --url "/dedicated/server/ns00000.ovh.net" --data '{"monitoring": true}'
```

