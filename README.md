# Freqtrade Manager

A Flutter-based client application for managing Freqtrade trading.

## Features

### 1. User Authentication
- Secure login/logout system
- Credential secure storage
- Session management

### 2. Market Data
- Real-time candlestick chart display
- Trading data visualization
- Automatic data refresh (30-second interval)
- Manual refresh capability

### 3. Trading Management
- View open trades
- Trading operation interface
- Real-time trade status updates

### 4. System Features
- Material Design 3 interface
- Responsive layout
- Dark/Light theme support
- Notification service
- Configurable sidebar

## Tech Stack

- Flutter
- Provider state management
- SharedPreferences local storage
- Material Design 3
- RESTful API integration

## Project Structure

```
lib/
├── main.dart              # Application entry
├── screens/              # Screen interfaces
├── services/             # Service layer
├── widgets/              # Reusable components
├── models/               # Data models
└── providers/            # State management
```

## Development Requirements

- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- Git

## Installation and Running

1. Clone the project
```bash
git clone [project-url]
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the project
```bash
flutter run
```

## Configuration Guide

1. API Configuration
   - Configure Freqtrade API address in settings
   - Set up API keys

2. Notification Settings
   - Configure trading notifications
   - Set up reminder methods

## Contributing

Issues and Pull Requests are welcome to help improve the project.

