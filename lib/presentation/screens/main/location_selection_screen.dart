import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/storage/cache_storage.dart';
import '../../blocs/master/master_bloc.dart';
import '../../../data/models/master/location.dart';
import '../../../core/constants/app_styles.dart';
import '../../../routes/route_names.dart';

/// Port từ screens/LocationSelection.js (nếu có trong RN)
///
/// Cho phép user chọn warehouse location trước khi bắt đầu làm việc.
/// Location được lưu vào SharedPreferences để dùng cho toàn app.
class LocationSelectionScreen extends StatelessWidget {
  const LocationSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MasterBloc(repository: sl())..add(FetchLocations()),
      child: const _LocationSelectionView(),
    );
  }
}

class _LocationSelectionView extends StatefulWidget {
  const _LocationSelectionView();

  @override
  State<_LocationSelectionView> createState() => _LocationSelectionViewState();
}

class _LocationSelectionViewState extends State<_LocationSelectionView> {
  final _searchCtrl = TextEditingController();
  List<Location> _allLocations = [];
  List<Location> _filtered = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final kw = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = kw.isEmpty
          ? _allLocations
          : _allLocations
              .where((l) =>
                  l.locationCode.toLowerCase().contains(kw) ||
                  l.locationName.toLowerCase().contains(kw))
              .toList();
    });
  }

  Future<void> _selectLocation(Location loc) async {
    final cacheStorage = sl<CacheStorage>();
    await cacheStorage.saveLocation(loc.locationCode);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ロケーション: ${loc.locationCode} を選択しました',
            style: const TextStyle(fontFamily: AppStyles.font),
          ),
          backgroundColor: AppColors.wageningenGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      context.go(RouteNames.mainMenu);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.themeBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppStyles.sizeAppBarIcon),
          onPressed: () => context.go(RouteNames.mainMenu),
        ),
        title: const Text('ロケーション選択', style: AppStyles.appBarTitle),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontFamily: AppStyles.font),
        decoration: InputDecoration(
          hintText: 'ロケーションを検索...',
          hintStyle: const TextStyle(fontFamily: AppStyles.font, color: AppColors.gray),
          prefixIcon: const Icon(Icons.search, color: AppColors.gray),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _searchCtrl.clear,
                )
              : null,
          filled: true,
          fillColor: AppColors.ghostWhiteColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<MasterBloc, MasterState>(
      listener: (context, state) {
        if (state is LocationsLoaded) {
          setState(() {
            _allLocations = state.locations;
            _filtered = state.locations;
          });
        }
      },
      builder: (context, state) {
        if (state is MasterLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.themeBackground),
          );
        }
        if (state is MasterError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.textError, size: 48),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: const TextStyle(
                    fontFamily: AppStyles.font,
                    color: AppColors.textError,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<MasterBloc>().add(FetchLocations()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.themeBackground,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('再試行', style: TextStyle(fontFamily: AppStyles.font)),
                ),
              ],
            ),
          );
        }
        if (_filtered.isEmpty) {
          return const Center(
            child: Text(
              'ロケーションが見つかりません',
              style: TextStyle(fontFamily: AppStyles.font, color: AppColors.gray),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _filtered.length,
          itemBuilder: (context, index) {
            final loc = _filtered[index];
            return _LocationTile(
              location: loc,
              onTap: () => _selectLocation(loc),
            );
          },
        );
      },
    );
  }
}

class _LocationTile extends StatelessWidget {
  final Location location;
  final VoidCallback onTap;

  const _LocationTile({required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.themeBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.location_on, color: Colors.white),
        ),
        title: Text(
          location.locationCode,
          style: TextStyle(
            fontFamily: AppStyles.font,
            fontSize: AppStyles.sizeBody,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: location.locationName.isNotEmpty
            ? Text(
                location.locationName,
                style: TextStyle(
                  fontFamily: AppStyles.font,
                  color: AppColors.grayTextColor,
                  fontSize: AppStyles.sizeSub,
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppColors.gray),
      ),
    );
  }
}
