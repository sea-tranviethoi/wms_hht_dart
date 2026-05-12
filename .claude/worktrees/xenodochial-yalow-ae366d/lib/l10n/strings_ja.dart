class StringsJa {
  const StringsJa();

  // Common
  String get menuTitle => 'メニュー';
  String get filter => 'フィルター';
  String get reset => 'リセット';
  String get search => '検索';
  String get noData => 'データがありません';
  String get confirm => '確認';
  String get yes => 'はい';
  String get no => 'いいえ';
  String get back => '戻る';
  String get clear => 'クリア';
  String get apply => '適用';
  String get cancel => 'キャンセル';
  String get save => '保存';
  String get complete => '完了';
  String get sync => '送信';
  String get close => '閉じる';

  // Menu
  List<String> get menuItems => [
    '1. 入荷',
    '2. 棚上げ',
    '3. ピッキング',
    '4. 事前セット',
    '5. 棚移動',
    '6. 棚卸',
    '7. ログアウト',
  ];

  // Tenant Selection
  String get tenantSelectionTitle => 'テナント選択';
  String get tenantLoadFailed => 'テナントの読み込みに失敗しました。';
  String get retry => '再試行';
  String get tenantSearchHint => 'テナントをフィルターする';

  // Auth
  String get loginTitle => 'ログイン';
  String get userName => 'ユーザー名';
  String get password => 'パスワード';
  String get loginButton => 'ログイン';
  String get qrLogin => 'QRコードスキャン';
  String get loginHint => 'ユーザー/パスワード入力、またはQRコードでログイン';
  String get loginFailed => 'ログインに失敗しました。';
  String get loginNoInternet => 'インターネット接続無し';
  String get loginWrongCredential => 'ユーザー名 または パスワードが正しくありません。';
  String get loginServerIssue => 'WMSに問題が発生してるため、WMSサーバに接続できません';
  String get qrInvalid => 'ユーザーとパスワードを入力してください';

  // Receipt List
  String get receiptListTitle => '入荷一覧';
  String get receiptNo => '入荷番号';
  String get supplierName => '仕入先名';
  String get searchHint => 'フィルターする内容を入力してください。';
  String get advancedSearch => '詳細検索';
  String get receiptSyncNone => 'データ同期なし';
  String get receiptSyncConfirm => 'をWMSに同期しますか？';
  String get receiptSynced => 'データは正常に同期されました';
  String get receiptSyncFailed => '同期に失敗しました';
  String get receiptResetConfirm => 'の対応中のデータをリセットしますか?';
  String get receiptResetDone => 'リセットしました';
  String get handledByOther => '別デバイスで対応中です。ご確認ください。';
  String get listEmpty => 'データがありません';

  // Receipt Detail
  String get receiptDetailTitle => '入荷詳細';
  String get basicInfo => '基本情報';
  String get date => '日付';
  String get items => 'アイテム一覧';
  String get add => '追加';
  String get images => '画像';
  String get imageLabel => '商品画像';
  String get status => 'ステータス';
  String get statusOk => 'OK';
  String get statusNg => 'NG';
  String get statusShort => '不足';
  String get actualQtyRequired => '実際数量を入力してください';
  String get saved => '保存しました';
  String get completeConfirm => '入荷を完了しますか？';

  // Receipt Filter
  String get filterTitle => '詳細検索';
  String get filterHint => 'フィルター条件を入力してください';
  String get vendorCode => '仕入先コード';
  String get productName => '商品名';
  String get productCode => '商品コード';
  String get janCode => 'JANコード';
  String get arrivalNumber => '入荷予定番号';
}


