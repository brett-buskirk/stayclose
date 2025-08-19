# StayClose 💝

**StayClose** is a Flutter app designed to help you maintain meaningful relationships by providing daily reminders to reach out to important people in your life. Never forget to stay in touch with friends and family again!

## 🎯 Why StayClose?

- **🎲 Smart Daily Selection**: Randomly picks a kindred each day, prioritizing those with upcoming important dates
- **📱 Device Integration**: Import contacts directly from your device with bulk selection
- **📸 Personal Touch**: Add profile pictures with camera or gallery access
- **⏰ Your Schedule**: Set your preferred notification time - no more fixed schedules
- **🎨 Beautiful Design**: Modern Material 3 interface with comprehensive onboarding
- **🔒 Privacy First**: All data stays on your device - no cloud storage or tracking
- **📱 Native Feel**: Built with Flutter for smooth performance on both iOS and Android

## ✨ Features

### 📱 Core Functionality
- **Contact Import**: Import contacts directly from your device with search and bulk selection
- **Smart Search**: Real-time search through all kindred by name, phone, or email
- **Kindred Management**: Add, edit, and delete kindred with phone and email information
- **Custom Circle Management**: Create unlimited personalized circles beyond the default four
- **Circle Customization**: Choose unique emojis and colors for each circle
- **Circle Reordering**: Drag & drop circles to organize them by preference  
- **Bulk Operations**: Multi-select contacts for mass circle reassignment
- **Circle Filtering**: Filter kindred by circle with visual filter chips
- **Alphabetical Organization**: All contacts automatically sorted alphabetically within circles
- **Profile Pictures**: Camera and gallery access with custom cropping interface
- **Important Dates**: Track birthdays, anniversaries in MM/DD/YYYY format
- **Daily Kindred Selection**: Smart random selection of a kindred to reach out to each day
- **Kindred of the Day Home**: Featured kindred display with large avatar and quick actions
- **Persistent Selection**: Same kindred selected for the entire day (resets daily)
- **Smart Prioritization**: 30% chance to select kindred with upcoming important dates
- **Welcome Experience**: Beautiful 5-page onboarding for first-time users

### 🔔 Notifications & Settings
- **Personalized Daily Nudges**: Daily reminders with specific kindred names and custom timing
- **Detailed Important Date Alerts**: Rich notifications with contact info for birthdays and anniversaries
- **Dual Time Settings**: Separate customizable times for daily nudges and important date notifications
- **Advance Warnings**: 3-day advance notices for important dates with planning suggestions
- **Settings Screen**: Easy access to notification preferences and test notifications
- **Test Notifications**: Verify your notification settings work correctly
- **Multiple Channels**: Separate notification categories for different reminder types

### 🎨 Modern UI/UX
- **Material 3 Design**: Clean, modern interface with teal color scheme
- **Custom Image Cropping**: Accessible crop interface with properly positioned controls
- **Kindred Avatars**: Profile pictures with letter fallbacks for kindred without photos
- **Kindred Cards**: Beautiful card-based layout with circular avatars and circle badges
- **Circle Badges**: Visual circle indicators with custom emojis and colors on each kindred card
- **Filter Chips**: Interactive circle filtering with emoji-enhanced filter buttons
- **Multi-Select Mode**: Checkbox interface for bulk operations with orange theme
- **Drag & Drop Interface**: Intuitive reordering with visual drag handles
- **Interactive Help**: Info button modals for contextual assistance
- **Progress Indicators**: Visual feedback during bulk operations and data loading
- **Upcoming Dates**: Visual indicators for kindred with important dates in the next 30 days
- **Responsive Design**: Optimized for various screen sizes and different devices
- **Empty States**: Helpful messages when no kindred exist

### 📞 Kindred Actions
- **Direct Integration**: Call, text, and email buttons launch external apps
- **Quick Copy**: Copy phone numbers and emails to clipboard
- **Kindred Details**: View all information including important dates
- **Profile Photo Management**: Add, edit, or remove kindred profile pictures
- **Info Access**: Persistent info icon to review app features anytime

## 🛠 Technical Details

