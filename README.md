# StayClose 💝

**StayClose** is a Flutter app designed to help you maintain meaningful relationships by providing daily reminders to reach out to important people in your life. Never forget to stay in touch with friends and family again!

## 🎯 Why StayClose?

- **🎲 Smart Daily Selection**: Randomly picks a contact each day, prioritizing those with upcoming important dates
- **📸 Personal Touch**: Add profile pictures with an accessible, custom cropping interface
- **⏰ Your Schedule**: Set your preferred notification time - no more fixed schedules
- **🎨 Beautiful Design**: Modern Material 3 interface optimized for accessibility
- **📱 Native Feel**: Built with Flutter for smooth performance on both iOS and Android

## ✨ Features

### 📱 Core Functionality
- **Contact Management**: Add, edit, and delete contacts with phone and email information
- **Profile Pictures**: Upload and crop square profile photos for each contact with accessible UI
- **Important Dates**: Track birthdays, anniversaries, and other meaningful dates for each contact
- **Daily Contact Selection**: Smart random selection of a contact to reach out to each day
- **Contact of the Day Home**: Featured contact display with large avatar and quick actions
- **Persistent Selection**: Same contact selected for the entire day (resets daily)
- **Smart Prioritization**: 30% chance to select contacts with upcoming important dates

### 🔔 Notifications & Settings
- **Customizable Daily Reminders**: Set your preferred notification time (default 9:00 AM)
- **Settings Screen**: Easy access to notification preferences and test notifications
- **Important Date Alerts**: Notifications on special days and 3-day advance warnings
- **Test Notifications**: Verify your notification settings work correctly
- **Multiple Channels**: Separate notification categories for different reminder types

### 🎨 Modern UI/UX
- **Material 3 Design**: Clean, modern interface with teal color scheme
- **Custom Image Cropping**: Accessible crop interface with properly positioned controls
- **Contact Avatars**: Profile pictures with letter fallbacks for contacts without photos
- **Contact Cards**: Beautiful card-based layout with circular avatars
- **Upcoming Dates**: Visual indicators for contacts with important dates in the next 30 days
- **Responsive Design**: Optimized for various screen sizes and different devices
- **Empty States**: Helpful messages when no contacts exist

### 📞 Contact Actions
- **Quick Copy**: Copy phone numbers and emails to clipboard
- **Contact Details**: View all information including important dates
- **Profile Photo Management**: Add, edit, or remove contact profile pictures
- **Action Buttons**: Quick access to call, text, or email (copy contact info)

## 🛠 Technical Details

### Built With
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **SharedPreferences** - Local data storage and user preferences
- **flutter_local_notifications** - Push notifications with custom scheduling
- **timezone** - Timezone handling for notifications
- **uuid** - Unique contact and file ID generation
- **image_picker** - Camera and gallery image selection
- **crop_your_image** - Custom image cropping with accessible UI
- **path_provider** - Local file system access for image storage

### Architecture
```
lib/
├── models/
│   └── contact.dart              # Contact and ImportantDate data models
├── screens/
│   ├── home_screen.dart          # Contact of the Day home screen
│   ├── contact_list_screen.dart  # All contacts list with settings access
│   ├── add_edit_contact_screen.dart # Contact form with profile pictures
│   ├── settings_screen.dart      # Notification preferences and test options
│   └── image_crop_screen.dart    # Custom accessible image cropping UI
├── services/
│   ├── contact_storage.dart      # Local storage management
│   ├── daily_contact_service.dart # Smart contact selection logic
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
   git clone https://github.com/yourusername/stayclose-flutter.git
   cd stayclose-flutter
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

**iOS (requires macOS and Xcode):**
```bash
flutter build ios --release
```

## 📱 Usage

1. **Add Your First Contact**
   - Tap the "Add Contact" button on the home screen or floating action button
   - Fill in name, phone, and email information
   - Add a profile picture by tapping the camera icon (camera or gallery)
   - Crop the photo using the accessible cropping interface
   - Add important dates like birthdays or anniversaries

2. **Contact of the Day**
   - Your home screen shows the daily selected contact with their photo
   - Tap the large contact avatar to view/edit their details
   - Use action buttons to copy contact information
   - Refresh selection using the three-dot menu

3. **Manage Contacts**
   - Access "All Contacts" from the home screen menu or people icon
   - Tap any contact to edit their information and photo
   - Use the popup menu to edit or delete contacts
   - View upcoming important dates highlighted on contact cards

4. **Customize Notifications**
   - Access Settings from the menu on any screen
   - Set your preferred daily reminder time using the time picker
   - Test your notification settings with the "Send Test Notification" option
   - Allow notification permissions when prompted

5. **Profile Pictures**
   - Add photos to contacts using the camera icon
   - Choose between camera or gallery
   - Use the custom crop interface with accessible button placement
   - Photos are automatically saved and managed locally

## 🔧 Configuration

### User Settings
Most configuration is now handled through the in-app Settings screen:

- **Notification Time**: Customize your daily reminder time using the time picker
- **Test Notifications**: Verify your settings work correctly
- **Default Time**: 9:00 AM (automatically applied for new users)

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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design for the beautiful UI components
- The open-source community for the helpful packages

---

**Made with ❤️ to help you stay close to the people who matter most.**
