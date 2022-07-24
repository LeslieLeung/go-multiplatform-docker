FROM alpine:3.15.5
ARG TARGETOS
ARG TARGETARCH
COPY build/hello_${TARGETOS}_${TARGETARCH} /usr/local/bin/hello
RUN chmod +x /usr/local/bin/hello
