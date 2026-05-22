ARG DEBIAN_VERSION=13-slim
ARG PROG_VERSION=1.23.1
ARG PROG_SHA256=32266198a4bc6a6df395d8526688c9697d9c8e472f888c749fdde2e08ea88dd2

# builder #####################################################################

FROM debian:${DEBIAN_VERSION} AS builder

ARG PROG_VERSION
ARG PROG_SHA256
ARG PROG_URL="https://github.com/samtools/samtools/releases/download/${PROG_VERSION}/samtools-${PROG_VERSION}.tar.bz2"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        libbz2-dev \
        libcurl4-openssl-dev \
        libdeflate-dev \
        liblzma-dev \
        libncurses-dev \
        libssl-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/build

RUN curl -fsSL --retry 3 -o "samtools.tar.bz2" "${PROG_URL}" \
    && sha256sum -c - <<< "${PROG_SHA256}  samtools.tar.bz2" \
    && tar -xjf samtools.tar.bz2 \
    && cd "samtools-${PROG_VERSION}" \
    && ./configure \
        --prefix=/opt/samtools \
        --with-htslib=bundled \
        --enable-libcurl \
        --enable-s3 \
        --enable-gcs \
    && make -j"$(nproc)" all \
    && make install \
    && strip /opt/samtools/bin/* || true

# runtime #####################################################################

FROM debian:${DEBIAN_VERSION} AS runtime

ARG DEBIAN_VERSION
ARG PROG_VERSION

LABEL org.opencontainers.image.title="samtools" \
    org.opencontainers.image.description="samtools on debian:${DEBIAN_VERSION}" \
    org.opencontainers.image.version="${PROG_VERSION}" \
    org.opencontainers.image.source="https://github.com/samtools/samtools" \
    org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    PATH=/opt/samtools/bin:${PATH} \
    LC_ALL=C.UTF-8

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libbz2-1.0 \
        libcurl4 \
        libdeflate0 \
        liblzma5 \
        libncursesw6 \
        libssl3 \
        zlib1g \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY --from=builder /opt/samtools /opt/samtools

ENTRYPOINT ["samtools"]
CMD ["--help"]