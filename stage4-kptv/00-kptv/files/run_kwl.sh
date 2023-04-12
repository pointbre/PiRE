#!/bin/bash
timeout=60
check_try=0
check_result=1
while true; do
  check_try=$((check_try+1))
  ifconfig | grep eth0 -A 1 | grep -q inet >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    break
  elif [[ $check_try -gt $timeout ]]; then
    break
  else
    sleep 1
  fi
done
nohup ./kwl/kiwiweblauncher --configFile ./kwl/kwl.conf & > /dev/null