### Built With
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **SharedPreferences** - Local data storage and user preferences
- **flutter_local_notifications** - Push notifications with custom scheduling
- **flutter_contacts** - Device contact access and import
- **permission_handler** - Contact and camera permission management
- **timezone** - Timezone handling for notifications
- **uuid** - Unique contact and file ID generation
- **image_picker** - Camera and gallery image selection
- **crop_your_image** - Custom image cropping with accessible UI
- **path_provider** - Local file system access for image storage
- **url_launcher** - External app integration for calls, texts, emails

### Architecture
```
lib/
├── models/
│   └── contact.dart              # Contact, ImportantDate, Circle, and Circles data models
├── screens/
│   ├── home_screen.dart          # Contact of the Day home screen with import
│   ├── contact_list_screen.dart  # All contacts list with multi-select and bulk operations
│   ├── add_edit_contact_screen.dart # Contact form with profile pictures
│   ├── circle_management_screen.dart # Custom circle creation and reordering
│   ├── settings_screen.dart      # Reorganized settings with interactive help
│   ├── welcome_screen.dart       # 5-page onboarding experience
│   └── image_crop_screen.dart    # Custom accessible image cropping UI
├── services/
│   ├── contact_storage.dart      # Local storage management
│   ├── daily_contact_service.dart # Smart contact selection logic
│   ├── circle_service.dart       # Circle CRUD operations and reordering
│   ├── notification_service.dart # Custom notification scheduling
│   └── image_service.dart        # Photo upload, cropping, and storage
└── main.dart                     # App entry point and Material 3 theming
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.8.0)
- Dart SDK
- Android Studio / Xcode for mobile development
- A physical device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/brett-buskirk/stayclose.git
   cd stayclose
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building for Release

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle (recommended for Play Store):**
```bash
flutter build appbundle --release
```

**iOS (requires macOS and Xcode):**
```bash
flutter build ios --release
```

**Note**: Release builds use ProGuard for code optimization. Custom ProGuard rules are configured in `android/app/proguard-rules.pro` to ensure `flutter_local_notifications` works correctly in production.

## 📱 Usage

1. **First Time Experience**
   - Beautiful 5-page welcome screen explains StayClose's purpose and features
   - Learn about daily kindred reminders and relationship management
   - Onboarding automatically appears for new users with no contacts

2. **Add Your First Kindred**
   - **Quick Import**: Use "Import from Device" button directly on home screen empty state
   - **Bulk Import**: Access import from floating action button on contact list screen
   - **Device Integration**: Search and select multiple contacts with bulk operations
   - **Manual Entry**: Add kindred individually using "Add Kindred" button
   - Fill in name, phone, and email information
   - Add profile pictures from camera or gallery
   - Add important dates like birthdays or anniversaries (MM/DD/YYYY format)

3. **Kindred of the Day**
   - Your home screen shows the daily selected kindred with their photo
   - Tap the large kindred avatar to view/edit their details
   - Use action buttons to call, text, or email directly via external apps
   - Copy contact information to clipboard with quick buttons
   - Refresh selection using the three-dot menu

4. **Manage Kindred**
   - Access "All Kindred" from the home screen menu or people icon
   - **Circle Filtering**: Use filter chips to view kindred by circle (supports custom circles)
   - **Smart Search**: Use search bar to quickly find specific kindred by name, phone, or email
   - **Multi-Select Mode**: Use checklist icon to select multiple contacts for bulk operations
   - **Bulk Circle Assignment**: Select contacts and use floating action button to reassign circles
   - **Circle Organization**: See custom circle badges with emojis and colors on each kindred card
   - **Alphabetical List**: All kindred automatically sorted alphabetically for easy browsing
   - **Dual Action Buttons**: Import more contacts or add individual kindred via floating buttons
   - Tap any kindred to edit their information, photo, and circle assignment
   - Use the popup menu to edit or delete kindred
   - View upcoming important dates highlighted on kindred cards

5. **Manage Custom Circles**
   - Access Settings → Circles → Manage Circles
   - **Create Custom Circles**: Add unlimited personalized circles with unique names
   - **Customize Appearance**: Choose emojis and colors for easy identification
   - **Drag & Drop Reordering**: Long-press drag handles to reorganize circle order
   - **Edit Circles**: Modify names, emojis, and colors (custom circles only)
   - **Safe Deletion**: Delete custom circles with automatic contact reassignment
   - **Default Circles**: Family, Friends, Work, Other (colors customizable, cannot delete)
   - **Circle Colors**: Separate access via Settings → Circles → Circle Colors

6. **Customize Notifications**
   - Access Settings from the menu on any screen
   - **Daily Nudges**: Set your preferred time for daily kindred reminders (with info button)
   - **Important Dates**: Set separate time for birthday/anniversary notifications
   - **Rich Content**: Notifications include specific names and contact information
   - Test your notification settings with the "Test Scheduled Nudge" option
   - Allow notification permissions when prompted
   - **Android 13+**: Enable "Alarms & reminders" permission in device settings for scheduled notifications

7. **Access App Information**
   - Tap the info icon (ℹ️) in the app bar to review StayClose features
   - Beautiful 5-page guide explains purpose, features, and privacy approach
   - Available anytime for reference or helping others understand the app

8. **Profile Pictures**
   - Add photos to kindred using the camera icon
   - Choose between camera or gallery
   - Use the custom crop interface with accessible button placement
   - Photos are automatically saved and managed locally

## 📲 Availability

StayClose is available on Google Play Store with comprehensive privacy policy compliance. The app requests minimal permissions:
- **Contacts**: For device contact import (optional feature)
- **Camera**: For profile photos (optional feature)  
- **Storage**: For saving profile pictures locally
- **Notifications**: For daily reminders and important date alerts
- **Schedule Exact Alarms**: For precise daily notification timing (Android 13+)
- **Full Screen Intent**: For important notification display (Android 14+)

**Privacy Policy**: [https://brett-buskirk.github.io/stayclose/privacy-policy.html](https://brett-buskirk.github.io/stayclose/privacy-policy.html)

All data remains on your device - no cloud storage, tracking, or third-party sharing.

## 🔧 Configuration

### User Settings
Most configuration is now handled through the in-app Settings screen:

- **Notification Time**: Customize your daily reminder time using the time picker
- **Test Notifications**: Use "Test Scheduled Nudge" to verify settings work correctly
- **Default Time**: 9:00 AM (automatically applied for new users)
- **Circle Management**: Create, edit, reorder, and delete custom circles
- **Circle Colors**: Customize colors for all circles (default and custom)
- **Interactive Help**: Info buttons provide contextual assistance for features
- **Theme Selection**: Choose between Light, Dark, or System theme

### Advanced Configuration

#### Timezone Settings
The app uses your local timezone by default. For development, you can modify the timezone in `lib/services/notification_service.dart`:

```dart
tz.setLocalLocation(tz.getLocation('America/New_York')); // Change to your timezone
```

#### Image Storage
Profile pictures are automatically managed and stored locally in the app's documents directory with unique identifiers.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/brett-buskirk/stayclose/blob/main/LICENSE) file for details.

## 🛠 Troubleshooting

### Notifications Not Working (Android 13+)
If daily nudges aren't appearing:

1. **Check App Settings**:
   - Go to device Settings > Apps > StayClose > Notifications
   - Ensure "Daily Kindred Reminder" channel is enabled
   - Verify notification importance is set to "High" or "Urgent"

2. **Enable Alarms & Reminders**:
   - Go to device Settings > Apps > Special app access > Alarms & reminders
   - Find StayClose and enable permission
   - This is required for scheduled notifications on Android 13+

3. **Battery Optimization**:
   - Go to device Settings > Apps > StayClose > Battery
   - Select "Unrestricted" or disable battery optimization
   - This prevents the system from stopping scheduled notifications

4. **Test Notifications**:
   - Use "Test Scheduled Nudge" in Settings to verify scheduling works
   - Test notification should arrive in exactly 1 minute

### Build Issues
If you encounter notification issues in release builds:
- Ensure ProGuard rules in `android/app/proguard-rules.pro` are properly configured
- The app includes custom keep rules for `flutter_local_notifications`

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design for the beautiful UI components
- The open-source community for the helpful packages

---

**Made with ❤️ to help you stay close to the people who matter most.**

**Current Version**: v0.3.0+16 - Custom Circle Management with bulk operations and enhanced UI
