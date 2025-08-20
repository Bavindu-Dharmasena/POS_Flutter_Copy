// import 'package:flutter/material.dart';
// import 'package:flutter_vector_icons/flutter_vector_icons.dart';
// import 'package:pos_system/features/stockkeeper/stockkeeper_inventory.dart';

// class ProductActionsSheet extends StatelessWidget {
//   final Product product;
//   final VoidCallback? onViewDetails;
//   final VoidCallback? onEdit;
//   final VoidCallback? onAdjustStock;
//   final VoidCallback? onDuplicate;
//   final VoidCallback? onDelete;

//   const ProductActionsSheet({
//     Key? key,
//     required this.product,
//     this.onViewDetails,
//     this.onEdit,
//     this.onAdjustStock,
//     this.onDuplicate,
//     this.onDelete,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     Theme.of(context);
    
//     return Container(
//       constraints: BoxConstraints(
//         maxHeight: MediaQuery.of(context).size.height * 0.7,
//       ),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Colors.grey[900]!,
//             Colors.black,
//           ],
//         ),
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.3),
//             blurRadius: 20,
//             offset: const Offset(0, -5),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Modern handle bar with glow effect
//           Container(
//             margin: const EdgeInsets.only(top: 16),
//             width: 50,
//             height: 4,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.blue[400]!, Colors.purple[400]!],
//               ),
//               borderRadius: BorderRadius.circular(2),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.blue[400]!.withOpacity(0.3),
//                   blurRadius: 8,
//                   spreadRadius: 1,
//                 ),
//               ],
//             ),
//           ),
          
//           // Glassmorphism header
//           Container(
//             margin: const EdgeInsets.all(20),
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   Colors.white.withOpacity(0.1),
//                   Colors.white.withOpacity(0.05),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.1),
//                 width: 1,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 10,
//                   offset: const Offset(0, 5),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 // Product avatar with modern styling
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [
//                         Colors.blue[400]!,
//                         Colors.purple[400]!,
//                       ],
//                     ),
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.blue[400]!.withOpacity(0.3),
//                         blurRadius: 15,
//                         offset: const Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: product.imageUrl != null
//                       ? ClipRRect(
//                           borderRadius: BorderRadius.circular(20),
//                           child: Image.network(
//                             product.imageUrl!,
//                             fit: BoxFit.cover,
//                           ),
//                         )
//                       : Icon(
//                           Icons.inventory_2_rounded,
//                           color: Colors.white,
//                           size: 32,
//                         ),
//                 ),
//                 const SizedBox(height: 16),
                
//                 Text(
//                   product.name,
//                   textAlign: TextAlign.center,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
                
//                 if (product.sku != null) ...[
//                   const SizedBox(height: 8),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: Colors.white.withOpacity(0.2),
//                       ),
//                     ),
//                     child: Text(
//                       'SKU: ${product.sku}',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.8),
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
          
//           // Modern action buttons
//           Flexible(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 children: [
//                   _modernActionTile(
//                     icon: Feather.eye,
//                     title: 'View Details',
//                     gradient: [Colors.blue[600]!, Colors.blue[400]!],
//                     onTap: () {
//                       Navigator.pop(context);
//                       onViewDetails?.call();
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   _modernActionTile(
//                     icon: Feather.edit_2,
//                     title: 'Edit Product',
//                     gradient: [Colors.green[600]!, Colors.green[400]!],
//                     onTap: () {
//                       Navigator.pop(context);
//                       onEdit?.call();
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   _modernActionTile(
//                     icon: Feather.trending_up,
//                     title: 'Adjust Stock',
//                     gradient: [Colors.orange[600]!, Colors.orange[400]!],
//                     onTap: () {
//                       Navigator.pop(context);
//                       onAdjustStock?.call();
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   _modernActionTile(
//                     icon: Feather.copy,
//                     title: 'Duplicate',
//                     gradient: [Colors.purple[600]!, Colors.purple[400]!],
//                     onTap: () {
//                       Navigator.pop(context);
//                       onDuplicate?.call();
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   _modernActionTile(
//                     icon: Feather.trash_2,
//                     title: 'Delete',
//                     gradient: [Colors.red[600]!, Colors.red[400]!],
//                     onTap: () {
//                       Navigator.pop(context);
//                       _confirmDelete(context);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
          
//           SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
//         ],
//       ),
//     );
//   }

//   Widget _modernActionTile({
//     required IconData icon,
//     required String title,
//     required List<Color> gradient,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           height: 56,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Colors.white.withOpacity(0.1),
//                 Colors.white.withOpacity(0.05),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: Colors.white.withOpacity(0.1),
//               width: 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Row(
//             children: [
//               // Icon container with gradient
//               Container(
//                 margin: const EdgeInsets.all(12),
//                 width: 32,
//                 height: 32,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(colors: gradient),
//                   borderRadius: BorderRadius.circular(8),
//                   boxShadow: [
//                     BoxShadow(
//                       color: gradient[0].withOpacity(0.3),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Icon(
//                   icon,
//                   color: Colors.white,
//                   size: 16,
//                 ),
//               ),
              
//               // Title
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     letterSpacing: 0.3,
//                   ),
//                 ),
//               ),
              
//               // Chevron with subtle animation
//               Container(
//                 margin: const EdgeInsets.only(right: 16),
//                 child: Icon(
//                   Icons.arrow_forward_ios_rounded,
//                   color: Colors.white.withOpacity(0.4),
//                   size: 14,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _confirmDelete(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.grey[900],
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//           side: BorderSide(
//             color: Colors.white.withOpacity(0.1),
//           ),
//         ),
//         title: Row(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.red[600]!, Colors.red[400]!],
//                 ),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Icon(
//                 Icons.warning_rounded,
//                 color: Colors.white,
//                 size: 20,
//               ),
//             ),
//             const SizedBox(width: 12),
//             const Text(
//               'Delete Product',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         content: Text(
//           'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
//           style: TextStyle(
//             color: Colors.white.withOpacity(0.8),
//             fontSize: 14,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             style: TextButton.styleFrom(
//               foregroundColor: Colors.white.withOpacity(0.7),
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             ),
//             child: const Text('Cancel'),
//           ),
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.red[600]!, Colors.red[400]!],
//               ),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 onDelete?.call();
//               },
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               ),
//               child: const Text('Delete'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Static method to show the bottom sheet
//   static Future<void> show({
//     required BuildContext context,
//     required Product product,
//     VoidCallback? onViewDetails,
//     VoidCallback? onEdit,
//     VoidCallback? onAdjustStock,
//     VoidCallback? onDuplicate,
//     VoidCallback? onDelete,
//   }) {
//     return showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => ProductActionsSheet(
//         product: product,
//         onViewDetails: onViewDetails,
//         onEdit: onEdit,
//         onAdjustStock: onAdjustStock,
//         onDuplicate: onDuplicate,
//         onDelete: onDelete,
//       ),
//     );
//   }
// }