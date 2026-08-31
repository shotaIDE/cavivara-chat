import 'dart:async';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/feedback_request.dart';
import 'package:house_worker/data/model/send_feedback_exception.dart';
import 'package:house_worker/data/repository/feedback_email_repository.dart';
import 'package:house_worker/data/service/auth_service.dart';
import 'package:house_worker/ui/feature/settings/submit_feedback_presenter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SubmitFeedbackScreen extends ConsumerStatefulWidget {
  const SubmitFeedbackScreen({super.key});

  static const name = 'SubmitFeedbackScreen';

  static MaterialPageRoute<SubmitFeedbackScreen> route() =>
      MaterialPageRoute<SubmitFeedbackScreen>(
        builder: (_) => const SubmitFeedbackScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  ConsumerState<SubmitFeedbackScreen> createState() =>
      _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends ConsumerState<SubmitFeedbackScreen> {
  var _includeUserId = true;

  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _emailController = TextEditingController();
  final _userIdController = TextEditingController();

  /// 保存済みの返信用メールアドレスを復元済みかどうか
  ///
  /// 復元は画面表示時の一度きりとする。保存のたびに復元すると、
  /// 入力中のカーソル位置が末尾に移動してしまうためである。
  var _hasRestoredEmail = false;

  @override
  void initState() {
    super.initState();

    ref.listenManual(
      feedbackEmailRepositoryProvider,
      (previous, next) {
        final email = next.value;
        if (email == null || _hasRestoredEmail) {
          return;
        }

        _hasRestoredEmail = true;
        _emailController.text = email;
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    _userIdController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = ref.watch(isSubmissionAvailableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ご意見・ご要望'),
        actions: [
          TextButton(
            onPressed: isAvailable ? _submitFeedback : null,
            child: Text(isAvailable ? '送信' : '送信中'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16 + MediaQuery.of(context).viewPadding.left,
            right: 16 + MediaQuery.of(context).viewPadding.right,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 24,
              children: [
                _FeedbackField(controller: _feedbackController),
                _EmailField(controller: _emailController),
                _UserIdSection(
                  controller: _userIdController,
                  includeUserId: _includeUserId,
                  onSwitchChanged: (value) {
                    setState(() {
                      _includeUserId = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final feedback = _feedbackController.text.trim();
    final email = _emailController.text.trim();
    final userId = _includeUserId ? _userIdController.text.trim() : null;

    final request = FeedbackRequest(
      body: feedback,
      email: email.isNotEmpty ? email : null,
      userId: userId,
    );

    try {
      await ref
          .read(isSubmissionAvailableProvider.notifier)
          .submitFeedback(request);
    } on SendFeedbackException catch (e) {
      if (!mounted) {
        return;
      }

      switch (e) {
        case SendFeedbackExceptionConnection():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('送信に失敗しました。インターネット接続を確認してください。'),
            ),
          );
          return;

        case SendFeedbackExceptionUncategorized():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('送信に失敗しました。しばらく時間をおいてから再度お試しください。'),
            ),
          );
          return;
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ご意見・ご要望を送信しました。開発者がすぐに内容を確認いたします。'),
      ),
    );

    Navigator.of(context).pop();
  }
}

class _FeedbackField extends ConsumerWidget {
  const _FeedbackField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(isSubmissionAvailableProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          'ご意見、ご要望など',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        TextFormField(
          controller: controller,
          enabled: isAvailable,
          decoration: const InputDecoration(
            hintText: 'お気づきの点やご要望をお聞かせください',
            border: OutlineInputBorder(),
          ),
          maxLines: 6,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'ご意見、ご要望をご入力ください';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _EmailField extends ConsumerWidget {
  const _EmailField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(isSubmissionAvailableProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          '返信用メールアドレス（任意）',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        // クリアボタンの表示・非表示を入力内容に追従させるため、
        // 入力内容の変化を購読して再構築する
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, editingValue, _) {
            final clearButton = IconButton(
              icon: const Icon(Icons.clear),
              tooltip: '返信用メールアドレスを消去',
              onPressed: isAvailable
                  ? () {
                      controller.clear();

                      unawaited(
                        ref
                            .read(feedbackEmailRepositoryProvider.notifier)
                            .clear(),
                      );
                    }
                  : null,
            );

            return TextFormField(
              controller: controller,
              enabled: isAvailable,
              decoration: InputDecoration(
                hintText: 'your.name@example.com',
                border: const OutlineInputBorder(),
                suffixIcon: editingValue.text.isEmpty ? null : clearButton,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                unawaited(
                  ref
                      .read(feedbackEmailRepositoryProvider.notifier)
                      .save(value),
                );
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null;
                }

                if (EmailValidator.validate(value)) {
                  return null;
                }

                return '有効な形式のメールアドレスを入力してください';
              },
            );
          },
        ),
      ],
    );
  }
}

class _UserIdSection extends ConsumerStatefulWidget {
  const _UserIdSection({
    required this.controller,
    required this.includeUserId,
    required this.onSwitchChanged,
  });

  final TextEditingController controller;
  final bool includeUserId;
  final ValueChanged<bool> onSwitchChanged;

  @override
  ConsumerState<_UserIdSection> createState() => _UserIdSectionState();
}

class _UserIdSectionState extends ConsumerState<_UserIdSection> {
  /// ユーザーIDの取得中にスケルトンとして表示する文字列
  static const _placeholderUserId = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxx';

  String _displayUserId = _placeholderUserId;

  @override
  void initState() {
    super.initState();

    // 入力欄への反映はコントローラーの書き換えを伴い、ビルド中には実行できない。
    // そのため取得結果の購読はビルドの外で行う。
    ref.listenManual(
      currentUserProfileProvider,
      (previous, next) {
        _displayUserId = next.hasError
            ? '-'
            : next.value?.id ?? _placeholderUserId;

        _updateDisplayUserId(includeUserId: widget.includeUserId);
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = ref.watch(isSubmissionAvailableProvider);
    // スケルトン表示の解除には再構築が必要なため、購読ではなく監視する。
    // listenManual のコールバックだけでは再構築されず、
    // 取得完了後もシマーが動き続けてしまう。
    final userProfile = ref.watch(currentUserProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ユーザーID',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Switch(
              value: widget.includeUserId,
              onChanged: isAvailable
                  ? (value) {
                      _updateDisplayUserId(includeUserId: value);

                      widget.onSwitchChanged(value);
                    }
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Skeletonizer(
          enabled: userProfile.isLoading,
          child: TextFormField(
            controller: widget.controller,
            enabled: false,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '不具合などのご報告は、ユーザーIDを共有していただくことで対応がスムーズに進むことがあります。',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateDisplayUserId({required bool includeUserId}) {
    if (includeUserId) {
      widget.controller.text = _displayUserId;
      return;
    }

    widget.controller.clear();
  }
}
