import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/features/stockkeeper/products/add_item_page.dart';

class StockKeeperInventory extends StatefulWidget {
  const StockKeeperInventory({Key? key}) : super(key: key);

  @override
  State<StockKeeperInventory> createState() => _StockKeeperInventoryState();
}

class _StockKeeperInventoryState extends State<StockKeeperInventory> {
  String searchQuery = '';
  String selectedCategory = 'All';
  String selectedStockStatus = 'All';

  // Sample data - in real app, this would come from database
  List<Product> products = [
    Product(
      id: '001',
      name: 'Cadbury Dairy Milk',
      category: 'Chocolates',
      currentStock: 45,
      minStock: 20,
      maxStock: 100,
      price: 250.00,
      barcode: '123456789',
      image: 'assets/images/cadbury.webp',
      supplier: 'Cadbury Lanka',
    ),
    Product(
      id: '002',
      name: 'Maliban Cream Crackers',
      category: 'Biscuits',
      currentStock: 8,
      minStock: 15,
      maxStock: 80,
      price: 180.00,
      barcode: '987654321',
      image: 'assets/images/maliban.webp',
      supplier: 'Maliban Biscuits',
    ),
    Product(
      id: '003',
      name: 'Coca Cola 330ml',
      category: 'Beverages',
      currentStock: 67,
      minStock: 25,
      maxStock: 120,
      price: 150.00,
      barcode: '456789123',
      image: 'assets/images/coca_cola.webp',
      supplier: 'Coca Cola Lanka',
    ),
    Product(
      id: '004',
      name: 'Anchor Milk Powder 400g',
      category: 'Dairy',
      currentStock: 12,
      minStock: 10,
      maxStock: 50,
      price: 850.00,
      barcode: '789123456',
      image: 'assets/images/anchor.webp',
      supplier: 'Fonterra Lanka',
    ),
    Product(
      id: '005',
      name: 'Sunquick Orange 700ml',
      category: 'Beverages',
      currentStock: 23,
      minStock: 15,
      maxStock: 60,
      price: 420.00,
      barcode: '321654987',
      image: 'assets/images/sunquick.webp',
      supplier: 'Lanka Beverages',
    ),
  ];

  List<String> get categories {
    final cats = products.map((p) => p.category).toSet().toList();
    cats.insert(0, 'All');
    return cats;
  }

