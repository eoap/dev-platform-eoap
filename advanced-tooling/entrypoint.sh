#!/bin/bash

collect_port=0
port="8888"
delim='='

for var in "$@"
do
    echo "$var"

    if [ "$collect_port" == "1" ]; then
       echo "Collecting external port $var"
       port=$var
       collect_port=0
    fi

    splitarg=${var%%$delim*}

    if [ "$splitarg" == "--port" ]; then
       if [ ${#splitarg} == ${#var} ]; then
         collect_port=1
       else
         port=${var#*$delim}
         echo "Setting external port $port"
       fi
    fi
done

destport=$((port + 1))

echo "Using internal port $destport"

if [ -z "$CODE_SERVER_WS" ]; then
    CODE_SERVER_WS="/workspace"
fi

jhsingle-native-proxy --port $port --destport $destport code-server {--}auth none {--}bind-addr 0.0.0.0:$destport {--}user-data-dir /workspace $CODE_SERVER_WS