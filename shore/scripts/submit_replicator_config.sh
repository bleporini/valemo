#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "replicaship",
  "config":{
      "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",
      "tasks.max": "1",
      "key.converter": "org.apache.kafka.connect.storage.StringConverter",
      "value.converter": "org.apache.kafka.connect.storage.StringConverter",
      "topic.regex": "temperature",
      "src.key.converter": "org.apache.kafka.connect.storage.StringConverter",
      "src.value.converter": "org.apache.kafka.connect.storage.StringConverter",
      "src.kafka.bootstrap.servers": "${SHIP_BOOTSTRAP_SERVERS}",
      "dest.kafka.bootstrap.servers": "kafka-shore:9094",
      "src.zookeeper.connect": "${SHIP_ZK}",
      "dest.zookeeper.connect": "zookeeper-shore:2181"
  }
}
EOF
)

wait_for_status(){
    local status=$1
    local query=$2
    local nbTries=$3
    local maxTries=$((120))
    local sleepTime=$((2))

    if [ -z "$nbTries" ]; then nbTries=0 ; fi

    if [ $nbTries -gt $maxTries ]
    then
        echo Tried $maxTries to get see if the status is $status, exiting...
        exit -1
    fi

    query_res=$($2)
    echo Status is $query_res, expecting $status ...

    if [ "$query_res" = "$status" ]
    then
        echo "OK"
    else
        nbTries=$(($nbTries + 1))
        sleep $sleepTime
        wait_for_status "$status" $query $nbTries
    fi
}

try_connect(){
    curl -X POST -H "${HEADER}" --data "${DATA}" http://connect:8083/connectors > /dev/null && echo "OK" || echo "KO"
}

wait_for_status "OK" try_connect 20


