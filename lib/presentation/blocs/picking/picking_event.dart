part of 'picking_bloc.dart';

abstract class PickingEvent {}

/// Load the picking list for one tenant
class FetchPickingLists extends PickingEvent {
  final int tenantId;
  final String hhtInfo; // HHT device name (used to check who is currently handling it)
  FetchPickingLists({required this.tenantId, this.hhtInfo = ''});
}

/// Filter the list by keyword
class SearchPickingLists extends PickingEvent {
  final String keyword;
  SearchPickingLists(this.keyword);
}

/// Select one picking order → load its lines
class SelectPickingList extends PickingEvent {
  final String pickNo;
  SelectPickingList(this.pickNo);
}

/// Submit staging data to the server and complete the picking
class SyncPickingData extends PickingEvent {
  final String pickNo;
  final List<StagingPayload> stagingList;
  final int tenantId;
  final String company;

  SyncPickingData({
    required this.pickNo,
    required this.stagingList,
    required this.tenantId,
    required this.company,
  });
}

/// Reset state to initial (when leaving the screen)
class ResetPickingState extends PickingEvent {}

// ─── Internal payload ─────────────────────────────────────────

class StagingPayload {
  final int lineId;
  final String productCode;
  final String bin;
  final String? lotNo;
  final double pickQty;
  final double actualQty;
  final String? qrCode;
  final String? shipmentLineId;
  final int? unitId;
  final String? unit;

  const StagingPayload({
    required this.lineId,
    required this.productCode,
    required this.bin,
    this.lotNo,
    required this.pickQty,
    required this.actualQty,
    this.qrCode,
    this.shipmentLineId,
    this.unitId,
    this.unit,
  });
}
