FROM alpine

ARG USER
ENV USER=${USER:-creator}

RUN adduser -D $USER && mkdir -p /etc/sudoers.d \
        && echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
        && chmod 0440 /etc/sudoers.d/$USER
USER root
RUN apk add --update p7zip syslinux xorriso bash wget shadow sudo
# Run root operation here
# Change user back to cassandra
USER creator
# WORKDIR $HOME