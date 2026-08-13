# Event Care Mobile

Flutter client organized by feature. Authentication is split into domain,
data, and presentation layers; API business rules remain in Laravel.

Create the native wrappers once (the command preserves `lib`, `test`, assets,
and `pubspec.yaml`):

```bash
flutter create --platforms=android,ios --org com.prowem --project-name event_care_mobile .
flutter pub get
```

Run against local Docker from an Android emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:18090/api/v1
```

Run against the demo server:

```bash
flutter run --dart-define=API_BASE_URL=http://178.239.147.50/api/v1
```

For plain HTTP demos, Android must allow cleartext traffic in the generated
`android/app/src/main/AndroidManifest.xml`. Use HTTPS before production.
