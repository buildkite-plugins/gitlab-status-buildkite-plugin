#!/usr/bin/env bats

setup() {
  load "$BATS_PLUGIN_PATH/load.bash"

  # Uncomment to enable stub debugging
  # export CURL_STUB_DEBUG=/dev/tty

  export BUILDKITE_BUILD_URL='https://localhost/bk/test'
  export BUILDKITE_COMMIT='commit-sha'
  export BUILDKITE_PROJECT_PROVIDER='gitlab'
  export BUILDKITE_REPO='ssh://gitlab.com/USER/REPO.git'
  export BUILDKITE_STEP_KEY='my-step'

  export GITLAB_ACCESS_TOKEN='my-secret-token'
}

@test "Build is set to running" {

  stub curl \
    "echo run curl against \${12}; while shift; do if [ \"\${1:-}\" = '--data-urlencode' ]; then echo with data \$2; fi; done"

  run "$PWD"/hooks/post-checkout

  assert_success
  assert_output --partial "run curl against" # the stub
  assert_output --partial "with data state=running" # the stub

  unstub curl
}
