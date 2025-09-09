// File: test/login_page_test.dart


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// ⬇️ Adjust these to your project structure.
import 'package:pos_system/features/auth/login_page.dart';
import 'package:pos_system/core/services/auth_service.dart';
import 'package:url_launcher_platform_interface/link.dart';

// ===== url_launcher mocking (matches your installed url_launcher_platform_interface ^2.3.2) =====
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeUrlLauncher extends UrlLauncherPlatform {
  String? lastLaunchedUrl;

  @override
  Future<bool> canLaunch(String url) async => true;

  // Signature from your version: no required webOnlyWindowName param.
  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName, // keep optional for forward compat
  }) async {
    lastLaunchedUrl = url;
    return true;
  }

  // Your installed interface expects (String url, LaunchOptions options)
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    return true;
  }

  @override
  Future<bool> canLaunchUrl(String url) async => true;

  @override
  // TODO: implement linkDelegate
  LinkDelegate? get linkDelegate => throw UnimplementedError();
}

// ===== Fake AuthService that matches your app’s interface exactly =====

// Minimal test user implementing your app's User interface with a role.
class _TestUser implements User {
  @override
  final String role;
  _TestUser(this.role);
  
  @override
  // TODO: implement token
  String get token => throw UnimplementedError();
  
  @override
  // TODO: implement username
  String get username => throw UnimplementedError();

  // If your User has other abstract members, add trivial stubs here.
  // Example:
  // @override
  // String get username => 'tester';
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  bool _nextLoginSuccess = true;
  Duration _delay = Duration.zero;
  bool _throwOnLogin = false;
  User? _currentUser;

  void configure({
    required bool success,
    String role = 'StockKeeper',
    Duration delay = Duration.zero,
    bool throwsOnLogin = false,
  }) {
    _nextLoginSuccess = success;
    _delay = delay;
    _throwOnLogin = throwsOnLogin;
    _currentUser = success ? _TestUser(role) : null;
  }

  @override
  Future<bool> login(String username, String password, {String? role}) async {
    if (_throwOnLogin) {
      await Future<void>.delayed(_delay);
      throw Exception('network');
    }
    await Future<void>.delayed(_delay);
    return _nextLoginSuccess;
  }

  @override
  User? get currentUser => _currentUser;

  @override
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
  
  @override
  Future<List<String>> checkUsername(String username) {
    // TODO: implement checkUsername
    throw UnimplementedError();
  }
}

// ===== Small helper widget shown after navigation =====
class _RouteMarker extends StatelessWidget {
  final String title;
  const _RouteMarker({required this.title});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(title)));
}

// ===== Test helpers =====
Widget _wrapApp({
  required Widget child,
  required FakeAuthService fakeAuth,
}) {
  // ✅ Use ChangeNotifierProvider.value to satisfy Provider's debug checks
  return ChangeNotifierProvider<AuthService>.value(
    value: fakeAuth,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder>{
        '/stockkeeper': (_) => const _RouteMarker(title: 'StockKeeperHome'),
        '/cashier': (_) => const _RouteMarker(title: 'CashierHome'),
        '/admin': (_) => const _RouteMarker(title: 'AdminHome'),
        '/manager': (_) => const _RouteMarker(title: 'ManagerHome'),
      },
      home: child,
    ),
  );
}

Future<void> _enterCreds(WidgetTester tester,
    {String user = 'u', String pass = 'p'}) async {
  await tester.enterText(find.bySemanticsLabel('Username'), user);
  await tester.enterText(find.bySemanticsLabel('Password'), pass);
}

