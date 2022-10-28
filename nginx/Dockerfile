# syntax=docker/dockerfile:1
FROM alpine:latest AS builder
ENV TZ=Etc/UTC
RUN apk update \
    && apk --no-cache add \
        ca-certificates \
        openssl \
    && update-ca-certificates 2>/dev/null || true
RUN mkdir -p /build
WORKDIR /build
COPY nginx/nginx.conf .
COPY nginx/ssl.tar.xz .
RUN tar xvfJ ssl.tar.xz

# https://hub.docker.com/_/nginx
FROM nginx:1-alpine
ENV TZ=Etc/UTC
RUN apk update \
    && apk --no-cache add \
        ca-certificates
COPY --from=builder /build/nginx.conf /etc/nginx/nginx.conf
COPY --from=builder /build/ssl/lgtv-tbc.key.pem /etc/ssl/private/lgtv-tbc.key
COPY --from=builder /build/ssl/lgtv-tbc.cert.pem /etc/ssl/certs/lgtv-tbc.crt
COPY --from=builder /build/ssl/LG_TV_TakeBackControl_Root.crt /usr/share/ca-certificates/mozilla/LG_TV_TakeBackControl_Root.crt
COPY --from=builder /build/ssl/LG_TV_TakeBackControl_Intermediate.crt /usr/share/ca-certificates/mozilla/LG_TV_TakeBackControl_Intermediate.crt
COPY --from=builder /build/ssl/lgtv-tbc.key.pem /etc/nginx/ssl/lgtv-tbc.key
COPY --from=builder /build/ssl/lgtv-tbc.cert.pem /etc/nginx/ssl/lgtv-tbc.crt
COPY --from=builder /build/ssl/ca-fullchain.cert.pem /etc/nginx/ssl/ca-fullchain.pem
RUN update-ca-certificates 2> /dev/null || true
HEALTHCHECK --interval=5m --timeout=3s CMD wget --no-verbose --tries=1 --spider http://lgtv-tbc || exit 1
EXPOSE 80 443
ENTRYPOINT [ "/docker-entrypoint.sh" ]
STOPSIGNAL SIGQUIT
CMD [ "nginx", "-g", "daemon off;" ]
