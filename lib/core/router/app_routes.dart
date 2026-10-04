
class AppRoutes {
  AppRoutes._();

  // ---------------- Auth ----------------
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const changePassword = '/change-password';

  // ---------------- Shell ----------------
  static const home = '/home';

  // ---------------- Destination ----------------
  static const destinationForm = '/destination-form';
  static const destinationTemplate = '/destination/:id';
  static String destination(String id) => '/destination/$id';

  // ---------------- Tour ----------------
  static const tourForm = '/tour-form';
  static const tourTemplate = '/tour/:id';
  static String tour(String id) => '/tour/$id';

  // ---------------- Schedule ----------------
  static const scheduleFormTemplate = '/schedule-form/:tourId';
  static String scheduleForm(String tourId) => '/schedule-form/$tourId';
  static const String mySchedules = '/my-schedules';

  // ---------------- Guide ----------------
  static const guideForm = '/guide-form';
  static const guideTemplate = '/guide/:id';
  static String guide(String id) => '/guide/$id';

  // ---------------- Booking ----------------
  static const bookings = '/bookings';
  static const bookingTemplate = '/booking/:id';
  static String booking(String id) => '/booking/$id';
  static const addParticipantTemplate = '/booking/:id/add-participant';
  static String addParticipant(String bookingId) =>
      '/booking/$bookingId/add-participant';
  static const createBookingTemplate = '/create-booking/:scheduleId';
  static String createBooking(String scheduleId) =>
      '/create-booking/$scheduleId';

      static const bookingParticipantsTemplate =
    '/booking/:id/participants';

static String bookingParticipants(String id) =>
    '/booking/$id/participants';

  // ---------------- Payment ----------------
  static const paymentTemplate = '/payment/:bookingId';
  static String payment(String bookingId) => '/payment/$bookingId';
  static const paymentFailedTemplate = '/payment-failed/:bookingId';
  static String paymentFailed(String bookingId, {bool cancelled = false}) =>
      '/payment-failed/$bookingId${cancelled ? '?cancelled=true' : ''}';

  // ---------------- Review ----------------
  static const addReviewTemplate = '/add-review/:tourId/:bookingId';
  static String addReview(String tourId, String bookingId) =>
      '/add-review/$tourId/$bookingId';
  static const myReviews = '/my-reviews';

  // ---------------- Profile ----------------
  static const editProfile = '/edit-profile';
  static const contactUs = '/contact-us';

  // ---------------- Admin ----------------
  static const adminUsers = '/admin/users';
  static const adminCreateUser = '/admin/create-user';
  static const adminReports = '/admin/reports';
  static const adminBookings = '/admin/bookings';
}
