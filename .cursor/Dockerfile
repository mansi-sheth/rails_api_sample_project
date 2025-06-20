ARG RUBY_VERSION=3.4.2
ARG NODE_VERSION=22.7.0
ARG USERNAME=ubuntu
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Use Node image so we can pull the binaries from here.
FROM node:$NODE_VERSION AS node

# Ruby build image.
FROM ruby:${RUBY_VERSION}-slim

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    libssl-dev \
    libpq-dev \
    vim \
    git \
    libsasl2-dev \
    libyaml-dev \
    curl && \
    rm -rf /var/lib/apt/lists/*

# Copy node binaries from node image.
COPY --from=node /usr/local /usr/local
COPY --from=node /opt /opt

# Setup environment variables.
ENV LANG=C.UTF-8

# Install development tools
RUN gem install bundler

# Enable corepack for yarn
RUN corepack enable

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# The code will be cloned by the agent later, so we don't copy any application files
