# syntax=docker/dockerfile:1
FROM golang:alpine AS builder
ENV TZ=Etc/UTC
RUN apk update \
    && apk --no-cache add \
        build-base \
        pkgconfig
RUN mkdir -p /build /go/bin /go/pkg /go/src/lgtv-tbc
WORKDIR /go/src/lgtv-tbc
COPY lgtv-tbc/go.mod lgtv-tbc/authentication.go lgtv-tbc/main.go lgtv-tbc/update.go .
RUN go build
RUN cp -f lgtv-tbc /build

FROM alpine:latest AS runtime
ENV TZ=UTC
RUN apk update \
    && apk --no-cache add \
        ca-certificates \
    && update-ca-certificates 2>/dev/null || true
COPY --from=builder /build/lgtv-tbc /run
HEALTHCHECK --interval=5m --timeout=3s CMD wget --no-verbose --tries=1 --spider http://localhost:8765 || exit 1
EXPOSE 8765
ENTRYPOINT ["/run/lgtv-tbc","-addr",":8765","-notify","true","-forward","true","-verbose","true"]
STOPSIGNAL SIGQUIT
#CMD[""]
