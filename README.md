# StayClose 💝

**StayClose** is a Flutter app designed to help you maintain meaningful relationships by providing daily reminders to reach out to important people in your life. Never forget to stay in touch with friends and family again!

## ✨ Features

### 📱 Core Functionality
- **Contact Management**: Add, edit, and delete contacts with phone and email information
- **Important Dates**: Track birthdays, anniversaries, and other meaningful dates for each contact
- **Daily Contact Selection**: Smart random selection of a contact to reach out to each day
- **Persistent Selection**: Same contact selected for the entire day (resets daily)
- **Smart Prioritization**: 30% chance to select contacts with upcoming important dates

### 🔔 Notifications
- **Daily Reminders**: 10:00 AM notification to check your contact of the day
- **Important Date Alerts**: Notifications on special days and 3-day advance warnings
- **Multiple Channels**: Separate notification categories for different reminder types

### 🎨 Modern UI/UX
- **Material 3 Design**: Clean, modern interface with teal color scheme
- **Contact Cards**: Beautiful card-based layout with avatar circles
- **Upcoming Dates**: Visual indicators for contacts with important dates in the next 30 days
- **Responsive Design**: Optimized for various screen sizes
- **Empty States**: Helpful messages when no contacts exist

### 📞 Contact Actions
- **Quick Copy**: Copy phone numbers and emails to clipboard
- **Contact Details**: View all information including important dates
- **Action Buttons**: Quick access to call, text, or email (copy contact info)

## 🛠 Technical Details

### Built With
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **SharedPreferences** - Local data storage
- **flutter_local_notifications** - Push notifications
- **timezone** - Timezone handling for notifications
- **uuid** - Unique contact ID generation

### Architecture
```
lib/
├── models/
│   └── contact.dart              # Contact and ImportantDate data models
├── screens/
│   ├── contact_list_screen.dart  # Main contact list with navigation
│   ├── add_edit_contact_screen.dart # Contact form with important dates
│   └── daily_contact_screen.dart # Daily contact display and actions
├── services/
│   ├── contact_storage.dart      # Local storage management
│   ├── daily_contact_service.dart # Smart contact selection logic
│   └── notification_service.dart # Notification scheduling and management
└── main.dart                     # App entry point and theming
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
   - Tap the "Add Contact" button
   - Fill in name, phone, and email
   - Add important dates like birthdays or anniversaries

2. **Daily Contact Selection**
   - Tap the calendar icon in the app bar
   - View your randomly selected contact for the day
   - Use the action buttons to reach out

3. **Manage Contacts**
   - Tap any contact to edit
   - Use the three-dot menu to delete
   - View upcoming important dates on contact cards

4. **Notifications**
   - Allow notification permissions when prompted
   - Receive daily reminders at 10:00 AM
   - Get alerts for upcoming important dates

## 🔧 Configuration

### Timezone Settings
The app uses your local timezone by default. To change it, modify the timezone in `lib/services/notification_service.dart`:

```dart
tz.setLocalLocation(tz.getLocation('America/New_York')); // Change to your timezone
```

### Notification Times
Daily reminders are set for 10:00 AM. To change this, modify the time in `notification_service.dart`:

```dart
_nextInstanceOfTime(10, 0); // Change to your preferred hour
```

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
