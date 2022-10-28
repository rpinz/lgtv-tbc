# syntax=docker/dockerfile:1
FROM alpine:latest
ENV TZ=Etc/UTC
RUN apk update \
    && apk --no-cache add \
        bind-tools \
        dnsmasq
COPY dnsmasq/dnsmasq.sh /
COPY dnsmasq/dnsmasq.conf.tmpl /etc
RUN chmod 751 /dnsmasq.sh
#HEALTHCHECK --interval=5m --timeout=3s CMD dig  || exit 1
EXPOSE 53
STOPSIGNAL SIGQUIT
ENTRYPOINT [ "/dnsmasq.sh" ]
