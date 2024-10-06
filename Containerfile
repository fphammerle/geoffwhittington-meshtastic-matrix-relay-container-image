# switched from alpine to debian base image in apparently failed attempt
# to reduce number of source builds of python packages for arm32
ARG BASE_IMAGE=docker.io/python:3.12.4-slim-bookworm
ARG MESHTASTIC_MATRIX_RELAY_SOURCE_DIR=/opt/meshtastic-matrix-relay
ARG MESHTASTIC_MATRIX_RELAY_REPO=https://github.com/geoffwhittington/meshtastic-matrix-relay/
ARG MESHTASTIC_MATRIX_RELAY_VERSION=0.8.5
ARG MESHTASTIC_MATRIX_RELAY_COMMIT_HASH=ca452f8b045daf725e4d902d652e4055d0b88155

FROM ${BASE_IMAGE} AS build
ARG MESHTASTIC_MATRIX_RELAY_SOURCE_DIR
ARG UID=1000
RUN set -ux \
    && apt-get update \
    && apt-get install --no-install-recommends --yes \
        g++ `# numpy build` \
        gcc `# pillow build` \
        git \
        libjpeg-dev `# pillow build` \
        ninja-build \
        zlib1g-dev `# pillow build` \
    && mkdir ${MESHTASTIC_MATRIX_RELAY_SOURCE_DIR} \
    && chown $UID ${MESHTASTIC_MATRIX_RELAY_SOURCE_DIR}
USER $UID:1000
WORKDIR ${MESHTASTIC_MATRIX_RELAY_SOURCE_DIR}
ARG MESHTASTIC_MATRIX_RELAY_REPO
ARG MESHTASTIC_MATRIX_RELAY_VERSION
ARG MESHTASTIC_MATRIX_RELAY_COMMIT_HASH
RUN set -ux \
    && git clone --branch ${MESHTASTIC_MATRIX_RELAY_VERSION} \
        ${MESHTASTIC_MATRIX_RELAY_REPO} . \
    && [ "$(git rev-parse HEAD)" \
         = "${MESHTASTIC_MATRIX_RELAY_COMMIT_HASH}" ] \
    && rm -r .git .github .gitignore \
    && python3 -m venv venv \
    && venv/bin/pip install --no-cache-dir --requirement requirements.txt

FROM ${BASE_IMAGE}
ARG MESHTASTIC_MATRIX_RELAY_SOURCE_DIR
ARG MESHTASTIC_MATRIX_RELAY_VERSION
ARG MESHTASTIC_MATRIX_RELAY_COMMIT_HASH
RUN set -ux \
    && apt-get update \
    && apt-get install --no-install-recommends --yes libjpeg62-turbo \
    && rm -r /var/lib/apt/lists/*
COPY --from=build ${MESHTASTIC_MATRIX_RELAY_SOURCE_DIR} \
    ${MESHTASTIC_MATRIX_RELAY_SOURCE_DIR}
# optional for finding source code faster when inspecting image
WORKDIR ${MESHTASTIC_MATRIX_RELAY_SOURCE_DIR}
ENV MESHTASTIC_MATRIX_RELAY_SOURCE_DIR=${MESHTASTIC_MATRIX_RELAY_SOURCE_DIR}
CMD exec \
    "${MESHTASTIC_MATRIX_RELAY_SOURCE_DIR}/venv/bin/python" \
    "${MESHTASTIC_MATRIX_RELAY_SOURCE_DIR}/main.py"
LABEL org.opencontainers.image.title="geoffwhittington/meshtastic-matrix-relay v${MESHTASTIC_MATRIX_RELAY_VERSION} (commit ${MESHTASTIC_MATRIX_RELAY_COMMIT_HASH}) in debian 12/bookworm" \
    org.opencontainers.image.source="https://github.com/fphammerle/geoffwhittington-meshtastic-matrix-relay-container-image"
