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

@test "Plugin fails if access token variable does not exist" {
  export BUILDKITE_PLUGIN_GITLAB_STATUS_TOKEN_VAR_NAME='NO_EXISTS'

  run "$PWD"/hooks/pre-exit

  assert_failure
  assert_output --partial 'ERROR:'
  assert_output --partial 'in variable NO_EXISTS'
}

@test "Plugin fails provider is not gitlab" {
  export BUILDKITE_PROJECT_PROVIDER='not-gitlab-definitely'

  run "$PWD"/hooks/pre-exit

  assert_failure
  assert_output --partial 'Provider is not gitlab'
}

@test "Default behaviour runs curl successfully" {
  stub curl \
    '\* \* \* \* \* : echo run curl with $@'

  run "$PWD"/hooks/pre-exit

  assert_success

  unstub curl
}

@test "Curl debug prints out message (but not token)" {
  export BUILDKITE_PLUGIN_GITLAB_STATUS_CURL_DEBUG=true
  stub curl \
    '\* \* \* \* \* : echo run curl'

  run "$PWD"/hooks/pre-exit

  assert_success
  assert_output --partial "run curl" # the stub
  assert_output --partial "Executing curl" # the log
  refute_output --partial "PRIVATE_TOKEN"
  refute_output --partial "my-secret-token"

  unstub curl
}

@test "Project is processed correctly (stripped and encoded)" {
  stub curl \
    '\* \* \* \* \* : echo run curl against $3'

  run "$PWD"/hooks/pre-exit

  assert_success
  assert_output --partial "run curl" # the stub
  assert_output --partial "/USER%2fREPO/"
  refute_output --partial "USER/REPO.git"

  unstub curl
}