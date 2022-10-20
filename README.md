# wg_peer_qr

This script helps you to add peers in Wireguard server config (wg0.conf) and create configs for peers.
So new Wireguard clients can easely connect with text or QR configs.

# WireGuard on Ubuntu OpenVZ server 

This may help to run Wireguard on cheap VPS with an outdated kernel which is incompatible with Wireguard

apt-get update && apt-get -y upgrade
apt-get -y install nano bash-completion wget git
apt-get -y install software-properties-common
add-apt-repository ppa:wireguard/wireguard
apt-get update && apt-get -y upgrade
apt install wireguard-tools --no-install-recommends

Then, to enable forwarding:

nano /etc/sysctl.conf
And uncomment the following lines:

net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1

Once saved, reboot. You could s

ysctl -p

but just makes sure all updates/upgrades/changes are in place properly

reboot

Now, we are going to use wireguard-go, so need to install "go". Check in on https://go.dev/dl/, but just change "go1.13.4" in each of the following lines if wish to try a differen version:

cd /tmp
wget https://go.dev/dl/go1.19.2.linux-amd64.tar.gz
tar zvxf go1.13.4.linux-amd64.tar.gz
mv go /opt/go1.13.4
ln -s /opt/go1.13.4/bin/go /usr/local/bin/go
Now, download and install wireguard-go itself

cd /usr/local/src
git clone https://git.zx2c4.com/wireguard-go
cd wireguard-go
make
cp wireguard-go /usr/local/bin
Reboot to ensure everything is clean

reboot
Check to see if working/version

wireguard-go --version
