#!/bin/bash

# This is to set the current version of raspberry pi os image
VERSION_NUMBER="1.0.0"
BUILD_RESULT="false"

# File naming rule:
# - 'kptv' + '_' + version number like 0.0.0 + _ + 'b' + jenkins build number + '.zip'
# - kptv_1.0.0_b12.zip
# - version number is from the environmental variable 'VERSION_NUMBER' defined in this script.
# - build number is from the environmental variable env.BUILD_NUMBER passed to jenkins agency. If not given, 'TEST' will be used instead.
IMAGE_FILE_NAME="kptv_${VERSION_NUMBER}_TEST.zip"
BUILDING_FOR_TEST="true"
if [ -n "${BUILD_NUMBER}" ]; then
  BUILDING_FOR_TEST="false"
  IMAGE_FILE_NAME="kptv_${VERSION_NUMBER}_b${BUILD_NUMBER}.zip"
fi
LATEST_IMAGE_FILE_NAME="kptv_latest.zip"

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

DO_CLEAN="false"
DO_BUILD_ALL="false"
echo "Given arguments: $#"
while [[ $# -ge 1 ]]; do
  i="$1"
  case $i in
    -c|--clean)
      DO_CLEAN="true"
      DO_BUILD_ALL="true"
      echo "-c or --clean is set, so will do clean all build"
      shift
      ;;
    -a|--all)
      DO_BUILD_ALL="true"
      echo "-a or --all is set, so will do all build"
      shift
      ;;
    *)
      echo "Unrecognized option $1"
      exit 1
      ;;
  esac
  shift
done

# Prepare flag files to build up to stage 4 plus the custom step, stage4-kptv
# - The flag files for stage4-kptv are already prepared.
# - We don't need stage5 at all.
if [ "${DO_BUILD_ALL}" == "true" ]; then
  echo "Activating all build"
  rm -f stage0/SKIP >/dev/null 2>&1
  rm -f stage1/SKIP >/dev/null 2>&1
  rm -f stage2/SKIP >/dev/null 2>&1
  rm -f stage3/SKIP >/dev/null 2>&1
  rm -f stage4/SKIP >/dev/null 2>&1
else
  touch stage0/SKIP
  touch stage1/SKIP
  touch stage2/SKIP
  touch stage3/SKIP
  touch stage4/SKIP
fi
touch stage5/SKIP
# - Don't generate image & noobs for all of stages except the customised stage4-kptv
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
cp -R ../stage4-kptv .

# Download the latest Kiwiplan Web Launcher file(zip format is for RPi4)
wget http://nznfsjavainstallers/data/currentgit/web-launcher/Kiwiplan_Web_Launcher_Setup_latest.zip -O ./stage4-kptv/00-kptv/files/kwl.zip
DOWLOAD_RESULT=$?
if [ $DOWLOAD_RESULT -eq 0 ]; then
  echo "The latest Kiwiplan Web Launcher file was downloaded well"

  # Remove files in deploy and work to save disk space
  rm -f ./work/kptv/export-image/*.img >/dev/null 2>&1
  rm -f ./deploy/* >/dev/null 2>&1

  # Build now
  # Clean run:
  # - Remove what previously was built
  # - CLEAN=1 ./build.sh -c ../config : To clean the existing generated files
  # Normal run:
  # - try to update the existing stuff if required
  # - ./build.sh -c ../config
  if [ "${DO_CLEAN}" == "true" ]; then
    echo "Activating clean build"
    CLEAN=1 ./build.sh -c ../config
  else
    ./build.sh -c ../config
  fi

  # Check if the image was exported
  if $(compgen -G "./deploy/image_*-kptv.zip" > /dev/null); then
    # Rename the generated file and then upload to nzjenkins3
    mv ./deploy/image_*-kptv.zip "./deploy/${IMAGE_FILE_NAME}"

    # When building for test, we shouldn't upload the built image.
    if [ "${BUILDING_FOR_TEST}" == "true" ]; then
      echo "./deploy/${IMAGE_FILE_NAME} was built well"
      BUILD_RESULT="true"
    else
      # Where to upload the build image
      # - Connection from kpbuildtv to nzjenkins3 using ssd account will be done with the pre-registered ssh key
      # - The new image file will be uploaded to /nfsjava/currentgit/kptv of nzjenkins
      # - The image files can be downloaded using web browser at http://nznfsjavainstallers/data/currentgit/kptv/
      scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "./deploy/${IMAGE_FILE_NAME}" ssd@nzjenkins3:/nfsjava/currentgit/kptv/
      UPLOAD_RESULT=$?

      # Create a symbolic link so that we can easily automate downloading the latest file
      ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ssd@nzjenkins3 "cd /nfsjava/currentgit/kptv/ ; rm -f ${LATEST_IMAGE_FILE_NAME}; ln -s \"${IMAGE_FILE_NAME}\" ${LATEST_IMAGE_FILE_NAME}"
      RENAME_RESULT=$?

      if [ $UPLOAD_RESULT -eq 0 ] && [ $RENAME_RESULT -eq 0 ]; then
        echo "./deploy/${IMAGE_FILE_NAME} was built and then uploaded to nzjenkins3 well"
        BUILD_RESULT="true"
      elif [ $UPLOAD_RESULT -ne 0 ]; then
        echo "Failed to upload ./deploy/${IMAGE_FILE_NAME} to nzjenkins3"
        BUILD_RESULT="false"
      elif [ $RENAME_RESULT -ne 0 ]; then
        echo "Failed to rename ./deploy/${IMAGE_FILE_NAME} to latest on nzjenkins3"
        BUILD_RESULT="false"
      fi
    fi
  else
    echo "No image was built"
    BUILD_RESULT="false"
  fi
else
  echo "Failed to download the latest Kiwiplan Web Launcher file"
  BUILD_RESULT="false"
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
rm -rf stage4-kptv >/dev/null 2>&1

# Move back to the previous directory
popd || exit 1

if [ "${BUILD_RESULT}" == "false" ]; then
  exit 1
fi
exit 0