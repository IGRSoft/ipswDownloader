#!/bin/sh

set -e

cp /usr/local/lib/libimobiledevice.a ./Frameworks/libimobiledevice.a
cp /usr/local/lib/libplist.1.dylib ./Frameworks/libplist.dylib
cp /usr/local/lib/libusbmuxd.dylib ./Frameworks/libusbmuxd.dylib
cp /usr/local/lib/libxml2.dylib ./Frameworks/libxml.dylib