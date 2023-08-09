FROM rubensa/ubuntu-tini-dev
LABEL author="Ruben Suarez <rubensa@gmail.com>"

# Architecture component of TARGETPLATFORM (platform of the build result)
ARG TARGETARCH

# Tell docker that all future commands should be run as root
USER root

# Set root home directory
ENV HOME=/root

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Debian repo version used to install chromium (18.04-buster,20.04-bullseye,22.04-bookworm)
ARG DEBIAN_VERSION=bookworm

# Install Google Noto font family
RUN echo "# Installing Google Noto font family..." \
  && apt-get update && apt-get -y install fonts-noto 2>&1

RUN if [ "$TARGETARCH" = "amd64" ]; then \
  echo "# Installing chrome dependencies..." \
  # Install chrome dependencies
  && apt-get -y install --no-install-recommends libgl1-mesa-glx libgl1-mesa-dri libx11-xcb1 pulseaudio-utils 2>&1 \
  # Add google chrome repo
  && mkdir -p /etc/apt/keyrings/ \
  && curl -sSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google.gpg  \
  && printf "deb [signed-by=/etc/apt/keyrings/google.gpg] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
  # Install google chrome
  && echo "# Installing chrome..." \
  && apt-get update && apt-get -y install --no-install-recommends google-chrome-stable 2>&1; \
  elif [ "$TARGETARCH" = "arm64" ]; then \
  # Add debian repo cause neither official arm64 chrome exists nor Ubuntu has deb package
  # In case it's the first time that the user runs gpg and the directory /root/.gnupg/ doesn't exist yet
  gpg -k \
  # Fix: "gpg: keyserver receive failed: Cannot assign requested address"
  # see: https://github.com/usbarmory/usbarmory-debian-base_image/issues/9#issuecomment-451635505
  && echo "disable-ipv6" >> /root/.gnupg/dirmngr.conf \
  && gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/debian.gpg --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138 \
  && gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/debian.gpg --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9 \
  && chmod a+r /etc/apt/trusted.gpg.d/debian.gpg \
  && printf "deb http://http.us.debian.org/debian ${DEBIAN_VERSION} main contrib non-free" > /etc/apt/sources.list.d/debian.list \
  # Configure apt to install chromium from debian repo
  && printf "Package: chromium*\n\rPin: release a=${DEBIAN_VERSION}\n\rPin-Priority: 501\n\r\n\rPackage: *\n\rPin: release a=${DEBIAN_VERSION}\n\rPin-Priority: -10\n\r" >  /etc/apt/preferences.d/99debian-updates \
  # Install chromium
  && echo "# Installing chrome..." \
  # Use --force-overwrite to avoid error (libc6-dev:arm64 (2.36-6)): trying to overwrite '/usr/lib/aarch64-linux-gnu/audit/sotruss-lib.so', which is also in package libc6:arm64 2.35-0ubuntu3.1
  && apt-get update && apt-get -y install --no-install-recommends -o Dpkg::Options::="--force-overwrite" chromium 2>&1 \
  # Make chromium look-like chrome
  && ln -s /usr/bin/chromium /usr/bin/google-chrome; \
  fi

# Clean up apt
RUN apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=

# Tell docker that all future commands should be run as the non-root user
USER ${USER_NAME}

# Set user home directory (see: https://github.com/microsoft/vscode-remote-release/issues/852)
ENV HOME /home/$USER_NAME
