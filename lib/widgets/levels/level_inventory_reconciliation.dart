import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/services.dart' as services;
import 'dart:convert';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import '../../theme/app_theme.dart';
import '../level_widget.dart';
import '../../data/inventory.dart' as inventory_data;
import '../../models/inventory_item.dart' as model;

class LevelInventoryReconciliation extends LevelWidget {
  const LevelInventoryReconciliation({super.key, required super.onComplete});

  @override
  State createState() => _LevelInventoryReconciliationState();
}

class _LevelInventoryReconciliationState extends State<LevelInventoryReconciliation>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // inventory data - use real data
  late List<model.InventoryItem> _items;
  late Map<String, int> _initialQuantities;

  // Expected deliveries aggregated by SKU from receipts (case-insensitive)
  final Map<String, int> _deliveredBySku = const {
    // polartech supplies
    'SRV-THM-001': 26,  // thermal survival blanket
    'SRV-HW-001': 50,   // hand warmer (loose units)
    'SRV-SLP-X40': 12,  // sleeping bag extreme cold (can be split across multiple items with same SKU)
    'SRV-GOG-S01': 5,   // snow goggles (multiple items share this SKU)
    'SRV-BOT-A42': 20,  // arctic boots size 42
    'SRV-TNT-P04': 4,   // polar expedition tent (normalize mixed-case in receipts)
    'SRV-WTR-P50': 8,   // water purifier (tablets)
    
    // glacier supplies
    'ORD-BRC-C01': 2,
    'LOG-SLD-M02': 1,
    'SRV-FLR-012': -2,
    'SRV-WTR-F01': -2,
    'SRV-HW-USB': -5,
    'TCH-RAD-E01': -4,
    
    
    // cryo delivery
    'MED-BLD-S01': 10,
    'MED-STM-E04': 8,
    'MED-TRM-F02': 5,
    'MED-BND-C01':  75,
    'MED-IV-K01': 12,
    'MED-SPL-S01': 15,
    'MED-HYP-X01': 6
  };

  // search + filters
  String _query = '';
  final Set<String> _selectedCategories = {};

  // pdf receipts found under assets/inventory
  List<_PdfDoc> _pdfDocs = [];
  bool _loadingPdfs = true;

  // initial totals by SKU (normalized)
  late Map<String, int> _initialSkuTotals;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize with all items from inventory data (public getter)
    _items = List.from(inventory_data.items);
    // Store initial quantities
    _initialQuantities = {for (final item in _items) item.id: item.quantity};
    _initialSkuTotals = _sumBySku(_items);
    // Load receipt PDFs from assets
    _loadPdfAssets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPdfAssets() async {
    // Try official AssetManifest API first, then JSON manifest, then known filenames
    final found = <String>{};

    // 1) Preferred: AssetManifest API (supports binary/json, works across modes)
    try {
      final manifest = await services.AssetManifest.loadFromAssetBundle(rootBundle);
      for (final asset in manifest.listAssets()) {
        if (asset.startsWith('assets/inventory/') && asset.toLowerCase().endsWith('.pdf')) {
          found.add(asset);
        }
      }
    } catch (_) {
      // ignore and try legacy JSON manifest
    }

    // 2) Legacy: parse JSON manifest if present
    if (found.isEmpty) {
      for (final manifestName in const ['AssetManifest.json']) {
        try {
          final manifestStr = await rootBundle.loadString(manifestName);
          if (manifestStr.isEmpty) continue;
          final map = Map<String, dynamic>.from(jsonDecode(manifestStr) as Map);
          for (final k in map.keys) {
            if (k.startsWith('assets/inventory/') && k.toLowerCase().endsWith('.pdf')) {
              found.add(k);
            }
          }
        } catch (_) {
          // ignore and try the next option
        }
      }
    }

    // 3) Hard fallback: probe known filenames directly (ensures all current receipts show up)
    if (found.isEmpty) {
      const candidates = <String>{
        'assets/inventory/polartech-delivery-manifest.pdf',
        'assets/inventory/cryo-delivery.pdf',
        'assets/inventory/glacier_supplies.pdf',
      };
      for (final probe in candidates) {
        try {
          await rootBundle.load(probe);
          found.add(probe);
        } catch (_) {
          // skip missing
        }
      }
    }

    final docs = <_PdfDoc>[];
    for (final p in found) {
      try {
        final data = await rootBundle.load(p);
        final name = p.split('/').last;
        docs.add(_PdfDoc(path: p, name: name, sizeBytes: data.lengthInBytes));
      } catch (_) {
        final name = p.split('/').last;
        docs.add(_PdfDoc(path: p, name: name));
      }
    }
    docs.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (mounted) {
      setState(() {
        _pdfDocs = docs;
        _loadingPdfs = false;
      });
    }
  }

  void _handleValidate() {
    final ok = _validateInventory();
    if (ok) {
      widget.onComplete(true);
    } else {
      widget.onComplete(false);
    }
  }

  bool _validateInventory() {
    // Validate at the SKU level (handles duplicates across items and multiple receipt lines per SKU)
    final currentTotals = _sumBySku(_items);

    // For each delivered SKU, final total must equal initial + delivered
    for (final entry in _deliveredBySku.entries) {
      final sku = _normSku(entry.key);
      final delivered = entry.value;
      final initial = _initialSkuTotals[sku] ?? 0;
      final current = currentTotals[sku] ?? 0;
      if (current != initial + delivered) return false;
    }

    // For SKUs not in delivered set, totals must remain unchanged
    final deliveredSkus = _deliveredBySku.keys.map(_normSku).toSet();
    final allSkus = <String>{..._initialSkuTotals.keys, ...currentTotals.keys};
    for (final sku in allSkus) {
      if (!deliveredSkus.contains(sku)) {
        final initial = _initialSkuTotals[sku] ?? 0;
        final current = currentTotals[sku] ?? 0;
        if (current != initial) return false;
      }
    }

    return true;
  }

  String _normSku(String sku) => sku.trim().toUpperCase();

  Map<String, int> _sumBySku(List<model.InventoryItem> items) {
    final map = <String, int>{};
    for (final i in items) {
      final key = _normSku(i.sku);
      map[key] = (map[key] ?? 0) + i.quantity;
    }
    return map;
  }

  int _initialQuantityFor(String id) {
    return _initialQuantities[id] ?? 0;
  }

  List<String> get _allCategories => _items.map((e) => e.category).toSet().toList()..sort();

  List<model.InventoryItem> get _filteredItems {
    final q = _query.trim().toLowerCase();
    final list = _items.where((i) {
      final matchesText = q.isEmpty ||
          i.name.toLowerCase().contains(q) ||
          i.sku.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q);
      final matchesCat = _selectedCategories.isEmpty || _selectedCategories.contains(i.category);
      return matchesText && matchesCat;
    }).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  void _changeQuantity(model.InventoryItem item, int delta) {
    setState(() {
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx != -1) {
        final next = (_items[idx].quantity + delta).clamp(0, 999999);
        _items[idx] = _items[idx].copyWith(quantity: next);
      }
    });
  }

  void _showItemBottomSheet(model.InventoryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _ItemBottomSheet(
          item: _items.firstWhere((i) => i.id == item.id), // Get fresh item data
          onQuantityChange: (delta) {
            _changeQuantity(item, delta);
            setModalState(() {}); // Update modal state
          },
          onQuantitySet: (value) {
            setState(() {
              final idx = _items.indexWhere((i) => i.id == item.id);
              if (idx != -1) {
                final safe = value.clamp(0, 999999);
                _items[idx] = _items[idx].copyWith(quantity: safe);
              }
            });
            setModalState(() {}); // Update modal state
          },
          onDelete: () {
            setState(() {
              _items.removeWhere((i) => i.id == item.id);
            });
            Navigator.pop(context);
          },
          getCategoryColor: _getCategoryColor,
          getCategoryIcon: _getCategoryIcon,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'survival':
        return Colors.orange;
      case 'tech':
        return Colors.blue;
      case 'ordnance':
        return Colors.red;
      case 'medical':
        return Colors.green;
      case 'logistics':
        return Colors.purple;
      default:
        return NunuColors.primaryMain;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'survival':
        return Icons.outdoor_grill;
      case 'tech':
        return Icons.memory;
      case 'ordnance':
        return Icons.flash_on;
      case 'medical':
        return Icons.medical_services;
      case 'logistics':
        return Icons.local_shipping;
      default:
        return Icons.inventory;
    }
  }

  void _showCreateItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateItemDialog(
        onCreateItem: (item) {
          setState(() {
            _items.add(item);
          });
        },
        getCategoryColor: _getCategoryColor,
        getCategoryIcon: _getCategoryIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: NunuColors.primaryLight,
              unselectedLabelColor: Colors.white70,
              indicatorColor: NunuColors.primaryMain,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(
                  icon: Icon(Icons.receipt_long),
                  text: 'receipts',
                ),
                Tab(
                  icon: Icon(Icons.inventory_2),
                  text: 'inventory',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDeliveryTab(),
                _buildInventoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTab() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // PDF receipts viewer
            Container(
              decoration: BoxDecoration(
                color: NunuColors.backgroundPaper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NunuColors.primaryMain.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [NunuColors.primaryMain.withOpacity(0.1), NunuColors.secondaryMain.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: NunuColors.primaryMain.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.text_format, color: NunuColors.primaryLight, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _loadingPdfs
                                    ? 'loading receipts...'
                                    : (_pdfDocs.isEmpty
                                        ? 'no receipts found in assets/inventory'
                                        : 'update inventory to match all deliveries and order receipts'),
                                style: TextStyle(color: NunuColors.primaryLight),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_loadingPdfs)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    for (final doc in _pdfDocs)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.white70),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(doc.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  if (doc.sizeBytes != null)
                                    Text(_prettySize(doc.sizeBytes!), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _openPdf(doc),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: NunuColors.primaryMain,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('open'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _prettySize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double s = bytes.toDouble();
    int i = 0;
    while (s >= 1024 && i < units.length - 1) {
      s /= 1024;
      i++;
    }
    return '${s.toStringAsFixed(1)} ${units[i]}';
  }

  Future<void> _openPdf(_PdfDoc doc) async {
    try {
      final data = await rootBundle.load(doc.path);
      final bytes = data.buffer.asUint8List();
      final fileName = doc.name;
      // Write to system temp directory and open
      final tempDir = Directory.systemTemp;
      final outFile = File('${tempDir.path}/$fileName');
      await outFile.writeAsBytes(bytes);
      await OpenFilex.open(outFile.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('failed to open PDF')),
      );
    }
  }

  Widget _buildInventoryTab() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          // search section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: NunuColors.backgroundDefault,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NunuColors.primaryMain.withOpacity(0.3)),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'search inventory...',
                  hintStyle: TextStyle(color: Colors.white60),
                  prefixIcon: Icon(Icons.search, color: NunuColors.primaryLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
          // inventory list
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white30),
                        const SizedBox(height: 16),
                        Text('no items found', style: TextStyle(color: Colors.white60, fontSize: 18)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredItems.length,
                    itemBuilder: (ctx, idx) {
                      final item = _filteredItems[idx];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        decoration: BoxDecoration(
                          color: NunuColors.backgroundPaper,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          onTap: () => _showItemBottomSheet(item),
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(item.category).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _getCategoryIcon(item.category),
                              color: _getCategoryColor(item.category),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${item.sku} • ${item.description}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: NunuColors.backgroundDefault,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: NunuColors.primaryMain.withOpacity(0.3)),
                            ),
                            child: Text(
                              'qty ${item.quantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // bottom action bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Create new item button
                ElevatedButton(
                  onPressed: _showCreateItemDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NunuColors.backgroundDefault,
                    foregroundColor: NunuColors.primaryLight,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: NunuColors.primaryMain.withOpacity(0.5)),
                    ),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(width: 12),
                // Complete reconciliation button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleValidate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NunuColors.primaryMain,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle),
                        SizedBox(width: 8),
                        Text(
                          'complete reconciliation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiptEntry {
  final String name;
  final String sku;
  final int qty;
  const ReceiptEntry({required this.name, required this.sku, required this.qty});
}

class _PdfDoc {
  final String path;
  final String name;
  final int? sizeBytes;
  const _PdfDoc({required this.path, required this.name, this.sizeBytes});
}

class _ItemBottomSheet extends StatefulWidget {
  final model.InventoryItem item;
  final Function(int) onQuantityChange;
  final Function(int) onQuantitySet;
  final VoidCallback onDelete;
  final Color Function(String) getCategoryColor;
  final IconData Function(String) getCategoryIcon;

  const _ItemBottomSheet({
    required this.item,
    required this.onQuantityChange,
    required this.onQuantitySet,
    required this.onDelete,
    required this.getCategoryColor,
    required this.getCategoryIcon,
  });

  @override
  State<_ItemBottomSheet> createState() => _ItemBottomSheetState();
}

class _ItemBottomSheetState extends State<_ItemBottomSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void didUpdateWidget(_ItemBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.quantity != oldWidget.item.quantity) {
      _controller.text = widget.item.quantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header with icon and title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: widget.getCategoryColor(widget.item.category).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.getCategoryIcon(widget.item.category),
                    color: widget.getCategoryColor(widget.item.category),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        widget.item.category,
                        style: TextStyle(
                          color: widget.getCategoryColor(widget.item.category),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'SKU', value: widget.item.sku),
                const SizedBox(height: 8),
                _DetailRow(label: 'Description', value: widget.item.description),
                const SizedBox(height: 8),
                if (widget.item.location != null)
                  _DetailRow(label: 'Location', value: widget.item.location!),
                if (widget.item.notes != null) ...[
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Notes', value: widget.item.notes!),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quantity controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'quantity',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Decrease button
                    Container(
                      decoration: BoxDecoration(
                        color: NunuColors.backgroundDefault,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: NunuColors.primaryMain.withOpacity(0.3)),
                      ),
                      child: IconButton(
                        onPressed: () => widget.onQuantityChange(-1),
                        icon: const Icon(Icons.remove, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Quantity input
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: NunuColors.backgroundDefault,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: NunuColors.primaryMain.withOpacity(0.3)),
                        ),
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                            hintText: '0',
                            hintStyle: TextStyle(color: Colors.white60),
                          ),
                          onSubmitted: (value) {
                            final parsed = int.tryParse(value);
                            if (parsed != null && parsed >= 0) {
                              final safe = parsed.clamp(0, 999999);
                              widget.onQuantitySet(safe);
                              _controller.text = safe.toString();
                            } else {
                              _controller.text = widget.item.quantity.toString();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Increase button
                    Container(
                      decoration: BoxDecoration(
                        color: NunuColors.backgroundDefault,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: NunuColors.primaryMain.withOpacity(0.3)),
                      ),
                      child: IconButton(
                        onPressed: () => widget.onQuantityChange(1),
                        icon: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Set quantity button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final parsed = int.tryParse(_controller.text);
                      if (parsed != null && parsed >= 0) {
                        final safe = parsed.clamp(0, 999999);
                        widget.onQuantitySet(safe);
                        _controller.text = safe.toString();
                        // Close the bottom sheet after setting quantity
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NunuColors.primaryMain,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('set quantity'),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Delete button
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: NunuColors.backgroundPaper,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: const Text('delete item', style: TextStyle(color: Colors.white)),
                        content: Text(
                          'remove "${widget.item.name}" from inventory?',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('cancel', style: TextStyle(color: Colors.white70)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              widget.onDelete();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: NunuColors.errorMain,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NunuColors.errorMain,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.delete),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  
  const _DetailRow({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateItemDialog extends StatefulWidget {
  final Function(model.InventoryItem) onCreateItem;
  final Color Function(String) getCategoryColor;
  final IconData Function(String) getCategoryIcon;

  const _CreateItemDialog({
    required this.onCreateItem,
    required this.getCategoryColor,
    required this.getCategoryIcon,
  });

  @override
  State<_CreateItemDialog> createState() => _CreateItemDialogState();
}

class _CreateItemDialogState extends State<_CreateItemDialog> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  String _selectedCategory = 'survival';
  
  final List<String> _categories = ['survival', 'tech', 'ordnance', 'medical', 'logistics'];

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _createItem() {
    if (_nameController.text.trim().isEmpty || _skuController.text.trim().isEmpty) {
      return;
    }

    final quantity = (int.tryParse(_quantityController.text) ?? 0).clamp(0, 999999);
    final newItem = model.InventoryItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      quantity: quantity,
    );

    widget.onCreateItem(newItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NunuColors.backgroundPaper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: NunuColors.primaryMain.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add_box, color: NunuColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('create new item', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name field
            Container(
              decoration: BoxDecoration(
                color: NunuColors.backgroundDefault,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NunuColors.primaryMain.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'item name',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // SKU field
            Container(
              decoration: BoxDecoration(
                color: NunuColors.backgroundDefault,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NunuColors.primaryMain.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _skuController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'sku',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Category dropdown
            Container(
              decoration: BoxDecoration(
                color: NunuColors.backgroundDefault,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NunuColors.primaryMain.withOpacity(0.3)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: NunuColors.backgroundPaper,
                  style: const TextStyle(color: Colors.white),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            widget.getCategoryIcon(category),
                            color: widget.getCategoryColor(category),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Description field
            Container(
              decoration: BoxDecoration(
                color: NunuColors.backgroundDefault,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NunuColors.primaryMain.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'description',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Quantity field
            Container(
              decoration: BoxDecoration(
                color: NunuColors.backgroundDefault,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NunuColors.primaryMain.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'initial quantity',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _createItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: NunuColors.primaryMain,
            foregroundColor: Colors.white,
          ),
          child: const Text('create'),
        ),
      ],
    );
  }
}
