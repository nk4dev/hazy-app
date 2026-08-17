import 'package:flutter/widgets.dart';

import 'app_locale_provider.dart';

/// UI chrome strings (screen titles, buttons, labels) for the app's own
/// interface — not backend content. Backend data (item titles, error
/// messages, etc) always renders as returned by the API, per
/// docs/backend-api-contract.md; only this static UI copy is localized.
///
/// Accessed via [AppStrings.of], provided by [AppStringsScope] near the
/// app root so any widget — including plain [StatelessWidget]s that don't
/// hold a Riverpod [WidgetRef] — can read it without extra plumbing.
abstract class AppStrings {
  const AppStrings();

  static AppStrings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AppStringsScope>();
    assert(scope != null, 'No AppStringsScope found in context');
    return scope!.strings;
  }

  /// For `package:intl`'s `DateFormat(pattern, localeCode)`.
  String get localeCode;

  // Common
  String get cancel;
  String get save;
  String get delete;
  String get create;
  String get retry;

  // Bottom navigation
  String get navLibrary;
  String get navReadLater;
  String get navSearch;
  String get navAsk;
  String get navSettings;

  // Library
  String get libraryTitle;
  String get sortNewest;
  String get sortOldest;
  String get deleteItemConfirmTitle;
  String get emptyLibraryTitle;
  String get emptyLibrarySubtitle;
  String get saveALink;
  String get enterValidUrl;

  // Add to collection
  String get addToCollectionTitle;
  String get noCollectionsYetShort;
  String get couldNotLoadCollections;
  String addedTo(String collectionName);

  // Item detail
  String get itemAppBarTitle;
  String get editDialogTitle;
  String get titleFieldPlaceholder;
  String get summaryFieldPlaceholder;
  String get descriptionLabel;
  String get summaryLabel;
  String get noSummaryYet;
  String get generate;
  String get regenerate;
  String get editTitleSummary;
  String get aiSummaryUnavailable;
  String get failedToFetchPage;
  String minRead(int minutes);

  // Settings
  String get settingsTitle;
  String get signedInFallback;
  String get appearanceSection;
  String get followSystem;
  String get light;
  String get dark;
  String get languageSection;
  String get answerInSourceLanguage;
  String get answerInSourceLanguageSubtitle;
  String get notificationsSection;
  String get readLaterDigest;
  String get weeklyStats;
  String get notYetSent;
  String get signOut;

  // Read later
  String get readLaterTitle;
  String get markAsRead;
  String get archive;
  String get backToInbox;
  String get couldNotUpdateItem;
  String todaysThree(int minutes);
  String get fiveMinuteReads;
  String get sitDownReads;
  String get emptyReadLaterTitle;
  String get emptyReadLaterSubtitle;
  String statsLine(int read, int saved);

  // Search
  String get searchPlaceholder;
  String get searchLibraryTitle;
  String get searchLibrarySubtitle;
  String get noResults;

  // Ask
  String get askTitle;
  String get newQuestion;
  String get askAnything;
  String get askSubtitle;
  String get newQuestionTitle;
  String get languageDefault;
  String get askAQuestionAboutSavedLinks;
  String get thinking;
  String get askQuestionPlaceholder;
  String get aiUnavailableFallback;
  String get sources;

  // Collections
  String get collectionsTitle;
  String get newCollection;
  String get nameFieldPlaceholder;
  String get emptyCollectionsTitle;
  String get emptyCollectionsSubtitle;
  String get collectionFallbackTitle;
  String get emptyCollectionItemsTitle;
  String get emptyCollectionItemsSubtitle;
  String itemsCount(int n);

  // Share intake
  String get saveToHazy;
  String get urlLabel;

  // Sign in
  String get signInToHazy;

  // Error view
  String get aiKeyNotConfigured;
  String get sessionExpired;
  String get itemNotFound;
  String get somethingWentWrong;

  // Splash / connection trouble
  String get connectionTroubleTitle;
  String get connectionTroubleSubtitle;
}

class EnStrings extends AppStrings {
  const EnStrings();

  @override
  String get localeCode => 'en';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get create => 'Create';
  @override
  String get retry => 'Retry';

