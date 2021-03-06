#!/bin/bash

source ../cf_deployment_functions.sh

usage() {
  echo "Usage:
    ./turn-on-holding-page.sh \"[service-available-date]\"

  (the date should be in quotation marks and in the format HH:mm DD/MM/YYYY, e.g. \"14:30 02/03/2019\")
  if no date is given then the holding page will display 'Try again later'"
}

check_date_format() {
  DATE=$1
  PATTERN="[0-9]{2}:[0-9]{2} [0-9]{2}\/[0-9]{2}\/[0-9]{4}"
  if ! [[ ${DATE} =~ ${PATTERN} ]]; then
    usage
    exit 1
  fi
}

# get the 'available from' date if provided
DATE=$1
if ! [[ -z ${DATE} ]]; then
  check_date_format "${DATE}"
fi

check_login_variables_are_set

cf_login

SPACE_SUFFIX="-${CF_SPACE}"
if [[ ${CF_SPACE} == 'production' ]]; then
	SPACE_SUFFIX=''
fi
export SPACE_SUFFIX

ENV_VARIABLES=`cf env apply-for-healthy-start${SPACE_SUFFIX}`
GA_TRACKING_ID=`echo "${ENV_VARIABLES}" | grep GA_TRACKING_ID | cut -d':' -f2 | cut -d',' -f1`
UI_LOG_LEVEL=`echo "${ENV_VARIABLES}" | grep UI_LOG_LEVEL | cut -d':' -f2 | cut -d',' -f1`

cf update-user-provided-service variable-service -p "'{ \"GA_TRACKING_ID\":${GA_TRACKING_ID}, \"UI_LOG_LEVEL\": ${UI_LOG_LEVEL}, \"MAINTENANCE_MODE\":true, \"SERVICE_AVAILABLE_DATE\": \"${DATE}\" }'"

echo
echo "Restarting the application. There will be downtime for a few seconds"
echo
cf restart apply-for-healthy-start${SPACE_SUFFIX}
