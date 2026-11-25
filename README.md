# 라우럴! 볼륨 좀 올려

공연장 음향 감독이 되어 관객을 떼창으로 이끄는 iOS·Android 오프라인 게임입니다. 현재 Flutter 시작 화면과 두 플랫폼의 앱 프로젝트가 준비되어 있습니다.

[게임 기획서](docs/game-design.md)

## 개발 시작

Flutter stable과 Android SDK 또는 macOS의 Xcode를 설치합니다. Android는 에뮬레이터 또는 실기기에서 실행하고, iOS는 macOS에서 시뮬레이터 또는 서명이 설정된 실기기로 실행합니다.

```sh
flutter doctor
flutter pub get
flutter devices
flutter run
```

## 검사와 빌드

```sh
flutter analyze
flutter test
flutter build apk --debug
```

macOS에서 iOS 시뮬레이터용 앱을 확인하려면 `flutter build ios --simulator`를 실행합니다.

앱 ID와 번들 ID는 `com.jordonpark.laureol`입니다. 앱 진입점은 `lib/main.dart`에 있습니다.
