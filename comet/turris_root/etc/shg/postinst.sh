#!/bin/sh
#
# Post-installation script for SHG onboarding

info() { logger -t shg-post-provisioning -p info $@; }
error() { logger -t shg-post-provisioning -p err $@; }
check_error() {
    if [ $? -ne 0 ]; then
        error $@
        exit 1
    fi
}

KEY="/etc/shg/shg.key"
CERTIF="/etc/shg/idevid_cert.pem"
INTERMEDIATE="/etc/shg/intermediate_certs.pem"
OUTPUT="/etc/shg/lighttpd.pem"

cd /etc/shg

# do not do this if shg-provision already did it.
if [ ! -f .done20190628 ]; then
        cat ${KEY} ${CERTIF}         > ${OUTPUT}

        cp ${KEY}                      /etc/shg/certificates/jrc_prime256v1.key
        cat ${CERTIF} ${INTERMEDIATE} >/etc/shg/certificates/jrc_prime256v1.crt
        cp masa.crt                    /etc/shg/certificates/masa.crt

    check_error "Failed to create certificate for lighttpd"
    chmod 600 ${OUTPUT}

    if [ -d extra ] ; then
        (cd extra; find . -type f -print | while read file
         do
             cat $file >>/$file
         done)
    fi
    touch .done20190628
fi
