import "package:flutter/material.dart";
import "package:flutter/gestures.dart";
import "package:flutter/services.dart"; // 👈 for keyboard keys
import "package:url_launcher/url_launcher.dart";
import "package:provider/provider.dart";
import "package:pos_system/core/services/auth_service.dart";

class SubmitIntent extends Intent {
  const SubmitIntent();
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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

  // 👇 Focus nodes for keyboard navigation
  final _usernameNode = FocusNode();
  final _passwordNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Colors
  static const Color _bg = Color(0xFF0D1B2A);
  static const Color _cardBgTop = Color(0xFFFFFFFF);
  static const Color _cardBgBottom = Color(0xFFF7F8FA);
  static const Color _inputFill = Color(0xFFF3F4F6);
  static const Color _border = Color(0xFFDFE3EA);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final auth = Provider.of<AuthService>(context, listen: false);

    try {
      final success = await auth.login(username, password);
      if (!success) {
        setState(() => _error = "Incorrect username or password. Please try again.");
        return;
      }

      final role = auth.currentUser?.role ?? "";
      if (!mounted) return;

      switch (role) {
        case "StockKeeper":
          Navigator.pushReplacementNamed(context, "/stockkeeper");
          break;
        case "Cashier":
          Navigator.pushReplacementNamed(context, "/cashier");
          break;
        case "Admin":
          Navigator.pushReplacementNamed(context, "/admin");
          break;
        case "Manager":
          Navigator.pushReplacementNamed(context, "/manager");
          break;
        default:
          setState(() => _error = "Your account role is not recognized. Contact admin.");
          auth.logout();
      }
    } catch (_) {
      setState(() => _error = "Login failed. Please check your connection and try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callHotline(String tel) async {
    final uri = Uri(scheme: 'tel', path: tel);
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Container(
        color: _bg,
        child: SafeArea(
          // 🔑 Keyboard handling wrapper
          child: Shortcuts(
            shortcuts: <ShortcutActivator, Intent>{
              // Move focus with arrow keys
              const SingleActivator(LogicalKeyboardKey.arrowDown): const NextFocusIntent(),
              const SingleActivator(LogicalKeyboardKey.arrowUp): const PreviousFocusIntent(),
              // Submit with Enter / Numpad Enter
              const SingleActivator(LogicalKeyboardKey.enter): const SubmitIntent(),
              const SingleActivator(LogicalKeyboardKey.numpadEnter): const SubmitIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                NextFocusIntent: CallbackAction<NextFocusIntent>(
                  onInvoke: (intent) {
                    FocusScope.of(context).nextFocus();
                    return null;
                  },
                ),
                PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
                  onInvoke: (intent) {
                    FocusScope.of(context).previousFocus();
                    return null;
                  },
                ),
                SubmitIntent: CallbackAction<SubmitIntent>(
                  onInvoke: (intent) {
                    _submitLogin();
                    return null;
                  },
                ),
              },
              child: FocusTraversalGroup(
                policy: WidgetOrderTraversalPolicy(),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      "Tharu Shop",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),

                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isWide ? 460 : double.infinity,
                              ),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  side: const BorderSide(color: Colors.white24),
                                ),
                                elevation: 14,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [_cardBgTop, _cardBgBottom],
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 32,
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            "Sign In",
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            "Enter your credentials to continue",
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 28),

                                          // Username
                                          TextFormField(
                                            focusNode: _usernameNode, // 👈
                                            controller: _usernameController,
                                            cursorColor: Colors.black,
                                            style: const TextStyle(color: Colors.black),
                                            decoration: InputDecoration(
                                              labelText: "Username",
                                              labelStyle: const TextStyle(color: Colors.black54),
                                              prefixIcon: const Icon(Icons.person_outline, color: Colors.black),
                                              filled: true,
                                              fillColor: _inputFill,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: _border),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: _border),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: Colors.black, width: 1.5),
                                              ),
                                            ),
                                            // Pressing Enter here can also submit (handled globally),
                                            // but we make UX nicer: Enter moves to password first.
                                            onFieldSubmitted: (_) => _passwordNode.requestFocus(),
                                            textInputAction: TextInputAction.next,
                                            validator: (v) => (v == null || v.isEmpty) ? "Enter username" : null,
                                          ),

                                          const SizedBox(height: 16),

                                          // Password
                                          TextFormField(
                                            focusNode: _passwordNode, // 👈
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            cursorColor: Colors.black,
                                            style: const TextStyle(color: Colors.black),
                                            decoration: InputDecoration(
                                              labelText: "Password",
                                              labelStyle: const TextStyle(color: Colors.black54),
                                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.black),
                                              suffixIcon: IconButton(
                                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                                icon: Icon(
                                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: _inputFill,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: _border),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: _border),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: Colors.black, width: 1.5),
                                              ),
                                            ),
                                            onFieldSubmitted: (_) => _submitLogin(), // 👈 Enter submits
                                            textInputAction: TextInputAction.done,
                                            validator: (v) => (v == null || v.isEmpty) ? "Enter password" : null,
                                          ),

                                          if (_error != null) ...[
                                            const SizedBox(height: 14),
                                            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                                          ],

                                          const SizedBox(height: 22),

                                          SizedBox(
                                            width: double.infinity,
                                            height: 52,
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : _submitLogin,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      width: 22, height: 22,
                                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                                    )
                                                  : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          TextButton(
                                            onPressed: () {
                                              // TODO: Forgot password flow
                                            },
                                            child: const Text("Forgot password?", style: TextStyle(color: Colors.black54)),
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

                    // Footer
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                          children: [
                            const TextSpan(text: "Powered by "),
                            TextSpan(
                              text: "AASA IT",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                                decoration: TextDecoration.none,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _openUrl("https://aasait.lk"),
                            ),
                            const TextSpan(text: " • Hotline: "),
                            TextSpan(
                              text: "+94-7X-XXXXXXX",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                                decoration: TextDecoration.none,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _callHotline("+947XXXXXXXX"),
                            ),
                            const TextSpan(text: "\n© 2025 AASA IT Solutions. All Rights Reserved."),
                          ],
                        ),
                      ),
                    ),
                  ],
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
    _usernameNode.dispose();
    _passwordNode.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
