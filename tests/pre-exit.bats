#!/usr/bin/env bats

setup() {
  load "$BATS_PLUGIN_PATH/load.bash"

  # Uncomment to enable stub debugging
  # export CURL_STUB_DEBUG=/dev/tty

  export BUILDKITE_BUILD_URL='https://localhost/bk/test'
  export BUILDKITE_COMMAND_EXIT_STATUS='0'
  export BUILDKITE_COMMIT='commit-sha'
  export BUILDKITE_PROJECT_PROVIDER='gitlab'
  export BUILDKITE_REPO='ssh://gitlab.com/USER/REPO.git'
  export BUILDKITE_STEP_KEY='my-step'

  export GITLAB_ACCESS_TOKEN='my-secret-token'
}

@test "Plugin fails if access token variable does not exist" {
  export BUILDKITE_PLUGIN_GITLAB_STATUS_API_TOKEN_VAR_NAME='NO_EXISTS'

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
    'echo run curl with $@'

  run "$PWD"/hooks/pre-exit

  assert_success
  assert_output --partial "run curl" # the stub
  assert_output --partial "state=success" # the state
  assert_output --partial "name=my-step" # the name

  unstub curl
}

@test "Plugin fails if step key is blank and no check-name is provided" {
  export BUILDKITE_STEP_KEY=''

  run "$PWD"/hooks/pre-exit

  assert_failure
  assert_output --partial 'ERROR:'
  assert_output --partial 'check-name must be provided'
}

@test "Plugin fails if step-key and check-name are blank" {
  export BUILDKITE_STEP_KEY=''
  export BUILDKITE_PLUGIN_GITLAB_STATUS_CHECK_NAME=''

  run "$PWD"/hooks/pre-exit

  assert_failure
  assert_output --partial 'ERROR:'
  assert_output --partial 'check-name must be provided'
}

@test "Curl debug prints out message (but not token)" {
  export BUILDKITE_PLUGIN_GITLAB_STATUS_CURL_DEBUG=true
  stub curl \
    'echo run curl'

  run "$PWD"/hooks/pre-exit

  assert_success
  assert_output --partial "run curl" # the stub
  assert_output --partial "Executing curl with" # the log
  refute_output --partial "Authorization"
  refute_output --partial "Bearer"
  refute_output --partial "my-secret-token"

  unstub curl
}

@test "Project is processed correctly (stripped and encoded)" {
  stub curl \
    "echo run curl against \${12}"

  run "$PWD"/hooks/pre-exit

  assert_success
  assert_output --partial "run curl" # the stub
  assert_output --partial "/USER%2fREPO/"
  refute_output --partial "USER/REPO.git"

  unstub curl
}

@test "Command exit code not 0 sets failure" {
  export BUILDKITE_COMMAND_EXIT_STATUS='1'

  stub curl \
    "echo run curl against \${12}; while shift; do if [ \"\${1:-}\" = '--data-urlencode' ]; then echo with data \$2; fi; done"

  run "$PWD"/hooks/pre-exit

  assert_success
  assert_output --partial "run curl against" # the stub
  assert_output --partial "with data state=failed" # the stub

  unstub curl
}

@test "Command exit code not set sets failure" {
  unset BUILDKITE_COMMAND_EXIT_STATUS

  stub curl \
    "echo run curl against \${12}; while shift; do if [ \"\${1:-}\" = '--data-urlencode' ]; then echo with data \$2; fi; done"

  run "$PWD"/hooks/pre-exit

  assert_success
  assert_output --partial "run curl against" # the stub
  assert_output --partial "with data state=failed" # the stub

  unstub curl
}

@test "JobID is passed through in URL if available" {
  export BUILDKITE_JOB_ID='my-step-id'
  stub curl \
    "echo run curl against \${12}; while shift; do if [ \"\${1:-}\" = '--data-urlencode' ]; then echo with data \$2; fi; done"

  run "$PWD"/hooks/pre-exit

  assert_success
  assert_output --partial "run curl" # the stub
  assert_output --partial "#my-step-id" # the argument
  
  unstub curl
}

@test "GITLAB_HOST changes the gitlab URL" {
  export BUILDKITE_PLUGIN_GITLAB_STATUS_GITLAB_HOST='my-server'
  export BUILDKITE_REPO='ssh://my-server/USER/REPO.git'

  stub curl \
    "echo run curl against \${12}"

  run "$PWD"/hooks/pre-exit

  assert_success
  assert_output --partial "run curl" # the stub
  assert_output --partial "//my-server/api/v4"
  refute_output --partial "//gitlab.com/api/v4"

  unstub curl
}

@test "Can change reported name with check-name option" {
  export BUILDKITE_PLUGIN_GITLAB_STATUS_CHECK_NAME='my-test'

  stub curl \
    "echo run curl against \${12}; while shift; do if [ \"\${1:-}\" = '--data-urlencode' ]; then echo with data \$2; fi; done"

  run "$PWD"/hooks/pre-exit

  assert_success
  assert_output --partial 'run curl' # the stub
  assert_output --partial 'with data name=my-test' # the check name
  refute_output --partial 'with data name=my-step' # the step name

  unstub curl
}

@test "Check name option can have special characters" {
  export BUILDKITE_PLUGIN_GITLAB_STATUS_CHECK_NAME='my test ":@'

  stub curl \
    "echo run curl against \${12}; while shift; do if [ \"\${1:-}\" = '--data-urlencode' ]; then echo with data \$2; fi; done"

  run "$PWD"/hooks/pre-exit

  assert_success
  assert_output --partial 'run curl' # the stub
  assert_output --partial 'with data name=my test ":@' # the check name
  refute_output --partial 'with data name=my-step' # the step name

  unstub curl
}

@test "Check \$BUILDKITE_PARALLEL_JOB appended to \$STATUS_NAME" {
  export BUILDKITE_PARALLEL_JOB=2

  stub curl \
    "echo run curl against \${12}; while shift; do if [ \"\${1:-}\" = '--data-urlencode' ]; then echo with data \$2; fi; done"

  run "$PWD"/hooks/pre-exit

  assert_success
  assert_output --partial 'run curl' # the stub
  assert_output --partial 'with data name=my-step_2' # the step name with parallel job number

  unstub curl
}