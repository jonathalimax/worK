#!/bin/bash

# Sparkle EdDSA Keypair Generator
# This script downloads Sparkle tools and generates EdDSA keys for auto-updates

set -e

echo "🔐 Sparkle EdDSA Keypair Generator"
echo "=================================="
echo ""

# Check if we're in the right directory
if [ ! -f "project.yml" ]; then
    echo "❌ Error: Must run this script from the worK project root directory"
    exit 1
fi

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "📥 Downloading Sparkle tools..."
curl -L -o sparkle.tar.xz https://github.com/sparkle-project/Sparkle/releases/download/2.6.0/Sparkle-2.6.0.tar.xz

echo "📦 Extracting..."
tar -xf sparkle.tar.xz

echo "🔑 Generating EdDSA keypair..."
chmod +x bin/generate_keys
./bin/generate_keys

echo ""
echo "✅ Keys generated successfully!"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Copy the PUBLIC key (SUPublicEDKey) to project.yml:"
echo "   Add under 'settings > base':"
echo "   INFOPLIST_KEY_SUPublicEDKey: \"YOUR_PUBLIC_KEY_HERE\""
echo ""
echo "2. Copy the PRIVATE key to GitHub Actions Secrets:"
echo "   - Go to: Settings → Secrets and variables → Actions"
echo "   - Click 'New repository secret'"
echo "   - Name: SPARKLE_PRIVATE_KEY"
echo "   - Value: [paste the entire private key]"
echo ""
echo "3. Store the PRIVATE key in a secure password manager as backup"
echo "   ⚠️  NEVER commit the private key to git!"
echo ""
echo "4. After adding the public key, run: xcodegen generate"
echo ""

# Clean up
cd -
rm -rf "$TEMP_DIR"

echo "🗑️  Cleaned up temporary files"
echo ""
echo "✨ Done! See SPARKLE_SETUP.md for detailed setup instructions."
