#!/bin/bash
set -e

# ============================================================================
# worK DMG Build Script
# ============================================================================
# Automates building, signing, and packaging the worK macOS app into a DMG
# with drag-to-Applications installation experience.
#
# Usage:
#   ./build-dmg.sh                    # Build unsigned DMG (for testing)
#   ./build-dmg.sh --sign             # Build + code sign
#   ./build-dmg.sh --sign --notarize  # Build + sign + notarize (full release)
#
# Prerequisites:
#   - brew install xcodegen
#   - brew install create-dmg
#   - Apple Developer account (for signing/notarizing)
# ============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="worK"
VERSION="1.0.0"
BUNDLE_ID="com.worK.app"
DERIVED_DATA_PATH="./build"
ARCHIVE_PATH="$DERIVED_DATA_PATH/${APP_NAME}.xcarchive"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

# Parse command line arguments
SHOULD_SIGN=false
SHOULD_NOTARIZE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --sign)
      SHOULD_SIGN=true
      shift
      ;;
    --notarize)
      SHOULD_NOTARIZE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--sign] [--notarize]"
      exit 1
      ;;
  esac
done

# ============================================================================
# Functions
# ============================================================================

print_header() {
  echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

check_prerequisites() {
  print_header "Checking Prerequisites"

  # Check xcodegen
  if ! command -v xcodegen &> /dev/null; then
    print_error "xcodegen not found. Install with: brew install xcodegen"
    exit 1
  fi
  print_success "xcodegen found"

  # Check create-dmg
  if ! command -v create-dmg &> /dev/null; then
    print_error "create-dmg not found. Install with: brew install create-dmg"
    exit 1
  fi
  print_success "create-dmg found"

  # Check for signing identity if --sign is specified
  if [ "$SHOULD_SIGN" = true ]; then
    if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
      print_error "No Developer ID Application certificate found in Keychain"
      print_warning "Install certificate from Apple Developer portal or build without --sign"
      exit 1
    fi
    print_success "Code signing identity found"
  fi

  # Check for notarization credentials if --notarize is specified
  if [ "$SHOULD_NOTARIZE" = true ]; then
    if ! xcrun notarytool history --keychain-profile "${APP_NAME}-notary" &> /dev/null; then
      print_error "Notarization profile '${APP_NAME}-notary' not found"
      print_warning "Run: xcrun notarytool store-credentials \"${APP_NAME}-notary\""
      exit 1
    fi
    print_success "Notarization profile found"
  fi
}

generate_project() {
  print_header "Generating Xcode Project"

  if [ ! -f "project.yml" ]; then
    print_error "project.yml not found. Are you in the worK directory?"
    exit 1
  fi

  xcodegen generate
  print_success "Xcode project generated"
}

build_app() {
  print_header "Building Release Version"

  # Clean previous builds
  rm -rf "$DERIVED_DATA_PATH"

  # Build and archive
  xcodebuild -scheme "$APP_NAME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    | xcpretty || xcodebuild -scheme "$APP_NAME" -configuration Release -archivePath "$ARCHIVE_PATH" archive

  if [ ! -d "$ARCHIVE_PATH" ]; then
    print_error "Archive failed"
    exit 1
  fi

  print_success "App built successfully"

  # Show app location
  APP_PATH="$ARCHIVE_PATH/Products/Applications/${APP_NAME}.app"
  echo "  App location: $APP_PATH"

  # Show app size
  APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
  echo "  App size: $APP_SIZE"
}

sign_app() {
  if [ "$SHOULD_SIGN" = false ]; then
    print_warning "Skipping code signing (build with --sign to enable)"
    return
  fi

  print_header "Code Signing Application"

  APP_PATH="$ARCHIVE_PATH/Products/Applications/${APP_NAME}.app"

  # Get signing identity
  IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk -F'"' '{print $2}')

  echo "  Signing with: $IDENTITY"

  # Sign the app
  codesign --deep --force --verify --verbose \
    --sign "$IDENTITY" \
    --options runtime \
    --entitlements "worK/Resources/worK.entitlements" \
    "$APP_PATH"

  # Verify signature
  if codesign --verify --deep --strict --verbose=2 "$APP_PATH" 2>&1 | grep -q "valid on disk"; then
    print_success "App code signed successfully"
  else
    print_error "Code signing verification failed"
    exit 1
  fi
}

create_dmg_background() {
  print_header "Creating DMG Background"

  if [ -f "dmg-background.png" ]; then
    print_success "Using existing dmg-background.png"
    return
  fi

  print_warning "dmg-background.png not found, creating basic background..."

  # Create a simple dark background with text
  # Requires ImageMagick: brew install imagemagick
  if command -v convert &> /dev/null; then
    convert -size 1200x800 xc:"rgb(20,20,20)" \
      -pointsize 36 -fill "rgba(255,255,255,0.7)" \
      -gravity South -annotate +0+100 "Drag worK to Applications to install" \
      dmg-background.png
    print_success "Created basic DMG background"
  else
    print_warning "ImageMagick not found, DMG will have no background"
    print_warning "Install with: brew install imagemagick"
  fi
}

