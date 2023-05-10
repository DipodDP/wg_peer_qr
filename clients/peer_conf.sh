#!/bin/sh

echo "\n *** Client config: ***\n"
cat ./$1/client.conf
qrencode -t ansiutf8 < ./$1/client.conf
