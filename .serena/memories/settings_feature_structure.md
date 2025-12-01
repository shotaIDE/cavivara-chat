# Settings Feature Structure Analysis

## File Structure
Location: `/Users/ide/works/cavivara-chat/client/lib/ui/feature/settings/`

Files:
1. `settings_screen.dart` - Main settings screen (534 lines)
2. `section_header.dart` - Reusable section header component
3. `chat_bubble_design_selection_dialog.dart` - Dialog for chat bubble design selection
4. `debug_screen.dart` - Debug screen with development tools

## Settings Screen Organization

The settings screen is organized into 6 sections using `SectionHeader`:

1. **ユーザー情報** (User Information)
   - Displays user profile info (photo, name, email)
   - Different UI for Google, Apple, and Anonymous accounts

2. **表示設定** (Display Settings)
   - Chat bubble design selection (opens dialog)

3. **アプリについて** (About App)
   - Review app (opens store)
   - Share app (uses SharePlus)
   - Terms of service (opens URL)
   - Privacy policy (opens URL)
   - License (shows license page)

4. **デバッグ** (Debug)
   - Debug screen (navigates to another screen)
   - App version display

5. **アカウント管理** (Account Management)
   - Logout (shows confirmation dialog)
   - Delete account (shows confirmation dialog)

## Navigation Patterns

### Pattern 1: Navigation to Sub-Screen
```dart
Widget _buildDebugTile(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.bug_report),
    title: const Text('デバッグ画面'),
    trailing: const _MoveScreenTrailingIcon(),
    onTap: () => Navigator.of(context).push(DebugScreen.route()),
  );
}
```

### Pattern 2: Open URL
```dart
Widget _buildTermsOfServiceTile(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.description),
    title: const Text('利用規約'),
    trailing: const _OpenTrailingIcon(),
    onTap: () async {
      final url = Uri.parse('https://example.com/terms');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // Show error
      }
    },
  );
}
```

### Pattern 3: Share Action
```dart
Widget _buildShareAppTile(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.share),
    title: const Text('友達に教える'),
    onTap: () {
      SharePlus.instance.share(
        ShareParams(
          text: '...',
          title: 'カヴィヴァラチャット',
        ),
      );
    },
  );
}
```

### Pattern 4: Dialog
```dart
// Chat bubble design - shows dialog
onTap: () {
  showDialog<void>(
    context: context,
    builder: (_) => const ChatBubbleDesignSelectionDialog(),
  );
},
```

### Pattern 5: Confirmation Dialog
```dart
void _showLogoutConfirmDialog(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(...),
  );
}
```

## Sub-Screen Pattern (DebugScreen as Template)

All sub-screens follow this pattern:
```dart
class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  static const name = 'DebugScreen';

  static MaterialPageRoute<DebugScreen> route() =>
      MaterialPageRoute<DebugScreen>(
        builder: (_) => const DebugScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('デバッグ')),
      body: ListView(...),
    );
  }
}
```

Note: UpgradeToProScreen also uses `fullscreenDialog: true` for modal presentation.

## Key Components

### SectionHeader Widget
- File: `section_header.dart`
- Displays section titles with:
  - Bold, primary-colored text
  - Dynamic padding based on safe areas
  - Standard 16pt top/bottom spacing

### Trailing Icons
- `_OpenTrailingIcon()` - Icon for external URLs (Icons.open_in_browser)
- `_MoveScreenTrailingIcon()` - Icon for navigation (Icons.arrow_forward_ios, size: 16)

## Architecture Patterns

1. **ConsumerWidget/ConsumerState** - Uses Riverpod for state management
2. **Async Data Handling** - Uses `.when()` pattern for async data
3. **Navigator Pattern** - Standard Flutter Navigator.of(context).push()
4. **Build Method Pattern** - Underscore methods (_build*, _show*) for UI building

## Recommended Location for "💝 カヴィヴァラを応援" Menu Item

Best location: After "アプリについて" section and before "デバッグ" section

Rationale:
- Donation is not user-specific (different from ユーザー情報)
- Donation is not a display preference (different from 表示設定)
- Donation is app-related content (fits 「アプリについて」category)
- Placing it before デバッグ keeps debug section at bottom (typically developer-only)
- Logical flow: App info → Support/Donation → Debug → Account

Alternative: Could be a separate "サポート" (Support) section between "アプリについて" and "デバッグ"
