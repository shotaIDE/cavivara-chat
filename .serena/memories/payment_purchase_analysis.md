# Payment/Purchase Infrastructure Analysis

## Current Payment Implementation Status

### Existing Infrastructure

#### 1. **Pro Upgrade Feature** (Partially Implemented)
- **Location**: `client/lib/ui/feature/pro/upgrade_to_pro_screen.dart`
- **Service**: `client/lib/data/service/purchase_pro_result.dart`
- **Exception**: `client/lib/data/model/purchase_exception.dart`

**Status**: Skeleton implementation with TODO markers
- The `purchasePro()` method contains a TODO comment: "TODO(ide): RevenueCatを使用して課金処理を実行"
- Currently no actual payment integration (returns true hardcoded)
- Basic UI showing Pro features and pricing (¥980 one-time purchase)
- Uses Riverpod for state management

#### 2. **In-App Purchase Package**
- **Status**: NOT currently in pubspec.yaml
- The donation design document specifies using `in_app_purchase` package
- Current pubspec.yaml contains: in_app_review, but NOT in_app_purchase

#### 3. **RevenueCat Integration Plan**
- The Pro feature indicates plans to use RevenueCat (legacy approach in comments)
- The donation design document recommends direct in_app_purchase package instead

### Models and Data Structures

#### AppSession Model
**Location**: `client/lib/data/model/app_session.dart`

```dart
@freezed
sealed class AppSession with _$AppSession {
  factory AppSession.signedIn({required bool isPro}) = AppSessionSignedIn;
  factory AppSession.notSignedIn() = AppSessionNotSignedIn;
}
```
- Tracks Pro status at app session level
- Used by root_presenter.dart

#### Purchase Exception
**Location**: `client/lib/data/model/purchase_exception.dart`
- Minimal exception class for purchase errors
- Should be expanded for more specific error handling

### Service Layer Pattern

#### Root Presenter (State Management)
**Location**: `client/lib/ui/root_presenter.dart`

Key patterns:
- Uses `@riverpod` for state management with code generation
- `CurrentAppSession` provider manages app session state
- Has `upgradeToPro()` method that updates isPro to true
- `unwrappedCurrentAppSession` provider provides unwrapped access

```dart
Future<void> upgradeToPro() async {
  final currentAppSession = state.value;
  if (currentAppSession case AppSessionSignedIn()) {
    final newState = currentAppSession.copyWith(isPro: true);
    state = AsyncValue.data(newState);
  }
}
```

### Preference Storage Pattern

#### PreferenceService
**Location**: `client/lib/data/service/preference_service.dart`

- Uses SharedPreferencesAsync for all preference access
- Methods: getBool, setBool, getString, setString, getInt, setInt, getStringList, setStringList
- All keyed by PreferenceKey enum

#### PreferenceKey Enum
**Location**: `client/lib/data/model/preference_key.dart`

Current keys:
```dart
enum PreferenceKey {
  employedCavivaraIds,
  lastTalkedCavivaraId,
  skipClearChatConfirmation,
  totalSentChatStringCount,
  totalReceivedChatStringCount,
  resumeViewingMilliseconds,
  hasEarnedPartTimerReward,
  hasEarnedPartTimeLeaderReward,
  chatBubbleDesign,
}
```

### Repository Pattern Example

**Location**: `client/lib/data/repository/last_talked_cavivara_id_repository.dart`

Pattern used for all repositories:
```dart
@riverpod
class LastTalkedCavivaraId extends _$LastTalkedCavivaraId {
  @override
  Future<String?> build() {
    final preferenceService = ref.read(preferenceServiceProvider);
    return preferenceService.getString(PreferenceKey.lastTalkedCavivaraId);
  }

  Future<void> updateId(String cavivaraId) async {
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setString(PreferenceKey.lastTalkedCavivaraId, value: cavivaraId);
    state = AsyncValue.data(cavivaraId);
  }
}
```

Key characteristics:
- Uses @riverpod code generation
- Extends _$ClassName generated class
- build() method returns Future of data type
- Async read/write methods update state
- Ref.read for dependencies
- State management via AsyncValue.data()

### Settings Screen UI Pattern

**Location**: `client/lib/ui/feature/settings/settings_screen.dart`

Structure:
- Organized by sections with SectionHeader
- ListTile for menu items with leading icon, title, subtitle, trailing icon
- ConsumerStatefulWidget for Riverpod integration
- Error handling with .when() on async providers
- Skeletonizer for loading states

Example pattern:
```dart
ListTile(
  leading: const Icon(Icons.star),
  title: const Text('アプリをレビューする'),
  trailing: const _OpenTrailingIcon(),
  onTap: () => // action
)
```

## Recommended Patterns for Donation Feature

### 1. Riverpod Code Generation
- Use @riverpod annotation for all providers
- Use ref.watch for state observation, ref.read for one-time access
- Return Future<T> from build() methods for async operations

### 2. Custom Exception Pattern
- Create specific exception classes for different error scenarios
- Implement Exception interface
- No complex error state, keep simple for clarity

### 3. Repository Layer
- One repository per domain concern
- All use Riverpod @riverpod pattern
- Use PreferenceService for SharedPreferences access
- Update state via AsyncValue.data() after mutations

### 4. UI Components
- Extract sub-widgets into private classes (_WidgetName)
- Use ListTile for settings menu items
- Handle loading/error states with .when()
- Use Skeletonizer for loading placeholders

### 5. Screen Navigation
- Define static route() method in screen class
- Use MaterialPageRoute with RouteSettings
- Push with Navigator.of(context).push(ScreenName.route())

## Coding Standards (from doc/coding-rule/)

### General Rules
- Use early returns to reduce nesting
- Wrap only the smallest necessary scope in try-catch
- Use meaningful variable names even for temporary variables
- Use const constructors when possible for immutability

### Flutter/Dart Rules
- Use Freezed for domain models
- Use functional methods (map, where, fold) for collections
- Watch all async providers first, then await later
- Use custom exception classes instead of generic exceptions
- Split widgets into classes for readability

### Testing
- Use mocktail for mocks
- Define common dummy constants in setUp or group start
- Write unit tests for repositories and services
- Write widget tests for UI components

## Design Patterns in Codebase

### State Management
- AsyncValue for async operation states
- Ref.watch for reactive updates
- Ref.read for one-time access
- Provider dependencies automatically tracked

### Error Handling
- Custom exception classes (implement Exception)
- Catch specific exception types in UI
- Show SnackBar for user-facing errors
- Log unexpected errors to Crashlytics

### Data Flow
- UI (Screen) → Repository → Service → Preference/Data
- State updates bubble up via Riverpod
- Changes in dependencies automatically trigger dependent updates

## Key Files to Reference

1. **Pro Feature UI**: `client/lib/ui/feature/pro/upgrade_to_pro_screen.dart`
2. **Root Session Management**: `client/lib/ui/root_presenter.dart`
3. **Repository Example**: `client/lib/data/repository/last_talked_cavivara_id_repository.dart`
4. **Settings Screen**: `client/lib/ui/feature/settings/settings_screen.dart`
5. **Preference Service**: `client/lib/data/service/preference_service.dart`
6. **Design Document**: `doc/design/support-cavivara-donation.md`
7. **Coding Standards**: `doc/coding-rule/general-coding-rules.md`
