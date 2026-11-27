# 라우럴! 광고 설정

Android와 iOS 앱은 AdMob에 미출시 앱으로 등록했다. 각 앱에 **공연 결과 배너** 광고 단위를 만들고 동영상 형식과 자동 새로고침을 껐다. 앱 안에서는 전체 결과 화면의 고정된 영역에 320×50 배너 하나를 요청한다. 앱의 점수 저장과 다음 공연 이동은 광고 요청을 기다리지 않는다.

| 플랫폼 | AdMob 앱 ID | 공연 결과 배너 단위 ID |
| --- | --- | --- |
| Android | `ca-app-pub-6973627802571104~5381884148` | `ca-app-pub-6973627802571104/2288816940` |
| iOS | `ca-app-pub-6973627802571104~7269680883` | `ca-app-pub-6973627802571104/4260374163` |

Android 앱 ID는 [AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml), iOS 앱 ID는 [Info.plist](../ios/Runner/Info.plist)에 연결했다. 광고 단위 선택과 로딩은 [festival_ads.dart](../lib/festival_ads.dart)에서 관리한다.

## 테스트 빌드

- Android와 iOS 빌드에 `--dart-define=LAUREOL_ADS_MODE=test`를 넣으면 Google 공식 샘플 배너를 사용한다. GitHub의 iOS 내부 TestFlight 작업에서는 `test_ads=true`로 고른다. 광고는 전체 공연의 결과 화면에서 확인한다. [Google 테스트 광고 안내](https://developers.google.com/admob/flutter/test-ads)
- 기본 빌드 모드는 `off`다. 운영 때에는 준비를 마친 뒤 릴리스 빌드에 `--dart-define=LAUREOL_ADS_MODE=live`를 넣는다.
- 운영 모드는 Google UMP로 시작 시 동의 상태를 갱신한다. 필요한 동의 화면은 결과 화면에서 띄우고, 광고를 요청할 수 있는 상태가 확인된 경우에만 배너를 요청한다. 개인정보 설정을 다시 열어야 하는 지역에서는 설정에 **광고 개인정보 설정**이 나타난다. 광고 요청은 비개인화로 보낸다. [Google Flutter UMP 안내](https://developers.google.com/admob/flutter/privacy)

## 운영 광고 준비

1. AdMob 계정 소유자가 **지급**에서 결제 프로필을 완료한다. 현재 콘솔에 결제 설정 미완료가 표시된다.
2. 각 앱을 출시한 뒤 공식 스토어 등록정보를 AdMob의 해당 iOS·Android 앱에 연결한다.
3. 스토어 개발자 웹사이트의 도메인 루트에 [app-ads.txt](app-ads.txt)를 게시하고 AdMob에서 소유권 확인과 앱 검토 상태를 확인한다. [Google app-ads.txt 게시 안내](https://support.google.com/admob/answer/9363762) · [Google 앱 검증 안내](https://support.google.com/admob/answer/14538460)
4. 운영 지역과 앱 설정에 맞춰 AdMob 개인정보 메시지를 게시하고, 제출하는 스토어의 개인정보 공개 항목을 SDK 설정에 맞춰 확인한다. [Google Mobile Ads 개인정보 공개 안내](https://developers.google.com/admob/ios/privacy/data-disclosure)
