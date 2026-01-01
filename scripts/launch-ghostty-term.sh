#!/usr/bin/env bash
# Run Ghostty with explicit class/title; avoid env+exec ordering issues
exec env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia \
  ghostty --class clipse --title term_ghostty "$@"
