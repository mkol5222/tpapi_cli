#!/bin/bash

# Check TPAPI quota for API key
# GET https://<service_address>/tecloud/api/<version>/file/quota

# API key
TPAPI_KEY="TE_API_KEY_s0hooUsyRAuWJkwePoRiVWDpiwyctpjUjalsOzsv"
TPAPI_SERVER="te.checkpoint.com"
TPAPI_VER="v1"

function main {
    if [ -f "$TPAPI_FILE" ]
    then
        echo "Investigating $TPAPI_FILE"
    else
        echo "File $TPAPI_FILE not found."
        exit 1
    fi

    filename=$(basename "$TPAPI_FILE")
    extension="${filename##*.}"
    echo "Filename: ${filename}"
    echo "Extension: $extension"

    # test if jq is available
    JQ=$(which jq)
    if [[ $? != 0 ]]; then
        echo "jq is missing - provide it on PATH: https://stedolan.github.io/jq/"
        exit 2
    else
        echo "jq found (${JQ})"
    fi

    # calculate md5 hash
    # calculate hash for $TPAPI_FILE
    TEMD5=`md5sum $TPAPI_FILE | cut -f1 -d" "`
    echo "file: ${TPAPI_FILE} md5: ${TEMD5}"
    TESHA1=`sha1sum $TPAPI_FILE | cut -f1 -d" "`
    echo "file: ${TPAPI_FILE} sha1: ${TESHA1}"

    # is server specified
    if [ ! -z "$TPAPI_SERVER" ]; then
        echo "TE API server: ${TPAPI_SERVER}"
    else
        TPAPI_SERVER="te.checkpoint.com"
        echo "TPAPI_SERVER variable not specified, using $TPAPI_SERVER"
    fi

    echo "Quering SHA1 $TESHA1 ($TPAPI_FILE) at $TPAPI_SERVER"

    # query sha1
    TEQ=`jq -c -n --arg sha1 "$TESHA1" --arg filename "$filename" --arg extension "$extension"  '{request: [{sha1: $sha1, file_type: $extension, file_name: $filename, features: ["te"], te: {reports: ["pdf","xml", "tar", "full_report"], benign_reports: "true" }} ]}'`
    echo Request
    echo $TEQ | jq .

    # call API
    TEQRESP=$(curl -b /tmp/teapicli-cookies -c /tmp/teapicli-cookies -d "$TEQ" -k -s\
        -H "Content-type: application/json"\
        -H "Authorization: $TPAPI_KEY"\
        https://${TPAPI_SERVER}/tecloud/api/${TPAPI_VER}/file/query)

    if [[ $? != 0 ]]; then
        echo "Error quering $TPAPI_SERVER"
        exit 3
    else
        echo "Response:"
        echo $TEQRESP | jq . 
        if [[ $? != 0 ]]; then
            echo "Unexpected API response - not JSON"
            exit 4
        else
            # remove \r because of Windows environments?
            TEQRESPSTATUS=$(echo $TEQRESP | jq -r ".response[0].status.code" | tr -d '\r')
            if [[ $? != 0 ]]; then
                echo "Unexpected API response - no status code"
                exit 5
            else
                TEQRESPLABEL=$(echo $TEQRESP | jq -r ".response[0].status.label" | tr -d '\r')
                TEQRESPMESSAGE=$(echo $TEQRESP | jq -r ".response[0].status.message" | tr -d '\r')
                echo "Status code: ${TEQRESPSTATUS} ${TEQRESPLABEL}"
                echo "${TEQRESPMESSAGE}"
            fi
        fi
    fi
}

# test if file was specified
if [ "$#" -ne 1 ]
then
  echo "Usage: $0 <filename>"
  exit 1
fi

# call query
TPAPI_FILE=$1
main
