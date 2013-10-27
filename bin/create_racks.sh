#!/bin/bash
TUSKAR_URL="http://localhost:8585/v1"

declare -A RACKS
RACKS["rack-m1"]="52:54:00:2c:54:ec"
RACKS["rack-control"]="52:54:00:a8:25:8b"

UUID_REGEXPR="[a-fA-F0-9]\{8\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{12\}"
MAC_REGEXPR="[a-fA-F0-9]\{2\}:[a-fA-F0-9]\{2\}:[a-fA-F0-9]\{2\}:[a-fA-F0-9]\{2\}:[a-fA-F0-9]\{2\}:[a-fA-F0-9]\{2\}"

declare -A MACS_NODES
for i in `nova baremetal-node-list`;
do
  if [ `expr $i : $UUID_REGEXPR` -ne 0 ]; then
    for mac in `nova baremetal-interface-list $i`
    do
      if [ `expr $mac : $MAC_REGEXPR` -ne 0 ]; then
        echo "FOUND $mac"
        MACS_NODES[$mac]=$i
      fi
    done
  fi
done

for name in "${!RACKS[@]}"
do
  echo "Creating rack: $name"
  nodes=""
  for mac in ${RACKS[$name]}
  do
    nodes="$nodes { \"id\": \"${MACS_NODES[$mac]}\" },"
  done
  nodes="${nodes%?}"
  echo "{ \"subnet\": \"192.168.1.0/255\", \"name\": \"$name\", \"capacities\": [], \"nodes\": [$nodes], \"slots\": 1 } "
  curl -vX POST -H 'Content-Type: application/json' -H 'Accept: application/json' -v -d  "{ \"subnet\": \"192.168.1.0/255\", \"name\": \"$name\", \"capacities\": [], \"nodes\": [$nodes], \"slots\": 1 } " $TUSKAR_URL/racks
done
