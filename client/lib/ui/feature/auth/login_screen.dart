import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/definition/app_definition.dart';
import 'package:house_worker/ui/component/cavivara_avatar.dart';
import 'package:house_worker/ui/feature/auth/login_presenter.dart';
import 'package:house_worker/ui/feature/home/home_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const name = 'LoginScreen';

  static MaterialPageRoute<LoginScreen> route() =>
      MaterialPageRoute<LoginScreen>(
        builder: (_) => const LoginScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final continueWithoutAccountButton = ElevatedButton(
      onPressed: _startWithoutAccount,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
      child: const Text('はじめる'),
    );

    final children = <Widget>[
      Text(
        'カヴィヴァラチャット',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 16),
      const CavivaraAvatar(
        size: 160,
      ),
      const SizedBox(height: 32),
      Text(
        'カヴィヴァラさんと\n楽しくおしゃべりしよう',
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 60),
      continueWithoutAccountButton,
      const SizedBox(height: 32),
      const _AgreementText(),
    ];

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );
  }

  Future<void> _startWithoutAccount() async {
    await ref.read(startResultProvider.notifier).startWithoutAccount();

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      HomeScreen.route(),
    );
  }
}

/// 「はじめる」をタップして利用を開始すると、利用規約とプライバシーポリシーに
/// 同意したものとみなす旨を表示するウィジェット。
///
/// 「利用規約」「プライバシーポリシー」の文言はそれぞれのページへのリンクになっている。
class _AgreementText extends StatefulWidget {
  const _AgreementText();

  @override
  State<_AgreementText> createState() => _AgreementTextState();
}

class _AgreementTextState extends State<_AgreementText> {
  final _termsOfServiceRecognizer = TapGestureRecognizer();
  final _privacyPolicyRecognizer = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _termsOfServiceRecognizer.onTap = () => _launch(termsOfServiceUrl);
    _privacyPolicyRecognizer.onTap = () => _launch(privacyPolicyUrl);
  }

  @override
  void dispose() {
    _termsOfServiceRecognizer.dispose();
    _privacyPolicyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    );
    final linkStyle = baseStyle?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: '「はじめる」をタップして利用を開始すると、\n'),
          TextSpan(
            text: '利用規約',
            style: linkStyle,
            recognizer: _termsOfServiceRecognizer,
          ),
          const TextSpan(text: 'と'),
          TextSpan(
            text: 'プライバシーポリシー',
            style: linkStyle,
            recognizer: _privacyPolicyRecognizer,
          ),
          const TextSpan(text: 'に同意したものとみなされます。'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Future<void> _launch(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('URLを開けませんでした')));
      }
    }
  }
}
