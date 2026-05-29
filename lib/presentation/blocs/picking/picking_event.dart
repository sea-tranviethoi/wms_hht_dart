part of 'picking_bloc.dart';

abstract class PickingEvent {}

/// Load danh sách picking cho 1 tenant
class FetchPickingLists extends PickingEvent {
  final int tenantId;
  final String hhtInfo; // tên thiết bị HHT (để check xem ai đang handle)
  FetchPickingLists({required this.tenantId, this.hhtInfo = ''});
}

/// Lọc danh sách theo keyword
class SearchPickingLists extends PickingEvent {
  final String keyword;
  SearchPickingLists(this.keyword);
}

/// Chọn 1 picking → load các lines
class SelectPickingList extends PickingEvent {
  final String pickNo;
  SelectPickingList(this.pickNo);
}

/// Submit staging data lên server + hoàn thành picking
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

/// Reset state về initial (khi rời màn hình)
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
