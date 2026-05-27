#!/bin/sh
set -eu

DATA_DIR=/prometheus
FIXTURE_FILE=/tmp/animalclinic-fixture.prom

rm -rf "${DATA_DIR:?}"/*

now="$(date +%s)"
now="$((now - now % 15))"

awk -v now="$now" '
function between(x, a, b) {
  return x >= a && x <= b
}

function lerp(a, b, t) {
  return a + ((b - a) * t)
}

function latency_max(p) {
  if (p < 0.09) return 1.63
  if (p < 0.12) return lerp(1.63, 4.16, (p - 0.09) / 0.03)
  if (p < 0.32) return 4.16
  if (p < 0.36) return 3.98
  if (p < 0.40) return 1.01
  if (p < 0.43) return 0.18
  if (p < 0.47) return 0.78
  if (p < 0.64) return 2.14
  if (p < 0.70) return 0.00
  if (p < 0.78) return 0.00
  if (p < 0.80) return 2.12
  if (p < 0.83) return 3.83
  if (p < 0.94) return 3.83
  if (p < 0.98) return 3.83
  return 1.042
}

function latency_avg(p) {
  if (between(p, 0.11, 0.15)) return lerp(0.05, 0.58, (p - 0.11) / 0.04)
  if (between(p, 0.15, 0.18)) return lerp(0.58, 0.08, (p - 0.15) / 0.03)
  if (between(p, 0.20, 0.25)) return lerp(0.02, 0.23, (p - 0.20) / 0.05)
  if (between(p, 0.43, 0.47)) return lerp(0.01, 0.24, (p - 0.43) / 0.04)
  if (between(p, 0.47, 0.51)) return lerp(0.24, 0.05, (p - 0.47) / 0.04)
  if (between(p, 0.79, 0.82)) return lerp(0.05, 0.50, (p - 0.79) / 0.03)
  if (between(p, 0.82, 0.85)) return lerp(0.50, 0.03, (p - 0.82) / 0.03)
  if (p > 0.96) return 0.012
  return 0.005
}

function request_rate(p) {
  if (between(p, 0.16, 0.19)) return lerp(0, 90, (p - 0.16) / 0.03)
  if (between(p, 0.19, 0.23)) return lerp(90, 188, (p - 0.19) / 0.04)
  if (between(p, 0.23, 0.27)) return lerp(188, 12, (p - 0.23) / 0.04)
  if (between(p, 0.27, 0.30)) return lerp(12, 0, (p - 0.27) / 0.03)
  if (between(p, 0.80, 0.92)) return lerp(0, 38, (p - 0.80) / 0.12)
  if (p > 0.92) return 38
  return 0
}

function error_rate(p) {
  if (between(p, 0.18, 0.21)) return lerp(0, 10.8, (p - 0.18) / 0.03)
  if (between(p, 0.21, 0.25)) return lerp(10.8, 0, (p - 0.21) / 0.04)
  return 0
}

function business_curve(p, first, plateau, final, boost_start, boost_end) {
  if (p < 0.16) return 0
  if (p < 0.20) return lerp(0, first, (p - 0.16) / 0.04)
  if (p < boost_start) return plateau
  if (p < boost_end) return lerp(plateau, final, (p - boost_start) / (boost_end - boost_start))
  return final
}

BEGIN {
  start = now - 900
  step = 15

  print "# TYPE http_server_requests_seconds_count counter"
  print "# TYPE http_server_requests_seconds_sum counter"
  print "# TYPE http_server_requests_seconds_max gauge"
  print "# TYPE animalclinic_owner_seconds_count counter"
  print "# TYPE animalclinic_pet_seconds_count counter"
  print "# TYPE animalclinic_visit_seconds_count counter"

  ok_count = 0
  err_count = 0
  ok_sum = 0
  err_sum = 0

  for (i = 0; i <= 80; i++) {
    p = i / 60
    if (p > 1) p = 1
    ts = start + (i * step)

    total_rate = request_rate(p)
    err_rate = error_rate(p)
    ok_rate = total_rate - err_rate
    if (ok_rate < 0) ok_rate = 0

    avg = latency_avg(p)
    ok_count += ok_rate * step
    err_count += err_rate * step
    ok_sum += ok_rate * avg * step
    err_sum += err_rate * 0.08 * step

    printf "http_server_requests_seconds_count{application=\"animalclinic\",job=\"api-gateway\",status=\"200\",method=\"GET\",uri=\"/api/gateway/owners\"} %.6f %s\n", ok_count, ts
    printf "http_server_requests_seconds_sum{application=\"animalclinic\",job=\"api-gateway\",status=\"200\",method=\"GET\",uri=\"/api/gateway/owners\"} %.6f %s\n", ok_sum, ts
    printf "http_server_requests_seconds_max{application=\"animalclinic\",job=\"api-gateway\",status=\"200\",method=\"GET\",uri=\"/api/gateway/owners\"} %.6f %s\n", latency_max(p), ts
    printf "http_server_requests_seconds_count{application=\"animalclinic\",job=\"api-gateway\",status=\"500\",method=\"GET\",uri=\"/api/gateway/owners\"} %.6f %s\n", err_count, ts
    printf "http_server_requests_seconds_sum{application=\"animalclinic\",job=\"api-gateway\",status=\"500\",method=\"GET\",uri=\"/api/gateway/owners\"} %.6f %s\n", err_sum, ts

    owner_create = business_curve(p, 650, 650, 1056, 0.83, 1.00)
    pet_create = business_curve(p, 1260, 1260, 2059, 0.83, 1.00)
    visit_create = business_curve(p, 1180, 1180, 1964, 0.83, 1.00)
    owner_update = business_curve(p, 620, 620, 1021, 0.83, 1.00)
    visit_read = business_curve(p, 1120, 1120, 1868, 0.83, 1.00)

    printf "animalclinic_owner_seconds_count{application=\"animalclinic\",class=\"org.springframework.samples.animalclinic.customers.web.OwnerResource\",method=\"createOwner\",exception=\"none\"} %.6f %s\n", owner_create, ts
    printf "animalclinic_pet_seconds_count{application=\"animalclinic\",class=\"org.springframework.samples.animalclinic.customers.web.PetResource\",method=\"processCreationForm\",exception=\"none\"} %.6f %s\n", pet_create, ts
    printf "animalclinic_visit_seconds_count{application=\"animalclinic\",class=\"org.springframework.samples.animalclinic.visits.web.VisitResource\",method=\"create\",exception=\"none\"} %.6f %s\n", visit_create, ts
    printf "animalclinic_visit_seconds_count{application=\"animalclinic\",class=\"org.springframework.samples.animalclinic.visits.web.VisitResource\",method=\"read\",exception=\"none\"} %.6f %s\n", visit_read, ts
    printf "animalclinic_owner_seconds_count{application=\"animalclinic\",class=\"org.springframework.samples.animalclinic.customers.web.OwnerResource\",method=\"updateOwner\",exception=\"none\"} %.6f %s\n", owner_update, ts
  }

  print "# EOF"
}
' > "$FIXTURE_FILE"

promtool tsdb create-blocks-from openmetrics "$FIXTURE_FILE" "$DATA_DIR"

exec /bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path="$DATA_DIR" \
  --web.console.libraries=/usr/share/prometheus/console_libraries \
  --web.console.templates=/usr/share/prometheus/consoles \
  "$@"
