#!/bin/bash

# Setup Verification Script
# Checks if auto-update and donation features are properly configured

set -e

echo "🔍 worK Setup Verification"
echo "=========================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Check if we're in the right directory
if [ ! -f "project.yml" ]; then
    echo -e "${RED}❌ Error: Must run this script from the worK project root directory${NC}"
    exit 1
fi

echo "📁 Directory: ✅ Correct location"
echo ""

# Check required files exist
echo "📋 Checking required files..."

FILES=(
    "worK/Dependencies/UpdateClient.swift"
    "worK/Dependencies/SparkleCoordinator.swift"
    "SPARKLE_SETUP.md"
    "IMPLEMENTATION_SUMMARY.md"
    "appcast.xml"
    ".github/workflows/release.yml"
    "scripts/generate_sparkle_keys.sh"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo -e "  ${RED}❌ $file (missing)${NC}"
        ((ERRORS++))
    fi
done

echo ""

# Check Constants.swift for placeholder URLs
echo "🔗 Checking URLs in Constants.swift..."

if grep -q "YOUR_USERNAME" worK/Shared/Constants.swift; then
    echo -e "  ${YELLOW}⚠️  Found 'YOUR_USERNAME' placeholder - needs to be replaced${NC}"
    ((WARNINGS++))
else
    echo "  ✅ No placeholders found"
fi

echo ""

# Check project.yml for Sparkle configuration
echo "⚙️  Checking project.yml configuration..."

if grep -q "Sparkle" project.yml; then
    echo "  ✅ Sparkle package added"
else
    echo -e "  ${RED}❌ Sparkle package not found${NC}"
    ((ERRORS++))
fi

if grep -q "INFOPLIST_KEY_SUFeedURL" project.yml; then
    echo "  ✅ SUFeedURL configured"
else
    echo -e "  ${YELLOW}⚠️  SUFeedURL not configured${NC}"
    ((WARNINGS++))
fi

if grep -q "INFOPLIST_KEY_SUPublicEDKey" project.yml; then
    echo "  ✅ SUPublicEDKey configured"
else
    echo -e "  ${YELLOW}⚠️  SUPublicEDKey not configured (run ./scripts/generate_sparkle_keys.sh)${NC}"
    ((WARNINGS++))
fi

if grep -q "YOUR_USERNAME" project.yml; then
    echo -e "  ${YELLOW}⚠️  Found 'YOUR_USERNAME' placeholder in project.yml${NC}"
    ((WARNINGS++))
fi

echo ""

# Check if XcodeGen is installed
echo "🛠️  Checking build tools..."

if command -v xcodegen &> /dev/null; then
    echo "  ✅ XcodeGen installed"
else
    echo -e "  ${YELLOW}⚠️  XcodeGen not installed (brew install xcodegen)${NC}"
    ((WARNINGS++))
fi

echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run: ./scripts/generate_sparkle_keys.sh"
    echo "2. Update project.yml with public key"
    echo "3. Replace 'YOUR_USERNAME' in Constants.swift and project.yml"
    echo "4. Add private key to GitHub Secrets"
    echo "5. Run: xcodegen generate"
    echo "6. Apply for GitHub Sponsors"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  ${WARNINGS} warning(s) found${NC}"
    echo ""
    echo "Review the warnings above and complete the setup steps."
else
    echo -e "${RED}❌ ${ERRORS} error(s) and ${WARNINGS} warning(s) found${NC}"
    echo ""
    echo "Fix the errors above before proceeding."
    exit 1
fi

echo ""
echo "📚 For detailed setup instructions, see:"
echo "   - SPARKLE_SETUP.md"
echo "   - IMPLEMENTATION_SUMMARY.md"
echo ""
