#!/bin/sh

# this script starts the eeylops container, stopping any previously running container,
# and performing all the initialization required if the container has run for the first time.
# set -e makes the script fail if anything fails.
# the script ends by tailing the production log file inside the container, which can be
# killed with ^C, but maybe run this entire thing iin tmux/screen/whathaveyou.
# DETAILS need to be edited in this file.

# after "here be dragons", the script performs some very very specific configuration
# which adds a second interface to the container, configuring it with the public IPv4
# and public IPv6 needed to be visible on the Internet.

# You might have a load balancer or other TLS proxy that you use, but make sure
# that it connects to the port 9443 in a way that does not lose the source IP address.
# If you are trying to use uwsgi or some such, then this way is not the way; you don't
# want to do the TLS work inside the container, and you need to build a proper Three-Tier
# framework system. I personally think docker sucks for that.



set -e
MOUNT="--mount source=comet_certs,target=/app/certificates --mount source=eeylops_devices,target=/app/devices"

if docker ps | grep eeylops; then
    docker stop eeylops_staging
    docker rm eeylops_staging || true
fi

set -v
docker build -t shg_comet:eeylops comet

# setup the database
docker run --rm --link staging_db:postgres -it shg_comet:eeylops bundle exec rake db:migrate

# configure some options in the database.
# HOSTNAME must be what is in DNS, as it goes into IDevID certificates as the MASA URL.
docker run --rm --link staging_db:postgres $MOUNT shg_comet:eeylops bundle exec rake highway:h0_set_hostname HOSTNAME=eeylops.sandelman.ca PORT=9443

# set up the DNS zone that will be used for creating LetsEncrypt certificates
docker run --rm --link staging_db:postgres $MOUNT shg_comet:eeylops bundle exec rake highway:h0_shg_zone SHG_ZONE=dasblinkenled.org SHG_PREFIX=r

# this makes sure that the internal CA is configured, or that the LetsEncrypt identity for this
# machine has been setup.
docker run --rm --link staging_db:postgres $MOUNT shg_comet:eeylops bundle exec rake highway:h1_bootstrap_ca highway:h2_bootstrap_masa highway:h3_bootstrap_mud highway:h4_masa_letsencrypt highway:h5_idevid_ca

# this actually starts the COMET server.
docker run --name eeylops_staging -p 9443:9443 --rm -itd --link staging_db:postgres $MOUNT shg_comet:eeylops $@

# here be dragons
if false; then
docker network connect --ip 172.30.3.26 --ip6 2607:f0b0:f:3::26 service-network eeylops_staging
sleep 1
NSPID=$(docker inspect -f '{{ .State.Pid }}' eeylops_staging)
sudo mkdir -p /var/run/netns
sudo rm -f "/var/run/netns/$NSPID"
sudo ln -s "/proc/$NSPID/ns/net" "/var/run/netns/$NSPID"
sudo ip netns exec $NSPID ip ad add 209.87.249.26/32 dev eth1
sudo ip netns exec $NSPID ip ad sh
sudo ip netns exec $NSPID ip route change default via 172.30.3.1 src 209.87.249.26
sudo ip netns exec $NSPID sysctl -w net.ipv4.ip_forward=1
sudo ip netns exec $NSPID sysctl -w net.ipv6.conf.all.forwarding=1
fi

docker exec -it eeylops_staging tail -f log/production.log

