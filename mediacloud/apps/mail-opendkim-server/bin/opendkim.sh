#!/bin/bash

set -e

if [ -z "$MC_MAIL_OPENDKIM_DOMAIN" ]; then
    echo "MC_MAIL_OPENDKIM_DOMAIN (top-level domain to use for signing emails) is not set."
    exit 1
fi

set -u

# (Re)generate dynamic configuration
rm -f /etc/opendkim/KeyTable
echo "mail._domainkey.${MC_MAIL_OPENDKIM_DOMAIN} ${MC_MAIL_OPENDKIM_DOMAIN}:mail:/etc/opendkim/keys/mail.private" \
    > /etc/opendkim/KeyTable
rm -f /etc/opendkim/SigningTable
echo "*@${MC_MAIL_OPENDKIM_DOMAIN} mail._domainkey.${MC_MAIL_OPENDKIM_DOMAIN}" \
    > /etc/opendkim/SigningTable
rm -f /etc/opendkim/TrustedHosts
cp /var/lib/opendkim-TrustedHosts /etc/opendkim/TrustedHosts

# Generate keys if those are missing
if [ ! -f "/etc/opendkim/keys/mail.private" ]; then
    opendkim-genkey \
        -s "mail" \
        -d "${MC_MAIL_OPENDKIM_DOMAIN}" \
        -D /etc/opendkim/keys/
    chown opendkim:opendkim "/etc/opendkim/keys/mail.private"
fi

# Print public key before every run
echo
echo "Add the following DNS record to ${MC_MAIL_OPENDKIM_DOMAIN} domain if you haven't already:"
echo
cat "/etc/opendkim/keys/mail.txt"
echo

# Set up rsyslog for logging
source /rsyslog.inc.sh

# Start OpenDKIM
exec opendkim \
    -f \
    -v \
    -x /etc/opendkim.conf \
    -u opendkim \
    -P /var/run/opendkim/opendkim.pid \
    -p inet:12301
