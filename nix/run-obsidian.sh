#!/usr/bin/env bash

set -o errexit

git rev-parse
cd "$(git rev-parse --show-toplevel)"
obsidian="$(readlink -f "$(which obsidian)")"

############################## Setup Testing Area ##############################
mkdir -p ./obsidian/.config/obsidian
jq -n '.vaults."1"=(.path="/home/obsidian/testvault"|.open=true)' \
  > ./obsidian/.config/obsidian/obsidian.json
mkdir -p ./obsidian/testvault

################################## Bubblewrap ##################################
# Base ARGs
declare -a base_args=(
  --ro-bind /nix/store /nix/store
  --proc /proc
  --dev /dev
  --tmpfs /tmp
  --tmpfs /run
  --unshare-all
  --share-net
  --clearenv
  --new-session
  --die-with-parent
)

# X11/Display
declare -a x11_args=(
  --tmpfs /tmp/.X11-unix
  --setenv DISPLAY "$DISPLAY"
  --setenv XAUTHORITY "$XAUTHORITY"
)

if [[ "$DISPLAY" =~ :([0-9]+) ]]; then
  local_socket=/tmp/.X11-unix/X${BASH_REMATCH[1]}
  x11_args+=(--ro-bind-try "$local_socket" "$local_socket")
fi

if [[ "$XAUTHORITY" == /tmp/* ]]; then
  x11_args+=(--ro-bind-try "$XAUTHORITY" "$XAUTHORITY")
fi

# ENVs
declare -a obsidian_vars_args=(
  --setenv OBSIDIAN_DISABLE_GPU 0
  --setenv OBSIDIAN_ENABLE_AUTOSCROLL 0
  --setenv OBSIDIAN_CLEAN_CACHE 1
)

# GRAPHICS
declare -a graphics_args=(
  --ro-bind-try /sys/dev /sys/dev
  --ro-bind-try /sys/devices /sys/devices
  --dev-bind /dev/dri /dev/dri
  --ro-bind /run/opengl-driver /run/opengl-driver
  --ro-bind /run/opengl-driver-32 /run/opengl-driver-32
)

# DBUS
declare -a dbus_args=(
  --setenv DBUS_SESSION_BUS_ADDRESS "$DBUS_SESSION_BUS_ADDRESS"
  --ro-bind /run/dbus /run/dbus
  --ro-bind /run/user /run/user
)

# Misc
declare -a extra_args=(
  --ro-bind /etc/fonts /etc/fonts
  --ro-bind /etc/resolv.conf /etc/resolv.conf
)

# Development
plugin_id="$(jq -r '.id' ./manifest.json)"
declare -a dev_args=(
  --bind ./obsidian /home/obsidian
  --setenv HOME /home/obsidian
  --ro-bind . "/home/obsidian/testvault/.obsidian/plugins/$plugin_id"
)

bwrap \
  "${base_args[@]}" \
  "${graphics_args[@]}" \
  "${obsidian_vars_args[@]}" \
  "${x11_args[@]}" \
  "${dbus_args[@]}" \
  "${extra_args[@]}" \
  "${dev_args[@]}" \
  -- "$obsidian"
