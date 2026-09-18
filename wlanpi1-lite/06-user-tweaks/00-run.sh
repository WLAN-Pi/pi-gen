#!/bin/bash -e

on_chroot <<CHEOF
	# Make the wlanpi user change their password at first login
	# passwd -e wlanpi

CHEOF
