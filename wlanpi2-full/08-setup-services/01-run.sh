#!/bin/bash -e

####################
# Setup RNDIS
####################

copy_overlay /etc/modprobe.d/g_ether.conf -o root -g root -m 644
