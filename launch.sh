#!/usr/bin/env bash
set -Eeuo pipefail
USERNAME=${USERNAME:-admin}
PASSWORD=${PASSWORD:-admin}
###############################################################################################
echo 'Starting Redis' #service redis-server@openvas start
runuser -u redis -- redis-server /etc/redis/redis-openvas.conf
while [ ! -S /run/redis-openvas/redis-server.sock ];do echo 'Waiting for redis-server socket';sleep 1;done;
while [ "$(redis-cli -s /run/redis-openvas/redis-server.sock ping)" != 'PONG' ];do echo 'Waiting for redis to respond';sleep 1;done;
###############################################################################################
echo 'Starting PostgreSQL'
service postgresql start
###############################################################################################
echo 'Starting OSPd' #service ospd-openvas start
if [ -f /var/lib/openvas/feed-update.lock ];then echo 'Removing stale feed-update.lock file';rm /var/lib/openvas/feed-update.lock;fi;
if [ -f /run/ospd/ospd-openvas.pid ];then echo 'Removing stale ospd-openvas.pid file';rm /run/ospd/ospd-openvas.pid;fi;
if [ -S /run/ospd/ospd.sock ];then echo 'Removing stale ospd.sock file';rm /run/ospd/ospd.sock;fi;
install --directory --owner=_gvm --group=_gvm --mode=777 /run/ospd/
runuser -u _gvm -- ospd-openvas --unix-socket /run/ospd/ospd.sock --pid-file /run/ospd/ospd-openvas.pid --log-file /var/log/gvm/ospd-openvas.log --lock-file-dir /var/lib/openvas
while [ ! -S /run/ospd/ospd.sock ];do echo 'Waiting for OSPd socket';sleep 10;done;
###############################################################################################
echo 'Starting GVMd' #service gvmd start
install --directory --owner=_gvm --group=_gvm --mode=777 /run/gvm/
runuser -u _gvm -- gvmd --osp-vt-update=/run/ospd/ospd.sock
###############################################################################################
echo 'Starting GSA' #service gsad start
runuser -u _gvm -- gsad  --verbose --http-only --no-redirect --port=9392
###############################################################################################
echo 'Creating admin user'
runuser -u _gvm -- gvmd --create-user=$USERNAME --password=$PASSWORD || true
###############################################################################################
echo '+++++++++++++++++++++++++++++++++++++++++++'
echo '+ Your GVM container is now ready to use! +'
echo '+++++++++++++++++++++++++++++++++++++++++++'
tail -F /var/log/gvm/*
