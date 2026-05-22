ARG DEBIAN_VERSION=13-slim
ARG SAMTOOLS_VERSION=1.23.1
ARG SAMTOOLS_SHA256=32266198a4bc6a6df395d8526688c9697d9c8e472f888c749fdde2e08ea88dd2
ARG HTSLIB_VERSION=1.23.1
ARG HTSLIB_SHA256=f8a3f36effeec38f043c53ab1f2d9ed45064f14205c5ef8e3c815763b90803c4

# builder #####################################################################

FROM debian:${DEBIAN_VERSION} AS builder

ARG SAMTOOLS_VERSION
ARG SAMTOOLS_SHA256
ARG SAMTOOLS_URL="https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2"
ARG HTSLIB_VERSION
ARG HTSLIB_SHA256
ARG HTSLIB_URL="https://github.com/samtools/htslib/releases/download/${HTSLIB_VERSION}/htslib-${HTSLIB_VERSION}.tar.bz2"

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

RUN curl -fsSL --retry 3 -o "htslib.tar.bz2" "${HTSLIB_URL}" \
    && echo "${HTSLIB_SHA256}  htslib.tar.bz2" | sha256sum -c - \
    && tar -xjf htslib.tar.bz2 \
    && cd "htslib-${HTSLIB_VERSION}" \
    && ./configure \
        --prefix=/opt/samtools \
        --enable-libcurl \
        --enable-s3 \
        --enable-gcs \
    && make -j"$(nproc)" \
    && make install

RUN curl -fsSL --retry 3 -o "samtools.tar.bz2" "${SAMTOOLS_URL}" \
    && echo "${SAMTOOLS_SHA256}  samtools.tar.bz2" | sha256sum -c - \
    && tar -xjf samtools.tar.bz2 \
    && cd "samtools-${SAMTOOLS_VERSION}" \
    && ./configure \
        --prefix=/opt/samtools \
        --with-htslib=/opt/samtools \
        LDFLAGS="-Wl,-rpath,/opt/samtools/lib" \
    && make -j"$(nproc)" all \
    && make install \
    && strip /opt/samtools/bin/* /opt/samtools/lib/libhts.so.* || true

# runtime #####################################################################

FROM debian:${DEBIAN_VERSION} AS runtime

ARG DEBIAN_VERSION
ARG SAMTOOLS_VERSION

LABEL org.opencontainers.image.title="samtools" \
    org.opencontainers.image.description="samtools on debian:${DEBIAN_VERSION}" \
    org.opencontainers.image.version="${SAMTOOLS_VERSION}" \
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