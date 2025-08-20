import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'supplier/add_supplier_page.dart';

// New page to show supplier products
class SupplierProductsPage extends StatelessWidget {
  final Map<String, dynamic> supplier;
  
  const SupplierProductsPage({Key? key, required this.supplier}) : super(key: key);

  // App palette
  static const Color kBg = Color(0xFF0B1623);
  static const Color kSurface = Color(0xFF121A26);
  static const Color kBorder = Color(0x1FFFFFFF);
  static const Color kText = Colors.white;
  static const Color kTextMuted = Colors.white70;
  static const Color kInfo = Color(0xFF3B82F6);
  static const Color kSuccess = Color(0xFF10B981);

  // Sample products for each supplier
  final Map<String, List<Map<String, dynamic>>> supplierProducts = const {
    '1': [
      {'name': 'Rice - Basmati', 'unit': 'kg', 'salesPrice': 'Rs. 450.00', 'stock': 150},
      {'name': 'Sugar - White', 'unit': 'kg', 'salesPrice': 'Rs. 180.00', 'stock': 200},
      {'name': 'Oil - Coconut', 'unit': 'liter', 'salesPrice': 'Rs. 850.00', 'stock': 80},
      {'name': 'Flour - All Purpose', 'unit': 'kg', 'salesPrice': 'Rs. 120.00', 'stock': 300},
    ],
    '2': [
      {'name': 'Tea - Black', 'unit': 'kg', 'salesPrice': 'Rs. 1200.00', 'stock': 50},
      {'name': 'Coffee - Instant', 'unit': 'jar', 'salesPrice': 'Rs. 650.00', 'stock': 25},
      {'name': 'Biscuits - Marie', 'unit': 'pack', 'salesPrice': 'Rs. 85.00', 'stock': 120},
    ],
    '3': [
      {'name': 'Soap - Bath', 'unit': 'piece', 'salesPrice': 'Rs. 45.00', 'stock': 500},
      {'name': 'Shampoo - Herbal', 'unit': 'bottle', 'salesPrice': 'Rs. 380.00', 'stock': 60},
      {'name': 'Toothpaste - Mint', 'unit': 'tube', 'salesPrice': 'Rs. 150.00', 'stock': 200},
    ],
    '4': [
      {'name': 'Milk Powder', 'unit': 'pack', 'salesPrice': 'Rs. 890.00', 'stock': 40},
      {'name': 'Butter - Salted', 'unit': 'pack', 'salesPrice': 'Rs. 320.00', 'stock': 30},
    ],
    '5': [
      {'name': 'Onions - Red', 'unit': 'kg', 'salesPrice': 'Rs. 280.00', 'stock': 100},
      {'name': 'Potatoes', 'unit': 'kg', 'salesPrice': 'Rs. 120.00', 'stock': 250},
      {'name': 'Tomatoes', 'unit': 'kg', 'salesPrice': 'Rs. 180.00', 'stock': 80},
      {'name': 'Carrots', 'unit': 'kg', 'salesPrice': 'Rs. 200.00', 'stock': 60},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final Color supplierColor = supplier['color'] as Color;
    final products = supplierProducts[supplier['id']] ?? [];
    
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: kBg,
              automaticallyImplyLeading: false,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Feather.arrow_left, color: kText, size: 20),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier['name'],
                      style: const TextStyle(
                        color: kText,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${products.length} Products',
                      style: const TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        supplierColor.withOpacity(0.1),
                        kBg,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Supplier Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: supplierColor,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: supplier.containsKey('image') && supplier['image'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.asset(supplier['image'], fit: BoxFit.cover),
                                  )
                                : const Icon(Feather.briefcase, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  supplier['contactPerson'],
                                  style: const TextStyle(
                                    color: kText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  supplier['location'],
                                  style: const TextStyle(
                                    color: kTextMuted,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  supplier['phone'],
                                  style: const TextStyle(
                                    color: kTextMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Products Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Products',
                          style: TextStyle(
                            color: kText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: supplierColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: supplierColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${products.length} items',
                            style: TextStyle(
                              color: supplierColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Products List
                    if (products.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kBorder),
                        ),
                        child: Column(
                          children: [
                            Icon(Feather.package, color: kTextMuted, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'No products found',
                              style: TextStyle(
                                color: kTextMuted,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kBorder),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: supplierColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Feather.package,
                                      color: supplierColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'],
                                          style: const TextStyle(
                                            color: kText,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: kInfo.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'per ${product['unit']}',
                                                style: const TextStyle(
                                                  color: kInfo,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: kSuccess.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Stock: ${product['stock']}',
                                                style: const TextStyle(
                                                  color: kSuccess,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    product['salesPrice'],
                                    style: TextStyle(
                                      color: supplierColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupplierPage extends StatefulWidget {
  const SupplierPage({Key? key}) : super(key: key);

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // App palette (matching AddItemPage)
  static const Color kBg = Color(0xFF0B1623);
  static const Color kSurface = Color(0xFF121A26); // cards
  static const Color kBorder = Color(0x1FFFFFFF);  // faint white border
  static const Color kText = Colors.white;
  static const Color kTextMuted = Colors.white70;

  static const Color kInfo = Color(0xFF3B82F6);    // info/primary
  static const Color kSuccess = Color(0xFF10B981); // save button / success
// header back, accents
  static const Color kDanger = Color(0xFFEF4444);  // validation / errors

  // Sample supplier data with flat colors instead of gradients
  final List<Map<String, dynamic>> suppliers = [
    {
      'id': '1',
      'name': 'ABC Traders',
      'location': 'Colombo',
      'image': 'assets/images/maliban.webp',
      'phone': '+94 11 234 5678',
      'email': 'contact@abctraders.lk',
      'address': '123 Main Street, Colombo 01',
      'contactPerson': 'John Silva',
      'status': 'Active',
      'color': Color(0xFF3B82F6), // Blue
    },
    {
      'id': '2',
      'name': 'XYZ Distributors',
      'location': 'Kandy',
      'phone': '+94 81 987 6543',
      'email': 'info@xyzdist.lk',
      'address': '456 Hill Road, Kandy',
      'contactPerson': 'Maria Fernando',
      'status': 'Active',
      'color': Color(0xFF10B981), // Green
    },
    {
      'id': '3',
      'name': 'Quick Supplies',
      'location': 'Galle',
      'image': 'assets/images/cadbury.webp',
      'phone': '+94 91 123 4567',
      'email': 'orders@quicksupplies.lk',
      'address': '789 Beach Road, Galle',
      'contactPerson': 'David Perera',
      'status': 'Active',
      'color': Color(0xFFF97316), // Orange
    },
    {
      'id': '4',
      'name': 'SuperMart Pvt Ltd',
      'location': 'Jaffna',
      'phone': '+94 21 555 0123',
      'email': 'business@supermart.lk',
      'address': '321 North Street, Jaffna',
      'contactPerson': 'Raj Kumar',
      'status': 'Inactive',
      'color': Color(0xFFEC4899), // Pink
    },
    {
      'id': '5',
      'name': 'Wholesale Hub',
      'location': 'Negombo',
      'phone': '+94 31 777 8899',
      'email': 'hub@wholesale.lk',
      'address': '654 Market Street, Negombo',
      'contactPerson': 'Sarah De Silva',
      'status': 'Active',
      'color': Color(0xFF6366F1), // Indigo
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Navigate to supplier products page
  void _viewSupplierProducts(Map<String, dynamic> supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierProductsPage(supplier: supplier),
      ),
    );
  }

  void _showEditPopup(Map<String, dynamic> supplier) {
    // Create controllers for form fields
    final nameController = TextEditingController(text: supplier['name']);
    final contactPersonController = TextEditingController(text: supplier['contactPerson']);
    final phoneController = TextEditingController(text: supplier['phone']);
    final emailController = TextEditingController(text: supplier['email']);
    final locationController = TextEditingController(text: supplier['location']);
    final addressController = TextEditingController(text: supplier['address']);
    
    String currentStatus = supplier['status'];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => RawKeyboardListener(
          focusNode: FocusNode(),
          autofocus: true,
          onKey: (RawKeyEvent event) {
            if (event is RawKeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.pop(context);
              }
            }
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive width
                double dialogWidth = constraints.maxWidth > 600 
                    ? constraints.maxWidth * 0.9 
                    : constraints.maxWidth - 32; // 16px padding on each side
                
                double dialogHeight = constraints.maxHeight > 700 
                    ? constraints.maxHeight * 0.8 
                    : constraints.maxHeight - 80; // Top and bottom margins
                
                return Container(
                  width: dialogWidth,
                  height: dialogHeight,
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: kBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: supplier['color'],
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: supplier['color'].withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: supplier.containsKey('image') && supplier['image'] != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.asset(
                                              supplier['image'],
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(Feather.briefcase, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Edit Supplier',
                                          style: TextStyle(
                                            color: kText,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          supplier['name'],
                                          style: const TextStyle(
                                            color: kTextMuted,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Feather.x, color: kTextMuted, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Content
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildEditField('Company Name', nameController, Feather.briefcase),
                                const SizedBox(height: 16),
                                _buildEditField('Contact Person', contactPersonController, Feather.user),
                                const SizedBox(height: 16),
                                _buildEditField('Phone', phoneController, Feather.phone),
                                const SizedBox(height: 16),
                                _buildEditField('Email', emailController, Feather.mail),
                                const SizedBox(height: 16),
                                _buildEditField('Location', locationController, Feather.map_pin),
                                const SizedBox(height: 16),
                                _buildEditField('Address', addressController, Feather.map),
                                const SizedBox(height: 16),
                                
                                // Status Toggle
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Status',
                                      style: TextStyle(
                                        color: kTextMuted,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: kBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setDialogState(() {
                                                  currentStatus = 'Active';
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: currentStatus == 'Active' ? kSuccess : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: currentStatus == 'Active' ? [
                                                    BoxShadow(
                                                      color: kSuccess.withOpacity(0.35),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ] : null,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Feather.check_circle,
                                                      color: currentStatus == 'Active' ? Colors.white : kTextMuted,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Active',
                                                      style: TextStyle(
                                                        color: currentStatus == 'Active' ? Colors.white : kTextMuted,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setDialogState(() {
                                                  currentStatus = 'Inactive';
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: currentStatus == 'Inactive' ? kDanger : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: currentStatus == 'Inactive' ? [
                                                    BoxShadow(
                                                      color: kDanger.withOpacity(0.35),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ] : null,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Feather.pause_circle,
                                                      color: currentStatus == 'Inactive' ? Colors.white : kTextMuted,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Inactive',
                                                      style: TextStyle(
                                                        color: currentStatus == 'Inactive' ? Colors.white : kTextMuted,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Column(
                          children: [
                            // Mobile-friendly button layout
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF334155),
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Update supplier data
                                        setState(() {
                                          final index = suppliers.indexWhere((s) => s['id'] == supplier['id']);
                                          if (index != -1) {
                                            suppliers[index]['name'] = nameController.text;
                                            suppliers[index]['contactPerson'] = contactPersonController.text;
                                            suppliers[index]['phone'] = phoneController.text;
                                            suppliers[index]['email'] = emailController.text;
                                            suppliers[index]['location'] = locationController.text;
                                            suppliers[index]['address'] = addressController.text;
                                            suppliers[index]['status'] = currentStatus;
                                          }
                                        });
                                        
                                        Navigator.pop(context);
                                        
                                        // Show success message
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.transparent,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            elevation: 0,
                                            margin: const EdgeInsets.all(16),
                                            duration: const Duration(seconds: 3),
                                            dismissDirection: DismissDirection.horizontal,
                                            content: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                              decoration: BoxDecoration(
                                                color: kSuccess,
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: kSuccess.withOpacity(0.35),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Feather.check_circle, color: Colors.white, size: 20),
                                                  const SizedBox(width: 12),
                                                  Flexible(
                                                    child: Text(
                                                      '${nameController.text} updated successfully!',
                                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: supplier['color'],
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Feather.save, color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'Save Changes',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: kTextMuted, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kInfo, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 100,
                floating: false,
                pinned: true,
                backgroundColor: kBg,
                automaticallyImplyLeading: false,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Feather.arrow_left, color: kText, size: 20),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Suppliers',
                    style: const TextStyle(
                      color: kText,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: suppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = suppliers[index];
                        final Color supplierColor = supplier['color'] as Color;
                        final hasImage = supplier.containsKey('image') && supplier['image'] != null;
                        final isActive = supplier['status'] == 'Active';

                        return Container(
                          margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: kBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _viewSupplierProducts(supplier),
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: EdgeInsets.all(isTablet ? 24 : 20),
                                child: Column(
                                  children: [
                                    // Header Section - Responsive layout
                                    Row(
                                      children: [
                                        Stack(
                                          children: [
                                            Container(
                                              width: isTablet ? 72 : 64,
                                              height: isTablet ? 72 : 64,
                                              decoration: BoxDecoration(
                                                color: supplierColor,
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: supplierColor.withOpacity(0.4),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: hasImage
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(16),
                                                      child: Image.asset(
                                                        supplier['image'],
                                                        width: isTablet ? 72 : 64,
                                                        height: isTablet ? 72 : 64,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                  : Icon(
                                                      Feather.briefcase,
                                                      color: Colors.white,
                                                      size: isTablet ? 32 : 28,
                                                    ),
                                            ),
                                            if (!isActive)
                                              Positioned(
                                                top: -4,
                                                right: -4,
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: kDanger,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: kDanger.withOpacity(0.35),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Feather.pause,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(width: isTablet ? 20 : 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      supplier['name'],
                                                      style: TextStyle(
                                                        fontSize: isTablet ? 20 : 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: kText,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isActive ? kSuccess : kDanger,
                                                      borderRadius: BorderRadius.circular(12),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: (isActive ? kSuccess : kDanger).withOpacity(0.3),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      supplier['status'],
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                supplier['contactPerson'],
                                                style: TextStyle(
                                                  fontSize: isTablet ? 16 : 14,
                                                  color: kTextMuted,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    SizedBox(height: isTablet ? 20 : 16),
                                    
                                    // Details Section - Mobile optimized
                                    if (isTablet)
                                      // Tablet layout - 2x2 grid
                                      Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildDetailItem(
                                                  icon: Feather.phone,
                                                  label: 'Phone',
                                                  value: supplier['phone'],
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _buildDetailItem(
                                                  icon: Feather.mail,
                                                  label: 'Email',
                                                  value: supplier['email'],
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildDetailItem(
                                                  icon: Feather.map_pin,
                                                  label: 'Location',
                                                  value: supplier['location'],
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _buildDetailItem(
                                                  icon: Feather.map,
                                                  label: 'Address',
                                                  value: supplier['address'],
                                                  color: Colors.black,
                                                  isAddress: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    else
                                      // Mobile layout - stacked
                                      Column(
                                        children: [
                                          _buildDetailItem(
                                            icon: Feather.phone,
                                            label: 'Phone',
                                            value: supplier['phone'],
                                            color: Colors.black,
                                          ),
                                          const SizedBox(height: 8),
                                          _buildDetailItem(
                                            icon: Feather.mail,
                                            label: 'Email',
                                            value: supplier['email'],
                                            color: Colors.black,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildDetailItem(
                                                  icon: Feather.map_pin,
                                                  label: 'Location',
                                                  value: supplier['location'],
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: _buildDetailItem(
                                                  icon: Feather.map,
                                                  label: 'Address',
                                                  value: supplier['address'],
                                                  color: Colors.black,
                                                  isAddress: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    
                                    SizedBox(height: isTablet ? 20 : 16),
                                    
                                    
                                    // Action Button Row - Responsive
Row(
  children: [
    Expanded(
      child: Container(
        height: isTablet ? 48 : 44,
        child: ElevatedButton(
          onPressed: () => _showEditPopup(supplier),
          style: ElevatedButton.styleFrom(
            backgroundColor: supplierColor,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Feather.edit_3, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Edit',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 15 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
),

                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            color: kInfo,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kInfo.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddSupplierPage(supplierData: {},)),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Feather.plus, color: Colors.white, size: 20),
            label: Text(
              'Add Supplier',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 17 : 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isAddress = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: isAddress ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}