  @override
  String get navLibrary => 'Library';
  @override
  String get navReadLater => 'Read later';
  @override
  String get navSearch => 'Search';
  @override
  String get navAsk => 'Ask';
  @override
  String get navSettings => 'Settings';

  @override
  String get libraryTitle => 'Library';
  @override
  String get sortNewest => 'Newest first';
  @override
  String get sortOldest => 'Oldest first';
  @override
  String get deleteItemConfirmTitle => 'Delete this item?';
  @override
  String get emptyLibraryTitle => 'Nothing saved yet';
  @override
  String get emptyLibrarySubtitle => 'Tap + to save your first link.';
  @override
  String get saveALink => 'Save a link';
  @override
  String get enterValidUrl => 'Enter a valid URL';

  @override
  String get addToCollectionTitle => 'Add to collection';
  @override
  String get noCollectionsYetShort =>
      'No collections yet. Create one from the Library tab.';
  @override
  String get couldNotLoadCollections => 'Could not load collections.';
  @override
  String addedTo(String collectionName) => 'Added to $collectionName';

  @override
  String get itemAppBarTitle => 'Item';
  @override
  String get editDialogTitle => 'Edit';
  @override
  String get titleFieldPlaceholder => 'Title';
  @override
  String get summaryFieldPlaceholder => 'Summary';
  @override
  String get descriptionLabel => 'Description';
  @override
  String get summaryLabel => 'Summary';
  @override
  String get noSummaryYet => 'No summary yet.';
  @override
  String get generate => 'Generate';
  @override
  String get regenerate => 'Regenerate';
  @override
  String get editTitleSummary => 'Edit title / summary';
  @override
  String get aiSummaryUnavailable => "AI summaries aren't available right now.";
  @override
  String get failedToFetchPage => 'Failed to fetch this page.';
  @override
  String minRead(int minutes) => '$minutes min read';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get signedInFallback => 'Signed in';
  @override
  String get appearanceSection => 'Appearance';
  @override
  String get followSystem => 'Follow system';
  @override
  String get light => 'Light';
  @override
  String get dark => 'Dark';
  @override
  String get languageSection => 'Language';
  @override
  String get answerInSourceLanguage => "Answer in the source page's language";
  @override
  String get answerInSourceLanguageSubtitle =>
      'Otherwise Ask answers in your interface language.';
  @override
  String get notificationsSection => 'Notifications';
  @override
  String get readLaterDigest => 'Read-later digest';
  @override
  String get weeklyStats => 'Weekly stats';
  @override
  String get notYetSent => 'Not yet sent — no push notifications configured.';
  @override
  String get signOut => 'Sign out';

  @override
  String get readLaterTitle => 'Read later';
  @override
  String get markAsRead => 'Mark as read';
  @override
  String get archive => 'Archive';
  @override
  String get backToInbox => 'Back to inbox';
  @override
  String get couldNotUpdateItem => 'Could not update this item.';
  @override
  String todaysThree(int minutes) => "Today's 3 (~$minutes min)";
  @override
  String get fiveMinuteReads => '5-minute reads';
  @override
  String get sitDownReads => 'Sit-down reads';
  @override
  String get emptyReadLaterTitle => 'Your read-later queue is empty';
  @override
  String get emptyReadLaterSubtitle => 'Saved items in your inbox show up here.';
  @override
  String statsLine(int read, int saved) => '$read read · $saved saved this week';

  @override
  String get searchPlaceholder => 'Search your saved items';
  @override
  String get searchLibraryTitle => 'Search your library';
  @override
  String get searchLibrarySubtitle =>
      "Full-text search across everything you've saved.";
  @override
  String get noResults => 'No results';

  @override
  String get askTitle => 'Ask';
  @override
  String get newQuestion => 'New question';
  @override
  String get askAnything => 'Ask Hazy anything';
  @override
  String get askSubtitle => 'Answers cite your own saved pages.';
  @override
  String get newQuestionTitle => 'New question';
  @override
  String get languageDefault => 'Default';
  @override
  String get askAQuestionAboutSavedLinks => 'Ask a question about your saved links.';
  @override
  String get thinking => 'Thinking through your saved links…';
  @override
  String get askQuestionPlaceholder => 'Ask a question…';
  @override
  String get aiUnavailableFallback =>
      'AI unavailable — showing a plain keyword match instead.';
  @override
  String get sources => 'Sources';

