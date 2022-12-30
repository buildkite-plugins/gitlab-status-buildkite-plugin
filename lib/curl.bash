#!/bin/bash
set -euo pipefail

set_status() {
  CURL_CMD=(
    curl --request POST
    # TODO: move this to be last value added before executing so it is never printed out
    --header "PRIVATE-TOKEN: ${TOKEN}"
  )

  VARS=(
    "target_url=${BUILDKITE_BUILD_URL}"
    "name=${STATUS_NAME}"
  )

  ARGUMENTS=$(IFS='&'; echo "${VARS[*]}")

  CURL_CMD+=("https://${GITLAB_URI}/api/v4/projects/${PROJECT_SLUG}/statuses/${BUILDKITE_COMMIT}?state=success&${ARGUMENTS}")

  "${CURL_CMD[@]}"
}

# Licensed under CC-BY-SA 4.0
# Source: https://stackoverflow.com/a/10660730
# Almost verbatim
urlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"
}