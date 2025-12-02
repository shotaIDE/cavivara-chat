import 'package:flutter/material.dart';

class SupportCavivaraScreen extends StatelessWidget {
  const SupportCavivaraScreen({super.key});

  static const name = 'SupportCavivaraScreen';

  static MaterialPageRoute<SupportCavivaraScreen> route() =>
      MaterialPageRoute<SupportCavivaraScreen>(
        builder: (_) => const SupportCavivaraScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カヴィヴァラを応援'),
      ),
      body: const Placeholder(
        color: Colors.grey,
      ),
    );
  }
}