  @override
  String get collectionsTitle => 'Collections';
  @override
  String get newCollection => 'New collection';
  @override
  String get nameFieldPlaceholder => 'Name';
  @override
  String get emptyCollectionsTitle => 'No collections yet';
  @override
  String get emptyCollectionsSubtitle => 'Group related saved links together.';
  @override
  String get collectionFallbackTitle => 'Collection';
  @override
  String get emptyCollectionItemsTitle => 'No items in this collection yet';
  @override
  String get emptyCollectionItemsSubtitle =>
      "Add items from any saved link's detail screen.";
  @override
  String itemsCount(int n) => '$n items';

  @override
  String get saveToHazy => 'Save to Hazy';
  @override
  String get urlLabel => 'URL';

  @override
  String get signInToHazy => 'Sign in to Hazy';

  @override
  String get aiKeyNotConfigured =>
      'This feature needs an AI key configured on the server. Please try again later.';
  @override
  String get sessionExpired => 'Your session expired. Please sign in again.';
  @override
  String get itemNotFound => "This item couldn't be found.";
  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get connectionTroubleTitle => "Can't connect right now";
  @override
  String get connectionTroubleSubtitle =>
      "We're having trouble reaching Hazy. Check your connection and try again.";
}

class JaStrings extends AppStrings {
  const JaStrings();

  @override
  String get localeCode => 'ja';
  @override
  String get cancel => 'キャンセル';
  @override
  String get save => '保存';
  @override
  String get delete => '削除';
  @override
  String get create => '作成';
  @override
  String get retry => '再試行';

  @override
  String get navLibrary => 'ライブラリ';
  @override
  String get navReadLater => 'あとで読む';
  @override
  String get navSearch => '検索';
  @override
  String get navAsk => '質問';
  @override
  String get navSettings => '設定';

  @override
  String get libraryTitle => 'ライブラリ';
  @override
  String get sortNewest => '新しい順';
  @override
  String get sortOldest => '古い順';
  @override
  String get deleteItemConfirmTitle => 'このアイテムを削除しますか?';
  @override
  String get emptyLibraryTitle => 'まだ何も保存されていません';
  @override
  String get emptyLibrarySubtitle => '＋をタップして最初のリンクを保存しましょう。';
  @override
  String get saveALink => 'リンクを保存';
  @override
  String get enterValidUrl => '有効なURLを入力してください';

  @override
  String get addToCollectionTitle => 'コレクションに追加';
  @override
  String get noCollectionsYetShort =>
      'コレクションがまだありません。ライブラリタブから作成してください。';
  @override
  String get couldNotLoadCollections => 'コレクションを読み込めませんでした。';
  @override
  String addedTo(String collectionName) => '$collectionNameに追加しました';

  @override
  String get itemAppBarTitle => 'アイテム';
  @override
  String get editDialogTitle => '編集';
  @override
  String get titleFieldPlaceholder => 'タイトル';
  @override
  String get summaryFieldPlaceholder => '概要';
  @override
  String get descriptionLabel => '説明';
  @override
  String get summaryLabel => '概要';
  @override
  String get noSummaryYet => 'まだ概要はありません。';
  @override
  String get generate => '生成';
  @override
  String get regenerate => '再生成';
  @override
  String get editTitleSummary => 'タイトル・概要を編集';
  @override
  String get aiSummaryUnavailable => '現在AIによる要約は利用できません。';
  @override
  String get failedToFetchPage => 'このページの取得に失敗しました。';
  @override
  String minRead(int minutes) => '$minutes分で読める';

  @override
  String get settingsTitle => '設定';
  @override
  String get signedInFallback => 'サインイン済み';
  @override
  String get appearanceSection => '外観';
  @override
  String get followSystem => 'システムに従う';
  @override
  String get light => 'ライト';
  @override
  String get dark => 'ダーク';
  @override
  String get languageSection => '言語';
  @override
  String get answerInSourceLanguage => '元のページの言語で回答する';
  @override
  String get answerInSourceLanguageSubtitle =>
      'オフの場合、Askはインターフェース言語で回答します。';
  @override
  String get notificationsSection => '通知';
  @override
  String get readLaterDigest => 'あとで読むダイジェスト';
  @override
  String get weeklyStats => '週間統計';
  @override
  String get notYetSent => 'まだ送信されていません — プッシュ通知は未設定です。';
  @override
  String get signOut => 'サインアウト';

