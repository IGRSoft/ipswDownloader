#!/bin/bash

###############################################################################
##                                                                           ##
## Build and package OpenSSL static libraries for OSX/iOS                    ##
##                                                                           ##
## This script is in the public domain.                                      ##
## Creator     : Laurent Etiemble                                            ##
##                                                                           ##
###############################################################################

## --------------------
## Parameters
## --------------------

VERSION=1.0.2e
OSX_SDK=10.11
MIN_OSX=10.8

# These values are used to avoid version detection
FAKE_NIBBLE=0x102031af
FAKE_TEXT="OpenSSL 0.9.8y 5 Feb 2013"

## --------------------
## Variables
## --------------------

DEVELOPER_DIR=`xcode-select -print-path`
if [ ! -d $DEVELOPER_DIR ]; then
    echo "Please set up Xcode correctly. '$DEVELOPER_DIR' is not a valid developer tools folder."
    exit 1
fi
if [ ! -d "$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/SDKs/MacOSX$OSX_SDK.sdk" ]; then
    echo "The OS X SDK $OSX_SDK was not found."
    exit 1
fi
if [ ! -d "$DEVELOPER_DIR/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$IOS_SDK.sdk" ]; then
    echo "The iOS SDK $IOS_SDK was not found."
    exit 1
fi

BASE_DIR=`pwd`
BUILD_DIR="$BASE_DIR/build"
DIST_DIR="$BASE_DIR"
FILES_DIR="$BASE_DIR/files"

OPENSSL_NAME="openssl-$VERSION"
OPENSSL_FILE="$OPENSSL_NAME.tar.gz"
OPENSSL_URL="http://www.openssl.org/source/$OPENSSL_FILE"
OPENSSL_PATH="$FILES_DIR/$OPENSSL_FILE"

## --------------------
## Main
## --------------------

_unarchive() {
	# Expand source tree if needed
	if [ ! -d "$SRC_DIR" ]; then
		echo "Unarchive sources for $PLATFORM-$ARCH..."
		(cd "$BUILD_DIR"; tar -zxf "$OPENSSL_PATH"; mv "$OPENSSL_NAME" "$SRC_DIR";)
	fi
}

_configure() {
	# Configure
	if [ "x$DONT_CONFIGURE" == "x" ]; then
		echo "Configuring $PLATFORM-$ARCH..."
		(cd "$SRC_DIR"; CROSS_TOP="$CROSS_TOP" CROSS_SDK="$CROSS_SDK" CC="$CC" ./Configure --prefix="$DST_DIR" -no-apps "$COMPILER" > "$LOG_FILE" 2>&1)
	fi
}

_build() {
	# Build
	if [ "x$DONT_BUILD" == "x" ]; then
		echo "Building $PLATFORM-$ARCH..."
		(cd "$SRC_DIR"; CROSS_TOP="$CROSS_TOP" CROSS_SDK="$CROSS_SDK" CC="$CC" make >> "$LOG_FILE" 2>&1)
	fi
}

build_osx() {
	ARCHS="x86_64"
	for ARCH in $ARCHS; do
		PLATFORM="MacOSX"
		COMPILER="darwin64-x86_64-cc"
		SRC_DIR="$BUILD_DIR/$PLATFORM-$ARCH"
		DST_DIR="$DIST_DIR/$PLATFORM-$ARCH"
		LOG_FILE="$BASE_DIR/$PLATFORM$OSX_SDK-$ARCH.log"

		CROSS_TOP="$DEVELOPER_DIR/Platforms/$PLATFORM.platform/Developer"
		CROSS_SDK="$PLATFORM$OSX_SDK.sdk"
		CC="$DEVELOPER_DIR/usr/bin/gcc -arch $ARCH"

		_unarchive
		_configure

		# Patch Makefile
		sed -ie "s/^CFLAG= -/CFLAG=  -mmacosx-version-min=$MIN_OSX -/" "$SRC_DIR/Makefile"
		# Patch versions
		sed -ie "s/^# define OPENSSL_VERSION_NUMBER.*$/# define OPENSSL_VERSION_NUMBER  $FAKE_NIBBLE/" "$SRC_DIR/crypto/opensslv.h"
		sed -ie "s/^#  define OPENSSL_VERSION_TEXT.*$/#  define OPENSSL_VERSION_TEXT  \"$FAKE_TEXT\"/" "$SRC_DIR/crypto/opensslv.h"

		_build
	done
}

distribute_osx() {
	NAME="openssl"
	DIR="$DIST_DIR/$NAME"
	FILES="libcrypto.a libssl.a"
	mkdir -p "$DIR/include"
	mkdir -p "$DIR/lib"

	echo "$VERSION" > "$DIR/VERSION"
	cp "$BUILD_DIR/MacOSX-x86_64/LICENSE" "$DIR"
	cp -LR "$BUILD_DIR/MacOSX-x86_64/include/" "$DIR/include"

	# Alter rsa.h to make Swift happy
	sed -i .bak 's/const BIGNUM \*I/const BIGNUM *i/g' "$DIR/include/openssl/rsa.h"

	for f in $FILES; do
		lipo -create \
			"$BUILD_DIR/MacOSX-x86_64/$f" \
			-output "$DIR/lib/$f"
	done

	(cd "$DIST_DIR"; tar -cvf "../$NAME.tar.gz" "$NAME")
}

# Create folders
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$FILES_DIR"

# Retrieve OpenSSL tarbal if needed
if [ ! -e "$OPENSSL_PATH" ]; then
	curl "$OPENSSL_URL" -o "$OPENSSL_PATH"
fi

build_osx

distribute_osx
