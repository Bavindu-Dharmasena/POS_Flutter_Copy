import 'package:flutter/material.dart';

class SupplierPage extends StatelessWidget {
  const SupplierPage({Key? key}) : super(key: key);

  // Sample supplier data with dummy image paths (some missing)
  final List<Map<String, String>> suppliers = const [
    {'name': 'ABC Traders', 'location': 'Colombo', 'image': 'assets/images/maliban.webp'},
    {'name': 'XYZ Distributors', 'location': 'Kandy'},
    {'name': 'Quick Supplies', 'location': 'Galle', 'image': 'assets/images/cadbury.webp'},
    {'name': 'SuperMart Pvt Ltd', 'location': 'Jaffna'},
    {'name': 'Wholesale Hub', 'location': 'Negombo'},
    
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1623),
      appBar: AppBar(
        title: const Text('Suppliers', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B1623),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: suppliers.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final supplier = suppliers[index];
            final hasImage = supplier.containsKey('image') && supplier['image']!.isNotEmpty;

            return Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    hasImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.asset(
                              supplier['image']!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.store,
                            color: Colors.blueAccent.shade100,
                            size: 40,
                          ),
                    const SizedBox(height: 12),
                    Text(
                      supplier['name']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      supplier['location']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Add Supplier tapped')));
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
      ),
    );
  }
}
