#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=./AppDir/share/icons/hicolor/256x256/apps/claude-desktop.png
export DESKTOP=./AppDir/share/applications/claude-desktop.desktop

export DEPLOY_GTK=1
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1

export PATH_MAPPING='
/usr/share/OVMF:${SHARUN_DIR%/*}/share/OVMF
/usr/share/AAVMF:${SHARUN_DIR%/*}/share/AAVMF
/usr/share/qemu:${SHARUN_DIR%/*}/share/qemu
'

quick-sharun ./AppDir/bin/* /usr/lib/libnss_nis.so* /usr/lib/libnsl.so* /usr/lib/libnss_mdns*_minimal.so*
quick-sharun --make-appimage
