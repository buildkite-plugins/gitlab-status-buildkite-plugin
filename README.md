# Gitlab Status Buildkite Plugin

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) for setting the status on a GitLab commit

## Example

The following pipeline just set the status to success

```yml
steps:
  - command: "echo 'OK'"
    plugins:
      - gitlab-status#v1.0.0: ~
```

