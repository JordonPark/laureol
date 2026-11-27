import 'dart:async';

// Keep the same Cupertino widgets as the rest of the game.
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

import 'festival_records.dart';

const _mode = String.fromEnvironment('LAUREOL_ADS_MODE', defaultValue: 'off');
const _networkWait = Duration(seconds: 8);
const _adsSettings = MethodChannel('com.jordonpark.laureol/ads');
const _supportEmail = 'jusun4257@gmail.com';
const _adDataNotice =
    '비개인화 광고를 표시하기 위해 Google에 접속 IP, 기기·앱 정보 및 광고 관련 정보가 전달될 수 있어요.';

class FestivalAds extends ChangeNotifier {
  FestivalAds._();

  static final instance = FestivalAds._();

  Future<bool>? _consentUpdate;
  Future<void>? _initialize;
  bool _showingPrivacy = false;
  bool _privacyOptionsRequired = false;

  bool get live => enabled && _mode == 'live';
  bool get enabled => _bannerId != null;
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  String? get _bannerId {
    if (kIsWeb) return null;
    return switch ((defaultTargetPlatform, _mode)) {
      (TargetPlatform.android, 'test') =>
        'ca-app-pub-3940256099942544/6300978111',
      (TargetPlatform.iOS, 'test') => 'ca-app-pub-3940256099942544/2934735716',
      (TargetPlatform.android, 'live') when kReleaseMode =>
        'ca-app-pub-6973627802571104/2288816940',
      (TargetPlatform.iOS, 'live') when kReleaseMode =>
        'ca-app-pub-6973627802571104/4260374163',
      _ => null,
    };
  }

  Future<bool> _refreshConsent() {
    if (!live) return Future.value(false);
    return _consentUpdate ??= _requestConsent().then((updated) {
      if (!updated) _consentUpdate = null;
      return updated;
    });
  }

  Future<bool> _requestConsent() async {
    try {
      final update = Completer<bool>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => update.complete(true),
        (_) => update.complete(false),
      );
      if (!await update.future.timeout(_networkWait, onTimeout: () => false)) {
        return false;
      }
      await _readPrivacyOptions();
      return true;
    } on Exception {
      return false;
    }
  }

  Future<void> _readPrivacyOptions() async {
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus()
        .timeout(_networkWait);
    final required = status == PrivacyOptionsRequirementStatus.required;
    if (required == _privacyOptionsRequired) return;
    _privacyOptionsRequired = required;
    notifyListeners();
  }

  Future<bool> showPrivacyOptions() async {
    if (!_privacyOptionsRequired || _showingPrivacy) return false;
    _showingPrivacy = true;
    try {
      FormError? error;
      await ConsentForm.showPrivacyOptionsForm((result) => error = result);
      await _readPrivacyOptions();
      return error == null;
    } on Exception {
      return false;
    } finally {
      _showingPrivacy = false;
    }
  }

  Future<bool> _adReady(bool Function() onResults) async {
    try {
      if (!enabled || !onResults()) return false;
      if (live) {
        if (!await _refreshConsent() || !onResults()) return false;
        final consent = ConsentInformation.instance;
        if (await consent.getConsentStatus().timeout(_networkWait) ==
            ConsentStatus.required) {
          await _showConsentOnResults(onResults);
          await _readPrivacyOptions();
        }
        if (!onResults() ||
            !await consent.canRequestAds().timeout(_networkWait)) {
          return false;
        }
      }
      if (!onResults()) return false;
      await (_initialize ??= _startSdk());
      return onResults();
    } on Exception {
      return false;
    }
  }

  Future<void> _startSdk() async {
    try {
      final sdk = MobileAds.instance;
      if (live) await sdk.disableMediationInitialization();
      await sdk.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
      );
      await sdk.initialize();
      if (live) await _adsSettings.invokeMethod<void>('useContextualAds');
      await sdk.setAppMuted(true);
    } on Exception {
      _initialize = null;
      rethrow;
    }
  }

  Future<void> _showConsentOnResults(bool Function() onResults) async {
    if (!onResults() || _showingPrivacy) return;
    _showingPrivacy = true;
    try {
      if (!await ConsentInformation.instance.isConsentFormAvailable().timeout(
            _networkWait,
          ) ||
          !onResults()) {
        return;
      }
      final loaded = Completer<ConsentForm?>();
      final timer = Timer(_networkWait, () => loaded.complete(null));
      ConsentForm.loadConsentForm(
        (form) {
          if (loaded.isCompleted) {
            unawaited(form.dispose());
          } else {
            loaded.complete(form);
          }
        },
        (_) {
          if (!loaded.isCompleted) loaded.complete(null);
        },
      );
      final form = await loaded.future;
      timer.cancel();
      if (form == null) return;
      try {
        // The player may have reopened the concert while the form was loading.
        if (!onResults()) return;
        final dismissed = Completer<void>();
        form.show((_) => dismissed.complete());
        await dismissed.future;
      } finally {
        await form.dispose();
      }
    } finally {
      _showingPrivacy = false;
    }
  }
}

class FestivalResultBanner extends StatelessWidget {
  const FestivalResultBanner({super.key, required this.records});

