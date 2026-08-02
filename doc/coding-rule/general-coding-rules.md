# Development guide

## General rules

### Style

Always use early returns to reduce nesting.

Use `try`-`catch` statements to enclose only processes that may throw, and in the smallest possible scope.

Example:

```dart
// Define the return value of a process that may throw an exception even outside the scope of try-catch, so that it is used first.
final CustomerInfo customerInfo;
try {
// Process that may throw an exception
  customerInfo = await Purchases.purchasePackage(product.package);
} catch (e) {
  throw PurchaseException();
}

// Subsequent process
return customerInfo.entitlements;
```

If you do not use a function argument, explicitly indicate that it is unused by naming it `_`.

Example:

```dart
onTap: (_) { // If you do not use an argument, explicitly state that it is unused as "_"
// ...
},
```

Immediately delete unused code.

### Maintain code consistency

Implement processes with similar functions in the same flow. Check whether a similar process has already been implemented in the surrounding area, and follow it if it has been implemented.

- In particular, standardize the flow of data acquisition, conversion, and filtering.

### Maintain sufficient comments

If you add code comments, finally check their sufficiency from the following perspective. If they are excessive or insufficient, delete or add them.

- Add comments only when necessary to clarify the intent or purpose of the code. Avoid comments if the content of the code is clear.
- Describe in detail any particularly important points to note or pitfalls, including the reasons for them.
- Comments should be written in Japanese.

### Maintain readability of naming

Name variables to clearly indicate their purpose and content.

Use meaningful names even for temporary variables.

Use consistent naming patterns for variables that handle the same type of data.

### Write prompts for the AI model in English

Write text that is sent to the AI model as input in English, because English conveys the same instruction with fewer tokens than Japanese. This applies to system prompts, instructions for Function Calling, descriptions of function declarations and response schemas, and messages returned to the model as a function result.

Keep the following in Japanese, because they lose their meaning when translated:

- Text the model outputs as is, such as sentence endings, expressions it must not use, and proper nouns
- Knowledge data the model speaks back to the user, and keywords matched against Japanese user input

Because the output to the user must be Japanese, state in the system prompt that the model always answers in Japanese.

When you change a prompt, also update its Japanese translation in [doc/design/ai-prompt-language.md](/doc/design/ai-prompt-language.md).

## Rules for Flutter

### Defining a Class

When implementing a class, use the `const` constructor whenever you can make the class immutable.

### Defining the domain model

Clearly separate the domain model and place it in the appropriate file.

Define an immutable domain model using `freezed`. Use `freezed` even when using `sealed class`.

### Utilize functional programming

Use functional methods for collection operations.

- Example: `map`, `where`, `fold`, `expand`

Divide complex data transformations into multiple steps to improve readability.

When converting a collection, use a process that returns a new converted collection.

- Example: `sortedBy` in the `collection` package.

### Use `Riverpod` appropriately for state management

Use `Riverpod` for state management.

The provider is Define using code generation using the `@riverpod` annotation.

When dealing with multiple asynchronous providers, `watch` all providers first and then `await` them later to prevent state resets.

Example:

```dart
@riverpod
Future<String> currentUser(Ref ref) async {
  final data1Future = ref.watch(provider1.future);
  final data2Future = ref.watch(provider2.future);

  final data1 = await data1Future;
  final data2 = await data2Future;

  // subsequent process
}
```

### Handle errors properly

Catch asynchronous processing errors properly and notify the user.

Instead of returning a Boolean value or a generic exception, use a custom exception class to represent a specific error condition. If you don't need detailed error information, define a simple exception class that has no member variables.

Example:

```dart
// Definition
class DeleteWorkLogException implements Exception {
  const DeleteWorkLogException();
}

// Usage
throw const DeleteWorkLogException();
```

### Build UI properly

Manage the visibility of UI elements with a dedicated state management class.

- Example: `HouseWorkVisibilities`

Implement state change logic in the presenter.

Filter data based on visibility in the provider.

Use `SingleChildScrollView` to make content scrollable if there is a possibility of a large amount of content.

Add padding that takes into account the device's safe area.

- Example: `EdgeInsets.only(left: 16 + MediaQuery.of(context).viewPadding.left, ...)`

Split widgets into classes to improve readability.

Example:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(),
        _Content(),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Header');
  }
}

class _Content extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Content');
  }
}
```

Separate the process into two steps: storing the widget in a local variable → assembling with margins.

Example:

```dart
Widget build(BuildContext context) {
  // Storing the widget in a local variable
  const firstText = Text('1st');
  const secondText = Text('2nd');

  // Assembling with margins
  return Column(
    children: const [
      firstText,
      Padding(
        padding: EdgeInsets.only(top: 16),
        child: secondText,
      ),
    ],
  );
}
```

Use the colors defined in the theme.

- Example: `Theme.of(context).colorScheme.primary`.

Use the text style defined in the text theme.

- Example: `Theme.of(context).textTheme.headline6`.

Add tooltips to areas where users can operate, and consider accessibility.

The strings to display in the UI are defined during the widget construction process.

### Screen navigation

Define `MaterialPageRoute` in a static field for the screen, and use the static field and `Navigator` when transitioning to that screen.

Example:

```dart
class SomeScreen extends StatelessWidget {
  const SomeScreen({super.key});

  static const name = 'AnalysisScreen';

  static MaterialPageRoute<SomeScreen> route() =>
      MaterialPageRoute<SomeScreen>(
        builder: (_) => const SomeScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  Widget build(BuildContext context) {
    // Screen build process
  }
}

// When transitioning
Navigator.of(context).push(SomeScreen.route);
```

### Unit testing

- Use `mocktail` for mocks.
- If you want to use the same dummy constants between test cases, define them at the beginning of the `group` function, the beginning of the `main` function, or in the `setUp` function to make them common.

### Operation

- Implement a process to send a report via Crashlytics if an exception or error that was not anticipated during implementation occurs at runtime.

## Troubleshooting

### Policy

When troubleshooting, adopt solutions in the following order of priority:

1. Apply solutions according to official documentation and guidelines
2. If a future response is planned in an official issue, wait for that response
3. Apply solutions indicated in the official issue
4. Apply solutions indicated in communities such as Stack Overflow
