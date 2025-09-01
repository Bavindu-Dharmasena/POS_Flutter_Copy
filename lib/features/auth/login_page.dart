import "package:flutter/material.dart";
import "package:flutter/gestures.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:url_launcher/url_launcher.dart";

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _error;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Focus nodes for keyboard navigation
  final _emailNode = FocusNode();
  final _passwordNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Colors (your palette)
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

  @override
  void dispose() {
    _animationController.dispose();
    _emailNode.dispose();
    _passwordNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return "Enter email";
    // very light validation
    final s = v.trim();
    if (!s.contains("@") || !s.contains(".")) return "Enter a valid email";
    return null;
  }

  String? _validatePassword(String? v) =>
      (v == null || v.isEmpty) ? "Enter password" : null;

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final auth = Provider.of<AuthService>(context, listen: false);

    try {
      // AuthService.login throws on failure, returns void on success
      await auth.login(email, password);

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
          await auth.logout();
      }
    } catch (e) {
      setState(() => _error = "Login failed. Please check your credentials/connection.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          child: Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
              SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
              SingleActivator(LogicalKeyboardKey.enter): SubmitIntent(),
              SingleActivator(LogicalKeyboardKey.numpadEnter): SubmitIntent(),
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

                                          // Email
                                          TextFormField(
                                            focusNode: _emailNode,
                                            controller: _emailController,
                                            keyboardType: TextInputType.emailAddress,
                                            cursorColor: Colors.black,
                                            style: const TextStyle(color: Colors.black),
                                            decoration: InputDecoration(
                                              labelText: "Email",
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
                                            onFieldSubmitted: (_) => _passwordNode.requestFocus(),
                                            textInputAction: TextInputAction.next,
                                            validator: _validateEmail,
                                          ),

                                          const SizedBox(height: 16),

                                          // Password
                                          TextFormField(
                                            focusNode: _passwordNode,
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
                                            onFieldSubmitted: (_) => _submitLogin(),
                                            textInputAction: TextInputAction.done,
                                            validator: _validatePassword,
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
                                              // TODO: forgot password
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
}
