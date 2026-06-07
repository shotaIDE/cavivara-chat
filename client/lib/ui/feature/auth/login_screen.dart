import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/ui/component/cavivara_avatar.dart';
import 'package:house_worker/ui/feature/auth/login_presenter.dart';
import 'package:house_worker/ui/feature/home/home_screen.dart';

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
    ];

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
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