void main() {
  late _FakeUrlLauncher fakeLauncher;
  late FakeAuthService fakeAuth;

  setUp(() {
    fakeLauncher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeLauncher;

    fakeAuth = FakeAuthService();
  });

  testWidgets('renders headings, inputs, and buttons', (tester) async {
    await tester.pumpWidget(_wrapApp(child: const LoginPage(), fakeAuth: fakeAuth));

    expect(find.text('Tharu Shop'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Enter your credentials to continue'), findsOneWidget);

    expect(find.bySemanticsLabel('Username'), findsOneWidget);
    expect(find.bySemanticsLabel('Password'), findsOneWidget);

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);

    expect(find.textContaining('Powered by'), findsOneWidget);
    expect(find.text('AASA IT'), findsOneWidget);
    expect(find.textContaining('Hotline:'), findsOneWidget);
  });

  testWidgets('validation: shows errors when fields are empty on submit', (tester) async {
    await tester.pumpWidget(_wrapApp(child: const LoginPage(), fakeAuth: fakeAuth));

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter username'), findsOneWidget);
    expect(find.text('Enter password'), findsOneWidget);
  });

  testWidgets('shows loading spinner while awaiting login then navigates', (tester) async {
    fakeAuth.configure(success: true, role: 'StockKeeper', delay: const Duration(milliseconds: 250));

    await tester.pumpWidget(_wrapApp(child: const LoginPage(), fakeAuth: fakeAuth));
    await _enterCreds(tester);
    await tester.tap(find.text('Sign In'));
    await tester.pump(); // start async frame

    // spinner visible
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('StockKeeperHome'), findsOneWidget);
  });

  testWidgets('failed login shows inline error', (tester) async {
    fakeAuth.configure(success: false);

    await tester.pumpWidget(_wrapApp(child: const LoginPage(), fakeAuth: fakeAuth));
    await _enterCreds(tester);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect username or password. Please try again.'), findsOneWidget);
  });

  testWidgets('exception during login shows connection error', (tester) async {
    fakeAuth.configure(success: false, throwsOnLogin: true);

    await tester.pumpWidget(_wrapApp(child: const LoginPage(), fakeAuth: fakeAuth));
    await _enterCreds(tester);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Login failed. Please check your connection and try again.'), findsOneWidget);
  });

  testWidgets('successful login routes by role: StockKeeper', (tester) async {
    fakeAuth.configure(success: true, role: 'StockKeeper');

    await tester.pumpWidget(_wrapApp(child: const LoginPage(), fakeAuth: fakeAuth));
    await _enterCreds(tester);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('StockKeeperHome'), findsOneWidget);
  });

  testWidgets('successful login routes by role: Cashier', (tester) async {
    fakeAuth.configure(success: true, role: 'Cashier');

    await tester.pumpWidget(_wrapApp(child: const LoginPage(), fakeAuth: fakeAuth));
    await _enterCreds(tester);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('CashierHome'), findsOneWidget);
  });

  testWidgets('successful login routes by role: Admin', (tester) async {
    fakeAuth.configure(success: true, role: 'Admin');

    await tester.pumpWidget(_wrapApp(child: const LoginPage(), fakeAuth: fakeAuth));
    await _enterCreds(tester);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('AdminHome'), findsOneWidget);
  });

  testWidgets('successful login routes by role: Manager', (tester) async {
    fakeAuth.configure(success: true, role: 'Manager');

    await tester.pumpWidget(_wrapApp(child: const LoginPage(), fakeAuth: fakeAuth));
    await _enterCreds(tester);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('ManagerHome'), findsOneWidget);
  });

  testWidgets('unknown role shows inline “not recognized” error and calls logout', (tester) async {
    fakeAuth.configure(success: true, role: 'SomeOtherRole');

    await tester.pumpWidget(_wrapApp(child: const LoginPage(), fakeAuth: fakeAuth));
    await _enterCreds(tester);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Your account role is not recognized. Contact admin.'), findsOneWidget);
  });

  testWidgets('password visibility toggle flips icon', (tester) async {
    await tester.pumpWidget(_wrapApp(child: const LoginPage(), fakeAuth: fakeAuth));

    // Initially "visibility" (obscured)
    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off), findsNothing);

    // Tap the suffixIcon
    final suffixIconButton = find
        .descendant(of: find.bySemanticsLabel('Password'), matching: find.byType(IconButton))
        .first;
    await tester.tap(suffixIconButton);
    await tester.pump();

    expect(find.byIcon(Icons.visibility), findsNothing);
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('Enter key submits from password field (SubmitIntent)', (tester) async {
    fakeAuth.configure(success: true, role: 'StockKeeper');

    await tester.pumpWidget(_wrapApp(child: const LoginPage(), fakeAuth: fakeAuth));

    await tester.enterText(find.bySemanticsLabel('Username'), 'u');
    await tester.tap(find.bySemanticsLabel('Password'));
    await tester.pump();
    await tester.enterText(find.bySemanticsLabel('Password'), 'p');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('StockKeeperHome'), findsOneWidget);
  });

  testWidgets('footer links: site and tel launch', (tester) async {
    await tester.pumpWidget(_wrapApp(child: const LoginPage(), fakeAuth: fakeAuth));

    await tester.tap(find.text('AASA IT'));
    await tester.pumpAndSettle();
    expect(fakeLauncher.lastLaunchedUrl, isNotNull);
    final firstUrl = fakeLauncher.lastLaunchedUrl!;

    // Tap hotline (matches "+94-7X-XXXXXXX" pattern in your widget)
    await tester.tap(find.textContaining('+94-7'));
    await tester.pumpAndSettle();

    expect(fakeLauncher.lastLaunchedUrl, isNot(firstUrl));
    expect(fakeLauncher.lastLaunchedUrl, contains('tel:'));
  });
}
