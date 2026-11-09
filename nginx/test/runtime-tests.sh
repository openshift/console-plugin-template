#!/usr/bin/env bash
#
# Runtime checks for the chart's nginx configuration. ../../test-nginx.sh runs
# this script with "exec --user 0" in a container that runs the nginx image
# the way the Helm chart does: nginx is PID 1 and runs as an arbitrary non-root
# UID with the configuration rendered from the chart in /etc/nginx/plugin, and
# the serving certificate directory /var/cert is an initially empty tmpfs
# owned by root.
#
# The script runs as root only to write /var/cert the way the kubelet's
# AtomicWriter updates a Secret volume: it writes the files to a new
# ..<timestamp> directory (mode 0755, files mode 0644 like the chart's
# defaultMode 420), points a ..data_tmp symlink at it, renames that symlink
# over ..data, and keeps tls.crt and tls.key as symlinks through ..data. This
# emulates a Secret volume update; it is not a real kubelet or the service CA
# operator. Every TLS check opens a new connection.
#
# Usage: runtime-tests.sh rotation NGINX_UID
#        runtime-tests.sh profile intermediate|modern|groups|control

set -uo pipefail

CERT_DIR=/var/cert
PORT=9443
WORK=$(mktemp -d)
failures=0

pass() { echo "PASS: $*"; }
fail() {
  echo "FAIL: $*"
  failures=$((failures + 1))
}

# check DESCRIPTION COMMAND...: passes when COMMAND succeeds.
check() {
  local description=$1
  shift
  if "$@"; then
    pass "$description"
  else
    fail "$description"
  fi
}

finish() {
  rm -rf "$WORK"
  if ((failures > 0)); then
    echo "$failures runtime check(s) failed"
    exit 1
  fi
}
trap finish EXIT

# project NAME=SOURCE...: replaces the content of $CERT_DIR like the kubelet
# AtomicWriter does for a Secret volume.
project() {
  local version spec name old="" link
  version="..$(date +%Y_%m_%d_%H_%M_%S).$RANDOM$RANDOM"
  mkdir -m 0755 "$CERT_DIR/$version"
  for spec in "$@"; do
    install -m 0644 "${spec#*=}" "$CERT_DIR/$version/${spec%%=*}"
  done
  if [[ -L $CERT_DIR/..data ]]; then
    old=$(readlink "$CERT_DIR/..data")
  fi
  ln -s "$version" "$CERT_DIR/..data_tmp"
  mv -T "$CERT_DIR/..data_tmp" "$CERT_DIR/..data"
  for spec in "$@"; do
    name=${spec%%=*}
    [[ -L $CERT_DIR/$name ]] || ln -s "..data/$name" "$CERT_DIR/$name"
  done
  shopt -s nullglob
  for link in "$CERT_DIR"/*; do
    [[ -e $CERT_DIR/$version/${link##*/} ]] || rm -f "$link"
  done
  shopt -u nullglob
  if [[ -n $old ]]; then
    rm -rf "${CERT_DIR:?}/$old"
  fi
}

# project_pair N: projects certificate N and its key.
project_pair() {
  project "tls.crt=$WORK/cert$1.crt" "tls.key=$WORK/cert$1.key"
}

# client [S_CLIENT_ARGS...]: a new TLS connection. The server name is
# "localhost" unless the arguments set -servername or -noservername.
# OPENSSL_CONF=/dev/null keeps the client from applying the image's system
# crypto policy, so the results reflect what the server accepts.
client() {
  local name=(-servername localhost) arg
  for arg in "$@"; do
    if [[ $arg == -servername || $arg == -noservername ]]; then
      name=()
    fi
  done
  OPENSSL_CONF=/dev/null timeout 10 openssl s_client -connect "127.0.0.1:$PORT" \
    ${name[@]+"${name[@]}"} "$@" </dev/null
}

served_fingerprint() {
  client "$@" 2>/dev/null | openssl x509 -noout -fingerprint -sha256 2>/dev/null
}

cert_fingerprint() {
  openssl x509 -in "$WORK/cert$1.crt" -noout -fingerprint -sha256
}

# serves_cert N [S_CLIENT_ARGS...]: a new handshake gets certificate N. The
# expected fingerprint must not be empty, so that a failed certificate
# generation cannot make two empty fingerprints match.
serves_cert() {
  local n=$1 expected
  shift
  expected=$(cert_fingerprint "$n")
  [[ -n $expected && $(served_fingerprint "$@") == "$expected" ]]
}

