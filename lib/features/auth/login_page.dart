import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final String role; // The role passed from POSHomePage

  const LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

  // Role-specific colors and gradients
  List<Color> get _roleGradient {
    switch (widget.role) {
      case 'Admin':
        return [
          Colors.red.shade400,
          Colors.pink.shade600,
          Colors.purple.shade400,
        ];
      case 'Manager':
        return [
          Colors.purple.shade400,
          Colors.indigo.shade500,
          Colors.blue.shade400,
        ];
      case 'Cashier':
        return [
          Colors.green.shade400,
          Colors.teal.shade500,
          Colors.cyan.shade400,
        ];
      case 'StockKeeper':
        return [
          Colors.yellow.shade400,
          Colors.amber.shade500,
          Colors.orange.shade400,
        ];
      default:
        return [
          Colors.orange.shade400,
          Colors.red.shade400,
          Colors.pink.shade400,
        ];
    }
  }

  Color get _primaryColor {
    switch (widget.role) {
      case 'Admin':
        return Colors.red.shade600;
      case 'Manager':
        return Colors.purple.shade600;
      case 'Cashier':
        return Colors.green.shade600;
      case 'StockKeeper':
        return Colors.amber.shade600;
      default:
        return Colors.indigo.shade600;
    }
  }

  Color get _accentColor {
    switch (widget.role) {
      case 'Admin':
        return Colors.pink.shade400;
      case 'Manager':
        return Colors.indigo.shade400;
      case 'Cashier':
        return Colors.teal.shade400;
      case 'StockKeeper':
        return Colors.yellow.shade400;
      default:
        return Colors.orange.shade400;
    }
  }

  IconData get _roleIcon {
    switch (widget.role) {
      case 'Admin':
        return Icons.admin_panel_settings;
      case 'Manager':
        return Icons.manage_accounts;
      case 'Cashier':
        return Icons.point_of_sale;
      case 'StockKeeper':
        return Icons.inventory;
      default:
        return Icons.person;
    }
  }

  // Submit login credentials
  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return; // Early exit if widget is disposed
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final auth = Provider.of<AuthService>(context, listen: false);

    try {
      bool success = await auth.login(username, password);

      if (!mounted) return; // Check again after async operation

      if (success) {
        final user = auth.currentUser!;
        final loggedInRole = user.role;

        if (loggedInRole.toLowerCase() != widget.role.toLowerCase()) {
          setState(
            () => _error =
                "Access denied: This login is for ${widget.role}s only",
          );
          auth.logout();
          return;
        }

        // Navigation
        _navigateBasedOnRole(loggedInRole);
      } else {
        setState(() => _error = 'Incorrect credentials');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Login error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateBasedOnRole(String role) {
    if (!mounted) return;

    switch (role.toLowerCase()) {
      case 'stockkeeper':
        Navigator.pushReplacementNamed(context, '/stockkeeper');
        break;
      case 'cashier':
        Navigator.pushReplacementNamed(context, '/cashier');
        break;
      case 'admin':
        Navigator.pushReplacementNamed(context, '/admin');
        break;
      case 'manager':
        Navigator.pushReplacementNamed(context, '/manager');
        break;
      default:
        if (mounted) {
          setState(() => _error = 'Unknown user role');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _roleGradient[0].withOpacity(0.8),
              _roleGradient[1].withOpacity(0.9),
              _roleGradient[2].withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 450 : double.infinity,
                    minHeight: screenHeight * 0.6,
                  ),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 20,
                    shadowColor: _primaryColor.withOpacity(0.4),
                    color: Colors.white,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Colors.grey.shade50],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Colorful header with animated icon
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _roleGradient,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      _roleIcon,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '${widget.role} Login',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Welcome back! Please sign in.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Colorful username field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _usernameController,
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(
                                      Icons.person,
                                      color: _primaryColor,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    labelStyle: TextStyle(color: _primaryColor),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(
                                        color: _primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your username';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Colorful password field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: _primaryColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: _primaryColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    labelStyle: TextStyle(color: _primaryColor),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(
                                        color: _primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              // Colorful error message
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error,
                                        color: Colors.red.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        // This prevents overflow
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 32),

                              // Colorful gradient login button
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryColor, _accentColor],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Colorful back button
                              Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(color: _primaryColor),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: Text(
                                    'Back to Home',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              // Colorful help text
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info,
                                      color: Colors.blue.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      // This prevents overflow
                                      child: Text(
                                        'Use your assigned credentials to access the system',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
