# SkeeterCast Mobile App - Session Status
## December 31, 2025 ~2:00 AM EST

### COMPLETED THIS SESSION:

1. **Fixed Auth API Issues**
   - Added 'admin' tier to `require_paid_tier` decorator (was blocking admin users from saving cities)
   - Fixed SQLite syntax → PostgreSQL syntax in device token endpoints
   - Server file: `/mnt/ai_pool/auth_api.py` (backup exists)

2. **Fixed Cities Screen Weather Display**
   - Wind speed/direction now comes from same source (observation or hourly, not mixed)
   - Added "Calm" display for 0 wind speed
   - Night icon (🌙) now shows correctly at night instead of sun
   - Dewpoint shows °F label
   - Dewpoint now uses observation data when available (fresh) instead of stale hourly

3. **Server-side Dewpoint Fix**
   - Added `dewpoint_f` to city_api.py observation response
   - Container: `skeeter-citycast` (restarted)
   - Observations update every 15 minutes via `skeeter-observations` container

4. **Fixed TOS/Privacy Policy Emails**
   - Changed all emails to `support@skeetercast.com`
   - Files: `privacy_policy_screen.dart`, `terms_of_service_screen.dart`

5. **Added Forgot Password Feature**
   - New file: `lib/screens/forgot_password_screen.dart`
   - Updated `login_screen.dart` to navigate to forgot password
   - Uses server endpoint `/api/forgot-password`

6. **App Branding/Logos**
   - Copied HQ logo to: `assets/images/logo_hq.png`
   - Updated app launcher icons using flutter_launcher_icons
   - Updated login, register, and about screens to show logo
   - Logo files in: `/mnt/c/Users/fires/skeetercast_app/assets/images/`

7. **Splash Screen Configuration**
   - Current config in pubspec.yaml:
     ```yaml
     flutter_native_splash:
       color: "#000000"
       image: assets/images/logo_hq.png
       android_12:
         color: "#000000"
     ```
   - Android 12: Black screen (no icon/circle)
   - Flutter splash: Logo on black background

### STILL TODO:
- Implement offline caching system (for offshore use with no cell signal)
- App icon may still show Flutter default - needs verification after clean install
- Test forgot password flow end-to-end

### KEY FILES MODIFIED:
- `/mnt/c/Users/fires/skeetercast_app/lib/screens/cities_screen.dart`
- `/mnt/c/Users/fires/skeetercast_app/lib/screens/login_screen.dart`
- `/mnt/c/Users/fires/skeetercast_app/lib/screens/register_screen.dart`
- `/mnt/c/Users/fires/skeetercast_app/lib/screens/settings_screen.dart`
- `/mnt/c/Users/fires/skeetercast_app/lib/screens/forgot_password_screen.dart` (NEW)
- `/mnt/c/Users/fires/skeetercast_app/lib/screens/privacy_policy_screen.dart`
- `/mnt/c/Users/fires/skeetercast_app/lib/screens/terms_of_service_screen.dart`
- `/mnt/c/Users/fires/skeetercast_app/pubspec.yaml`
- `/mnt/c/Users/fires/skeetercast_app/android/app/src/main/res/values-v31/styles.xml`
- `/mnt/c/Users/fires/skeetercast_app/android/app/src/main/res/values-night-v31/styles.xml`

### SERVER FILES MODIFIED:
- `/mnt/ai_pool/auth_api.py` - Added admin tier, fixed SQL syntax, device token endpoints
- `/mnt/ai_pool/city_api.py` (inside skeeter-citycast container) - Added dewpoint_f

### LOGO FILES:
- Source: `C:\Users\fires\OneDrive\Desktop\Fixed Logos\skeetercast_transparent.png`
- App assets: `/mnt/c/Users/fires/skeetercast_app/assets/images/`
  - logo_hq.png (501KB - high quality)
  - logo_512.png
  - logo_192.png

### COMMANDS TO REBUILD:
```bash
cd /mnt/c/Users/fires/skeetercast_app
cmd.exe /c "C:\Users\fires\flutter\bin\flutter.bat pub get"
cmd.exe /c "C:\Users\fires\flutter\bin\flutter.bat pub run flutter_launcher_icons"
cmd.exe /c "C:\Users\fires\flutter\bin\flutter.bat pub run flutter_native_splash:create"
cmd.exe /c "C:\Users\fires\AppData\Local\Android\Sdk\platform-tools\adb.exe uninstall com.skeetercast.app"
cmd.exe /c "C:\Users\fires\flutter\bin\flutter.bat run -d emulator-5554"
```

### NOTES:
- Emulator: sdk gphone64 x86 64 (emulator-5554)
- Flutter path: C:\Users\fires\flutter\bin\flutter.bat
- ADB path: C:\Users\fires\AppData\Local\Android\Sdk\platform-tools\adb.exe