  List<Product> get filteredProducts {
    return products.where((product) {
      final matchesSearch =
          product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          product.barcode.contains(searchQuery) ||
          product.id.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesCategory =
          selectedCategory == 'All' || product.category == selectedCategory;

      final matchesStockStatus =
          selectedStockStatus == 'All' ||
          (selectedStockStatus == 'Low Stock' && product.isLowStock) ||
          (selectedStockStatus == 'In Stock' &&
              !product.isLowStock &&
              product.currentStock > 0) ||
          (selectedStockStatus == 'Out of Stock' && product.currentStock == 0);

      return matchesSearch && matchesCategory && matchesStockStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 800;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1623),
      appBar: AppBar(
        title: const Text(
          'Inventory Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0B1623),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Feather.search, color: Colors.white),
            onPressed: () {
              // Open search focus
            },
          ),
          IconButton(
            icon: const Icon(Feather.download, color: Colors.white),
            onPressed: () {
              _showExportDialog(context);
            },
          ),
        ],
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          children: [
            // Dashboard Summary Cards
            _buildDashboardSummary(isTablet, isMobile),

            // Search and Filter Section
            _buildSearchAndFilter(isTablet, isMobile),

            // Product Grid/List
            Expanded(child: _buildProductGrid(isTablet, isMobile)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context),
        backgroundColor: Colors.green,
        icon: const Icon(Feather.plus, color: Colors.white),
        label: Text(
          isMobile ? 'Add' : 'Add Product',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardSummary(bool isTablet, bool isMobile) {
    final totalItems = products.length;
    final lowStockItems = products.where((p) => p.isLowStock).length;
    final outOfStockItems = products.where((p) => p.currentStock == 0).length;
    final totalValue = products.fold(
      0.0,
      (sum, p) => sum + (p.price * p.currentStock),
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = isTablet ? 4 : (isMobile ? 2 : 3);

          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isMobile ? 8 : 12,
            mainAxisSpacing: isMobile ? 8 : 12,
            childAspectRatio: isMobile ? 1.8 : 2.2, // Increased from 1.5 to 1.8
            children: [
              _buildSummaryCard(
                'Total Items',
                totalItems.toString(),
                Icons.inventory,
                Colors.blue,
                Colors.blue.withOpacity(0.1),
                isMobile: isMobile,
              ),
              _buildSummaryCard(
                'Low Stock',
                lowStockItems.toString(),
                Icons.warning,
                Colors.orange,
                Colors.orange.withOpacity(0.1),
                isMobile: isMobile,
              ),
              _buildSummaryCard(
                'Out of Stock',
                outOfStockItems.toString(),
                Icons.cancel,
                Colors.red,
                Colors.red.withOpacity(0.1),
                isMobile: isMobile,
              ),
              _buildSummaryCard(
                'Total Value',
                'Rs. ${totalValue.toStringAsFixed(0)}',
                Icons.trending_up,
                Colors.green,
                Colors.green.withOpacity(0.1),
                isMobile: isMobile,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor, {
    bool isMobile = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      padding: EdgeInsets.all(isMobile ? 8 : 16), // Reduced padding for mobile
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Important: minimize the column size
        children: [
          Icon(
            icon,
            color: iconColor,
            size: isMobile ? 18 : 24,
          ), // Reduced icon size
          SizedBox(height: isMobile ? 2 : 6), // Reduced spacing
          Flexible(
            // Wrap in Flexible to prevent overflow
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 14 : 18, // Reduced font size
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: isMobile ? 1 : 2), // Reduced spacing
          Flexible(
            // Wrap in Flexible to prevent overflow
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: isMobile ? 10 : 12, // Reduced font size
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isTablet, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 10,
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search products, barcode, or ID...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: Icon(
                  Feather.search,
                  color: Colors.white.withOpacity(0.6),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          const SizedBox(height: 12),

          // Filter Row
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Category',
                  selectedCategory,
                  categories,
                  (value) => setState(() => selectedCategory = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Stock Status',
                  selectedStockStatus,
                  ['All', 'In Stock', 'Low Stock', 'Out of Stock'],
                  (value) => setState(() => selectedStockStatus = value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String hint,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
          dropdownColor: const Color(0xFF1a2332),
          style: const TextStyle(color: Colors.white),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildProductGrid(bool isTablet, bool isMobile) {
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Feather.search,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = isTablet ? 3 : (isMobile ? 1 : 2);

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: isMobile ? 3.5 : 1.2,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              return _buildProductCard(filteredProducts[index], isMobile);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isMobile) {
    return InkWell(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: product.isLowStock
                ? Colors.orange.withOpacity(0.5)
                : product.currentStock == 0
                ? Colors.red.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isMobile
              ? _buildMobileProductCard(product)
              : _buildDesktopProductCard(product),
        ),
      ),
    );
  }

  Widget _buildMobileProductCard(Product product) {
    return Row(
      children: [
        // Product Image
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: product.image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    product.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Feather.package,
                        color: Colors.white.withOpacity(0.5),
                        size: 20,
                      );
                    },
                  ),
                )
              : Icon(
                  Feather.package,
                  color: Colors.white.withOpacity(0.5),
                  size: 20,
                ),
        ),

        const SizedBox(width: 10),

        // Product Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                product.category,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildStockBadge(product),
                  const Spacer(),
                  Text(
                    'Rs. ${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Action Button
        IconButton(
          onPressed: () => _showProductActions(product),
          icon: const Icon(Feather.more_vertical, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildDesktopProductCard(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with image and actions
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: product.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        product.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Feather.package,
                            color: Colors.white.withOpacity(0.5),
                          );
                        },
                      ),
                    )
                  : Icon(
                      Feather.package,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showProductActions(product),
              icon: const Icon(
                Feather.more_horizontal,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Product name
        Text(
          product.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Category
        Text(
          product.category,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),

        const Spacer(),

        // Stock info
        _buildStockBadge(product),

        const SizedBox(height: 8),

        // Price
        Text(
          'Rs. ${product.price.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStockBadge(Product product) {
    Color badgeColor;
    String text;
    IconData icon;

    if (product.currentStock == 0) {
      badgeColor = Colors.red;
      text = 'Out of Stock';
      icon = Feather.x_circle;
    } else if (product.isLowStock) {
      badgeColor = Colors.orange;
      text = 'Low Stock (${product.currentStock})';
      icon = Feather.alert_triangle;
    } else {
      badgeColor = Colors.green;
      text = 'In Stock (${product.currentStock})';
      icon = Feather.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailsDialog(product: product),
    );
  }

  void _showProductActions(Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a2332),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ProductActionsSheet(product: product),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddItemPage()),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a2332),
        title: const Text(
          'Export Inventory',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Choose export format for your inventory data.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting inventory...')),
              );
            },
            child: const Text('Export CSV'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting inventory...')),
              );
            },
            child: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }
}

// Product Model
class Product {
  final String id;
  final String name;
  final String category;
  final int currentStock;
  final int minStock;
  final int maxStock;
  final double price;
  final String barcode;
  final String? image;
  final String supplier;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minStock,
    required this.maxStock,
    required this.price,
    required this.barcode,
    this.image,
    required this.supplier,
  });

  bool get isLowStock => currentStock <= minStock && currentStock > 0;
}

// Product Details Dialog
class ProductDetailsDialog extends StatelessWidget {
  final Product product;

  const ProductDetailsDialog({Key? key, required this.product})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1a2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: product.image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            product.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Feather.package,
                                color: Colors.white.withOpacity(0.5),
                              );
                            },
                          ),
                        )
                      : Icon(
                          Feather.package,
                          color: Colors.white.withOpacity(0.5),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        product.category,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Feather.x, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildDetailRow('Product ID', product.id),
            _buildDetailRow('Barcode', product.barcode),
            _buildDetailRow('Supplier', product.supplier),
            _buildDetailRow('Price', 'Rs. ${product.price.toStringAsFixed(2)}'),
            _buildDetailRow('Current Stock', '${product.currentStock} units'),
            _buildDetailRow('Min Stock Level', '${product.minStock} units'),
            _buildDetailRow('Max Stock Level', '${product.maxStock} units'),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Open edit dialog
                    },
                    icon: const Icon(Feather.edit_2),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Open stock adjustment dialog
                    },
                    icon: const Icon(Feather.trending_up),
                    label: const Text('Adjust Stock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Product Actions Bottom Sheet
class ProductActionsSheet extends StatelessWidget {
  final Product product;

  const ProductActionsSheet({Key? key, required this.product})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height *
            0.7, // Limit height to 70% of screen
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        // Make it scrollable
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16), // Reduced from 20
            Text(
              product.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16), // Reduced from 20
            _buildActionTile(
              icon: Feather.eye,
              title: 'View Details',
              onTap: () {
                Navigator.pop(context);
                // Show details
              },
            ),
            _buildActionTile(
              icon: Feather.edit_2,
              title: 'Edit Product',
              onTap: () {
                Navigator.pop(context);
                // Edit product
              },
            ),
            _buildActionTile(
              icon: Feather.trending_up,
              title: 'Adjust Stock',
              onTap: () {
                Navigator.pop(context);
                // Adjust stock
              },
            ),
            _buildActionTile(
              icon: Feather.copy,
              title: 'Duplicate',
              onTap: () {
                Navigator.pop(context);
                // Duplicate product
              },
            ),
            _buildActionTile(
              icon: Feather.trash_2,
              title: 'Delete',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                // Delete product with confirmation
              },
            ),
            SizedBox(
              height: MediaQuery.of(context).viewInsets.bottom + 10,
            ), // Account for keyboard
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final actionColor = color ?? Colors.white;

    return ListTile(
      leading: Icon(icon, color: actionColor, size: 20), // Reduced icon size
      title: Text(
        title,
        style: TextStyle(
          color: actionColor,
          fontSize: 14, // Reduced font size
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 2,
      ), // Reduced vertical padding
      dense: true, // Make tiles more compact
    );
  }
}
