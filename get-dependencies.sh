#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"

case "$ARCH" in
	x86_64)
		farch=amd64
		qemu_pkg="qemu-system-x86"
		qemu_bin="qemu-system-x86_64"
		edk2_pkg="edk2-ovmf"
		edk2_src="/usr/share/edk2/x64"
		;;
	aarch64)
		farch=arm64
		qemu_pkg="qemu-system-aarch64"
		qemu_bin="qemu-system-aarch64"
		edk2_pkg=""
		edk2_src="/usr/share/edk2/aarch64"
		;;
esac

pacman -Syu --noconfirm patchelf libnss_nis nss-mdns nss socat qemu-img $qemu_pkg $edk2_pkg

if [ "$ARCH" = "aarch64" ]; then
	echo "Installing edk2-aarch64 from Arch Linux extra repo..."
	curl -sL "https://archlinux.org/packages/extra/any/edk2-aarch64/download/" -o /tmp/edk2-aarch64.pkg.tar.zst
	pacman -U --noconfirm /tmp/edk2-aarch64.pkg.tar.zst || bsdtar -xf /tmp/edk2-aarch64.pkg.tar.zst -C /
fi

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

cp /usr/bin/$qemu_bin /usr/bin/qemu-img /usr/bin/socat ./AppDir/bin/

mkdir -p ./AppDir/share/qemu
cp -r /usr/share/qemu/keymaps ./AppDir/share/qemu/
cp /usr/share/qemu/{vgabios*.bin,efi-*.rom,kvmvapic.bin,linuxboot*.bin,bios*.bin,pvh.bin} ./AppDir/share/qemu/ 2>/dev/null || true

mkdir -p ./AppDir/share/OVMF
cp $edk2_src/*.fd ./AppDir/share/OVMF/

ovmf_name=$(basename "$(find ./AppDir/share/OVMF/ -name '*.fd' -print -quit)")
cat > ./AppDir/bin/cowork.hook <<EOF
export CLAUDE_OVMF_CODE_PATH="\${APPDIR}/share/OVMF/$ovmf_name"
EOF
