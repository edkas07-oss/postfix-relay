# Base OCI runtime Postfix Enterprise Relay Bridge generik.
ARG BASE_IMAGE=docker.io/library/alpine:latest
FROM ${BASE_IMAGE}

ARG IMAGE_PROJECT=postfix-relay
ARG IMAGE_VERSION=1.0.0
ARG POSTFIX_VERSION=3.11.7

LABEL org.opencontainers.image.title="${IMAGE_PROJECT}" \
      org.opencontainers.image.description="Postfix Enterprise SMTP Relay Bridge" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.postfix.version="${POSTFIX_VERSION}"

RUN apk add --no-cache \
        postfix \
        cyrus-sasl \
        cyrus-sasl-login \
        openssl \
        ca-certificates \
        bash \
    && rm -rf /var/cache/apk/*

COPY entrypoint.sh /usr/local/bin/postfix-entrypoint.sh
RUN chmod 0555 /usr/local/bin/postfix-entrypoint.sh

EXPOSE 25 587

ENTRYPOINT ["/usr/local/bin/postfix-entrypoint.sh"]
