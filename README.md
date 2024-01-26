# Gitlab Status Buildkite Plugin [![Build status](https://badge.buildkite.com/c8fbdc52eafaf1b5b9f74463c8b8736abad9895b7a825f6189.svg)](https://buildkite.com/buildkite/plugins-gitlab-status)

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) for setting the status on a GitLab commit (It's currently an MVP).

This plugin requires that the agent has a gitlab access token ([personal](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#personal-access-tokens), [group](https://docs.gitlab.com/ee/user/group/settings/group_access_tokens.html), [project](https://docs.gitlab.com/ee/user/project/settings/project_access_tokens.html) or [OAuth2](https://docs.gitlab.com/ee/api/oauth2.html)) configured with `api` scope.

## Example

The following pipeline just set the status to success

```yml
steps:
  - command: "echo 'OK'"
    key: "success"
    plugins:
      - gitlab-status#v1.2.0: ~
```

## Configuration options

### Required

Technically, there are no required options for this plugin to work. It is to note that defaults will cause failures in the following situations:

* `check-name`: if the step does not have a `key`
* `token-var-name`: if the access token is not available in the variable `GITLAB_ACCESS_TOKEN`
* `gitlab-host`: if you are not using `gitlab.com`

### Optional

#### `api-token-var-name` (string)

Name **of the variable** that contains the value of the gitlab access token to authenticate with its API. Default: `GITLAB_ACCESS_TOKEN`

#### `check-name` (string)

The name of the check status being reported.

If the step does not have a `key`, you have to provide a non-empty value or it will cause the step to fail.

#### `curl-debug` (boolean)

Whether to show the arguments for the `curl` command to execute (exluding the access token). Default: `false`

#### `gitlab-host` (string)

The host to communicate with gitlab. Should be the same as the one in `BUILDKITE_REPO`. Default: `gitlab.com`

## Development

You can run existing development tools with the following commands:

* tests: `docker run --rm -ti -v "$PWD":/plugin buildkite/plugin-tester:v4.0.0`
* linter: `docker run --rm -ti -v "$PWD":/plugin buildkite/plugin-linter --id gitlab-status`
* shellcheck: `docker run -v "$PWD":/mnt --rm -ti koalaman/shellcheck:stable hooks/* lib/*`
