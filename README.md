# dcind (Docker-Compose-in-Docker) For Concourse

Alpine based image that lets you run Docker inside a Concourse task. Task must have `privileged: true` for Docker to start.

[<img src="https://concourse.emjot.de/api/v1/teams/emjot/pipelines/dcind/jobs/build-and-publish/badge">](https://concourse.emjot.de/teams/emjot/pipelines/dcind)

This is an updated fork of https://github.com/taylorsilva/dcind which (as of mid 2024) seems do be unmaintained and still used docker compose v1. Images are published to https://hub.docker.com/repository/docker/emjotde/dcind/.

## Usage

Use it in a task config:
```yaml
image_resource:
  type: registry-image
  source:
    repository: emjotde/dcind
```

Pull it in as a resource to use as a task image:
```yaml
resoures:
- name: dcind
  icon: docker
  type: registry-image
  source:
    repository: emjotde/dcind
    tag: latest

jobs:
...
  - get: dcind
  - task: doing-things
    image: dcind
    privileged: true
```

Run it locally on your machine:
```
$ docker run -it --privileged emjotde/dcind
Starting Docker...
waiting for docker to come up...
bash-5.1#
```

## Tags

The Docker version is used to tag releases of the image. A new image is
published every week to ensure OS packages are up to date.

There are three kinds of tags being published, two rolling and one static.

Rolling Tags:
- `latest`: points to the latest image pushed which contains the latest versions of Docker and Docker Compose
- `DOCKER_VERSION`: This tag is the docker version (e.g. `20.10.6`) and is republished weekly. Only the latest version of docker is republished. Older versions will become stale.

Static Tag:
- `DOCKER_VERSION-YYYYmmdd`: This tag is the docker version plus the date it was published. If you want to stay on a specific version of Docker + Docker Compose then sticking to a particular weekly build will meet your needs.

## Example

Here is an example of a Concourse [job](https://concourse-ci.org/jobs.html)
that uses `emjotde/dcind` image to run a bunch of containers in a task, and
then runs the integration test suite. You can find a full version of this
example in the [`example`](example) directory.

Note that `docker-lib.sh` has bash dependencies, so it is important to use `bash` in your task.

```yaml
- name: integration
  plan:
  - aggregate:
    - get: code
      params: {depth: 1}
      passed: [unit-tests]
      trigger: true
    - get: redis #a registry-image resource
      params:
        format: oci
    - get: busybox #a registry-image resource
      params:
        format: oci
  - task: Run integration tests
    privileged: true
    config:
      platform: linux
      image_resource:
        type: docker-image
        source:
          repository: emjotde/dcind
      inputs:
      - name: code
      - name: redis
      - name: busybox
      run:
        path: bash
        args:
        - -cex
        - |
          source /docker-lib.sh
          start_docker

          # Strictly speaking, preloading of Docker images is not required.
          # However, you might want to do this for a couple of reasons:
          # - If the image comes from a private repository, it is much easier to let Concourse pull it,
          #   and then pass it through to the task.
          # - When the image is passed to the task, Concourse can often get the image from its cache.
          docker load -i redis/image
          docker tag "$(cat redis/image-id)" "$(cat redis/repository):$(cat redis/tag)"

          docker load -i busybox/image
          docker tag "$(cat busybox/image-id)" "$(cat busybox/repository):$(cat busybox/tag)"

          # This is just to visually check in the log that images have been loaded successfully
          docker images

          # Run the container with tests and its dependencies.
          docker compose -f code/example/integration.yml run --rm tests

          # Cleanup.
          # Not sure if this is required.
          # It's quite possible that Concourse is smart enough to clean up the Docker mess itself.
          docker volume rm $(docker volume ls -q)
```
