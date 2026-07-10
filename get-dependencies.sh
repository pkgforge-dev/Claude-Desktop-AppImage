#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm patchelf libnss_nis nss-mdns nss

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

echo "Getting binary..."
echo "---------------------------------------------------------------"

case "$ARCH" in
	x86_64)  farch=amd64;;
	aarch64) farch=arm64;;
esac

BASE_URL="https://downloads.claude.ai/claude-desktop/apt/stable"
link="$BASE_URL/$(curl -sL --compressed "$BASE_URL/dists/stable/main/binary-$farch/Packages" | grep -oP '^Filename:\s*\K.+' | head -1)"

curl -sSfL --retry 30 --retry-connrefused "$link" -o /tmp/temp.deb
echo "$link" | grep -oP 'claude-desktop_\K[^_]+' > ~/version

echo "Preparing AppDir..."
mkdir -p ./AppDir/
bsdtar -xOf /tmp/temp.deb data.tar.* | bsdtar -xf - -C ./AppDir/
