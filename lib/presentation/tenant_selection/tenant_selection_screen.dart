import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme_config.dart';
import '../../routes/route_names.dart';
import '../../data/models/tenant.dart';
import '../../data/repositories/tenant_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/local_storage.dart';
import '../../l10n/app_strings.dart';
import '../widgets/loading_indicator.dart';
import '../../core/constants/app_styles.dart';

class TenantSelectionScreen extends StatefulWidget {
  final String? funcNumber; // "3" for Picking, null or other for Warehouse Receipt

  const TenantSelectionScreen({
    super.key,
    this.funcNumber,
  });

  @override
  State<TenantSelectionScreen> createState() => _TenantSelectionScreenState();
}

class _TenantSelectionScreenState extends State<TenantSelectionScreen> {
  late TenantRepository _tenantRepository;
  final TextEditingController _searchController = TextEditingController();
  List<Tenant> _tenants = [];
  List<Tenant> _filteredTenants = [];
  bool _isLoading = true;
  List<Color> _tenantColors = [];

  @override
  void initState() {
    super.initState();
    // initialize repository with prefs
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _tenantRepository = TenantRepository(ApiClient(prefs));
      });
      _loadTenants();
    });
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadTenants() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final tenants = await _tenantRepository.getTenants();
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorage(prefs);
      
      // Load or generate colors
      String? colorsJson = await localStorage.getString('dataColor');
      List<Color> colors = [];
      
      if (colorsJson != null) {
        try {
          // Parse JSON string to get color values
          final colorsList = (await localStorage.getJson('dataColor')) as List<dynamic>;
          colors = colorsList.map((c) => Color(c is int ? c : int.parse(c.toString()))).toList();
        } catch (e) {
          colors = _generateColors(tenants.length);
        }
      } else {
        colors = _generateColors(tenants.length);
        await localStorage.saveJson('dataColor', 
            colors.map((c) => c.toARGB32()).toList());
      }

      // Ensure colors list matches tenants length
      while (colors.length < tenants.length) {
        colors.add(_randomGrayToBlueColor());
      }

      setState(() {
        _tenants = tenants;
        _filteredTenants = tenants;
        _tenantColors = colors;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading tenants: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Color> _generateColors(int count) {
    return List.generate(count, (_) => _randomGrayToBlueColor());
  }

  Color _randomGrayToBlueColor() {
    final grayStart = 150;
    final r = (grayStart * (0.5 + 0.5 * (DateTime.now().millisecondsSinceEpoch % 100) / 100)).toInt();
    final g = (grayStart * (0.5 + 0.5 * (DateTime.now().millisecondsSinceEpoch % 200) / 200)).toInt();
    final b = 150 + ((255 - 150) * (DateTime.now().millisecondsSinceEpoch % 100) / 100).toInt();
    return Color.fromRGBO(r, g, b, 1.0);
  }

  void _onSearchChanged() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      if (keyword.isEmpty) {
        _filteredTenants = _tenants;
      } else {
        _filteredTenants = _tenants
            .where((tenant) =>
                tenant.tenantFullName.toLowerCase().contains(keyword))
            .toList();
      }
    });
  }

  void _handleTenantTap(Tenant tenant) {
    final company = Uri.encodeComponent(tenant.tenantFullName);
    
    // If funcNumber is "3", navigate to PickingList, otherwise Warehouse Receipt
    if (widget.funcNumber == "3") {
      context.push(
        '${RouteNames.pickingList}?tenantId=${tenant.tenantId}&company=$company',
      );
    } else {
      context.push(
        '${RouteNames.warehouseReceiptList}?tenantId=${tenant.tenantId}&company=$company',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final strings = AppStrings.of(context);
            return Text(
              widget.funcNumber == "3" ? 'ピッキング' : strings.tenantSelectionTitle,
              style: AppStyles.appBarTitle,
            );
          },
        ),
        backgroundColor: AppColors.headerColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Always go back to main menu (function screen)
            context.go(RouteNames.mainMenu);
          },
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Builder(
              builder: (context) {
                final strings = AppStrings.of(context);
                return TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontFamily: AppStyles.font,
                    fontSize: AppStyles.sizeBodyText,
                    color: AppColors.blackTextColor,
                  ),
                  decoration: InputDecoration(
                    hintText: strings.tenantSearchHint,
                    hintStyle: const TextStyle(
                      fontFamily: AppStyles.font,
                      color: AppColors.gray,
                      fontSize: AppStyles.sizeBodyText,
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppColors.gray, size: AppStyles.sizeSearchIcon),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.gray, size: AppStyles.sizeSearchIcon),
                            onPressed: () { _searchController.clear(); },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 0),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.lighter, width: 2),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.lighter, width: 2),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
                    ),
                  ),
                );
              },
            ),
          ),

          // Tenant list
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(size: 100)
                : _filteredTenants.isEmpty
                    ? Builder(
                        builder: (context) {
                          final strings = AppStrings.of(context);
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  strings.tenantLoadFailed,
                                  style: TextStyle(fontSize: AppStyles.sizeBodyText),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(strings.retry),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _filteredTenants.length,
                        itemBuilder: (context, index) {
                          final tenant = _filteredTenants[index];
                          final colorIndex = _tenants.indexOf(tenant);
                          final bgColor = colorIndex < _tenantColors.length
                              ? _tenantColors[colorIndex]
                              : _randomGrayToBlueColor();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Material(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(15),
                              child: InkWell(
                                onTap: () => _handleTenantTap(tenant),
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}. ${tenant.tenantFullName}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

