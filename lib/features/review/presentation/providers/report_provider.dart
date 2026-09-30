import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/base_api_service.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/report_remote_datasource.dart';
import '../../domain/entities/report_summary.dart';

final reportRemoteDataSourceProvider = Provider<ReportRemoteDataSource>(
  (ref) => ReportRemoteDataSource(ref.watch(baseApiServiceProvider)),
);

final reportSummaryProvider = FutureProvider<ReportSummary>((ref) async {
  final dataSource = ref.watch(reportRemoteDataSourceProvider);
  final result = await guardResult(dataSource.getReportSummary);
  return result.when(success: (data) => data, failure: (f) => throw f);
});
