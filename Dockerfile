FROM alpine:3.8
LABEL maintainer="v.zorin@anchorfree.com"

RUN apk add --no-cache iptables ipset bash
COPY k8s-iptables.bash /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/k8s-iptables.bash"]


