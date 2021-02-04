#!/bin/bash

echo "[+] Installing Utilities: jq, nano ..."
sudo yum -y update
sudo yum -y upgrade
sudo yum install -y nano jq

echo "[+] Upgrade lts/erbium nodejs12.x & Installing CDK ..."
# nvm install lts/erbium
# nvm use lts/erbium
# nvm alias default lts/erbium
# nvm uninstall v10.23.1

echo "[+] AMZ-Linux2/CenOS EBS Extending a Partition on a T2/T3 Instance"
# sudo file -s /dev/nvme?n*
# sudo growpart /dev/nvme0n1 1
# lsblk
# echo "Extend an ext2/ext3/ext4 file system"
# sudo yum install xfsprogs
# sudo resize2fs /dev/nvme0n1p1
# df -h

npm update && npm update -g
sudo npm install -g aws-cdk

sudo pip3 install boto3

pip3 install git-remote-codecommit

echo "[x] Verify AWS CLI": $(aws  --version)
echo "[x] Verify git":     $(git  --version)
echo "[x] Verify jq":      $(jq   --version)
echo "[x] Verify nano":    $(nano --version)
echo "[x] Verify Docker":  $(docker version)
echo "[x] Verify Docker Deamon":  $(docker ps -q)
# echo "[x] Verify nvm":     $(nvm ls)
echo "[x] Verify Node.js": $(node --version)
echo "[x] Verify CDK":     $(cdk  --version)
echo "[x] Verify Python":  $(python -V)
echo "[x] Verify Python3": $(python3 -V)
# echo "[x] Verify kubectl":  $(kubectl version --client)