# Automate creating WireGuard peers

This script helps you to add peers in Wireguard server config (`wg0.conf`) and create configs for peers.
So new Wireguard clients can easily connect with text or QR configs.

## Installation

```shell
sudo apt install qrencode
```
```shell
cd /etc/wireguard/
```
clone this repository to `/etc/wireguard/` or other directory where wireguard is installed:

```shell
git clone git@github.com:DipodDP/wg_peer_qr.git
```
For ipv4 and ipv6 dualstack support use Wireguard `wg0.conf` like described [here](#configuring-server-wg0-interface).

## Configuration

Then go to clients dir:

```shell
cd /etc/wireguard/wg_peer_qr/clients
```
and make copy of `..._template` files with removing `..._template` part in file name.

Put in file `ipv4state` ip adress of the last peer in wg0.conf, or server local IP if there is no peers added. For new peers ip addresses will be added as +1 to last peer IP.

Put in file `ipv6subnet` your ipv6 subnet, generated with [IPv6 Local Address Range Generator (dnschecker.org)](https://dnschecker.org/ipv6-address-generator.php).
Last number in peer ipv6 adress equals ipv4 address.

Open file `client.conf`:

```shell
nano client.conf
```

File `client.conf` contains template of peers config, like:

```shell
[Interface]
PrivateKey = private_key_to_replace
Address = client_addresses_to_replace
DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2001:67c:2b0::4, 2001:67c:2b0::6
MTU = 1380

[Peer]
PublicKey = server_public_key_to_replace
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = 123.234.56.78:51820
PersistentKeepalive = 7
```

You should change `123.234.56.78:51820` to your endpoint value, and change other settings if you need.
Do not change `..._to_replace` parameters (need for script working).

Open `wg_gencli.sh`:

```shell
nano wg_gencli.sh
```

and change variables `WG_KEY_PATH` and `WG_CONF_PATH` if you need.


## Peer config creation

Run `wg_gencli.sh` with name of new peer:

```shell
chmod u+x wg_gencli.sh
```

```shell
./wg_gencli.sh newpeer
```

In result it should create new directory "newpeer" that containes:

`client.conf` - peer config file

`client.key` - peer private key

`client.key.pub` - peer public key

`clinet.png` - QR-code to connect mobile app

and show new peer text and QR configs in console, so you can instantly connect client app. 

To recall client config run command `peer_conf` with name of peer:

```shell
./peer_conf.sh newpeer
```

---

# WireGuard-go on Ubuntu OpenVZ server 

This may help (I think it's the only way) to run Wireguard on cheap VPS with an outdated kernel which you have no access to update (like OpenVZ), incompatible with Wireguard.

## Wireguard-go installation

```shell
sudo apt update && sudo apt upgrade -y
```

Install `make` if not installed:

```shell
sudo apt install make
```

Then, to enable forwarding:

```shell
sudo nano /etc/sysctl.conf
```

And uncomment the following lines:

`net.ipv4.ip_forward=1`

`net.ipv6.conf.all.forwarding=1`

You could do

```shell
sudo sysctl -p
```

just makes sure all updates/upgrades/changes are in place properly

```shell
sudo reboot
```

Now, we are going to use wireguard-go, so need to install `go`. Check it on https://go.dev/dl/, and change `go1.19.2` in each of the following lines if wish to try a differen version:

Get root (or use sudo command)

```shell
sudo su
```

Download wireguard-go:

```shell
cd /tmp
```
```shell
wget https://go.dev/dl/go1.19.2.linux-amd64.tar.gz
```
```shell
tar zvxf go1.19.2.linux-amd64.tar.gz
```
```shell
mv go /opt/go1.19.2
```
```shell
ln -s /opt/go1.19.2/bin/go /usr/local/bin/go
```

Now, download and install wireguard-go itself

```shell 
cd /usr/local/src
```

```shell 
git clone https://git.zx2c4.com/wireguard-go
```

```shell 
cd wireguard-go
```

If you are on a system with limited RAM (such as a 256 MB or lower "LowEndSpirit" VPS), you will need to do a small tweak to the `wireguard-go` code to make it use less RAM. Open `device/queueconstants_default.go` and replace this:

```
MaxSegmentSize             = (1 << 16) - 1 // largest possible UDP datagram 
PreallocatedBuffersPerPool = 0 // Disable and allow for infinite memory growth
```

With these values (taken from `device/queueconstants_ios.go`):

```
MaxSegmentSize             = 1700 
PreallocatedBuffersPerPool = 1024
```

Now we can compile it:

```shell 
make
```

```shell 
cp wireguard-go /usr/local/bin
```

Reboot to ensure everything is clean

```shell 
reboot
```

Check to see if working/version

```shell 
wireguard-go --version
```

Generate private and public keys:

```shell
mkdir /etc/wireguard/
```

```shell
cd /etc/wireguard/
```

```shell
umask 077
```

```shell
apt install wireguard-dkms wireguard-tools -y
```
## Configuring server wg0 interface

```shell
wg genkey | tee privatekey | wg pubkey > publickey
```

write down the public key:

```shell
cat publickey
```

write down the private key:

```shell
cat privatekey
```

Define wg0 interface by creating "wg.conf".

```shell
nano wg0.conf
```

And copy the following into the file (changing private key and address as appropriate). An example addresses would be 10.10.1.1/24 and fd42:42:42::1/64. 

```shell
[Interface]
PrivateKey = <privatekey>
Address = 10.10.0.1/24
Address = fd42:42:42::1/64
PostUp = ufw route allow in on wg0 out on eth0
PostUp = iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
PostUp = ip6tables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
PreDown = ufw route delete allow in on wg0 out on eth0
PreDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
PreDown = ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

One note, you may need to change eth0 to your proper interface, you can find it with:
 
```shell
ip a
```
  
We need to modify the systemd unit to pass the `WG_I_PREFER_BUGGY_USERSPACE_TO_POLISHED_KMOD` flag to `wireguard-go`, to allow it to run on Linux. Open 
  
```shell
nano /lib/systemd/system/wg-quick@.service
```

find:
`
Environment=WG_ENDPOINT_RESOLUTION_RETRIES=infinity
`

and add this line directly below:
`
Environment=WG_I_PREFER_BUGGY_USERSPACE_TO_POLISHED_KMOD=1 
`
## Configuring firewall

Check if `iptables` is installed on your system,  if not you need install it:

```shell
apt install iptables -y
```

Enable and start the service

```shell
systemctl enable wg-quick@wg0
```

```shell
systemctl start wg-quick@wg0
```

```shell
systemctl status wg-quick@wg0.service
```

Assuming your client is set up correctly, all should flow. Depending on the environment, you may need the following to enable and configure the firewall (ufw firewall):

```shell
sudo ufw allow 22/tcp
```

```shell
sudo ufw allow 51820/udp
```

```shell
sudo ufw allow OpenSSH
```

```shell
ufw enable
```
You also may need to add the following if the default firewall policy is to REJECT:

```shell
iptables -A INPUT -p udp -m udp --dport 51820 -j ACCEPT
```

```shell
iptables -A OUTPUT -p udp -m udp --sport 51820 -j ACCEPT
```

And finally, if you are running this on OpenVZ, you may need to (at the host level - so need to talk to your service provider):

```shell
vzctl set $CTID --netfilter full --save
```

---

Sources:

- https://wiki.shulepov.com/software/linux/qrnecode_wireguard
- https://www.reddit.com/r/WireGuard/comments/dze220/wireguard_on_ubuntu_1804_openvz/
- https://d.sb/2019/07/wireguard-on-openvz-lxc
