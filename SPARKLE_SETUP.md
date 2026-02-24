# Sparkle Auto-Update Setup Guide

This guide walks you through setting up Sparkle auto-updates for worK.

## Prerequisites

- GitHub repository (public or private)
- macOS development environment
- Homebrew installed

## Step 1: Generate EdDSA Keypair

Sparkle uses EdDSA (Ed25519) signatures to verify update integrity. Generate a keypair once and store it securely.

### Install Sparkle Tools

```bash
# Download Sparkle tools
curl -L https://github.com/sparkle-project/Sparkle/releases/download/2.6.0/Sparkle-2.6.0.tar.xz -o sparkle.tar.xz
tar -xf sparkle.tar.xz
chmod +x bin/generate_keys
```

### Generate Keypair

```bash
./bin/generate_keys
```

This will output:
- **Public Key** (SUPublicEDKey) - Add to Info.plist
- **Private Key** - Store as GitHub Actions secret

### Add Public Key to Info.plist

1. Open `project.yml`
2. Add the public key under settings > base:

```yaml
INFOPLIST_KEY_SUPublicEDKey: "YOUR_PUBLIC_KEY_HERE"
```

3. Regenerate project:

```bash
xcodegen generate
```

## Step 2: Configure GitHub Repository

### Add GitHub Actions Secret

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `SPARKLE_PRIVATE_KEY`
5. Value: Paste your private key (the one that starts with `-----BEGIN PRIVATE KEY-----`)
6. Click **Add secret**

### Update URLs in Code

Replace `YOUR_USERNAME` with your actual GitHub username in:

1. **Constants.swift**:
   ```swift
   static let githubSponsorsURL = "https://github.com/sponsors/YOUR_USERNAME"
   static let appcastURL = "https://raw.githubusercontent.com/YOUR_USERNAME/worK/main/appcast.xml"
   ```

2. **project.yml**:
   ```yaml
   INFOPLIST_KEY_SUFeedURL: https://raw.githubusercontent.com/YOUR_USERNAME/worK/main/appcast.xml
   ```

3. **appcast.xml**:
   ```xml
   <link>https://raw.githubusercontent.com/YOUR_USERNAME/worK/main/appcast.xml</link>
   ```

## Step 3: Test the Workflow

### Create a Release

1. Commit all changes:
   ```bash
   git add .
   git commit -m "Add Sparkle auto-update system"
   git push
   ```

2. Create and push a tag:
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

3. GitHub Actions will:
   - Build the app
   - Sign the update
   - Create a GitHub Release with the ZIP file
   - Update `appcast.xml`

### Verify the Release

1. Go to **Actions** tab on GitHub - verify the workflow succeeded
2. Go to **Releases** tab - verify `v1.0.1` exists with `worK.zip`
3. Check that `appcast.xml` was updated in the main branch

## Step 4: Test Auto-Update

### Manual Test

1. Build and run the current version (v1.0.0)
2. Open Settings
3. Click "Check for Updates"
4. You should see an update dialog for v1.0.1
5. Click "Install Update"
6. App should download, quit, install, and relaunch

### Automatic Test

1. Keep the app running for 4 hours (or modify `SUScheduledCheckInterval` to a shorter time for testing)
2. Sparkle will automatically check for updates and prompt the user

## Step 5: GitHub Sponsors Setup (Optional)

1. Apply for GitHub Sponsors at https://github.com/sponsors
2. Complete your profile setup
3. Enable one-time sponsorships
4. Update `Constants.swift` with your actual Sponsors URL

## Troubleshooting

### Update Check Fails

- Verify `appcast.xml` is accessible at the URL in `SUFeedURL`
- Check Console.app for Sparkle logs (filter by "Sparkle")
- Ensure `SUPublicEDKey` matches your public key

### GitHub Actions Fails

- Verify `SPARKLE_PRIVATE_KEY` secret is set correctly
- Check Actions logs for specific error messages
- Ensure XcodeGen is generating the project correctly

### Signature Verification Fails

- Public and private keys must match (regenerate both if needed)
- Ensure the private key in GitHub Secrets is the complete key including header/footer

## Security Notes

- **NEVER** commit your private key to the repository
- Store the private key in a secure password manager as backup
- GitHub Secrets are encrypted and only exposed during workflow runs
- Sparkle automatically verifies signatures before installing updates
- HTTPS is required for the appcast URL (prevents MITM attacks)

## Cost Breakdown

- **GitHub Actions** (public repos): FREE
- **GitHub Actions** (private repos): 2,000 free minutes/month
- **GitHub Releases**: FREE (unlimited storage and bandwidth)
- **GitHub Sponsors**: FREE (0% platform fees)
- **Total**: $0/month for public repos

## Update Frequency

By default, Sparkle checks for updates:
- Every 4 hours (14,400 seconds) - `SUScheduledCheckInterval`
- On app launch (if last check was > 4 hours ago)
- When user clicks "Check for Updates"

To change the interval, modify `INFOPLIST_KEY_SUScheduledCheckInterval` in `project.yml`:
- 3600 = 1 hour
- 14400 = 4 hours (default)
- 86400 = 24 hours

## Release Process

For each new release:

1. Update version in `project.yml`:
   ```yaml
   MARKETING_VERSION: "1.0.2"
   CURRENT_PROJECT_VERSION: "2"
   ```

2. Commit changes:
   ```bash
   git add .
   git commit -m "Version 1.0.2"
   git push
   ```

3. Create and push tag:
   ```bash
   git tag v1.0.2
   git push origin v1.0.2
   ```

4. GitHub Actions will handle the rest automatically!

## Additional Resources

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Sponsors Documentation](https://docs.github.com/en/sponsors)
