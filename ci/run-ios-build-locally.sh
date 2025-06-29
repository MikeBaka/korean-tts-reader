#!/usr/bin/env bash
# Simulate the GitHub macOS build (for cloud Mac rental)
set -e
xcodebuild -scheme HanguTTS \
           -destination 'generic/platform=iOS' \
           -configuration Release \
           BUILD_DIR=$(pwd)/build \
           CODE_SIGNING_ALLOWED=NO
mkdir -p Payload && cp -R build/Release-iphoneos/HanguTTS.app Payload/
xcrun -sdk iphoneos PackageApplication -v Payload -o HanguTTS-unsigned.ipa
echo "Unsigned IPA ready: $(pwd)/HanguTTS-unsigned.ipa"