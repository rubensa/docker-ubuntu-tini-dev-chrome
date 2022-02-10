FROM rubensa/ubuntu-tini-dev
LABEL author="Ruben Suarez <rubensa@gmail.com>"

# Tell docker that all future commands should be run as root
USER root

# Set root home directory
ENV HOME=/root

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt
RUN apt-get update

# Install chrome dependencies
RUN apt-get -y install --no-install-recommends libx11-xcb1 pulseaudio-utils 2>&1

# Add google chrome repo
RUN curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && printf "deb https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    #
    # Install google chrome
    && echo "# Installing chrome..." \
    && apt-get update && apt-get -y install --no-install-recommends google-chrome-stable 2>&1

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
