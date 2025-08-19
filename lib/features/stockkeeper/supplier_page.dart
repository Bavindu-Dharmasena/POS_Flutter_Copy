import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'supplier/add_supplier_page.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({Key? key}) : super(key: key);

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Sample supplier data with additional details for editing
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
      'gradient': const LinearGradient(
        colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
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
      'gradient': const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
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
      'gradient': const LinearGradient(
        colors: [Color(0xFFF97316), Color(0xFFEAB308)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
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
      'gradient': const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
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
      'gradient': const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
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

  void _showEditPopup(Map<String, dynamic> supplier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
            }
          }
        },
        child: _buildEditPopup(supplier),
      ),
    );
  }

  Widget _buildEditPopup(Map<String, dynamic> supplier) {
    final gradient = supplier['gradient'] as LinearGradient;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E3A8A),
              Color(0xFF0F172A),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.colors.first.withOpacity(0.4),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Supplier',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            supplier['name'],
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Feather.x, color: Colors.white60, size: 20),
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
                      _buildEditField('Company Name', supplier['name'], Feather.briefcase),
                      const SizedBox(height: 16),
                      _buildEditField('Contact Person', supplier['contactPerson'], Feather.user),
                      const SizedBox(height: 16),
                      _buildEditField('Phone', supplier['phone'], Feather.phone),
                      const SizedBox(height: 16),
                      _buildEditField('Email', supplier['email'], Feather.mail),
                      const SizedBox(height: 16),
                      _buildEditField('Location', supplier['location'], Feather.map_pin),
                      const SizedBox(height: 16),
                      _buildEditField('Address', supplier['address'], Feather.map),
                      const SizedBox(height: 16),
                      _buildStatusToggle(supplier),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF475569).withOpacity(0.8),
                            const Color(0xFF334155).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
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
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: gradient.colors.first.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle save logic here
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${supplier['name']} updated successfully!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
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
        ),
      ),
    );
  }

  Widget _buildEditField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextFormField(
            initialValue: value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white60, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggle(Map<String, dynamic> supplier) {
    final isActive = supplier['status'] == 'Active';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      supplier['status'] = 'Active';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Feather.check_circle,
                          color: isActive ? Colors.white : Colors.white60,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Active',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.white60,
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
                    setState(() {
                      supplier['status'] = 'Inactive';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: !isActive
                          ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Feather.pause_circle,
                          color: !isActive ? Colors.white : Colors.white60,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Inactive',
                          style: TextStyle(
                            color: !isActive ? Colors.white : Colors.white60,
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
    );
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: const Color(0xFF0B1623),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E3A8A),
                Color(0xFF0F172A),
              ],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
                    ).createShader(bounds),
                    child: const Text(
                      'Suppliers',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: suppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = suppliers[index];
                        final gradient = supplier['gradient'] as LinearGradient;
                        final hasImage = supplier.containsKey('image') && supplier['image'] != null;
                        final isActive = supplier['status'] == 'Active';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: gradient.colors.map((color) => color.withOpacity(0.1)).toList().length >= 2
                                ? LinearGradient(
                                    colors: gradient.colors.map((color) => color.withOpacity(0.1)).toList(),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: gradient.colors.first.withOpacity(0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showEditPopup(supplier),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    // Header Section
                                    Row(
                                      children: [
                                        Stack(
                                          children: [
                                            Container(
                                              width: 64,
                                              height: 64,
                                              decoration: BoxDecoration(
                                                gradient: gradient,
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: gradient.colors.first.withOpacity(0.4),
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
                                                        width: 64,
                                                        height: 64,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Feather.briefcase,
                                                      color: Colors.white,
                                                      size: 28,
                                                    ),
                                            ),
                                            if (!isActive)
                                              Positioned(
                                                top: -4,
                                                right: -4,
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                                    ),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Color(0xFFEF4444),
                                                        blurRadius: 8,
                                                        offset: Offset(0, 2),
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
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      supplier['name'],
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      gradient: isActive
                                                          ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                                                          : const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                                                      borderRadius: BorderRadius.circular(12),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: (isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                                              .withOpacity(0.3),
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
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Details Section
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDetailItem(
                                            icon: Feather.phone,
                                            label: 'Phone',
                                            value: supplier['phone'],
                                            color: const Color(0xFF60A5FA),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildDetailItem(
                                            icon: Feather.mail,
                                            label: 'Email',
                                            value: supplier['email'],
                                            color: const Color(0xFF10B981),
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
                                            color: const Color(0xFFF97316),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildDetailItem(
                                            icon: Feather.map,
                                            label: 'Address',
                                            value: supplier['address'],
                                            color: const Color(0xFFEC4899),
                                            isAddress: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Action Button
                                    Container(
                                      width: double.infinity,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: gradient,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: gradient.colors.first.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () => _showEditPopup(supplier),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Feather.edit_3, color: Colors.white, size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              'Edit Supplier',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
            gradient: const LinearGradient(
              colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF60A5FA).withOpacity(0.4),
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
            label: const Text(
              'Add Supplier',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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