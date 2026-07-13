#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"

case "$ARCH" in
	x86_64)
		farch=amd64
		qemu_pkg="qemu-system-x86"
		edk2_flag="-S"
		edk2_pkg="edk2-ovmf"
		edk_arch="x64"
		vmf_dir="OVMF"
		code_src="OVMF_CODE.4m.fd"
		vars_src="OVMF_VARS.4m.fd"
		vmf_sfx="_4M"
		;;
	aarch64)
		farch=arm64
		qemu_pkg="qemu-system-aarch64"
		edk2_flag="-U"
		curl -sL "https://archlinux.org/packages/extra/any/edk2-aarch64/download/" -o /tmp/edk2-aarch64.pkg.tar.zst
		edk2_pkg="/tmp/edk2-aarch64.pkg.tar.zst"
		edk_arch="aarch64"
		vmf_dir="AAVMF"
		code_src="QEMU_EFI.fd"
		vars_src="QEMU_VARS.fd"
		vmf_sfx=""
		;;
esac

pacman -Syu --noconfirm patchelf libnss_nis nss-mdns nss socat qemu-img virtiofsd $qemu_pkg
pacman $edk2_flag --noconfirm $edk2_pkg

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

echo "Getting binary..."
echo "---------------------------------------------------------------"

BASE_URL="https://downloads.claude.ai/claude-desktop/apt/stable"
link="$BASE_URL/$(curl -sL --compressed "$BASE_URL/dists/stable/main/binary-$farch/Packages" | grep -oP '^Filename:\s*\K.+' | head -1)"

curl -sSfL --retry 30 --retry-connrefused "$link" -o /tmp/temp.deb
echo "$link" | grep -oP 'claude-desktop_\K[^_]+' > ~/version

echo "Preparing AppDir..."
mkdir -p ./AppDir/
bsdtar -xOf /tmp/temp.deb data.tar.* | bsdtar -xf - --strip-components=2 -C ./AppDir/

mv -f ./AppDir/lib/claude-desktop/* ./AppDir/bin/
sed -i 's|MimeType=x-scheme-handler/claude;|MimeType=x-scheme-handler/claude;x-scheme-handler/claude-desktop;|' ./AppDir/share/applications/claude-desktop.desktop

cp /usr/bin/qemu-system-$ARCH /usr/bin/qemu-img /usr/bin/socat /usr/lib/virtiofsd ./AppDir/bin/

mkdir -p ./AppDir/share/qemu
cp -r /usr/share/qemu/keymaps ./AppDir/share/qemu/
cp /usr/share/qemu/{vgabios*.bin,efi-*.rom,kvmvapic.bin,linuxboot*.bin,bios*.bin,pvh.bin} ./AppDir/share/qemu/

mkdir -p ./AppDir/share/$vmf_dir
cp -f /usr/share/edk2/$edk_arch/$code_src ./AppDir/share/$vmf_dir/${vmf_dir}_CODE${vmf_sfx}.fd
cp -f /usr/share/edk2/$edk_arch/$vars_src ./AppDir/share/$vmf_dir/${vmf_dir}_VARS${vmf_sfx}.fd
