#!/bin/bash
set -o errexit

ABSOLUTE_PATH=$(cd ${0%/*} && pwd -P)

PROJECT_NAME="ipswDownloader"
VERSION="2.4.2"
VERSION_SHORT="242"
BUILD="95"
DOWNLOAD_BASE_URL="http://downloads.igrsoft.com/ipswDownloader/"
RELEASENOTES_BASE_URL="http://igrsoft.com/wp-content/iPhone/info"

UNDERSCORE="_"
ARCHIVE_FILENAME="$PROJECT_NAME$UNDERSCORE$VERSION_SHORT.zip"
DOWNLOAD_URL="$DOWNLOAD_BASE_URL$ARCHIVE_FILENAME"
RELEASENOTES_URL="$RELEASENOTES_BASE_URL$UNDERSCORE$VERSION_SHORT.html"

WD=$PWD
rm -f "$ABSOLUTE_PATH/$ARCHIVE_FILENAME"
ditto -ck --keepParent "$ABSOLUTE_PATH/$PROJECT_NAME.app" "$ABSOLUTE_PATH/$ARCHIVE_FILENAME"

SIZE=$(stat -f %z "$ABSOLUTE_PATH/$ARCHIVE_FILENAME")
PUBDATE=$(date +"%a, %d %b %G %T %z")

SIGNATURE=$(ruby "$ABSOLUTE_PATH/sign_update.rb" "$ABSOLUTE_PATH/$ARCHIVE_FILENAME" "$ABSOLUTE_PATH/dsa_priv.pem")

clear

cat <<EOF     
				<item>
					<title>Version $VERSION, Build $BUILD</title>
					<sparkle:releaseNotesLink>$RELEASENOTES_URL</sparkle:releaseNotesLink>
					<pubDate>$PUBDATE</pubDate>
					<enclosure url="$DOWNLOAD_URL" sparkle:version="$VERSION" length="$SIZE" type="application/octet-stream" sparkle:dsaSignature="$SIGNATURE" />
				</item>
EOF