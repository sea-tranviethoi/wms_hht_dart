class StringsEn {
  const StringsEn();

  // Common
  String get menuTitle => 'Menu';
  String get filter => 'Filter';
  String get reset => 'Reset';
  String get search => 'Search';
  String get noData => 'No data';
  String get confirm => 'Confirm';
  String get yes => 'Yes';
  String get no => 'No';
  String get back => 'Back';
  String get clear => 'Clear';
  String get apply => 'Apply';
  String get cancel => 'Cancel';
  String get save => 'Save';
  String get complete => 'Complete';
  String get sync => 'Sync';
  String get close => 'Close';

  // Menu
  List<String> get menuItems => [
    '1. Receipt',
    '2. Putaway',
    '3. Picking',
    '4. Pre-bundle',
    '5. Bin Movement',
    '6. Bin Audit',
    '7. Logout',
  ];

  // Tenant Selection
  String get tenantSelectionTitle => 'Tenant Selection';
  String get tenantLoadFailed => 'Failed to load tenants.';
  String get retry => 'Retry';
  String get tenantSearchHint => 'Type to filter tenants';

  // Auth
  String get loginTitle => 'Login';
  String get userName => 'Username';
  String get password => 'Password';
  String get loginButton => 'Login';
  String get qrLogin => 'Scan QR';
  String get loginHint => 'Enter username/password or scan QR to login.';
  String get loginFailed => 'Login failed. Please check credentials and try again.';
  String get loginNoInternet => 'No internet connection';
  String get loginWrongCredential => 'Username or password is incorrect. Please try again.';
  String get loginServerIssue => 'Cannot connect to WMS server due to server issues.';
  String get qrInvalid => 'Invalid QR data. Please input user & password.';

  // Receipt List
  String get receiptListTitle => 'Receipt List';
  String get receiptNo => 'Receipt No';
  String get supplierName => 'Supplier Name';
  String get searchHint => 'Enter text to filter';
  String get advancedSearch => 'Advanced Search';
  String get receiptSyncNone => 'No data to sync';
  String get receiptSyncConfirm => 'Sync the following to WMS?';
  String get receiptSynced => 'Synced successfully';
  String get receiptSyncFailed => 'Sync failed';
  String get receiptResetConfirm => 'Reset in-progress data for this receipt?';
  String get receiptResetDone => 'Reset completed';
  String get handledByOther => 'This receipt is being handled on another device. Please check.';
  String get listEmpty => 'No receipts found';

  // Receipt Detail
  String get receiptDetailTitle => 'Receipt Detail';
  String get basicInfo => 'Basic Info';
  String get date => 'Date';
  String get items => 'Items';
  String get add => 'Add';
  String get images => 'Images';
  String get imageLabel => 'Product Image';
  String get status => 'Status';
  String get statusOk => 'OK';
  String get statusNg => 'NG';
  String get statusShort => 'Shortage';
  String get actualQtyRequired => 'Please input actual quantity';
  String get saved => 'Saved';
  String get completeConfirm => 'Complete this receipt?';

  // Receipt Filter
  String get filterTitle => 'Advanced Search';
  String get filterHint => 'Enter filter conditions';
  String get vendorCode => 'Supplier Code';
  String get productName => 'Product Name';
  String get productCode => 'Product Code';
  String get janCode => 'JAN Code';
  String get arrivalNumber => 'Arrival Number';
}



