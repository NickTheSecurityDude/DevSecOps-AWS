#!/bin/bash

REPORT_FILE="report/cfn_nag_junit.xml"

echo "Starting Script"

function escapeXml() {
    export xmlEncoded=$(echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g')
}

function createJUnitTestSuites() {
    if [[ -f $REPORT_FILE ]]; then
        rm $REPORT_FILE
    fi

    echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>" >> $REPORT_FILE
    echo "<testsuites>" >> $REPORT_FILE
}

function endJUnitTestSuites() {
    echo "</testsuites>" >> $REPORT_FILE
}

function createJUnitTestSuite() {
    local id=$1
    escapeXml "$2"
    local filename=$xmlEncoded
    local namespace=$(echo "$filename" | sed 's/\//\./g;')
    local failures=$3
    local host=$4
    local timestamp=$(date +%Y-%m-%dT%H:%M:%S)

    echo "  <testsuite id=\"$id\" package=\"dm.infrastructure.$namespace\" name=\"$filename\" tests=\"1\" failures=\"$failures\" errors=\"0\" timestamp=\"$timestamp\" time=\"1.0\" hostname=\"$host\">" >> $REPORT_FILE
}

function endJUnitTestSuite() {
    echo "  </testsuite>" >> $REPORT_FILE
}


function createJUnitTestCase() {
    escapeXml "$1"
    local id=$xmlEncoded

    escapeXml "$2"
    local message=$xmlEncoded

    echo "      <testcase classname=\"$id\" name=\"$message\" time=\"1.0\">" >> $REPORT_FILE

}

function endJUnitTestCase() {
    echo "      </testcase>" >> $REPORT_FILE
}

function createJUnitFailure() {
    escapeXml "$1"
    local id=$xmlEncoded

    escapeXml "$2"
    local fileName=$xmlEncoded

    escapeXml "$3"
    local message=$xmlEncoded

    if [[ "WARN" == "$4" ]]; then
        local type="WARNING"
    else
        local type="FAILURE"
    fi

    escapeXml "$5"
    local resources=$xmlEncoded

    echo "          <failure message=\"$fileName: $message\" type=\"$type\">" >> $REPORT_FILE
    echo "              Id: $id" >> $REPORT_FILE
    echo "              Message: $message" >> $REPORT_FILE
    echo "              Type: $type" >> $REPORT_FILE
    echo "              File: $fileName" >> $REPORT_FILE
    echo "              Resources: $resources" >> $REPORT_FILE
    echo "          </failure>" >> $REPORT_FILE
}

set +x
set +e

echo "Processing $1"

#Counter for test suite id
export counter=1

# Start junit results file
createJUnitTestSuites

# Loop and write the failure data into the file
for file in $(cat $1 | jq -r '.[].filename'); do

    #Processing each file
    echo "Processing file: ${file}"

    for result in $(cat $1 | jq -r --arg FILENAME "${file}" '.[] | select(.filename == $FILENAME) | .file_results' | base64 -w 0); do

        #Get number of failures in the file
        export failures=$(echo ${result} | base64 --decode | jq -r '.failure_count')

        #Create single test suite for this file
        createJUnitTestSuite "$counter" "$file" "$failures" "$HOSTNAME"

        for (( i = 0; i < $(echo ${result} | base64 --decode | jq -r '.violations | length'); i++ )); do

            export id=$(echo ${result} | base64 --decode | jq -r --arg INDEX $i '.violations[$INDEX | tonumber].id')
            export type=$(echo ${result} | base64 --decode | jq -r --arg INDEX $i '.violations[$INDEX | tonumber].type')
            export message=$(echo ${result} | base64 --decode | jq -r --arg INDEX $i '.violations[$INDEX | tonumber].message')
            export resources=$(echo ${result} | base64 --decode | jq -r --arg INDEX $i '.violations[$INDEX | tonumber].logical_resource_ids[]?')

            #Create a test case
            createJUnitTestCase "$id" "$message"
            createJUnitFailure "$id" "$file" "$message" "$type" "$resources"
            endJUnitTestCase
        done

        #Close junit test suite
        endJUnitTestSuite

        export counter=$(($counter + 1))
    done
done

#Close junit test suite element
endJUnitTestSuites

echo "Script Finished."