create_dmg_file() {
  print_header "Creating DMG Installer"

  APP_PATH="$ARCHIVE_PATH/Products/Applications/${APP_NAME}.app"

  # Remove old DMG if exists
  rm -f "$DMG_NAME"

  # Build create-dmg command
  CMD=(create-dmg
    --volname "$APP_NAME"
    --window-size 600 400
    --icon-size 100
    --icon "${APP_NAME}.app" 150 190
    --hide-extension "${APP_NAME}.app"
    --app-drop-link 450 190)

  # Add background if exists
  if [ -f "dmg-background.png" ]; then
    CMD+=(--background "dmg-background.png")
  fi

  # Add volume icon if exists
  ICON_PATH="worK/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"
  if [ -f "$ICON_PATH" ]; then
    CMD+=(--volicon "$ICON_PATH")
  fi

  CMD+=(--hdiutil-verbose "$DMG_NAME" "$APP_PATH")

  # Execute
  "${CMD[@]}"

  if [ ! -f "$DMG_NAME" ]; then
    print_error "DMG creation failed"
    exit 1
  fi

  print_success "DMG created successfully"

  # Show DMG size
  DMG_SIZE=$(du -sh "$DMG_NAME" | cut -f1)
  echo "  DMG size: $DMG_SIZE"
}

sign_dmg() {
  if [ "$SHOULD_SIGN" = false ]; then
    return
  fi

  print_header "Signing DMG"

  IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk -F'"' '{print $2}')

  codesign --sign "$IDENTITY" "$DMG_NAME"

  if codesign --verify --verbose "$DMG_NAME" 2>&1 | grep -q "valid on disk"; then
    print_success "DMG signed successfully"
  else
    print_error "DMG signing failed"
    exit 1
  fi
}

notarize_dmg() {
  if [ "$SHOULD_NOTARIZE" = false ]; then
    print_warning "Skipping notarization (build with --notarize to enable)"
    return
  fi

  print_header "Notarizing DMG with Apple"

  echo "  Submitting to Apple..."
  echo "  This may take several minutes (or hours)..."

  # Submit for notarization
  xcrun notarytool submit "$DMG_NAME" \
    --keychain-profile "${APP_NAME}-notary" \
    --wait

  # Check if successful
  if [ $? -eq 0 ]; then
    print_success "Notarization successful"

    # Staple ticket to DMG
    echo "  Stapling notarization ticket..."
    xcrun stapler staple "$DMG_NAME"

    # Verify stapling
    if xcrun stapler validate "$DMG_NAME" 2>&1 | grep -q "is valid"; then
      print_success "Notarization ticket stapled successfully"
    else
      print_error "Stapling failed"
      exit 1
    fi
  else
    print_error "Notarization failed"
    echo "  Check status with: xcrun notarytool history --keychain-profile ${APP_NAME}-notary"
    exit 1
  fi
}

copy_to_landing_page() {
  print_header "Copying to Landing Page"

  LANDING_PAGE_PATH="../worK_landing/public"

  if [ ! -d "$LANDING_PAGE_PATH" ]; then
    print_warning "Landing page directory not found at: $LANDING_PAGE_PATH"
    print_warning "Skipping copy to landing page"
    return
  fi

  cp "$DMG_NAME" "$LANDING_PAGE_PATH/worK.dmg"
  print_success "DMG copied to landing page"
  echo "  Location: $LANDING_PAGE_PATH/worK.dmg"
  echo "  Download URL: https://your-domain.com/worK.dmg"
}

# ============================================================================
# Main Execution
# ============================================================================

print_header "worK DMG Build Script"
echo "Version: $VERSION"
echo "Bundle ID: $BUNDLE_ID"
echo "Build type: $([ "$SHOULD_SIGN" = true ] && echo "Signed" || echo "Unsigned")$([ "$SHOULD_NOTARIZE" = true ] && echo " + Notarized" || echo "")"
echo ""

check_prerequisites
generate_project
build_app
sign_app
create_dmg_background
create_dmg_file
sign_dmg
notarize_dmg
copy_to_landing_page

# ============================================================================
# Completion
# ============================================================================

print_header "Build Complete! 🎉"

echo "  DMG file: $(pwd)/$DMG_NAME"
echo "  Size: $(du -sh "$DMG_NAME" | cut -f1)"
echo ""

if [ "$SHOULD_SIGN" = true ] && [ "$SHOULD_NOTARIZE" = true ]; then
  print_success "Fully signed and notarized - ready for public distribution!"
  echo ""
  echo "Next steps:"
  echo "  1. Test the DMG on a clean macOS installation"
  echo "  2. Upload to landing page: vercel deploy --prod"
  echo "  3. Post on LinkedIn!"
elif [ "$SHOULD_SIGN" = true ]; then
  print_warning "Signed but not notarized - users may see warnings"
  echo ""
  echo "Consider running with --notarize for best user experience"
else
  print_warning "Unsigned build - only for testing"
  echo ""
  echo "For public distribution, run with --sign --notarize"
fi

echo ""
print_success "All done!"
