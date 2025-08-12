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
        return [Colors.red.shade400, Colors.pink.shade600, Colors.purple.shade400];
      case 'Manager': 
        return [Colors.purple.shade400, Colors.indigo.shade500, Colors.blue.shade400];
      case 'Cashier': 
        return [Colors.green.shade400, Colors.teal.shade500, Colors.cyan.shade400];
      case 'StockKeeper': 
        return [Colors.yellow.shade400, Colors.amber.shade500, Colors.orange.shade400];
      default: 
        return [Colors.orange.shade400, Colors.red.shade400, Colors.pink.shade400];
    }
  }

  Color get _primaryColor {
    switch (widget.role) {
      case 'Admin': return Colors.red.shade600;
      case 'Manager': return Colors.purple.shade600;
      case 'Cashier': return Colors.green.shade600;
      case 'StockKeeper': return Colors.amber.shade600;
      default: return Colors.indigo.shade600;
    }
  }

  Color get _accentColor {
    switch (widget.role) {
      case 'Admin': return Colors.pink.shade400;
      case 'Manager': return Colors.indigo.shade400;
      case 'Cashier': return Colors.teal.shade400;
      case 'StockKeeper': return Colors.yellow.shade400;
      default: return Colors.orange.shade400;
    }
  }

  IconData get _roleIcon {
    switch (widget.role) {
      case 'Admin': return Icons.admin_panel_settings;
      case 'Manager': return Icons.manage_accounts;
      case 'Cashier': return Icons.point_of_sale;
      case 'StockKeeper': return Icons.inventory;
      default: return Icons.person;
    }
  }

  // Submit login credentials
  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final auth = Provider.of<AuthService>(context, listen: false);

    try {
      bool success = await auth.login(username, password);

      if (success) {
        final loggedInRole = auth.currentUser!.role;

        // Only allow login if the role matches
        if (loggedInRole != widget.role) {
          setState(() => _error = "Access denied: You are not authorized for the ${widget.role} role.");
          auth.logout();
          return;
        }

        // Navigate to the correct dashboard
        switch (loggedInRole) {
          case 'StockKeeper':
            Navigator.pushReplacementNamed(context, '/stockkeeper');
            break;
          case 'Cashier':
            Navigator.pushReplacementNamed(context, '/cashier');
            break;
          case 'Admin':
            Navigator.pushReplacementNamed(context, '/admin');
            break;
          case 'Manager':
            Navigator.pushReplacementNamed(context, '/manager');
            break;
        }
      } else {
        setState(() => _error = 'Incorrect username or password. Please try again.');
      }
    } catch (e) {
      setState(() => _error = 'Login failed. Please check your connection and try again.');
    } finally {
      setState(() => _isLoading = false);
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 20,
                    shadowColor: _primaryColor.withOpacity(0.4),
                    color: Colors.white,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
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
                                    colors: _roleGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Icon(
                                        _roleIcon,
                                        size: 48,
                                        color: _primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '${widget.role} Login',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                            color: Colors.black26,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Welcome! Please enter your credentials',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Colorful username field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    colors: [
                                      _accentColor.withOpacity(0.1),
                                      _primaryColor.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _usernameController,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your username';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    labelStyle: TextStyle(
                                      fontSize: 16,
                                      color: _primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _accentColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.person_outline, color: _primaryColor),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(color: _accentColor.withOpacity(0.3), width: 2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(color: _primaryColor, width: 3),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Colorful password field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    colors: [
                                      _primaryColor.withOpacity(0.1),
                                      _accentColor.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submitLogin(),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(
                                      fontSize: 16,
                                      color: _primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.lock_outline, color: _primaryColor),
                                    ),
                                    suffixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _accentColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                          color: _primaryColor,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                        tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3), width: 2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(color: _primaryColor, width: 3),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                              
                              // Colorful error message
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.shade50,
                                        Colors.orange.shade50,
                                      ],
                                    ),
                                    border: Border.all(color: Colors.red.shade300, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.error_outline, color: Colors.red.shade700),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
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
                                    colors: _roleGradient,
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
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
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  child: _isLoading
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text('Logging in...', style: TextStyle(color: Colors.white)),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.login, size: 22, color: Colors.white),
                                            SizedBox(width: 12),
                                            Text('Login', style: TextStyle(color: Colors.white)),
                                          ],
                                        ),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Colorful back button
                              Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _accentColor, width: 2),
                                  gradient: LinearGradient(
                                    colors: [
                                      _accentColor.withOpacity(0.1),
                                      _primaryColor.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: _primaryColor,
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.arrow_back, size: 18, color: _primaryColor),
                                      const SizedBox(width: 8),
                                      Text('Back to Role Selection', style: TextStyle(color: _primaryColor)),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Colorful help text
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade50,
                                      Colors.cyan.shade50,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.help_outline, color: Colors.blue.shade600, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Having trouble? Ask your system administrator for help.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
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