# handshake_result [S_CLIENT_ARGS...]: prints accepted, rejected or "no TLS
# response". A handshake only counts as rejected when the server answered
# with a TLS alert, not when the connection failed for another reason.
handshake_result() {
  local output
  if output=$(client -brief "$@" 2>&1) && grep -q '^CONNECTION ESTABLISHED' <<<"$output"; then
    echo accepted
  elif grep -qi 'alert' <<<"$output"; then
    echo rejected
  else
    echo "no TLS response"
  fi
}

# expect_handshake accepted|rejected DESCRIPTION S_CLIENT_ARGS...
expect_handshake() {
  local expected=$1 description=$2 result
  shift 2
  result=$(handshake_result "$@")
  if [[ $result == "$expected" ]]; then
    pass "$description: $expected"
  else
    fail "$description: expected $expected, got $result"
  fi
}

port_open() {
  (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null
}

wait_for_port() {
  for _ in $(seq 1 50); do
    port_open && return 0
    sleep 0.2
  done
  return 1
}

# PIDs of the nginx master and worker processes.
nginx_pids() {
  ps -e -o pid=,args= | awk '$2 == "nginx:" { print $1 }' | sort -n | tr '\n' ' '
}

generate_certs() {
  local n
  for n in $(seq 1 "$1"); do
    if ! openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj "/CN=localhost-$n" \
      -addext "subjectAltName=DNS:localhost" \
      -keyout "$WORK/cert$n.key" -out "$WORK/cert$n.crt" 2>"$WORK/openssl.err"; then
      fail "generating test certificate $n: $(cat "$WORK/openssl.err")"
      exit 1
    fi
  done
}

rotation_tests() {
  local nginx_uid=$1 pids name result mode

  echo "Running nginx $(nginx -v 2>&1 | sed 's/.*nginx\///'), $(openssl version)"
  generate_certs 7
  check "nginx listens on port $PORT" wait_for_port

  echo "== nginx process"
  pid1_is_nginx() {
    [[ $(tr '\0' ' ' </proc/1/cmdline) == "nginx: master process "* ]]
  }
  check "PID 1 is the nginx master process: $(tr '\0' ' ' </proc/1/cmdline)" pid1_is_nginx
  nginx_runs_as_uid() {
    [[ $(ps -e -o uid=,args= | awk '$2 == "nginx:" { print $1 }' | sort -u) == "$nginx_uid" ]]
  }
  check "nginx master and workers run as uid $nginx_uid" nginx_runs_as_uid
  pids=$(nginx_pids)
  same_pids() { [[ -n $pids && $(nginx_pids) == "$pids" ]]; }

  echo "== startup without certificate files"
  # nginx does not load certificates whose path contains variables at
  # startup, so it starts, and fails each handshake until the files exist.
  expect_handshake rejected "handshake while $CERT_DIR is empty"
  project_pair 1
  check "first projected certificate is served without a restart" serves_cert 1
  check "nginx processes unchanged (PIDs $pids)" same_pids

  echo "== test fixture: projected certificate files"
  # nginx served the key above, so it reads a file that it does not own.
  mode=$(stat -L -c '%a %u:%g' "$CERT_DIR/tls.key")
  check "fixture: tls.key is mode 644 and owned by root, not by uid $nginx_uid ($mode)" \
    test "$mode" = "644 0:0"
  check "fixture: ..data is a symlink to a timestamped directory" test -L "$CERT_DIR/..data"

  echo "== static files"
  static_status() {
    curl -sk --max-time 5 -o /dev/null -w '%{http_code} %{content_type}' "https://localhost:$PORT/$1"
  }
  check "plugin-manifest.json is served as JSON ($(static_status plugin-manifest.json))" \
    test "$(static_status plugin-manifest.json)" = "200 application/json"
  check "a missing file returns 404" test "$(static_status does-not-exist.js | cut -d' ' -f1)" = 404

  echo "== projected certificate rotation, twice"
  project_pair 2
  check "first rotation: new handshakes get the second certificate" serves_cert 2
  check "first rotation: nginx processes unchanged" same_pids
  project_pair 3
  check "second rotation: new handshakes get the third certificate" serves_cert 3
  check "second rotation: nginx processes unchanged" same_pids

  echo "== server names"
  check "no server name: the projected certificate is served" serves_cert 3 -noservername
  check "server name localhost: the projected certificate is served" serves_cert 3 -servername localhost
  check "unexpected server name: the projected certificate is served" \
    serves_cert 3 -servername unexpected.example.com
  # The server name is never part of the certificate path. nginx may reject
  # a name that is not a valid host name; either way no other file is used.
  # shellcheck disable=SC2016 # literal nginx variable name as a server name
  for name in '../../../../etc/pki/tls/private/localhost.key' '/etc/passwd' \
    '$plugin_certificate_dir' 'tls.key%00.crt'; do
    if serves_cert 3 -servername "$name"; then
      result="the projected certificate is served"
    else
      result=$(handshake_result -servername "$name")
    fi
    case $result in
      "the projected certificate is served" | rejected) pass "server name '$name': $result" ;;
      *) fail "server name '$name': $result" ;;
    esac
  done

  # An invalid update makes handshakes fail until a valid generation is
  # projected; nginx keeps no copy of the previous certificate to fall back to.
  invalid_update() {
    local description=$1 corrected=$2
    shift 2
    echo "== $description, then corrected"
    project "$@"
    expect_handshake rejected "$description"
    check "$description: nginx processes unchanged" same_pids
    project_pair "$corrected"
    check "corrected generation: new handshakes get certificate $corrected" serves_cert "$corrected"
  }
  invalid_update "mismatched key" 4 "tls.crt=$WORK/cert4.crt" "tls.key=$WORK/cert3.key"
  invalid_update "missing key" 5 "tls.crt=$WORK/cert5.crt"
  printf 'not a private key\n' >"$WORK/malformed.key"
  invalid_update "malformed key" 6 "tls.crt=$WORK/cert6.crt" "tls.key=$WORK/malformed.key"
  printf 'not a certificate\n' >"$WORK/malformed.crt"
  invalid_update "malformed certificate" 7 "tls.crt=$WORK/malformed.crt" "tls.key=$WORK/cert7.key"

  check "nginx processes unchanged after all updates (PIDs $(nginx_pids))" same_pids
}

