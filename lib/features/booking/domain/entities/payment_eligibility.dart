

import 'package:equatable/equatable.dart';

/// Result of the backend's `GET /payments/booking/{id}/can-pay` check.
class PaymentEligibility extends Equatable {
  final bool canPay;
  final String message;

  const PaymentEligibility({required this.canPay, required this.message});

  @override
  List<Object?> get props => [canPay, message];
}