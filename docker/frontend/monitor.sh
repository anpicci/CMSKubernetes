#!/bin/bash

# determine which port httpd server uses
aport=`cat /data/srv/state/frontend/server.conf | grep Listen | grep 80 | awk '{print $2}'`
suri="http://localhost:$aport/server-status/?auto"
echo "Start apache_exporter with $suri"
nohup apache_exporter -scrape_uri $suri -telemetry.address ":18443" 2>&1 1>& apache_exporter.log < /dev/null &

# run filebeat if present (first choice)
if [ -f /etc/secrets/filebeat.conf ] && [ -f /usr/bin/filebeat ]; then
    ldir=/data/srv/logs/frontend/filebeat
    mkdir -p $ldir/data
    nohup /usr/bin/filebeat \
        -c /etc/secrets/filebeat.conf \
        --path.data $ldir/data --path.logs $ldir -e 2>&1 1>& $ldir/log < /dev/null &
# run logstash if present (second choice)
elif [ -f /etc/secrets/logstash.conf ] && [ -f /usr/share/logstash/bin/logstash ]; then
    ldir=/data/srv/logs/frontend/logstash
    mkdir -p $ldir/data
    nohup /usr/share/logstash/bin/logstash \
        -f /etc/secrets/logstash.conf \
        --path.settings /etc/logstash \
        --path.data $ldir/data \
        --path.logs $ldir 2>&1 1>& $ldir/log < /dev/null &
fi
