#!/bin/sh
IP6_RANGE=$(cat ipv6subnet)
WG_CONF_PATH="/etc/wireguard/wg0.conf"
WG_KEY_PATH="/etc/wireguard/publickey"
CURRENT_IP=$(cat ipv4state)
CN="${CURRENT_IP##*.}"
NEW_IP="${CURRENT_IP%.*}.$(($CN + 1))"
mkdir $1
wg genkey | tee ./$1/client.key |  wg pubkey | tee ./$1/client.key.pub | awk '/^/{print "Public Key: "$1}'
cp client.conf ./$1/client.conf
sed -i 's~private_key_to_replace~'$(cat ./$1/client.key)'~g' ./$1/client.conf
sed -i 's~server_public_key_to_replace~'$(cat $WG_KEY_PATH)'~g' ./$1/client.conf
sed -i 's~client_addresses_to_replace~'"$NEW_IP/32, $IP6_RANGE$(($CN + 1))/128"'~g' ./$1/client.conf
echo "\n *** Client config: ***\n"
cat ./$1/client.conf
qrencode -o ./$1/client.png < ./$1/client.conf
qrencode -t ansiutf8 < ./$1/client.conf
echo $NEW_IP > ipv4state

systemctl stop wg-quick@wg0

echo "*** Next lines has been added to wg0.conf: ***"
echo "\n[Peer]\nPublicKey = $(cat ./$1/client.key.pub)\nAllowedIPs = ${NEW_IP}/32, $IP6_RANGE$(($CN + 1))/128\n" | tee -a $WG_CONF_PATH

systemctl start wg-quick@wg0
wg show
