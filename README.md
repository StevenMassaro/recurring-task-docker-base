# Scheduled Task Docker Base

![ci](https://github.com/StevenMassaro/scheduled-task-docker-base/actions/workflows/build.yml/badge.svg)
[![Docker](https://badgen.net/badge/icon/docker?icon=docker&label)](https://hub.docker.com/r/stevenmassaro/scheduled-task-base)

A simple Docker image that runs a command with a specified delay.

## Usage

### As a standalone image

#### Environment variables:

| Name      | Required | Default value | Example value                                                 |
|-----------|----------|---------------|---------------------------------------------------------------|
| `COMMAND` | Yes      |               | `echo Hello`                                                  |
| `DELAY`   | No       | `1d`          | `7d` (or any other permissible value for the `sleep` command) |

### As the base image of another project

See [this project](https://github.com/StevenMassaro/cuofco-mortgage-rate-check/blob/main/Dockerfile) for an example of how to use this image as your base docker image.
