FROM alpine:3.18.4

# Define default organization name CA belongs to
ARG ORGANIZATION=PTDemo.LOCAL
ENV ORGANIZATION=${ORGANIZATION}

# Install prerequisites
RUN apk add bash openjdk11 uuidgen openssl mc nano

COPY assets/conf/ /opt/ca/conf
COPY assets/bin/ /opt/ca/bin
RUN \
  sed -i "s|___ORGANIZATION_PLACEHOLDER___|${ORGANIZATION}\3|g" /opt/ca/conf/root-ca/ca.conf && \
  sed -i "s|___ORGANIZATION_PLACEHOLDER___|${ORGANIZATION}\3|g" /opt/ca/conf/intermediate-ca/ca.conf && \
  chmod a+x /opt/ca/bin/entrypoint.sh

VOLUME [ "/opt/ca/data" ]

# Where scripts are to be executed from
WORKDIR /opt/ca/bin

# Define entry point that will be executed every time container is activated
ENTRYPOINT [ "/opt/ca/bin/entrypoint.sh" ]
