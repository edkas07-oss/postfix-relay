#!/usr/bin/env bash
# Entrypoint for Postfix Containerized Enterprise Relay Bridge (Pola A).
set -euo pipefail

readonly MYHOSTNAME="${POSTFIX_MYHOSTNAME:-postfix-relay.devops-lab}"
readonly MYDOMAIN="${POSTFIX_MYDOMAIN:-devops-lab}"
readonly MYORIGIN="${POSTFIX_MYORIGIN:-devops-lab}"
readonly RELAY_HOST="${RELAY_HOST:-mailpit}"
readonly RELAY_PORT="${RELAY_PORT:-1025}"
readonly SASL_DOMAIN="${POSTFIX_SASL_DOMAIN:-devops-lab}"
readonly TLS_DIR="/etc/postfix/tls"
readonly SASL_DIR="/etc/sasl2"

echo "=== Initializing Postfix Enterprise Relay Bridge ==="
echo "Hostname: ${MYHOSTNAME}"
echo "Downstream Relay: [${RELAY_HOST}]:${RELAY_PORT}"

# 1. Ensure directory permissions
mkdir -p "${TLS_DIR}" "${SASL_DIR}" /etc/postfix/sasl /var/spool/postfix /var/lib/postfix
chmod 0755 "${TLS_DIR}" "${SASL_DIR}"

# 2. TLS Certificate initialization
if [[ ! -f "${TLS_DIR}/server.crt" || ! -f "${TLS_DIR}/server.key" ]]; then
    echo "Generating self-signed TLS certificate for ${MYHOSTNAME}..."
    openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
        -subj "/CN=${MYHOSTNAME}" \
        -addext "subjectAltName=DNS:${MYHOSTNAME},DNS:postfix-relay,DNS:localhost" \
        -keyout "${TLS_DIR}/server.key" \
        -out "${TLS_DIR}/server.crt" >/dev/null 2>&1
    chmod 0400 "${TLS_DIR}/server.key"
    chmod 0444 "${TLS_DIR}/server.crt"
fi

# 3. SASL Configuration (Cyrus SASL sasldb)
cat <<SASL_CONF > "${SASL_DIR}/smtpd.conf"
pwcheck_method: auxprop
auxprop_plugin: sasldb
mech_list: PLAIN LOGIN
sasldb_path: ${SASL_DIR}/sasldb2
SASL_CONF

cp "${SASL_DIR}/smtpd.conf" /etc/postfix/sasl/smtpd.conf

# 4. SASL Credentials Setup
SASL_USER="${SASL_USER:-diagnostic-service}"
SASL_PASSWORD="${SASL_PASSWORD:-SecretPassword123!}"

if [[ -f "/run/secrets/smtp-username" && -f "/run/secrets/smtp-password" ]]; then
    SASL_USER="$(head -n 1 /run/secrets/smtp-username | tr -d '\r\n')"
    SASL_PASSWORD="$(head -n 1 /run/secrets/smtp-password | tr -d '\r\n')"
elif [[ -f "/run/secrets/smtp-sasl-credentials" ]]; then
    # Format: username:password
    IFS=':' read -r SASL_USER SASL_PASSWORD < "/run/secrets/smtp-sasl-credentials"
fi

if [[ -n "${SASL_USER}" && -n "${SASL_PASSWORD}" ]]; then
    echo "Configuring SASL user: ${SASL_USER} (realm: ${SASL_DOMAIN})"
    printf '%s' "${SASL_PASSWORD}" | saslpasswd2 -c -p -u "${SASL_DOMAIN}" "${SASL_USER}"
    printf '%s' "${SASL_PASSWORD}" | saslpasswd2 -c -p -u "${MYHOSTNAME}" "${SASL_USER}"
    printf '%s' "${SASL_PASSWORD}" | saslpasswd2 -c -p "${SASL_USER}"
fi

# Link / copy sasldb2 to postfix search paths and fix ownership
if [[ -f "${SASL_DIR}/sasldb2" ]]; then
    cp "${SASL_DIR}/sasldb2" /etc/postfix/sasldb2
    chown postfix:postfix "${SASL_DIR}/sasldb2" /etc/postfix/sasldb2
    chmod 0640 "${SASL_DIR}/sasldb2" /etc/postfix/sasldb2
fi

# 5. Aliases DB
if [[ ! -f /etc/postfix/aliases.lmdb && ! -f /etc/postfix/aliases.db ]]; then
    touch /etc/postfix/aliases
    newaliases >/dev/null 2>&1 || true
fi

# 6. Postfix main.cf configuration
postconf -e "myhostname = ${MYHOSTNAME}"
postconf -e "mydomain = ${MYDOMAIN}"
postconf -e "myorigin = ${MYORIGIN}"
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = ipv4"
postconf -e "mydestination ="
postconf -e "relayhost = [${RELAY_HOST}]:${RELAY_PORT}"
postconf -e "smtp_tls_security_level = ${SMTP_OUTBOUND_TLS:-none}"

# Inbound TLS (Port 587 STARTTLS)
postconf -e "smtpd_tls_security_level = may"
postconf -e "smtpd_tls_auth_only = yes"
postconf -e "smtpd_tls_cert_file = ${TLS_DIR}/server.crt"
postconf -e "smtpd_tls_key_file = ${TLS_DIR}/server.key"
postconf -e "smtpd_tls_loglevel = 1"
postconf -e "smtpd_tls_session_cache_database = lmdb:/var/lib/postfix/smtpd_scache"

# Inbound SASL Auth
postconf -e "smtpd_sasl_auth_enable = yes"
postconf -e "smtpd_sasl_type = cyrus"
postconf -e "smtpd_sasl_path = smtpd"
postconf -e "smtpd_sasl_security_options = noanonymous"
postconf -e "smtpd_sasl_local_domain = ${SASL_DOMAIN}"
postconf -e "broken_sasl_auth_clients = yes"

# Access Controls
postconf -e "smtpd_relay_restrictions = permit_sasl_authenticated, reject"
postconf -e "smtpd_recipient_restrictions = permit_sasl_authenticated, reject"

# Enterprise Queue & Rate Limiting Controls
postconf -e "maximal_queue_lifetime = 1h"
postconf -e "bounce_queue_lifetime = 1h"
postconf -e "maximal_backoff_time = 300s"
postconf -e "minimal_backoff_time = 30s"
postconf -e "queue_run_delay = 30s"
postconf -e "smtpd_client_connection_rate_limit = 60"
postconf -e "smtpd_client_message_rate_limit = 60"
postconf -e "maillog_file = /dev/stdout"
postconf -e "compatibility_level = 3.11"

# 7. Configure master.cf submission service without chroot
sed -i -e 's/^#submission inet n       -       n       -       -       smtpd/submission inet n       -       n       -       0       smtpd/' \
       -e 's/^submission inet n       -       n       -       -       smtpd/submission inet n       -       n       -       0       smtpd/' \
       /etc/postfix/master.cf

# Also disable chroot for smtp inet service
sed -i -e 's/^smtp      inet  n       -       n       -       -       smtpd/smtp      inet  n       -       n       -       0       smtpd/' \
       /etc/postfix/master.cf

echo "=== Postfix configuration complete. Starting master in foreground ==="
exec /usr/sbin/postfix start-fg
