# Recurring Task Docker Base

![ci](https://github.com/StevenMassaro/recurring-task-docker-base/actions/workflows/build.yml/badge.svg)
[![Docker](https://badgen.net/badge/icon/docker?icon=docker&label)](https://hub.docker.com/r/stevenmassaro/recurring-task-base)

A simple Docker image that repeatedly runs a command with a specified delay.

## Usage

### As a standalone image

#### Environment variables:

| Name                 | Required | Default value | Example value                                                 | Description                                                                                                                                                  |
|----------------------|----------|---------------|---------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `COMMAND`            | Yes      |               | `echo Hello`                                                  |                                                                                                                                                              |
| `AFTER_COMMAND`      | No       |               | `echo Hello after`                                            | Command that should be executed after `COMMAND`                                                                                                              |
| `DELAY`              | No       | `1d`          | `7d` (or any other permissible value for the `sleep` command) |                                                                                                                                                              |
| `ADJUST_FOR_RUNTIME` | No       | `true`        | `false`                                                       | If set to true, subtracts the execution time of the task from the delay, ensuring the scheduler runs at consistent intervals (e.g., the same time each day). |

### As the base image of another project

See [this project](https://github.com/StevenMassaro/cuofco-mortgage-rate-check/blob/main/Dockerfile) for an example of
how to use this image as your base docker image.
