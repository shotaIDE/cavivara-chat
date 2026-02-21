import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/repository/resume_viewing_duration_repository.dart';
import 'package:house_worker/data/service/cavivara_directory_service.dart';
import 'package:house_worker/ui/component/cavivara_avatar.dart';
import 'package:house_worker/ui/feature/home/home_screen.dart';

class ResumeScreen extends ConsumerStatefulWidget {
  const ResumeScreen({super.key, required this.cavivaraId});

  /// 表示対象のカヴィヴァラID
  final String cavivaraId;

  static const name = 'ResumeScreen';

  static MaterialPageRoute<ResumeScreen> route(String cavivaraId) =>
      MaterialPageRoute<ResumeScreen>(
        builder: (_) => ResumeScreen(cavivaraId: cavivaraId),
        settings: const RouteSettings(name: name),
      );

  @override
  ConsumerState<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends ConsumerState<ResumeScreen> {
  late final Stopwatch _viewStopwatch;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _viewStopwatch = Stopwatch()..start();
    _startDurationTimer();
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_viewStopwatch.isRunning) {
        final elapsed = _viewStopwatch.elapsed;
        _viewStopwatch
          ..reset()
          ..start();

        if (elapsed > Duration.zero) {
          ref
              .read(resumeViewingDurationRepositoryProvider.notifier)
              .add(elapsed);
        }
      }
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _viewStopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cavivaraProfile = ref.watch(cavivaraByIdProvider(widget.cavivaraId));

    Widget sectionTitle(String text) {
      return Text(
        text,
        style: theme.textTheme.titleLarge,
      );
    }

    Widget bulletList(List<String> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${cavivaraProfile.displayName}の履歴書'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                left: 16 + MediaQuery.of(context).viewPadding.left,
                right: 16 + MediaQuery.of(context).viewPadding.right,
                top: 16,
                bottom: 16,
              ),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CavivaraAvatar(
                              size: 96,
                              assetPath: cavivaraProfile.iconPath,
                              cavivaraId: widget.cavivaraId,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cavivaraProfile.displayName,
                                    style: theme.textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cavivaraProfile.title,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    cavivaraProfile.description,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in cavivaraProfile.tags)
                              Chip(label: Text(tag)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // 履歴書セクションを動的に生成
                for (final section in cavivaraProfile.resumeSections) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionTitle(section.title),
                          const SizedBox(height: 12),
                          bulletList(section.items),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 画面下部に固定表示される会議ボタン
          Container(
            color: theme.colorScheme.surface,
            padding: EdgeInsets.only(
              left: 16 + MediaQuery.of(context).viewPadding.left,
              right: 16 + MediaQuery.of(context).viewPadding.right,
              top: 16,
              bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
            ),
            child: OutlinedButton.icon(
              onPressed: _navigateToChat,
              icon: const Icon(Icons.chat),
              label: const Text('会議する'),
            ),
          ),
        ],
      ),
    );
  }

  /// チャット画面に遷移
  void _navigateToChat() {
    Navigator.of(context).pushAndRemoveUntil(
      HomeScreen.route(widget.cavivaraId),
      (route) => false,
    );
  }
}
