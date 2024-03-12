FROM alpine:3.18.4

# Define default organization name CA belongs to
ARG ORGANIZATION=PTDemo.LOCAL
ENV ORGANIZATION=${ORGANIZATION}

COPY assets/conf/ /opt/ca/conf
COPY assets/bin/ /opt/ca/bin

# Install prerequisites
RUN apk add bash openjdk11 uuidgen openssl mc nano && chmod a+x /opt/ca/bin/entrypoint.sh

# Where scripts are to be executed from
WORKDIR /opt/ca/bin
# Define entry point that will be executed every time container is activated
ENTRYPOINT [ "/opt/ca/bin/entrypoint.sh" ]
