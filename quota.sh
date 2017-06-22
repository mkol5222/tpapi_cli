#!/bin/bash

# Check TPAPI quota for API key
# GET https://<service_address>/tecloud/api/<version>/file/quota

# API key
TPAPI_KEY="TE_API_KEY_s0hooUsyRAuWJkwePoRiVWDpiwyctpjUjalsOzsv"
TPAPI_SERVER="te.checkpoint.com"
TPAPI_VER="v1"

curl -s -H "Authorization: ${TPAPI_KEY}" "https://${TPAPI_SERVER}/tecloud/api/${TPAPI_VER}/file/quota"

