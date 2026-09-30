// ignore_for_file: constant_identifier_names

import '../../../../core/network/base_api_service.dart';
import '../../../../core/network/http_method.dart';
import '../../domain/entities/booking_participant.dart';
import '../models/booking_participant_model.dart';

/// `/participants` endpoints of the tour-management API.
class ParticipantRemoteDataSource {
  static const String _PARTICIPANTS = "/participants";
  static const String _BOOKINGS = "/bookings";

  final BaseApiService api;
  ParticipantRemoteDataSource(this.api);

  /// The API can't filter participants by booking, so filter here.
  Future<List<BookingParticipantModel>> getParticipantsByBookingId(
    String bookingId,
  ) async {
    final all = await api.getAllPages(
      path: _PARTICIPANTS,
      fromJson: BookingParticipantModel.fromApi,
    );
    return all.where((p) => p.bookingId == bookingId).toList();
  }

  Future<int> _declaredPeople(String bookingId) {
    return api.onRequest(
      path: '$_BOOKINGS/$bookingId',
      method: HTTPMethod.GET,
      onSuccess: (r) =>
          (BaseApiService.dataOf(r)['numberOfPeople'] as num).toInt(),
    );
  }

  Future<BookingParticipantModel> addParticipant(
    BookingParticipant participant,
  ) async {
    final declared = await _declaredPeople(participant.bookingId);
    final existing = await getParticipantsByBookingId(participant.bookingId);
    if (existing.length >= declared) {
      throw Exception(
        'This booking already has the declared number of participants ($declared)',
      );
    }
    return api.onRequest(
      path: _PARTICIPANTS,
      method: HTTPMethod.POST,
      data: BookingParticipantModel.fromEntity(participant).toApi(),
      onSuccess: (r) =>
          BookingParticipantModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  Future<BookingParticipantModel> updateParticipant(
    BookingParticipant participant,
  ) {
    return api.onRequest(
      path: '$_PARTICIPANTS/${participant.id}',
      method: HTTPMethod.PUT,
      data: BookingParticipantModel.fromEntity(participant).toApi(),
      onSuccess: (r) =>
          BookingParticipantModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  Future<void> removeParticipant(String id) {
    return api.onRequest(
      path: '$_PARTICIPANTS/$id',
      method: HTTPMethod.DELETE,
      onSuccess: (_) {},
    );
  }

  Future<String?> checkEligibility(String bookingId) async {
    final declared = await _declaredPeople(bookingId);
    final count = (await getParticipantsByBookingId(bookingId)).length;
    if (count < declared) {
      return 'Add ${declared - count} more participant(s) to complete this booking.';
    }
    if (count > declared) {
      return 'Too many participants registered — remove ${count - declared}.';
    }
    return null;
  }
}
