// test/login_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:pos_system/features/auth/login_page.dart';
import 'package:pos_system/core/services/auth_service.dart';

import 'mocks/mock_auth_service.mocks.dart';

void main() {
  late MockAuthService mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockAuthService();
    mockUser = MockUser();
  });

  Widget createWidgetUnderTest({String role = 'Cashier'}) {
    return ChangeNotifierProvider<AuthService>.value(
      value: mockAuth,
      child: MaterialApp(
        home: LoginPage(role: role),
        routes: {
          '/cashier': (_) => const Scaffold(body: Text('Cashier Dashboard')),
          '/admin': (_) => const Scaffold(body: Text('Admin Dashboard')),
          '/manager': (_) => const Scaffold(body: Text('Manager Dashboard')),
          '/stockkeeper': (_) =>
              const Scaffold(body: Text('Stockkeeper Dashboard')),
        },
      ),
    );
  }

  Finder usernameField() => find.byType(TextFormField).at(0);
  Finder passwordField() => find.byType(TextFormField).at(1);
  Finder signInButton() => find.text('Sign In');

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    required String username,
    required String password,
  }) async {
    await tester.enterText(usernameField(), username);
    await tester.enterText(passwordField(), password);
    await tester.tap(signInButton());
    await tester.pumpAndSettle();
  }

  testWidgets('Login succeeds and navigates if role matches', (
    WidgetTester tester,
  ) async {
    when(mockAuth.login(any, any)).thenAnswer((_) async => true);
    when(mockUser.role).thenReturn('Cashier');
    when(mockAuth.currentUser).thenReturn(mockUser);

    await tester.pumpWidget(createWidgetUnderTest(role: 'Cashier'));
    await tester.pump();

    await fillAndSubmit(tester, username: 'cashier', password: 'cash123');

    verify(mockAuth.login('cashier', 'cash123')).called(1);
    expect(find.text('Cashier Dashboard'), findsOneWidget);
  });

  testWidgets('Login fails with wrong credentials shows correct error', (
    WidgetTester tester,
  ) async {
    when(mockAuth.login(any, any)).thenAnswer((_) async => false);

    await tester.pumpWidget(createWidgetUnderTest(role: 'Cashier'));
    await tester.pump();

    await fillAndSubmit(tester, username: 'wronguser', password: 'wrongpass');

    expect(
      find.text('Incorrect username or password. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('Login fails if role mismatches shows access denied', (
    WidgetTester tester,
  ) async {
    when(mockAuth.login(any, any)).thenAnswer((_) async => true);
    when(mockUser.role).thenReturn('Admin');
    when(mockAuth.currentUser).thenReturn(mockUser);

    await tester.pumpWidget(createWidgetUnderTest(role: 'Cashier'));
    await tester.pump();

    await fillAndSubmit(tester, username: 'admin', password: 'admin123');

    expect(
      find.text('Access denied: You are not authorized for the Cashier role.'),
      findsOneWidget,
    );
  });
}
