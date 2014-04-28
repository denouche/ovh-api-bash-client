#!/bin/bash

# DEFAULT CONFIG
OVH_CONSUMER_KEY=""
OVH_APP_KEY=""
OVH_APP_SECRET=""

CONSUMER_KEY_FILE=".ovhConsumerKey"
OVH_APPLICATION_FILE=".ovhApplication"
LIBS="libs"

API_URL="https://api.ovh.com/1.0"
API_CREAT_APP_URL="https://api.ovh.com/createApp/"
CURRENT_PATH="$(pwd)"


# THESE VARS WILL BE USED LATER
METHOD="GET"
URL="/me"
TIME=""
SIGDATA=""
POST_DATA=""



createApp()
{
    echo -e "In order to create an API Application, please visit the link below:\n$API_CREAT_APP_URL"
    echo
    echo "Once your application is created, we will configure this script for this application"
    echo -n "Enter the Application Key: "
    read OVH_APP_KEY
    echo -n "Enter the Application Secret: "
    read OVH_APP_SECRET
    echo "OK!"
    echo "These informations will be stored in the following file: $CURRENT_PATH/$OVH_APPLICATION_FILE"
    echo -e "${OVH_APP_KEY}\n${OVH_APP_SECRET}" > $CURRENT_PATH/$OVH_APPLICATION_FILE

    echo
    echo "Do you also need to create a consumer key? (y/n)"
    read NEXT
    if [ -n "$NEXT" ] && [ $( echo $NEXT | tr [:upper:] [:lower:] ) = y ]
    then
        initApplication
        createConsumerKey
    else
        echo -e "OK, no consumer key created for now.\nYou will be able to initiaze the consumer key later calling :\n$0 --init"
    fi
}

createConsumerKey()
{
    METHOD="POST"
    URL="/auth/credential"
    POST_DATA='{ "accessRules": [ { "method": "GET", "path": "/*"}, { "method": "PUT", "path": "/*"}, { "method": "POST", "path": "/*"}, { "method": "DELETE", "path": "/*"} ] }'

    ANSWER=$(requestNoAuth)
    getJSONFieldString "$ANSWER" 'consumerKey' > $CURRENT_PATH/$CONSUMER_KEY_FILE
    echo -e "In order to validate the generated consumerKey, visit the validation url at:\n$(getJSONFieldString "$ANSWER" 'validationUrl')"
}

initConsumerKey()
{
    cat $CURRENT_PATH/$CONSUMER_KEY_FILE &> /dev/null
    if [ $? -eq 0 ]
    then
        OVH_CONSUMER_KEY="$(cat $CURRENT_PATH/$CONSUMER_KEY_FILE)"
    fi
}

initApplication()
{
    cat $CURRENT_PATH/$OVH_APPLICATION_FILE &> /dev/null
    if [ $? -eq 0 ]
    then
        OVH_APP_KEY=$(sed -n 1p $CURRENT_PATH/$OVH_APPLICATION_FILE)
        OVH_APP_SECRET=$(sed -n 2p $CURRENT_PATH/$OVH_APPLICATION_FILE)
    fi
}

updateTime()
{
    TIME=$(date '+%s')
}

updateSignData()
{
    SIGDATA="$OVH_APP_SECRET+$OVH_CONSUMER_KEY+$1+${API_URL}$2+$3+$TIME"
    SIG='$1$'$(echo -n $SIGDATA | sha1sum - | cut -d' ' -f1)
}

help()
{
    echo 
    echo "Help: possible arguments are:"
    echo "  --url <url>         : the API URL to call, for example /domains (default is /me)"
    echo "  --method <method>   : the HTTP method to use, for example POST (default is GET)"
    echo "  --data <JSON data>  : the data body to send with the request"
    echo "  --init              : to initialize the consumer key"
    echo "  --initApp           : to initialize the API application"
    echo
}

parseArguments()
{
    while [ $# -gt 0 ]
    do
        case $1 in
        --data)
            shift
            POST_DATA=$1
            ;;
        --init)
            initApplication
            createConsumerKey
            exit 0
            ;;
        --initApp)
            createApp
            exit 0
            ;;
        --method)
            shift
            METHOD=$1
            ;;
        --url)
            shift
            URL=$1
            ;;
        *)
            echo "Unknow parameter $1"
            help
            exit 0
            ;;
        esac
        shift
    done

}

requestNoAuth()
{
    updateTime
    curl -s -X $METHOD --header 'Content-Type:application/json;charset=utf-8' --header "X-Ovh-Application:$OVH_APP_KEY" --header "X-Ovh-Timestamp:$TIME" --data "$POST_DATA" ${API_URL}$URL
}

request()
{
    updateTime
    updateSignData "$METHOD" "$URL" "$POST_DATA"
    
    RESPONSE=$(curl -s -w "\n%{http_code}\n" -X $METHOD --header 'Content-Type:application/json;charset=utf-8' --header "X-Ovh-Application:$OVH_APP_KEY" --header "X-Ovh-Timestamp:$TIME" --header "X-Ovh-Signature:$SIG" --header "X-Ovh-Consumer:$OVH_CONSUMER_KEY" --data "$POST_DATA" ${API_URL}$URL)
    RESPONSE_STATUS=$(echo "$RESPONSE" | sed -n '$p')
    RESPONSE_CONTENT=$(echo "$RESPONSE" | sed '$d')
    echo "$RESPONSE_STATUS $RESPONSE_CONTENT"
}

getJSONFieldString()
{
    JSON="$1"
    FIELD="$2"
    RESULT=$(echo $JSON | $CURRENT_PATH/$LIBS/JSON.sh | grep "\[\"$FIELD\"\]" | sed -r "s/\[\"$FIELD\"\]\s+(.*)/\1/")
    echo ${RESULT:1:-1}
}

main()
{
    parseArguments "$@"
    
    initApplication
    initConsumerKey
    
    if [ -z $OVH_APP_KEY ] && [ -z $OVH_APP_SECRET ]
    then
        echo -e "No application is defined, please call to initialize it:\n$0 --initApp"
    elif [ -z $OVH_CONSUMER_KEY ]
    then
        echo -e "No consumer key, please call to initialize it:\n$0 --init"
    else
        request $METHOD $URL
    fi
}


main "$@"

