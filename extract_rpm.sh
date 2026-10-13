#!/bin/bash
# vim: set tabstop=2 smarttab shiftwidth=2 softtabstop=2 expandtab foldmethod=syntax :
#
# Bash script that extracts an RPM package using rpm2cpio/cpio
# and additionally saves all scriptlets (pre/post install/uninstall/trans)
# as separate .txt files.
#
# Usage:
#   extract_rpm.sh <package.rpm> [target_dir]
#
# If no target_dir is given, the rpm-filename will be used to createw a target directory in the current directory
#
# Source:
# https://github.com/ChrLau/scripts/blob/master/extract_rpm.sh

# Bash strict mode
#  read: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

VERSION="1.0"
SCRIPT="$(basename "$0")"

# Colored output
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

extract_rpm() {

  # No arguments or more than two? Print help
  if [ "$#" -eq 0 ] || [ "$#" -gt 2 ]; then
    echo "$SCRIPT $VERSION: Extract RPM-Packages, including all scripts, into a separate directory"
    echo ""
    echo "Usage: $SCRIPT package.rpm [target_dir]"
    echo "  If [target_dir] is omitted, ./package_extracted will be used as [target_dir]."
    echo "  Example:"
    echo "    blafoo-1.2.3-4.noarch.rpm will be extracted to: ./blafoo-1.2.3-4.noarch_extracted"
    return 1
  fi

  # remember the absolute path before we change directories
  RPM_FILE="$(readlink -f "$1")"

  BASE_NAME="$(basename "$RPM_FILE" .rpm)"

  # second argument is optional, otherwise derive from the package name
  DEST_DIR="${2:-./${BASE_NAME}_extracted}"

  echo -e "${YELLOW}${1} will be extracted to: ${DEST_DIR}${ENDCOLOR}"

  # Validate RPM-File
  if ! rpm -qp --info "$RPM_FILE" > /dev/null 2>&1; then
    echo -e "${RED}Error: file $RPM_FILE is not a valid RPM file.${ENDCOLOR}"
    return 1
  fi

  # Check tooling
  for cmd in rpm rpm2cpio cpio; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo -e "${RED}Error: required tool is not installed: $cmd${ENDCOLOR}"
      return 1
    fi
  done

  mkdir -p "$DEST_DIR/contents" "$DEST_DIR/scripts" || {
    echo -e "${RED}Error: could not create target directory $DEST_DIR.${ENDCOLOR}"
    return 1
  }

  echo -e "${GREEN}==> Extracting file contents into $DEST_DIR/contents ...${ENDCOLOR}"

  # Start in subshell because cpio supports no parameter to specify where to extract the contents to
  if ! (
    cd "$DEST_DIR/contents" || exit 1
    rpm2cpio "$RPM_FILE" | cpio -idmv 2>&1
  ); then
    echo -e "${YELLOW}Warning: rpm2cpio/cpio may have reported errors.${ENDCOLOR}"
  fi

  echo -e "${GREEN}==> Extracting scriptlets into $DEST_DIR/scripts ...${ENDCOLOR}"

  # mapping: rpm tag -> file name
  declare -A SCRIPT_TAGS=(
    ["PRETRANS"]="pretrans.txt"
    ["PREIN"]="pre_install.txt"
    ["POSTIN"]="post_install.txt"
    ["PREUN"]="pre_uninstall.txt"
    ["POSTUN"]="post_uninstall.txt"
    ["POSTTRANS"]="posttrans.txt"
    ["VERIFYSCRIPT"]="verify.txt"
  )

  for TAG in "${!SCRIPT_TAGS[@]}"; do
    FILE="${SCRIPT_TAGS[$TAG]}"
    CONTENT="$(rpm -qp --qf "%{${TAG}}" "$RPM_FILE" 2>/dev/null)"

    # rpm returns either an empty string or "(none)" when a
    # scriptlet is missing -> skip both cases
    if [[ -n "$CONTENT" && "$CONTENT" != "(none)" ]]; then
      printf '%s\n' "$CONTENT" > "$DEST_DIR/scripts/$FILE"
      echo "    - wrote $FILE"
    fi
  done

  # Document scriptlet interpreters (e.g. /bin/sh)
  rpm -qp --qf '=== Scriptlet interpreters ===\nPREIN:  %{PREINPROG}\nPOSTIN: %{POSTINPROG}\nPREUN:  %{PREUNPROG}\nPOSTUN: %{POSTUNPROG}\n' \
    "$RPM_FILE" > "$DEST_DIR/scripts/interpreters.txt" 2>/dev/null

  # also capture trigger scripts (if any) via --scripts, since these
  # aren't accessible through simple %{TAG} queries
  rpm -qp --scripts "$RPM_FILE" > "$DEST_DIR/scripts/all_scripts_raw.txt" 2>/dev/null

  echo -e "${GREEN}==> Done. Files haven been written to: $DEST_DIR${ENDCOLOR}"
}

# If this script is executed directly (not sourced), call the
# function with the given arguments.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  extract_rpm "$@"
fi
