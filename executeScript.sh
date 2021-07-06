#!/bin/bash

#updating/upgrading system
apt-get update ; apt-get upgrade -y

#Change password of GVM admin
runuser -u _gvm -- gvmd --user=admin --new-password=admin

#Adding admin user and changing gvmd.sock owner
adduser admin --disabled-password --gecos ""
chmod -R 777 /var/run/gvm ; chmod -R 777 /home/admin
#chown admin /var/run/gvm/gvmd.sock ; cd /home/admin

#to allow use of scan configs
runuser -u _gvm -- greenbone-nvt-sync
runuser -u _gvm -- greenbone-scapdata-sync
runuser -u _gvm -- greenbone-certdata-sync

echo "Starting sleep time of 15 minutes now..."
sleep 900

runuser -u _gvm -- gvmd --get-scanners | grep "OpenVAS" > scanner-id.txt
runuser -u _gvm -- gvmd --get-users --verbose | grep "admin" > user-id.txt

sed -i "s/OpenVAS  \/var\/run\/ospd\/ospd.sock  0  OpenVAS Default//g" scanner-id.txt
sed -i "s/admin//g" user-id.txt

scanner_id=$(cat scanner-id.txt | xargs)
user_id=$(cat user-id.txt | xargs)

runuser -u _gvm -- gvmd --modify-scanner ${scanner_id} --value ${user_id}

#Changing permissions and executing gvm_bash script
chmod +x gvm_bash.sh
cd / ; cp gvm_bash.sh /home/admin ; cd /home/admin
sed -i -e 's/\r$//' /home/admin/gvm_bash.sh
sed -i -e 's/^M$//' /home/admin/gvm_bash.sh

./gvm_bash.sh 127.0.0.1