  final FestivalRecords records;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      if (bounds.maxWidth < AdSize.banner.width) return const SizedBox.shrink();
      if (!FestivalAds.instance.live) return const _ResultBannerSlot();
      return ListenableBuilder(
        listenable: records,
        builder: (context, _) => switch (records.adConsent) {
          true => const _ResultBannerSlot(),
          false => const SizedBox.shrink(),
          null => _AdConsentPrompt(records: records),
        },
      );
    },
  );
}

class _AdConsentPrompt extends StatelessWidget {
  const _AdConsentPrompt({required this.records});

  final FestivalRecords records;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('결과 화면 광고'),
        const Text(_adDataNotice, style: TextStyle(fontSize: 13)),
        Wrap(
          spacing: 8,
          children: [
            CupertinoButton(
              onPressed: () => unawaited(records.setAdConsent(true)),
              child: const Text('동의하고 광고 허용'),
            ),
            CupertinoButton(
              onPressed: () => unawaited(records.setAdConsent(false)),
              child: const Text('건너뛰기'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ResultBannerSlot extends StatefulWidget {
  const _ResultBannerSlot();

  @override
  State<_ResultBannerSlot> createState() => _ResultBannerSlotState();
}

class _ResultBannerSlotState extends State<_ResultBannerSlot> {
  BannerAd? _request;
  Timer? _loadDeadline;
  DateTime? _loadedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  bool _onResults() =>
      mounted &&
      ModalRoute.of(context)?.isCurrent == true &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);

  Future<void> _load() async {
    final ads = FestivalAds.instance;
    final unit = ads._bannerId;
    if (unit == null) return;

    try {
      if (!await ads._adReady(_onResults) || !_onResults()) return;
      final ad = BannerAd(
        size: AdSize.banner,
        adUnitId: unit,
        request: const AdRequest(nonPersonalizedAds: true),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted && identical(ad, _request)) {
              _loadDeadline?.cancel();
              setState(() => _loadedAt = DateTime.now().toUtc());
            }
          },
          onAdFailedToLoad: (ad, _) => _clear(ad as BannerAd),
        ),
      );
      _request = ad;
      _loadDeadline = Timer(_networkWait, () => _clear(ad));
      await ad.load();
    } on Exception {
      if (_request case final ad?) _clear(ad);
    }
  }

  void _clear(BannerAd ad) {
    if (!identical(_request, ad)) return;
    _loadDeadline?.cancel();
    final wasVisible = _loadedAt != null;
    _request = null;
    if (wasVisible) {
      setState(() => _loadedAt = null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(ad.dispose());
      });
    } else {
      unawaited(ad.dispose());
    }
  }

  @override
  void dispose() {
    _loadDeadline?.cancel();
    final ad = _request;
    _request = null;
    if (ad != null) unawaited(ad.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _request;
    final loadedAt = _loadedAt;
    if (ad == null || loadedAt == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF3D334E))),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          SizedBox(
            width: AdSize.banner.width.toDouble(),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('광고', style: TextStyle(fontSize: 12)),
                CupertinoButton(
                  onPressed: _showAdInfo,
                  child: const Text('광고 정보', style: TextStyle(fontSize: 13)),
                ),
                CupertinoButton(
                  onPressed: () => _showAdReport(ad, loadedAt),
                  child: const Text('광고 신고', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          SizedBox(
            width: AdSize.banner.width.toDouble(),
            height: AdSize.banner.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdInfo() => showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('광고 정보'),
      content: Text(
        FestivalAds.instance.live
            ? 'Google AdMob이 제공하는 비개인화 광고예요. 광고는 '
                  '공연 결과 화면의 콘텐츠와 접속 IP에서 파악한 대략적인 지역을 기준으로 '
                  '선택될 수 있어요. 전체 관람가 광고 등급을 요청하며, '
                  '설정에서 결과 화면 광고 허용을 끌 수 있어요.'
            : 'Google AdMob이 제공하는 테스트 광고예요.',
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    ),
  );

  Future<void> _showAdReport(BannerAd ad, DateTime loadedAt) async {
    final responseId = ad.responseInfo?.responseId;
    final report = [
      '앱: 라우럴! 볼륨 좀 올려',
      '위치: 공연 결과',
      '표시 시각(UTC): ${loadedAt.toIso8601String()}',
      '광고 단위: ${ad.adUnitId}',
      if (responseId != null) '광고 응답 ID: $responseId',
      '',
      '어떤 내용이 부적절했는지 적어 주세요.',
    ].join('\n');
    final openEmail = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('부적절한 광고 신고'),
        content: const Text(
          '광고 응답 정보가 포함된 고객지원 메일 초안을 열어요. 메일에서 신고 사유를 적어 직접 보내 주세요.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('신고 메일 열기'),
          ),
        ],
      ),
    );
    if (!mounted || openEmail != true) return;
    try {
      final subject = Uri.encodeComponent('라우럴! 광고 신고');
      final body = Uri.encodeComponent(report);
      final mail = Uri(
        scheme: 'mailto',
        path: _supportEmail,
        query: 'subject=$subject&body=$body',
      );
      if (await launchUrl(mail, mode: LaunchMode.externalApplication)) return;
    } on Exception {
      // Offer the same report details when no mail app is available.
    }
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('메일 앱을 열 수 없어요.'),
        content: const Text('신고 내용을 복사해 고객지원 메일로 보내 주세요.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: '받는 사람: $_supportEmail\n\n$report'),
              );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('신고 내용 복사'),
          ),
        ],
      ),
    );
  }
}
