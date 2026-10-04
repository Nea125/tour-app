import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_app/features/booking/presentation/screens/booking_participants_screen.dart';
import 'package:travel_app/features/schedule/presentation/screens/assigned_schedule.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/booking/presentation/screens/add_participant_screen.dart';
import '../../features/booking/presentation/screens/admin_bookings_screen.dart';
import '../../features/booking/presentation/screens/booking_detail_screen.dart';
import '../../features/booking/presentation/screens/create_booking_screen.dart';
import '../../features/booking/presentation/screens/my_bookings_screen.dart';
import '../../features/booking/presentation/screens/payment_failed_screen.dart';
import '../../features/booking/presentation/screens/payment_screen.dart';
import '../../features/destination/domain/entities/destination.dart';
import '../../features/destination/presentation/screens/destination_detail_screen.dart';
import '../../features/destination/presentation/screens/destination_form_screen.dart';
import '../../features/guide/domain/entities/tour_guide.dart';
import '../../features/guide/presentation/screens/guide_detail_screen.dart';
import '../../features/guide/presentation/screens/guide_form_screen.dart';
import '../../features/home/presentation/screens/contact_us_screen.dart';
import '../../features/home/presentation/screens/home_shell.dart';
import '../../features/review/presentation/screens/add_review_screen.dart';
import '../../features/review/presentation/screens/my_reviews_screen.dart';
import '../../features/review/presentation/screens/report_dashboard_screen.dart';
import '../../features/schedule/domain/entities/tour_schedule.dart';
import '../../features/schedule/presentation/screens/schedule_form_screen.dart';
import '../../features/tour/domain/entities/tour.dart';
import '../../features/tour/presentation/screens/tour_detail_screen.dart';
import '../../features/tour/presentation/screens/tour_form_screen.dart';
import '../../features/user/presentation/screens/create_user_screen.dart';
import '../../features/user/presentation/screens/edit_profile_screen.dart';
import '../../features/user/presentation/screens/user_list_screen.dart';
import 'app_routes.dart';

const _authRoutes = [
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
];

/// Bridges Riverpod's async auth state into a [Listenable] so GoRouter can
/// re-run its redirect logic whenever sign-in state changes, without
/// rebuilding the GoRouter instance itself (which would reset navigation).
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) {
      final previousUser = previous?.valueOrNull;
      final nextUser = next.valueOrNull;
      // Each fresh sign-in should land on the Home tab rather than wherever
      // the previous session's tab index (e.g. Profile) was left.
      if (nextUser != null && previousUser?.id != nextUser.id) {
        ref.read(homeTabIndexProvider.notifier).state = 0;
      }
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      if (authState.isLoading && !authState.hasValue) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isLoggedIn = authState.valueOrNull != null;

      if (!isLoggedIn) {
        return _authRoutes.contains(loc) ? null : AppRoutes.login;
      }

      if (_authRoutes.contains(loc) || loc == AppRoutes.splash) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: AppRoutes.destinationTemplate,
        builder: (context, state) =>
            DestinationDetailScreen(destinationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.destinationForm,
        builder: (context, state) =>
            DestinationFormScreen(destination: state.extra as Destination?),
      ),
      GoRoute(
        path: AppRoutes.tourTemplate,
        builder: (context, state) =>
            TourDetailScreen(tourId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.tourForm,
        builder: (context, state) => TourFormScreen(tour: state.extra as Tour?),
      ),
      GoRoute(
        path: AppRoutes.scheduleFormTemplate,
        builder: (context, state) => ScheduleFormScreen(
          tourId: state.pathParameters['tourId']!,
          schedule: state.extra as TourSchedule?,
        ),
      ),
      GoRoute(
        path: AppRoutes.guideTemplate,
        builder: (context, state) =>
            GuideDetailScreen(guideId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.guideForm,
        builder: (context, state) =>
            GuideFormScreen(guide: state.extra as TourGuide?),
      ),
      GoRoute(
        path: AppRoutes.bookings,
        builder: (context, state) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingTemplate,
        builder: (context, state) =>
            BookingDetailScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.addParticipantTemplate,
        builder: (context, state) =>
            AddParticipantScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.createBookingTemplate,
        builder: (context, state) => CreateBookingScreen(
          scheduleId: state.pathParameters['scheduleId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentTemplate,
        builder: (context, state) =>
            PaymentScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: AppRoutes.paymentFailedTemplate,
        builder: (context, state) => PaymentFailedScreen(
          bookingId: state.pathParameters['bookingId']!,
          cancelled: state.uri.queryParameters['cancelled'] == 'true',
          message: state.extra as String?,
        ),
      ),
      GoRoute(
        path: AppRoutes.addReviewTemplate,
        builder: (context, state) => AddReviewScreen(
          tourId: state.pathParameters['tourId']!,
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.myReviews,
        builder: (context, state) => const MyReviewsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.contactUs,
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (context, state) => const UserListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCreateUser,
        builder: (context, state) => const CreateUserScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminReports,
        builder: (context, state) => const ReportDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminBookings,
        builder: (context, state) => const AdminBookingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.mySchedules,
        builder: (context, state) => const MyAssignedSchedulesScreen(),
      ),
      GoRoute(
  path: AppRoutes.bookingParticipantsTemplate,
  builder: (context, state) {
    return BookingParticipantsScreen(
      bookingId: state.pathParameters['id']!,
    );
  },
),
    ],
  );
});
