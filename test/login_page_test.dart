import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:pos_system/features/auth/login_page.dart';
import 'package:pos_system/core/services/auth_service.dart';

import 'mocks/mock_auth_service.mocks.dart'; // generated with build_runner

void main() {
  late MockAuthService mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockAuthService();
    mockUser = MockUser();
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<AuthService>.value(
      value: mockAuth,
      child: MaterialApp(
        home: const LoginPage(role: 'Cashier'),
        routes: {
          '/cashier': (_) => const Scaffold(body: Text('Cashier Dashboard')),
          '/admin': (_) => const Scaffold(body: Text('Admin Dashboard')),
          '/manager': (_) => const Scaffold(body: Text('Manager Dashboard')),
          '/stockkeeper': (_) => const Scaffold(body: Text('Stockkeeper Dashboard')),
        },
      ),
    );
  }

  testWidgets('Login succeeds and navigates if role matches', (WidgetTester tester) async {
    // Simulate login success and correct role
    when(mockAuth.login(any, any)).thenAnswer((_) async => true);
    when(mockUser.role).thenReturn('Cashier');
    when(mockAuth.currentUser).thenReturn(mockUser);

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextField).first, 'cashier');
    await tester.enterText(find.byType(TextField).last, 'cash123');

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    verify(mockAuth.login('cashier', 'cash123')).called(1);
    expect(find.text('Cashier Dashboard'), findsOneWidget);
  });

  testWidgets('Login fails with wrong credentials', (WidgetTester tester) async {
    when(mockAuth.login(any, any)).thenAnswer((_) async => false);

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextField).first, 'wronguser');
    await tester.enterText(find.byType(TextField).last, 'wrongpass');

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid username or password'), findsOneWidget);
  });

  testWidgets('Login fails if role mismatches', (WidgetTester tester) async {
    when(mockAuth.login(any, any)).thenAnswer((_) async => true);
    when(mockUser.role).thenReturn('Admin'); // incorrect role for 'Cashier' login
    when(mockAuth.currentUser).thenReturn(mockUser);

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextField).first, 'admin');
    await tester.enterText(find.byType(TextField).last, 'admin123');

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('You are not authorized for this role.'), findsOneWidget);
  });
}
