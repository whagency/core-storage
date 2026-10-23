FROM coredns/coredns:1.14.1

COPY ./docker/production/dns/Corefile /etc/coredns/

CMD ["-conf", "/etc/coredns/Corefile"]