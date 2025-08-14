// import 'package:flutter/material.dart';

// class SectionHeader extends StatefulWidget {
//   final String title;
//   final IconData icon;
//   final int reportCount;

//   const SectionHeader({
//     Key? key,
//     required this.title,
//     required this.icon,
//     required this.reportCount,
//   }) : super(key: key);

//   @override
//   State<SectionHeader> createState() => _SectionHeaderState();
// }

// class _SectionHeaderState extends State<SectionHeader>
//     with TickerProviderStateMixin {
//   late AnimationController _slideController;
//   late AnimationController _pulseController;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _pulseAnimation;
//   late Animation<double> _scaleAnimation;

//   @override
//   void initState() {
//     super.initState();
    
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
    
//     _pulseController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.easeOutCubic,
//     ));

//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
//     ));

//     _pulseAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.05,
//     ).animate(CurvedAnimation(
//       parent: _pulseController,
//       curve: Curves.easeInOut,
//     ));

//     _scaleAnimation = Tween<double>(
//       begin: 0.8,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.elasticOut,
//     ));

//     _slideController.forward();
//     _pulseController.repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _slideController.dispose();
//     _pulseController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isMobile = screenWidth <= 600;
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     return SlideTransition(
//       position: _slideAnimation,
//       child: FadeTransition(
//         opacity: _fadeAnimation,
//         child: AnimatedBuilder(
//           animation: _pulseAnimation,
//           builder: (context, child) {
//             return Transform.scale(
//               scale: _pulseAnimation.value,
//               child: Container(
//                 padding: EdgeInsets.all(isMobile ? 20 : 28),
//                 decoration: BoxDecoration(
//                   gradient: isDark
//                       ? LinearGradient(
//                           colors: [
//                             const Color(0xFF1E293B),
//                             const Color(0xFF334155),
//                             const Color(0xFF475569),
//                           ],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         )
//                       : LinearGradient(
//                           colors: [
//                             Colors.white,
//                             const Color(0xFFF8FAFC),
//                             const Color(0xFFEFF6FF),
//                           ],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                   borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
//                   border: Border.all(
//                     color: isDark 
//                         ? Colors.white.withOpacity(0.1)
//                         : const Color(0xFF667eea).withOpacity(0.2),
//                     width: 1.5,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: isDark
//                           ? Colors.black.withOpacity(0.3)
//                           : const Color(0xFF667eea).withOpacity(0.12),
//                       blurRadius: 32,
//                       offset: const Offset(0, 12),
//                       spreadRadius: -4,
//                     ),
//                     BoxShadow(
//                       color: isDark
//                           ? Colors.black.withOpacity(0.2)
//                           : const Color(0xFF667eea).withOpacity(0.06),
//                       blurRadius: 8,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: isMobile ? _buildMobileLayout(isDark) : _buildDesktopLayout(isDark),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildMobileLayout(bool isDark) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             _buildModernIcon(isDark),
//             const SizedBox(width: 20),
//             Expanded(child: _buildModernTitle(isDark)),
//           ],
//         ),
//         const SizedBox(height: 20),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             _buildStatusIndicator(isDark),
//             _buildModernBadge(isDark),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildDesktopLayout(bool isDark) {
//     return Row(
//       children: [
//         _buildModernIcon(isDark),
//         const SizedBox(width: 24),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildModernTitle(isDark),
//               const SizedBox(height: 8),
//               _buildStatusIndicator(isDark),
//             ],
//           ),
//         ),
//         const SizedBox(width: 20),
//         _buildModernBadge(isDark),
//       ],
//     );
//   }

//   Widget _buildModernIcon(bool isDark) {
//     return ScaleTransition(
//       scale: _scaleAnimation,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               const Color(0xFF667eea),
//               const Color(0xFF764ba2),
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: const Color(0xFF667eea).withOpacity(0.4),
//               blurRadius: 20,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Stack(
//           children: [
//             Icon(
//               widget.icon, 
//               color: Colors.white, 
//               size: 28,
//             ),
//             Positioned(
//               top: -4,
//               right: -4,
//               child: Container(
//                 width: 12,
//                 height: 12,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF10b981),
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.white, width: 2),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildModernTitle(bool isDark) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         ShaderMask(
//           shaderCallback: (bounds) => LinearGradient(
//             colors: isDark
//                 ? [Colors.white, Colors.white70]
//                 : [const Color(0xFF1E293B), const Color(0xFF475569)],
//           ).createShader(bounds),
//           child: Text(
//             widget.title,
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.w700,
//               color: Colors.white,
//               letterSpacing: -0.5,
//             ),
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           'Advanced Analytics Dashboard',
//           style: TextStyle(
//             fontSize: 13,
//             color: isDark ? Colors.white54 : const Color(0xFF64748B),
//             fontWeight: FontWeight.w500,
//             letterSpacing: 0.2,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatusIndicator(bool isDark) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: const Color(0xFF10b981).withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: const Color(0xFF10b981).withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 6,
//             height: 6,
//             decoration: const BoxDecoration(
//               color: Color(0xFF10b981),
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 6),
//           Text(
//             'Live Data',
//             style: TextStyle(
//               color: const Color(0xFF10b981),
//               fontSize: 11,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildModernBadge(bool isDark) {
//     return TweenAnimationBuilder<double>(
//       duration: const Duration(milliseconds: 1000),
//       tween: Tween(begin: 0.0, end: 1.0),
//       curve: Curves.elasticOut,
//       builder: (context, animation, child) {
//         return Transform.scale(
//           scale: animation,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   const Color(0xFF667eea),
//                   const Color(0xFF764ba2),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: const Color(0xFF667eea).withOpacity(0.4),
//                   blurRadius: 16,
//                   offset: const Offset(0, 6),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   Icons.analytics_outlined,
//                   color: Colors.white,
//                   size: 16,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   '${widget.reportCount}',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 16,
//                     letterSpacing: -0.3,
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//                 Text(
//                   widget.reportCount == 1 ? 'report' : 'reports',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.9),
//                     fontWeight: FontWeight.w500,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';

class ModernSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int reportCount;

  const ModernSectionHeader({
    Key? key,
    required this.title,
    required this.icon,
    required this.reportCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF64FFDA), Color(0xFF1DE9B6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0F0F23),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$reportCount reports available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF64FFDA).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              reportCount.toString(),
              style: const TextStyle(
                color: Color(0xFF64FFDA),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}