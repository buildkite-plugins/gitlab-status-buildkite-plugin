#!/bin/bash
set -euo pipefail

set_status() {
  CURL_ARGS=(
    --request POST
    --silent
    --show-error
    --get
  )

  local status=$1

  VARS=(
    "state=${status}"
    "target_url=${BUILDKITE_BUILD_URL}#${BUILDKITE_JOB_ID:-}"
    "name=${STATUS_NAME}"
  )

  for i in "${VARS[@]}"; do
    CURL_ARGS+=(--data-urlencode "$i")
  done

  # https://docs.gitlab.com/ee/api/commits.html#set-the-pipeline-status-of-a-commit
  CURL_ARGS+=("https://${GITLAB_HOST}/api/v4/projects/${PROJECT_SLUG}/statuses/${BUILDKITE_COMMIT}")

  if [ "$(plugin_read_config CURL_DEBUG "false")" = "true" ]; then
    echo "Executing curl with ${CURL_ARGS[*]} + private token"
  fi

  curl "${CURL_ARGS[@]}" --header @<(printf 'Authorization: Bearer %s\n' "${TOKEN}")
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