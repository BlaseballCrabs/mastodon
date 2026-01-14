# For details, see https://github.com/devcontainers/images/tree/main/src/ruby
FROM mcr.microsoft.com/devcontainers/ruby:1-3.3-bookworm

# Install node version from .nvmrc
WORKDIR /app
COPY .nvmrc .
RUN /bin/bash --login -i -c "nvm install"

# Install additional OS packages
RUN apt-get update && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y install --no-install-recommends libicu-dev libidn11-dev ffmpeg imagemagick libvips42 libpam-dev libclang-dev

# lmao rust
RUN /bin/bash --login -i -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"

# Disable download prompt for Corepack
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0

# Move welcome message to where VS Code expects it
COPY .devcontainer/welcome-message.txt /usr/local/etc/vscode-dev-containers/first-run-notice.txt
