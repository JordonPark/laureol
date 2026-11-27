import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _mode = String.fromEnvironment('LAUREOL_ADS_MODE', defaultValue: 'off');
const _networkWait = Duration(seconds: 8);

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
        'ca-app-pub-3940256099942544/9214589741',
      (TargetPlatform.iOS, 'test') => 'ca-app-pub-3940256099942544/2435281174',
      (TargetPlatform.android, 'live') when kReleaseMode =>
        'ca-app-pub-6973627802571104/2288816940',
      (TargetPlatform.iOS, 'live') when kReleaseMode =>
        'ca-app-pub-6973627802571104/4260374163',
      _ => null,
    };
  }

  Future<bool> refreshConsent() {
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
        if (!await refreshConsent() || !onResults()) return false;
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
      await sdk.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
      );
      await sdk.setAppMuted(true);
      await sdk.initialize();
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
  const FestivalResultBanner({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => bounds.maxWidth >= AdSize.banner.width
        ? const _ResultBannerSlot()
        : const SizedBox.shrink(),
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
  bool _loaded = false;

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
              setState(() => _loaded = true);
            }
          },
          onAdFailedToLoad: (ad, _) => _clear(ad as BannerAd),
        ),
      );
      setState(() => _request = ad);
      _loadDeadline = Timer(_networkWait, () => _clear(ad));
      await ad.load();
    } on Exception {
      if (_request case final ad?) _clear(ad);
    }
  }

  void _clear(BannerAd ad) {
    if (!identical(_request, ad)) return;
    _loadDeadline?.cancel();
    final wasVisible = _loaded;
    setState(() {
      _request = null;
      _loaded = false;
    });
    if (wasVisible) {
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
    if (ad == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF3D334E))),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: AdSize.banner.width.toDouble(),
        height: AdSize.banner.height.toDouble(),
        child: _loaded ? AdWidget(ad: ad) : null,
      ),
    );
  }
}
