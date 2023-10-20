#!/bin/bash

set -e

if [ -z "$MC_SOLR_SHARD_COUNT" ]; then
    echo "MC_SOLR_SHARD_COUNT (total shard count) is not set."
    exit 1
fi

set -u

# If we're running off a ZFS partition and its ARC cache size is not limited,
# we're very likely to run out of RAM after a while, so it's better not to run
# at all and insist user on updating zfs_arc_max
if grep -qs /var/lib/solr /proc/mounts; then
    if df -t zfs /var/lib/solr > /dev/null 2>&1; then
        if [ $(cat /sys/module/zfs/parameters/zfs_arc_max) -eq "0" ]; then
            echo "zfs_arc_max is not limited; please set it to 10% of available"
            echo "RAM or a similar figure."
            exit 1
        fi
    fi
fi

MC_SOLR_ZOOKEEPER_HOST="solr-zookeeper"
MC_SOLR_ZOOKEEPER_PORT=2181
MC_SOLR_PORT=8983

# Timeout in milliseconds at which Solr shard disconnects from ZooKeeper
MC_SOLR_ZOOKEEPER_TIMEOUT=30000

# <luceneMatchVersion> value
MC_SOLR_LUCENEMATCHVERSION="6.5.0"

# Make Solr's heap use 40-70% of available RAM allotted to the container
MC_RAM_SIZE=$(/container_memory_limit.sh)
MC_SOLR_MX=$((MC_RAM_SIZE / 10 * 7))
MC_SOLR_MS=$((MC_RAM_SIZE / 10 * 4))

# Wait for ZooKeeper container to show up
while true; do
    echo "Waiting for ZooKeeper to start..."
    if nc -z -w 10 solr-zookeeper 2181; then
        break
    else
        sleep 1
    fi
done

mkdir -p /var/lib/solr/jvm-oom-heapdumps/

# Run Solr
java_args=(
    -server
    "-Xmx${MC_SOLR_MX}m"
    "-Xms${MC_SOLR_MS}m"
    -Djava.util.logging.config.file=file:///var/lib/solr/resources/log4j.properties
    -Djetty.base=/var/lib/solr
    -Djetty.home=/var/lib/solr
    -Djetty.port="${MC_SOLR_PORT}"
    -Dsolr.solr.home=/var/lib/solr
    -Dsolr.data.dir=/var/lib/solr
    -Dsolr.log.dir=/var/lib/solr
    -Dhost="${HOSTNAME}"
    -DzkHost="${MC_SOLR_ZOOKEEPER_HOST}:${MC_SOLR_ZOOKEEPER_PORT}"
    -DnumShards="${MC_SOLR_SHARD_COUNT}"
    -DzkClientTimeout="${MC_SOLR_ZOOKEEPER_TIMEOUT}"
    -Dmediacloud.luceneMatchVersion="${MC_SOLR_LUCENEMATCHVERSION}"
    # Store heap dumps on OOM errors
    -XX:+HeapDumpOnOutOfMemoryError
    -XX:HeapDumpPath=/var/lib/solr/jvm-oom-heapdumps/
    # Stop running on OOM
    -XX:+CrashOnOutOfMemoryError
    # Needed for resolving paths to JARs in solrconfig.xml
    -Dmediacloud.solr_dist_dir=/opt/solr
    -Dmediacloud.solr_webapp_dir=/opt/solr/server/solr-webapp
    # Remediate CVE-2017-12629
    -Ddisable.configEdit=true
    -jar start.jar
    --module=http
)
cd /var/lib/solr
exec java "${java_args[@]}"
