ARG SOURCE_TOOL_IMAGE=alpine:3.18.4
FROM ${SOURCE_TOOL_IMAGE}

# Install prerequisites
RUN apk add bash openjdk11 uuidgen openssl

COPY assets/ /

RUN \
  chmod a+x /usr/bin/ca/entrypoint.sh

VOLUME [ "/var/lib/ca", "/etc/ca" ]

# Where scripts are to be executed from
WORKDIR /usr/bin/ca

# Define entry point that will be executed every time container is activated
ENTRYPOINT [ "/usr/bin/ca/entrypoint.sh" ]
