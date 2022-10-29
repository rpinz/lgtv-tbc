#!/usr/bin/env bash

LGTV_HOST="10.2.2.53"

scp 0* root@${LGTV_HOST}:/var/lib/webosbrew/init.d

PREFERENCES=()
PREFERENCES+=(/var/luna/preferences/webosbrew_date)
PREFERENCES+=(/var/luna/preferences/webosbrew_telemetry)
PREFERENCES+=(/var/luna/preferences/webosbrew_lgtv_tbc)
PREFERENCES+=(/var/luna/preferences/webosbrew_resolv)

for preference in ${PREFERENCES[@]}; do
  ssh root@${LGTV_HOST} "[ ! -e $preference ] && touch $preference || ls -l $preference"
done

