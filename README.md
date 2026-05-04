# Scrintelligent

Scrintelligent is a context-aware parental control app built with Flutter and Firebase. The app helps parents manage child screen time using role-based onboarding, family linking, in-app usage tracking, activity classification, rewards, and adaptive rules that adjust screen-time allowance based on child activity.

## Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Google Sign-In
- Firebase Core

## Main Features

- Parent and child account creation
- Google Sign-In support
- Role selection for parent or child onboarding
- Family code generation and child-family linking
- Maximum of 5 linked children per family
- Parent dashboard with linked child usage overview
- Child dashboard with screen-time remaining, activity category, rewards, and badges
- In-app screen-time tracking
- Daily usage reset
- Adaptive rule engine for quiz rewards, education rewards, and entertainment penalties
- Parent settings for adjusting adaptive rule values
- Parent actions to pause or reset child usage for the day
- Child lock screen when daily screen time is exhausted

## How To Run The App

1. Clone or open the project folder.

2. Install dependencies:

```bash
flutter pub get
```

3. Make sure Firebase is connected.

The project uses Firebase, so `lib/firebase_options.dart` should be present and configured for your Firebase project. If Firebase needs to be reconnected, run:

```bash
flutterfire configure
```

4. Start an emulator or connect a physical Android device.

5. Run the app:

```bash
flutter run
```

For a release build:

```bash
flutter run --release
```

## Test Login Info

Parent account:

```text
email: favourabimbola03@gmail.com
password: Ab123456@@
```

Child account:

```text
email: divineagbeleye@gmail.com
password: Divine01
```

## Notes

- The current screen-time manager tracks in-app usage.
- Parent and child data are stored in Firestore.
- Children join a parent family using the family code generated for that parent.
- Daily reset is triggered when child usage is read by the app.
