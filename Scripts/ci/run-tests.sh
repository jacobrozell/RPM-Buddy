#!/usr/bin/env bash
set -euo pipefail

SIM_DESTINATION="${1:-platform=iOS Simulator,name=iPhone 17}"

xcodebuild test \
  -project RPMBuddy.xcodeproj \
  -scheme RPMBuddyCI \
  -destination "${SIM_DESTINATION}" \
  -resultBundlePath TestResults.xcresult \
  -derivedDataPath DerivedData \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tee xcodebuild-test.log