profile_tests() {
  generate_certs 1
  check "nginx listens on port $PORT" wait_for_port
  project_pair 1
  check "the projected certificate is served" serves_cert 1

  case $1 in
    intermediate)
      expect_handshake accepted "TLS 1.3" -tls1_3
      expect_handshake accepted "TLS 1.2 with profile cipher ECDHE-RSA-AES128-GCM-SHA256" \
        -tls1_2 -cipher ECDHE-RSA-AES128-GCM-SHA256
      expect_handshake rejected "TLS 1.1" -tls1_1 -cipher 'DEFAULT:@SECLEVEL=0'
      expect_handshake rejected "TLS 1.2 with non-profile cipher AES128-GCM-SHA256" \
        -tls1_2 -cipher AES128-GCM-SHA256
      expect_handshake rejected "TLS 1.3 with non-profile suite TLS_AES_128_CCM_SHA256" \
        -tls1_3 -ciphersuites TLS_AES_128_CCM_SHA256
      ;;
    modern)
      expect_handshake rejected "TLS 1.2" -tls1_2
      expect_handshake accepted "TLS 1.3" -tls1_3
      ;;
    groups)
      expect_handshake accepted "group X25519MLKEM768" -tls1_3 -groups X25519MLKEM768
      expect_handshake accepted "group X25519" -tls1_3 -groups X25519
      expect_handshake rejected "group secp521r1 (not listed)" -tls1_3 -groups secp521r1
      ;;
    control)
      # The configuration without the rendered TLS settings shows that the
      # restrictions above come from those settings.
      expect_handshake accepted "TLS 1.2 with AES128-GCM-SHA256" -tls1_2 -cipher AES128-GCM-SHA256
      expect_handshake accepted "TLS 1.3 with TLS_AES_128_CCM_SHA256" \
        -tls1_3 -ciphersuites TLS_AES_128_CCM_SHA256
      expect_handshake accepted "group secp521r1" -tls1_3 -groups secp521r1
      ;;
    *)
      fail "unknown profile $1"
      ;;
  esac
}

case ${1:-} in
  rotation) rotation_tests "${2:?NGINX_UID is required}" ;;
  profile) profile_tests "${2:?profile is required}" ;;
  *)
    echo "usage: $0 rotation NGINX_UID | profile intermediate|modern|groups|control" >&2
    exit 2
    ;;
esac
