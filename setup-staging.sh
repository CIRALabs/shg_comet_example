#!/bin/sh

# this creates an auxiliary network that is connected to a bridge "service-network"
# that is bridged on the host to the Internet.  It's likely entirely wrong for your
# environment, but is here as an example.
if false; then
docker network create --subnet 172.30.3.0/24 --ip-range 172.30.3.192/28 \
      --gateway 172.30.3.1 --gateway 2607:f0b0:f:3::1 \
       --ipv6 --subnet 2607:f0b0:f:3::/64 --ip-range 2607:f0b0:f:3::ffff:0/96 \
       service-network
fi

# this creates some persistent volumes for storing things
docker volume create --label eeylops_certs
docker volume create --label eeylops_devices
docker volume create --label staging_data

