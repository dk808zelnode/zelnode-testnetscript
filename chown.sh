#!/bin/bash

# This script is a setup to have cron run chown command to fix the peers.dat issue.

USERNAME=$LOGNAME

sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/.zelcash
