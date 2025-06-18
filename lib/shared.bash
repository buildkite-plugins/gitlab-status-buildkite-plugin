#!/bin/bash
set -euo pipefail

# shellcheck source=lib/plugin.bash
. "$DIR/../lib/plugin.bash"
# shellcheck source=lib/curl.bash
. "$DIR/../lib/curl.bash"


if [ "${BUILDKITE_PROJECT_PROVIDER}" != 'gitlab' ]; then
  echo '+++ Provider is not gitlab, can not do anything'
  exit 1
fi

GITLAB_TOKEN_ENV_VAR=$(plugin_read_config API_TOKEN_VAR_NAME "GITLAB_ACCESS_TOKEN")
if [ -z "${!GITLAB_TOKEN_ENV_VAR:-}" ]; then
  echo "+++ ERROR: gitlab access token not configured in variable ${GITLAB_TOKEN_ENV_VAR}"
  exit 1
fi

STATUS_NAME=$(plugin_read_config CHECK_NAME "${BUILDKITE_STEP_KEY:-}$([[ -n "${BUILDKITE_PARALLEL_JOB:-}" ]] && echo "_${BUILDKITE_PARALLEL_JOB:-}")")

if [ -z "${STATUS_NAME}" ]; then
  echo "+++ ERROR: if the step has no key, check-name must be provided"
  exit 1
fi

GITLAB_HOST=$(plugin_read_config GITLAB_HOST "gitlab.com")
PROJECT="$(echo "${BUILDKITE_REPO##*"${GITLAB_HOST}"}" | cut -c 2- )"
PROJECT_SLUG=$(urlencode "${PROJECT%.git}")

TOKEN="${!GITLAB_TOKEN_ENV_VAR}"
