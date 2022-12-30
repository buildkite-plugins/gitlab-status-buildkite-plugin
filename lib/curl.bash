#!/bin/bash
set -euo pipefail

set_status() {
  CURL_CMD=(curl --request POST)

  VARS=(
    "state=success"
    "target_url=${BUILDKITE_BUILD_URL}"
    "name=${STATUS_NAME}"
  )

  # TODO: move this to --data-urlencode
  ARGUMENTS=$(IFS='&'; echo "${VARS[*]}")

  CURL_CMD+=("https://${GITLAB_URI}/api/v4/projects/${PROJECT_SLUG}/statuses/${BUILDKITE_COMMIT}?${ARGUMENTS}")

  if [ "$(plugin_read_config CURL_DEBUG "false")" = "true" ]; then
    echo "Executing ${CURL_CMD[*]} + private token"
  fi

  CURL_CMD+=(
    # TODO: move this to be last value added before executing so it is never printed out
    --header "PRIVATE-TOKEN: ${TOKEN}"
  )

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