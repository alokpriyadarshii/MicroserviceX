FROM prom/prometheus:v2.55.1
ADD prometheus.yml /etc/prometheus/
ADD fixture-entrypoint.sh /usr/local/bin/fixture-entrypoint.sh
ENTRYPOINT ["/bin/sh", "/usr/local/bin/fixture-entrypoint.sh"]
