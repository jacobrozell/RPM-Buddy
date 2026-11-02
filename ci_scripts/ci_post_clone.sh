#!/bin/sh
# Xcode Cloud clone hook for XcodeGen apps.
# Copy to <repo>/ci_scripts/ci_post_clone.sh and chmod +x.
# Xcode Cloud only runs ci_scripts at the repository root.
set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"

yml=""
# Portable shallow search (macOS CI image has python3 and find).
yml=$(find . -name project.yml -not -path '*/.*' -maxdepth 4 | head -n 1)
if [ -z "$yml" ]; then
  echo "No project.yml; assuming the Xcode project is already in git"
  exit 0
fi

brew install xcodegen

root="$(dirname "$yml")"
if [ -n "${GOOGLE_SERVICE_INFO_PLIST_BASE64:-}" ]; then
  echo "$GOOGLE_SERVICE_INFO_PLIST_BASE64" | base64 --decode \
    > "$root/Resources/GoogleService-Info.plist"
else
  echo "warning: GOOGLE_SERVICE_INFO_PLIST_BASE64 not set; using example plist"
  cp "$root/Resources/GoogleService-Info.plist.example" "$root/Resources/GoogleService-Info.plist"
fi

(cd "$root" && xcodegen generate)
echo "Generated Xcode project from $yml"

# Xcode Cloud will not resolve Swift packages on its own. The generated
# project needs the same pin file a local build already produced.
resolved_src="$root/ci/Package.resolved"
resolved_dest="$root/RPMBuddy.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [ ! -f "$resolved_src" ]; then
  echo "error: ci/Package.resolved is missing" >&2
  exit 1
fi
mkdir -p "$(dirname "$resolved_dest")"
cp "$resolved_src" "$resolved_dest"
echo "Installed Package.resolved"