  @override
  String get readLaterTitle => 'あとで読む';
  @override
  String get markAsRead => '既読にする';
  @override
  String get archive => 'アーカイブ';
  @override
  String get backToInbox => '受信箱に戻す';
  @override
  String get couldNotUpdateItem => 'このアイテムを更新できませんでした。';
  @override
  String todaysThree(int minutes) => '今日の3件(約$minutes分)';
  @override
  String get fiveMinuteReads => '5分で読める記事';
  @override
  String get sitDownReads => 'じっくり読む記事';
  @override
  String get emptyReadLaterTitle => 'あとで読むキューは空です';
  @override
  String get emptyReadLaterSubtitle => '受信箱に保存されたアイテムがここに表示されます。';
  @override
  String statsLine(int read, int saved) => '今週 $read件既読・$saved件保存';

  @override
  String get searchPlaceholder => '保存したアイテムを検索';
  @override
  String get searchLibraryTitle => 'ライブラリを検索';
  @override
  String get searchLibrarySubtitle => '保存したすべてのアイテムを全文検索します。';
  @override
  String get noResults => '検索結果がありません';

  @override
  String get askTitle => '質問';
  @override
  String get newQuestion => '新しい質問';
  @override
  String get askAnything => 'Hazyに何でも質問しよう';
  @override
  String get askSubtitle => '回答はあなたの保存済みページを引用します。';
  @override
  String get newQuestionTitle => '新しい質問';
  @override
  String get languageDefault => 'デフォルト';
  @override
  String get askAQuestionAboutSavedLinks => '保存したリンクについて質問してみましょう。';
  @override
  String get thinking => '保存したリンクを調べています…';
  @override
  String get askQuestionPlaceholder => '質問を入力…';
  @override
  String get aiUnavailableFallback =>
      'AIが利用できないため、キーワード一致による結果を表示しています。';
  @override
  String get sources => '情報源';

  @override
  String get collectionsTitle => 'コレクション';
  @override
  String get newCollection => '新しいコレクション';
  @override
  String get nameFieldPlaceholder => '名前';
  @override
  String get emptyCollectionsTitle => 'コレクションがまだありません';
  @override
  String get emptyCollectionsSubtitle => '関連するリンクをまとめましょう。';
  @override
  String get collectionFallbackTitle => 'コレクション';
  @override
  String get emptyCollectionItemsTitle => 'このコレクションにはまだアイテムがありません';
  @override
  String get emptyCollectionItemsSubtitle =>
      '保存済みアイテムの詳細画面から追加できます。';
  @override
  String itemsCount(int n) => '$n件';

  @override
  String get saveToHazy => 'Hazyに保存';
  @override
  String get urlLabel => 'URL';

  @override
  String get signInToHazy => 'Hazyにサインイン';

  @override
  String get aiKeyNotConfigured =>
      'この機能を使うにはサーバー側でAIキーの設定が必要です。後でもう一度お試しください。';
  @override
  String get sessionExpired => 'セッションの有効期限が切れました。再度サインインしてください。';
  @override
  String get itemNotFound => 'このアイテムが見つかりませんでした。';
  @override
  String get somethingWentWrong => '問題が発生しました。もう一度お試しください。';

  @override
  String get connectionTroubleTitle => '接続できません';
  @override
  String get connectionTroubleSubtitle =>
      'Hazyへの接続に問題が発生しています。ネットワーク接続を確認してもう一度お試しください。';
}

class AppStringsScope extends StatelessWidget {
  const AppStringsScope({super.key, required this.locale, required this.child});

  final AppLocale locale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _AppStringsScope(
      strings: locale == AppLocale.ja ? const JaStrings() : const EnStrings(),
      child: child,
    );
  }
}

class _AppStringsScope extends InheritedWidget {
  const _AppStringsScope({required this.strings, required super.child});

  final AppStrings strings;

  @override
  bool updateShouldNotify(_AppStringsScope oldWidget) =>
      oldWidget.strings.runtimeType != strings.runtimeType;
}
