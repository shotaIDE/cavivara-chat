import 'package:freezed_annotation/freezed_annotation.dart';

part 'function_calling_config.freezed.dart';

/// アプリに実装が固定されている、現在の日時を取得する組み込み関数の名前
const String currentDateTimeFunctionName = 'getCurrentDateTime';

/// アプリに実装が固定されている組み込み関数の名前
///
/// Remote Config で同名の関数を定義しても、組み込みの実装が優先される。
const Set<String> builtInFunctionNames = {currentDateTimeFunctionName};

/// Function Calling の設定
///
/// Remote Config から取得した内容、またはアプリに埋め込んだ組み込みデフォルト設定を表す。
/// 組み込み関数は本設定には含まれず、アプリが常に固定の宣言で提供する。
@freezed
abstract class FunctionCallingToolConfig with _$FunctionCallingToolConfig {
  const factory FunctionCallingToolConfig({
    /// 設定の構造バージョン
    required int schemaVersion,

    /// Function Calling の利用を促すため、システムプロンプトに追記する指示文
    @Default('') String toolInstruction,

    /// モデルに提供するデータ駆動関数の定義
    @Default([]) List<FunctionCallingFunction> functions,
  }) = _FunctionCallingConfig;
}

/// データ駆動関数の定義
///
/// 関数が返す項目一覧（[entries]）を関数ごとに持つことで、
/// 関数を複数に分割した際にそれぞれが独立した項目一覧を参照できる。
@freezed
abstract class FunctionCallingFunction with _$FunctionCallingFunction {
  const factory FunctionCallingFunction({
    /// モデルに提示する関数名
    required String name,

    /// アプリ側の実行処理の種別
    required FunctionCallingHandler handler,

    /// モデルが呼び出しの判断に使う関数の説明
    required String description,

    /// 関数の引数定義
    @Default([]) List<FunctionCallingParameter> parameters,

    /// 関数が返す項目一覧
    @Default([]) List<KnowledgeEntry> entries,
  }) = _FunctionCallingFunction;
}

/// データ駆動関数の実行処理の種別
enum FunctionCallingHandler {
  /// 項目一覧から、トピックIDまたは検索クエリに一致する項目を返す
  knowledgeLookup,
}

/// 関数の引数定義
@freezed
abstract class FunctionCallingParameter with _$FunctionCallingParameter {
  const factory FunctionCallingParameter({
    /// 引数名
    required String name,

    /// 引数の型
    required FunctionCallingParameterType type,

    /// 引数の説明
    required String description,

    /// 必須の引数か否か
    @Default(false) bool isRequired,

    /// 取りうる値の制限
    ///
    /// [FunctionCallingParameterType.string] の場合のみ有効。
    @Default([]) List<String> enumValues,
  }) = _FunctionCallingParameter;
}

/// 関数の引数の型
enum FunctionCallingParameterType {
  string,
  integer,
  number,
  boolean,
  stringArray,
}

/// データ駆動関数が返す項目
@freezed
abstract class KnowledgeEntry with _$KnowledgeEntry {
  const factory KnowledgeEntry({
    /// トピックID
    ///
    /// 同一関数内で一意であればよく、別の関数との重複は許容される。
    required String topic,

    /// トピックの表示名
    required String title,

    /// トピックの要約
    required String summary,

    /// トピックに関する事実のリスト
    required List<String> facts,

    /// 検索クエリとの一致判定に使うキーワード
    @Default([]) List<String> keywords,
  }) = _KnowledgeEntry;

  const KnowledgeEntry._();

  /// 正規化済みの [query] がこの項目のキーワードに一致するかどうかを判定する
  bool matches(String query) {
    final normalizedQuery = query.toLowerCase();
    return keywords
        .map((keyword) => keyword.toLowerCase())
        .any(normalizedQuery.contains);
  }
}
