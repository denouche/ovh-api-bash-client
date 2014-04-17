ovhApiBashClient
================

A bash client for OVH API (https://api.ovh.com/)

Initialize
----------

In order to create a new OVH API application, run :
    ./ovhApiBashClient.sh --initApp
    

Usage
-----

To make a basic call on GET /me just run :
    ./ovhApiBashClient.sh

Options
-------

Possible arguments are:
    --url <url>         : the API URL to call, for example /domains (default is /me)
    --method <method>   : the HTTP method to use, for example POST (default is GET)
    --data <JSON data>  : the data body to send with the request
    --init              : to initialize the consumer key
    --initApp           : to initialize the API application

