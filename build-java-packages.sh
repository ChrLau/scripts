#!/bin/bash

# Build Java packages with epoch version numbers

SCRIPT="$(basename "$0")"
SCRIPT_VERSION="1.0"
PACKAGES_DIR="/home/$USER/packages"
PACKAGES_TMP_DIR="$PACKAGES_DIR/tmp"

function HELP {
  echo "$SCRIPT, v$SCRIPT_VERSION: Build Debian Java packages"
  echo "Usage: $SCRIPT filename"
  echo ""
  echo "Currently only 1 filename is supported!"
  exho ""
  echo "Packages are created with normal version and an additional package with epoch version of 1:"
  echo "This is needed because of naming incompatibilities in the Java package ecosystem"
  exit 1
}

# Print help if no arguments are given
if [ "$#" -eq 0 ]; then
  HELP
elif [ "$#" -gt 1 ]; then
  HELP
fi

# Check / Created needed directories
if [ ! -d "$PACKAGES_DIR" ]; then
  mkdir -p "$PACKAGES_TMP_DIR"
fi

if [ ! -d "$PACKAGES_TMP_DIR" ]; then
  mkdir -p "$PACKAGES_TMP_DIR"
fi

# Get and check for presence of needed binaries
AR=$(which ar)
TAR=$(which tar)
FAKEROOT=$(which fakeroot)
MAKEJPKG=$(which make-jpkg)

# Do this as function?
#function CHECKBINARY($BINARYNAME) {
#  # Test if ar is present and executeable
#  if [ ! -x "$BINARYNAME" ]; then
#    echo "This script requires ar for extracting and re-packaging the .deb files."
#    echo "Please install the package: binutils"
#    exit 3;
#  fi
#}

# Test if ar is present and executeable
if [ ! -x "$AR" ]; then
  echo "This script requires ar for extracting and re-packaging the .deb files."
  echo "Please install the package: binutils"
  exit 3;
fi

# Test if tar is present and executeable
if [ ! -x "$TAR" ]; then
  echo "This script requires tar to (un)zip the control.tar.gz file."
  echo "Please install the package: tar"
  exit 3;
fi

# Test if fakeroot is present and executeable
if [ ! -x "$FAKEROOT" ]; then
  echo "This script requires fakeroot for building the .deb files."
  echo "Please install the package: fakeroot"
  exit 3;
fi

# Test if make-jpkg is present and executeable
if [ ! -x "$MAKEJPKG" ]; then
  echo "This script requires make-jpkg to build the .deb file."
  echo "Please install the package: java-package"
  exit 3;
fi

if [ -r "$1" ]; then
  TARFILE="$1"
else
  echo "File: $PWD/$1 is not readable. Is the filename correct?"
  exit 2
fi

#####
##### Build packages without epoch version - starts here
#####

cd "$PACKAGES_DIR" || exit

yes | fakeroot make-jpkg --with-system-certs --full-name "ITOEBIZ Build Script" --email "ito-team-hosting-application@1und1.de" "$PACKAGES_DIR/$TARFILE" >> "$PACKAGES_TMP_DIR/$TARFILE-make-jpkg.log" 2>&1

# Check the returncode and set DEBFILE
if [ "$?" -eq 0 ]; then
  # Get the filename from the build .deb file from the log file
  #  Needed to build the epoch version packages
  DEBFILE=$(grep "dpkg -i" "$PACKAGES_TMP_DIR/$TARFILE-make-jpkg.log" | awk -F"-i " '{print $2}')
else
  echo "make-jpkg didn't exit cleanly, please check the logfile: $PACKAGES_TMP_DIR/$TARFILE-make-jpkg.log"
  exit 4
fi


#####
##### Build packages with epoch version - starts here
#####

# Switch to tmp dir
cd "$PACKAGES_TMP_DIR" || exit

# Extract the control file of the package
if [ -r "$PACKAGES_DIR/$DEBFILE" ]; then
  $AR p "$PACKAGES_DIR/$DEBFILE" control.tar.gz | $TAR -xz
else
  echo "\$DEBFILE doesn't exist or is not readable."
  exit 5
fi

# Get the version number from extracted file "control"
VERSION="$(grep Version control | awk -F": " '{print $2}')"
EPOCH_VERSION="1:$VERSION"

# Replace version with epoch version
sed -i "s/Version: $VERSION/Version: $EPOCH_VERSION/" control

# Get Java package type (everything before the first underscore from left to right)
FILENAME_PACKAGE_TYPE=$(echo "$DEBFILE" | awk -F_ '{print $1}')

# Luckily the second hit is the version number
FILENAME_VERSION_NUMBER=$(echo "$DEBFILE" | awk -F_ '{print $2}')

# And the third is the architecture + file extension
FILENAME_ARCHITECURE=$(echo "$DEBFILE" | awk -F_ '{print $3}')

# Replace version from filename with epoch version
FILENAME_EPOCH_VERSION_NUMBER="1-$FILENAME_VERSION_NUMBER"

# Construct the new filename with epoch version
FILENAME_WITH_EPOCH="${FILENAME_PACKAGE_TYPE}_${FILENAME_EPOCH_VERSION_NUMBER}_${FILENAME_ARCHITECURE}"

# To prevent the creation of non-sense files we check VERSION
# as only then we can be sure the .deb generation and extraction worked
if [ -n "$VERSION" ]; then

  # Copy the original .deb file to create the additional .deb file with epoch numbering
  cp "$PACKAGES_DIR/$DEBFILE" "$PACKAGES_DIR/$FILENAME_WITH_EPOCH"

  # Create the control.tar.gz file again out of all files in the tmp directory
  # But omitting build-related files
  $TAR czf control.tar.gz *[!z]
  
  # Re-package the newly copied .deb file with epoch version
  # Overwriting the control.tar.gz one with the one we just created
  $AR r "../$FILENAME_WITH_EPOCH" control.tar.gz

else

  echo "VERSION is empty, please check if .deb file was extracted successfully."
  exit 6

fi

# Delete everything in PACKAGES_TMP_DIR to clean up
# But check first if the variable is actually set
if [ -n "$PACKAGES_TMP_DIR" ]; then

  rm "$PACKAGES_TMP_DIR"/*

else

  echo "Variable PACKAGES_TMP_DIR is empty! As this is potentially dangerous when running: rm \"\$PACKAGES_TMP_DIR\/\*\" this script exists now."
  echo "Please clean up your \$PACKAGES_TMP_DIR manually!"
  exit 6

fi
