#!/bin/sh
IP_RANGE=10.10.0.0
WG_CONF_PATH="/etc/wireguard/wg0.conf"
CURRENT_IP=$(cat state)
CN="${CURRENT_IP##*.}"
NEW_IP=10.10.0.$(($CN + 1))

mkdir $1
wg genkey | tee ./$1/client.key |  wg pubkey | tee ./$1/client.key.pub | awk '/^/{print "Public Key: "$1}'
cp client.conf ./$1/client.conf
sed -i 's~privatekeytoreplace~'$(cat ./$1/client.key)'~g' ./$1/client.conf
sed -i 's~'"$IP_RANGE"'~'"$NEW_IP"'~g' ./$1/client.conf
echo "\n *** Client config: ***\n"
cat ./$1/client.conf
qrencode -o ./$1/client.png < ./$1/client.conf
qrencode -t ansiutf8 < ./$1/client.conf
echo $NEW_IP > state

echo "*** Next lines has been added to wg0.conf: ***"
echo "\n[Peer]\nPublicKey = $(cat ./$1/client.key.pub)\nAllowedIPs = ${NEW_IP}/32\n" | tee -a $WG_CONF_PATH

systemctl restart wg-quick@wg0
wg show
