#!/bin/bash

VERSION_NUMBER="0.0.1"
IMAGE_FILE_NAME="pire_${VERSION_NUMBER}.zip"

# Check if executed with root user or using sudo
echo ""
if [ "${EUID:-$(id -u)}" == "0" ]; then
  echo "Executed with root user or using sudo"
else
  echo "Please run with root user or using sudo."
  exit 1
fi

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Move to pi-gen
pushd "${SCRIPT_DIR}/pi-gen/" || exit 1

# Remove SKIP files except stage5 as we won't need it
#rm -f stage0/SKIP >/dev/null 2>&1
#rm -f stage1/SKIP >/dev/null 2>&1
#rm -f stage2/SKIP >/dev/null 2>&1
#rm -f stage3/SKIP >/dev/null 2>&1
#rm -f stage4/SKIP >/dev/null 2>&1

touch stage0/SKIP
touch stage1/SKIP
touch stage2/SKIP
touch stage3/SKIP
touch stage4/SKIP

touch stage5/SKIP

# Prepare SKIP_IMAGES and SKIP_NOOBS files of all of stages except the customised stage4-pire
touch stage0/SKIP_IMAGES
touch stage0/SKIP_NOOBS
touch stage1/SKIP_IMAGES
touch stage1/SKIP_NOOBS
touch stage2/SKIP_IMAGES
touch stage2/SKIP_NOOBS
touch stage3/SKIP_IMAGES
touch stage3/SKIP_NOOBS
touch stage4/SKIP_IMAGES
touch stage4/SKIP_NOOBS
touch stage5/SKIP_IMAGES
touch stage5/SKIP_NOOBS

# Copy the custom build stage directory to pi-gen
cp -R ../stage4-pire .

# Remove files in deploy and work to save disk space
rm -f ./work/pire/export-image/*.img >/dev/null 2>&1
rm -f ./deploy/* >/dev/null 2>&1

# Build now
# Clean run:
# - Remove what previously was built
# - CLEAN=1 ./build.sh -c ../config : To clean the existing generated files
# Normal run:
# - try to update the existing stuff if required
# - ./build.sh -c ../config
CLEAN=1 ./build.sh -c ../config

# Check if the image was exported
if $(compgen -G "./deploy/image_*-pire.zip" > /dev/null); then
  # Rename the generated file
  mv ./deploy/image_*-pire.zip "./deploy/${IMAGE_FILE_NAME}"
else
  echo "No image was built"
fi

# Now remove the flag files and the custom build directory to keep pi-gen clean
rm -f stage0/SKIP >/dev/null 2>&1
rm -f stage0/SKIP_IMAGES >/dev/null 2>&1
rm -f stage0/SKIP_NOOBS >/dev/null 2>&1
rm -f stage1/SKIP >/dev/null 2>&1
rm -f stage1/SKIP_IMAGES >/dev/null 2>&1
rm -f stage1/SKIP_NOOBS >/dev/null 2>&1
rm -f stage2/SKIP >/dev/null 2>&1
rm -f stage2/SKIP_IMAGES >/dev/null 2>&1
rm -f stage2/SKIP_NOOBS >/dev/null 2>&1
rm -f stage3/SKIP >/dev/null 2>&1
rm -f stage3/SKIP_IMAGES >/dev/null 2>&1
rm -f stage3/SKIP_NOOBS >/dev/null 2>&1
rm -f stage4/SKIP >/dev/null 2>&1
rm -f stage4/SKIP_IMAGES >/dev/null 2>&1
rm -f stage4/SKIP_NOOBS >/dev/null 2>&1
rm -f stage5/SKIP >/dev/null 2>&1
rm -f stage5/SKIP_IMAGES >/dev/null 2>&1
rm -f stage5/SKIP_NOOBS >/dev/null 2>&1
rm -rf stage4-pire >/dev/null 2>&1

# Move back to the previous directory
popd || exit 1
