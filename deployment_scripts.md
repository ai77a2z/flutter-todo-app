# 🚀 Deployment Scripts & Guide

## 🌐 Web Deployment (Easiest Start)

### Option 1: Firebase Hosting (Recommended)
```bash
# 1. Install Firebase CLI
npm install -g firebase-tools

# 2. Login to Firebase
firebase login

# 3. Initialize Firebase in your project
firebase init hosting

# 4. Build your Flutter web app
flutter build web

# 5. Deploy to Firebase
firebase deploy
```

### Option 2: Netlify (Drag & Drop)
```bash
# 1. Build for web
flutter build web

# 2. Go to netlify.com
# 3. Drag and drop the 'build/web' folder
# 4. Your app is live!
```

### Option 3: GitHub Pages
```bash
# 1. Build for web
flutter build web --base-href "/mytodo/"

# 2. Create gh-pages branch
git checkout -b gh-pages

# 3. Copy build files
cp -r build/web/* .

# 4. Commit and push
git add .
git commit -m "Deploy to GitHub Pages"
git push origin gh-pages

# 5. Enable GitHub Pages in repo settings
```

## 📱 Mobile App Deployment

### Android - Google Play Store

#### 1. Prepare Release Build
```bash
# Generate signing key (first time only)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Create android/key.properties
```

Create `android/key.properties`:
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-keystore-file>
```

#### 2. Build Release
```bash
# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Or build APK for testing
flutter build apk --release
```

#### 3. Upload to Play Console
- Go to [Google Play Console](https://play.google.com/console)
- Create new app
- Upload `build/app/outputs/bundle/release/app-release.aab`

### iOS - App Store

#### 1. Prepare iOS Build
```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace

# In Xcode:
# 1. Set Team and Bundle ID
# 2. Choose "Any iOS Device" 
# 3. Product > Archive
# 4. Upload to App Store Connect
```

## 🔧 Pre-Deployment Checklist

### App Configuration
- [ ] Update app name in `pubspec.yaml`
- [ ] Set app icon (`flutter_launcher_icons` package)
- [ ] Configure splash screen
- [ ] Update version number
- [ ] Add app description

### Security & Performance
- [ ] Remove debug prints
- [ ] Test on physical devices
- [ ] Performance profiling
- [ ] Memory leak checking

### Store Requirements
- [ ] Privacy policy (required for stores)
- [ ] App screenshots (multiple sizes)
- [ ] Store listing description
- [ ] Age rating classification

## 📦 Quick Deploy Script

Create `deploy.sh`:
```bash
#!/bin/bash

echo "🚀 Starting deployment process..."

# Clean previous builds
flutter clean
flutter pub get

echo "📱 Building for Android..."
flutter build appbundle --release

echo "🌐 Building for Web..."
flutter build web

echo "✅ Build complete!"
echo "📁 Android bundle: build/app/outputs/bundle/release/app-release.aab"
echo "📁 Web files: build/web/"

echo "🎉 Ready for deployment!"
```

Make it executable:
```bash
chmod +x deploy.sh
./deploy.sh
```

## 🎯 Recommended Deployment Order

1. **Start with Web** (easiest, immediate sharing)
   - Deploy to Netlify or Firebase
   - Share link with friends/family
   - Get feedback

2. **Android Play Store** (larger audience)
   - Create developer account ($25 one-time)
   - Upload APK/Bundle
   - Review process (1-3 days)

3. **iOS App Store** (premium platform)
   - Apple Developer account ($99/year)
   - More strict review process
   - Higher revenue potential

## 💡 Pro Tips

- **Start with web deployment** - it's free and instant
- **Test thoroughly** on different screen sizes
- **Gather feedback** before store submission
- **Create compelling screenshots** for store listings
- **Write clear app descriptions** highlighting key features

## 🆘 Common Issues & Solutions

### Web Deploy Issues
```bash
# If web build fails
flutter clean
flutter pub get
flutter build web --release
```

### Android Signing Issues
```bash
# Reset signing if needed
cd android
./gradlew clean
cd ..
flutter clean
flutter build appbundle --release
```

### iOS Build Issues
```bash
# Clean iOS build
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter clean
flutter build ios --release
``` 