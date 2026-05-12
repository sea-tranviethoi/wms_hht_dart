class ApiEndpoints {
  // Auth
  static const String login = '/api/Account/identity/loginasync';
  static const String loginByQR = '/api/Account/identity/loginht';
  static const String refreshToken = '/api/Account/identity/refresh-token';
  
  // Master Data
  static const String tenants = '/api/Tenants';
  static const String tenantsById = '/api/Tenants/{id}';
  static const String products = '/api/Products';
  static const String productsByCode = '/api/Products/get-by-product-code';
  static const String productsList = '/api/Products/get-product-list';
  static const String productsWithInventory = '/api/Products/GetAllDtoAsync';
  static const String suppliers = '/api/Suppliers';
  static const String bins = '/api/Bins';
  static const String units = '/api/Units';
  static const String locations = '/api/Locations';
  static const String vendors = '/api/Vendors';
  static const String roles = '/api/Account/identity/user-with-role';
  
  // Warehouse Receipt
  static const String warehouseReceiptOrder = '/api/WarehouseReceiptOrder';
  static const String warehouseReceiptOrderByReceiptNo =
      '/api/WarehouseReceiptOrder/GetByMasterCodeAsync/{receiptNo}';
  static const String warehouseReceiptOrderUpdate =
      '/api/WarehouseReceiptOrder/update';
  static const String warehouseReceiptOrderLine =
      '/api/WarehouseReceiptOrderLine';
  static const String warehouseReceiptOrderLineByReceiptNo =
      '/api/WarehouseReceiptOrderLine/GetByMasterCodeAsync/{receiptNo}';
  static const String warehouseReceiptOrderLineUpdate =
      '/api/WarehouseReceiptOrderLine/update';
  static const String warehouseReceiptStaging = '/api/WarehouseReceiptStaging';
  static const String warehouseReceiptStagingByReceiptNo =
      '/api/WarehouseReceiptStaging/GetByMasterCodeAsync/{receiptNo}';
  static const String warehouseReceiptStagingAddRange =
      '/api/WarehouseReceiptStaging/AddRange';
  static const String warehouseReceiptStagingDelete =
      '/api/WarehouseReceiptStaging/delete';
  static const String warehouseReceiptStagingUploadImage =
      '/api/WarehouseReceiptStaging/UploadProductErrorImageAsync';
  static const String completeWarehouseReceipt =
      '/api/WarehouseReceiptOrder/complete-putaway-receipts';

  // Putaway
  static const String putaway = '/api/WarehousePutAway';
  static const String putawayByPutawayNo =
      '/api/WarehousePutAway/GetByMasterCodeAsync/{putAwayNo}';
  static const String putawayLines = '/api/WarehousePutAwayLine';
  static const String putawayLinesByPutawayNo =
      '/api/WarehousePutAwayLine/GetByMasterCodeAsync/{putAwayNo}';
  static const String putawayStaging = '/api/WarehousePutAwayStaging';
  static const String putawayStagingByPutawayNo =
      '/api/WarehousePutAwayStaging/GetByMasterCodeAsync/{putAwayNo}';
  static const String putawayStagingAddRange =
      '/api/WarehousePutAwayStaging/AddRange';
  static const String putawayStagingDelete =
      '/api/WarehousePutAwayStaging/delete';
  static const String completePutaway = '/api/WarehousePutAway/complete-putaway';
  
  // Picking
  static const String pickingList = '/api/WarehousePickingList';
  static const String pickingListByPickingNo =
      '/api/WarehousePickingList/GetByMasterCodeAsync/{pickNo}';
  static const String pickingLines = '/api/WarehousePickingLine';
  static const String pickingLinesByPickingNo =
      '/api/WarehousePickingLine/GetPickingLineDTOAsync/{pickNo}';
  static const String pickingStaging = '/api/WarehousePickingStaging';
  static const String pickingStagingByPickingNo =
      '/api/WarehousePickingStaging/GetByMasterCodeAsync/{pickNo}';
  static const String pickingStagingAddRange =
      '/api/WarehousePickingStaging/AddRange';
  static const String pickingStagingDeleteRange =
      '/api/WarehousePickingStaging/DeleteRange';
  static const String completePicking = '/api/WarehousePickingList/complete-pickings';
  
  // Bundle
  static const String bundle = '/api/InventBundle';
  static const String bundleByTransNo =
      '/api/InventBundle/GetByTransNoDTOAsync/{transNo}';
  static const String bundleLines = '/api/InventBundleLine';
  static const String bundleLinesByTransNo =
      '/api/InventBundleLine/GetProductsByTransNo/{TransNo}';
  static const String bundleLineAddRange = '/api/InventBundleLine/AddRange';
  static const String bundleUploadFromHandheld =
      '/api/InventBundle/UploadFromHandheldAsync';
  
  // Bin Movement
  static const String inventTransfer = '/api/InventTransfer';
  
  // Bin Audit
  static const String stockTake = '/api/InventStockTakeRecording';
  
  // Common
  static const String updateHHTStatus = '/api/Common/UpdateHHTStatusAsync';
  static const String devices = '/api/Devices';
}

