import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_app/core/entities/app_user.dart';
import 'package:travel_app/core/utils/result.dart';
import 'package:travel_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:travel_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:travel_app/main.dart';

/// Stands in for the Keycloak PKCE flow (which needs a real browser):
/// every session starts signed out.
class FakeAuthRepository implements AuthRepository {
  @override
  Future<Result<AppUser?>> login({
    String? loginHint,
    String? identityProvider,
  }) async => const Success(null);

  @override
  Future<Result<AppUser?>> restoreSession() async => const Success(null);

  @override
  Future<Result<void>> logout() async => const Success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App boots to the login screen when signed out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const TravelApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });
}
