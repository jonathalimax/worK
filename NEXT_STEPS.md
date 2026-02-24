# Next Steps - Quick Start Guide

## ✅ Implementation Complete!

Both the **Auto-Update System** and **Donation Feature** have been successfully implemented. Here's what you need to do before the features become active.

---

## 🚀 Quick Start (5 Steps)

### Step 1: Generate Sparkle Keys (5 minutes)

```bash
./scripts/generate_sparkle_keys.sh
```

**What this does:**
- Downloads Sparkle tools
- Generates EdDSA keypair (public + private)
- Shows you the keys to copy

**Output:**
- **Public Key** → Copy this for Step 2
- **Private Key** → Save in password manager + use in Step 4

---

### Step 2: Add Public Key to project.yml (2 minutes)

Edit `project.yml` and add under `settings > base`:

```yaml
INFOPLIST_KEY_SUPublicEDKey: "YOUR_PUBLIC_KEY_FROM_STEP_1"
```

Then regenerate the project:

```bash
xcodegen generate
```

---

### Step 3: Update Username Placeholders (3 minutes)

Replace `YOUR_USERNAME` with your actual GitHub username in:

**1. worK/Shared/Constants.swift:**
```swift
static let githubSponsorsURL = "https://github.com/sponsors/your-username"
static let appcastURL = "https://raw.githubusercontent.com/your-username/worK/main/appcast.xml"
```

**2. project.yml:**
```yaml
INFOPLIST_KEY_SUFeedURL: https://raw.githubusercontent.com/your-username/worK/main/appcast.xml
```

**3. appcast.xml:**
```xml
<link>https://raw.githubusercontent.com/your-username/worK/main/appcast.xml</link>
```

Then regenerate:

```bash
xcodegen generate
```

---

### Step 4: Add Private Key to GitHub (2 minutes)

1. Go to your GitHub repo
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `SPARKLE_PRIVATE_KEY`
5. Value: Paste the **entire** private key (including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`)
6. Click **Add secret**

---

### Step 5: Apply for GitHub Sponsors (5 minutes + wait)

1. Visit https://github.com/sponsors
2. Click "Join the waitlist" or "Set up GitHub Sponsors"
3. Complete your profile:
   - Bio/description
   - Sponsorship tiers (suggest: $5, $10, $25)
   - Enable one-time sponsorships
   - Payment information (bank account or Stripe)
4. Submit application
5. Wait for approval (usually 1-2 days)

---

## ✅ Verification

After completing the steps above, verify everything works:

```bash
./scripts/verify_setup.sh
```

Expected output: **"✅ All checks passed!"**

---

## 🧪 Testing

### Test 1: Build the App

```bash
xcodebuild -scheme worK -configuration Debug build
```

Should complete without errors.

### Test 2: Run the App

Open `worK.xcodeproj` in Xcode and press ⌘R

**Check Settings Tab:**
1. Look for new **"Support"** section (pink heart icon)
2. Look for **"Check for Updates"** in About section

**Test Donation:**
1. Click "GitHub Sponsors" in Support section
2. Should open your GitHub Sponsors page in browser
3. (Will show 404 until GitHub Sponsors is approved)

**Test Updates:**
1. Click "Check for Updates" in About section
2. Should show "You're up to date" dialog (since no releases exist yet)

---

## 📦 Creating Your First Release

Once everything is set up and tested:

### 1. Update Version

Edit `project.yml`:

```yaml
MARKETING_VERSION: "1.0.1"
CURRENT_PROJECT_VERSION: "2"
```

### 2. Commit & Tag

```bash
git add .
git commit -m "Version 1.0.1: Add auto-update and donation features"
git push

git tag v1.0.1
git push origin v1.0.1
```

### 3. Watch GitHub Actions

1. Go to your repo's **Actions** tab
2. Watch the "Release" workflow run
3. Should complete in ~5-10 minutes

### 4. Verify Release

1. Go to **Releases** tab
2. Should see `v1.0.1` with `worK.zip` attached
3. Check `appcast.xml` in main branch (should be updated)

---

## 📚 Documentation

- **SPARKLE_SETUP.md** - Detailed setup guide with troubleshooting
- **IMPLEMENTATION_SUMMARY.md** - Complete technical overview
- **CLAUDE.md** - Updated project documentation

---

## 🆘 Troubleshooting

### "No such module 'Sparkle'" error

```bash
# In Xcode: File → Packages → Resolve Package Versions
# Or from terminal:
xcodebuild -resolvePackageDependencies -scheme worK
```

### Verification script shows warnings

Make sure you:
1. Replaced all `YOUR_USERNAME` placeholders
2. Added public key to `project.yml`
3. Ran `xcodegen generate` after changes

### GitHub Actions fails

1. Check that `SPARKLE_PRIVATE_KEY` secret is set
2. Verify the private key includes header/footer lines
3. Check Actions logs for specific error

---

## 💰 Cost Summary

- **GitHub Actions** (public repo): FREE
- **GitHub Releases**: FREE
- **GitHub Sponsors**: FREE (0% fees)
- **Sparkle**: FREE (MIT license)

**Total: $0/month**

---

## ✨ What You'll Get

### For Users:
- ✅ One-click updates (no manual downloads)
- ✅ Automatic update notifications
- ✅ Cryptographically signed releases (security)
- ✅ Easy way to support development

### For You:
- ✅ Automated release pipeline
- ✅ Version control for updates
- ✅ Optional donation revenue
- ✅ Professional distribution system

---

## 📞 Need Help?

1. Check `SPARKLE_SETUP.md` for detailed instructions
2. Review `IMPLEMENTATION_SUMMARY.md` for technical details
3. Open an issue on GitHub

---

**Ready to get started? Run Step 1:**

```bash
./scripts/generate_sparkle_keys.sh
```

Good luck! 🚀
