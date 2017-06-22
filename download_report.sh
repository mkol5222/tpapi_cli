#!/bin/bash


TEAPIKEY="TE_API_KEY_s0hooUsyRAuWJkwePoRiVWDpiwyctpjUjalsOzsv"

function extract_full_report {
    # report folder
    TEREPORTFOLDER="/tmp/tereport-${TEREPORT}"

    # test folder already exists
    if [ -d $TEREPORTFOLDER ]
    then
    echo "Error: directory $TEREPORTFOLDER already exists. Remove it and retry"
    exit 1
    fi

    echo "Creating folder $TEREPORTFOLDER"
    mkdir -p $TEREPORTFOLDER

    # extract
    echo "Extracting $TEREPORTFILE into $TEREPORTFOLDER"
    base64 -s $TEREPORTFILE | gzip -cd - | (cd $TEREPORTFOLDER; tar xvf -)
}

# test if file was specified
if [ "$#" -ne 1 ]
then
  echo "Usage: $0 <report_uid>"
  exit 1
fi

if [ -r ~/.teapirc ]; then
    echo "Reading user config in ~/teapirc...." >&2
    . ~/.teapirc
fi

# is server specified
if [ ! -z "$TESERVER" ]; then
    echo "TE API server: ${TESERVER}"
else
    TESERVER="te.checkpoint.com"
    echo "TESERVER variable not specified, using $TESERVER"
fi

# download
TEREPORT=$1
TEREPORTFILE="/tmp/tereport-${TEREPORT}.bin"

# test file already exists
if [ -f $TEREPORTFILE ]
then
  echo "Error: $TEREPORTFILE already exists. Remove it and retry"
  exit 1
fi

echo "Downloading report ID $TEREPORT to ${TEREPORTFILE}"
curl -s -o "$TEREPORTFILE"\
    -k -H "Authorization: $TEAPIKEY"\
    "https://$TESERVER/tecloud/api/v1/file/download?id=${TEREPORT}"

if [[ $? != 0 ]]; then
    echo "Error downloading report $TEREPORT"
    exit 1
fi

# test if report archive file exists
if [ -f "$TEREPORTFILE" ]
then
	echo "$TEREPORTFILE found."
else
	echo "$TEREPORTFILE not found."
fi

# guess report type
TEREPORTFILETYPE=$(file -b $TEREPORTFILE)
echo "Report file downloaded: $TEREPORTFILETYPE"

case "$TEREPORTFILETYPE" in
    "ASCII text") 
        echo "Error getting report"
        exit 1
        ;;
    "ASCII text, with very long lines, with no line terminators")
        echo "Got full report. Extracting"
        extract_full_report
        exit 0
        ;;
    "XML 1.0 document, ASCII text, with very long lines"|"XML 1.0 document text"|"XML 1.0 document text, ASCII text, with very long lines")
        echo "Got XML report. Renaming"
        TEREPORTXML="/tmp/tereport-${TEREPORT}.xml"
        mv $TEREPORTFILE $TEREPORTXML
        echo "Report file $TEREPORTXML"
        exit 0
        ;;
    "PDF document, version 1.4")
        echo "Got PDF report. Renaming"
        TEREPORTXML="/tmp/tereport-${TEREPORT}.pdf"
        mv $TEREPORTFILE $TEREPORTXML
        echo "Report file $TEREPORTXML"
        exit 0
        ;;
    *) 
        echo "Unexpected file type: $TEREPORTFILETYPE"
        exit 1
        ;;
esac

