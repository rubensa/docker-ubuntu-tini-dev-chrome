# Docker image with development tools and Google Chrome

This is a Docker image based on [rubensa/ubuntu-tini-dev](https://github.com/rubensa/docker-ubuntu-tini-dev) and chrome for headless development.

## Building

You can build the image like this:

```
#!/usr/bin/env bash

DOCKER_REPOSITORY_NAME="rubensa"
DOCKER_IMAGE_NAME="ubuntu-tini-dev-chrome"
DOCKER_IMAGE_TAG="latest"

docker buildx build --platform=linux/amd64,linux/arm64 --no-cache \
  -t "${DOCKER_REPOSITORY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  .

docker buildx build --load \
  -t "${DOCKER_REPOSITORY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
  .
```

## Running

You can run the container like this (change --rm with -d if you don't want the container to be removed on stop):

```
#!/usr/bin/env bash

DOCKER_REPOSITORY_NAME="rubensa"
DOCKER_IMAGE_NAME="ubuntu-tini-dev-chrome"
DOCKER_IMAGE_TAG="latest"

# Get current user UID
USER_ID=$(id -u)
# Get current user main GUID
GROUP_ID=$(id -g)

prepare_docker_timezone() {
  # https://www.waysquare.com/how-to-change-docker-timezone/
  ENV_VARS+=" --env=TZ=$(cat /etc/timezone)"
}

prepare_docker_user_and_group() {
  RUNNER+=" --user=${USER_ID}:${GROUP_ID}"
}

prepare_docker_from_docker() {
  MOUNTS+=" --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker-host.sock"
}

prepare_docker_sound_host_sharing() {
  # Sound device (ALSA - Advanced Linux Sound Architecture - support)
  [ -d /dev/snd ] && DEVICES+=" --device /dev/snd"
  # Pulseaudio unix socket (needs XDG_RUNTIME_DIR support)
  MOUNTS+=" --mount type=bind,source=${XDG_RUNTIME_DIR}/pulse,target=${XDG_RUNTIME_DIR}/pulse,readonly"
  # https://github.com/TheBiggerGuy/docker-pulseaudio-example/issues/1
  ENV_VARS+=" --env=PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native"
  RUNNER_GROUPS+=" --group-add audio"
}

prepare_docker_webcam_host_sharing() {
  # Allow webcam access
  for device in /dev/video*
  do
    if [[ -c $device ]]; then
      DEVICES+=" --device $device"
    fi
  done
  RUNNER_GROUPS+=" --group-add video"
}

prepare_docker_ipc_host_sharing() {
  # Allow shared memory to avoid RAM access failures and rendering glitches due to X extesnion MIT-SHM
  EXTRA+=" --ipc=host"
}

prepare_docker_x11_host_sharing() {
   # X11 Unix-domain socket
  MOUNTS+=" --mount type=bind,source=/tmp/.X11-unix,target=/tmp/.X11-unix"
  ENV_VARS+=" --env=DISPLAY=${DISPLAY}"
  # Credentials in cookies used by xauth for authentication of X sessions
  MOUNTS+=" --mount type=bind,source=${XAUTHORITY},target=${XAUTHORITY}"
  ENV_VARS+=" --env=XAUTHORITY=${XAUTHORITY}"
}

prepare_chrome_seccomp() {
  # mix: https://github.com/moby/moby/blob/master/profiles/seccomp/default.json
  # with: https://github.com/jessfraz/dotfiles/blob/master/etc/docker/seccomp/chrome.json
  # adding: arch_prctl,chroot,clone,fanotify_init,name_to_handle_at,open_by_handle_at,setdomainname,sethostname,setns,syslog,timer_getoverrun,timer_gettime,timer_settime,unshare,vhangup
  # extra additions: clone3 (see https://github.com/moby/moby/pull/42681)
  SECURITY+=" --security-opt seccomp:./chrome-seccomp.json"
}

prepare_docker_timezone
prepare_docker_user_and_group
prepare_docker_from_docker
prepare_docker_sound_host_sharing
prepare_docker_webcam_host_sharing
prepare_docker_ipc_host_sharing
prepare_docker_x11_host_sharing
prepare_chrome_seccomp

docker run --rm -it \
  --name "${DOCKER_IMAGE_NAME}" \
  ${SECURITY} \
  ${ENV_VARS} \
  ${DEVICES} \
  ${MOUNTS} \
  ${EXTRA} \
  ${RUNNER} \
  ${RUNNER_GROUPS} \
   "${DOCKER_REPOSITORY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" "$@"
```

*NOTE*: Mounting /var/run/docker.sock allows host docker usage inside the container (docker-from-docker).

This way, the internal user UID and group GID are changed to the current host user:group launching the container and the existing files under his internal HOME directory that where owned by user and group are also updated to belong to the new UID:GID.

Functions prepare_docker_sound_host_sharing, prepare_docker_webcam_host_sharing, prepare_docker_ipc_host_sharing, prepare_docker_x11_host_sharing and prepare_chrome_seccomp allows chrome to access your host resources.

## Connect

You can connect to the running container like this:

```
#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-dev-chrome"

docker exec -it \
  "${DOCKER_IMAGE_NAME}" \
  bash -l
```

This creates a bash shell run by the internal user.

Once connected...

You can check installed development software:

```
gcc --version
g++ --version
make --version
git version
git lfs install --skip-repo
conda info
sdk version
nvm --version
google-chrome-stable --headless --disable-gpu --no-sandbox --dump-dom http://www.chromestatus.com
```

## Stop

You can stop the running container like this:

```
#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-dev-chrome"

docker stop  \
  "${DOCKER_IMAGE_NAME}"
```

## Start

If you run the container without --rm you can start it again like this:

```
#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-dev-chrome"

docker start \
  "${DOCKER_IMAGE_NAME}"
```

## Remove

If you run the container without --rm you can remove once stopped like this:

```
#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-dev-chrome"

docker rm \
  "${DOCKER_IMAGE_NAME}"
```
