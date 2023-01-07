#!/bin/bash
set -euo pipefail

set_status() {
  CURL_ARGS=(
    --request POST
    --silent
    --show-error
  )

  local status=$1

  VARS=(
    "state=${status}"
    "target_url=${BUILDKITE_BUILD_URL}%23${BUILDKITE_STEP_ID:-}"
    "name=${STATUS_NAME}"
  )

  # TODO: move this to --data-urlencode
  ARGUMENTS=$(IFS='&'; echo "${VARS[*]}")

  CURL_ARGS+=("https://${GITLAB_HOST}/api/v4/projects/${PROJECT_SLUG}/statuses/${BUILDKITE_COMMIT}?${ARGUMENTS}")

  if [ "$(plugin_read_config CURL_DEBUG "false")" = "true" ]; then
    echo "Executing curl with ${CURL_ARGS[*]} + private token"
  fi

  CURL_ARGS+=(
    --header "Authorization: Bearer ${TOKEN}"
  )

  curl "${CURL_ARGS[@]}"
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