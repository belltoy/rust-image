ARG DOCKER_REGISTRY_MIRROR
ARG BASE_RUST_IMAGE_TAG=alpine

FROM ${DOCKER_REGISTRY_MIRROR}rust:${BASE_RUST_IMAGE_TAG}

ARG ALPINE_MIRROR
ARG CARGO_MIRROR_SOURCE
ARG RUSTUP_DIST_SERVER
ENV RUSTUP_DIST_SERVER=${RUSTUP_DIST_SERVER:-https://static.rust-lang.org}

ENV LANG=C.UTF-8

RUN if [ -n "$ALPINE_MIRROR" ]; then \
        cp /etc/apk/repositories /etc/apk/repositories.back; \
        sed -i "s/dl-cdn.alpinelinux.org/${ALPINE_MIRROR}/g" /etc/apk/repositories; \
    fi

RUN apk update && apk upgrade && \
    apk add --no-cache \
    ca-certificates curl wget openssl-dev

RUN if [ -n "$CARGO_MIRROR_SOURCE" ]; then \
        mkdir -p "$CARGO_HOME"; \
        touch $CARGO_HOME/config.toml; \
        echo "" > $CARGO_HOME/config.toml; \
        echo "[source.mirror]"                   >> $CARGO_HOME/config.toml; \
        echo "registry = '$CARGO_MIRROR_SOURCE'" >> $CARGO_HOME/config.toml; \
        echo "[source.crates-io]"                >> $CARGO_HOME/config.toml; \
        echo "replace-with = 'mirror'"           >> $CARGO_HOME/config.toml; \
        echo "Use $CARGO_MIRROR_SOURCE as crates-io index mirror"; \
    fi

RUN curl -L --proto '=https' --tlsv1.2 -o /tmp/cargo-binstall.tgz -sSf \
    "https://github.com/cargo-bins/cargo-binstall/releases/latest/download/cargo-binstall-$(uname -m)-unknown-linux-musl.tgz" && \
    tar zxvf /tmp/cargo-binstall.tgz --directory "$CARGO_HOME/bin" && \
    cargo binstall -V && \
    rm /tmp/cargo-binstall.tgz

RUN cargo binstall -y cargo-nextest && cargo nextest -h && cargo nextest -V && \
    cargo binstall -y cargo-llvm-cov && cargo llvm-cov -h && cargo llvm-cov -V && \
    rustup component add clippy llvm-tools-preview

RUN if [ -s /etc/apk/repositories.back ]; then \
        mv /etc/apk/repositories.back /etc/apk/repositories; \
    fi
