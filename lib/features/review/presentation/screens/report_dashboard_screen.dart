import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../../booking/presentation/screens/my_bookings_screen.dart';
import '../../domain/entities/report_summary.dart';
import '../providers/report_provider.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class ReportDashboardScreen extends ConsumerWidget {
  const ReportDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(reportSummaryProvider),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (report) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(reportSummaryProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    label: 'Total Revenue',
                    value: Formatters.currency(report.totalRevenue),
                    icon: Icons.payments_outlined,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    label: 'Total Bookings',
                    value: '${report.totalBookings}',
                    icon: Icons.confirmation_number_outlined,
                    color: AppColors.info,
                  ),
                  _StatCard(
                    label: 'Total Tours',
                    value: '${report.totalTours}',
                    icon: Icons.card_travel_rounded,
                    color: AppColors.secondary,
                  ),
                  _StatCard(
                    label: 'Total Destinations',
                    value: '${report.totalDestinations}',
                    icon: Icons.map_outlined,
                    color: AppColors.info,
                  ),
                  _StatCard(
                    label: 'Avg. Rating',
                    value: report.averageRating.toStringAsFixed(1),
                    icon: Icons.star_rounded,
                    color: AppColors.warning,
                  ),
                  _StatCard(
                    label: 'Total Customers',
                    value: '${report.totalCustomers}',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.success,
                  ),
                  _StatCard(
                    label: 'Tour Guides',
                    value: '${report.totalGuides}',
                    icon: Icons.support_agent_rounded,
                    color: AppColors.error,
                  ),
                  _StatCard(
                    label: 'Upcoming Tours',
                    value: '${report.upcomingTours}',
                    icon: Icons.event_available_outlined,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    label: 'Completed Tours',
                    value: '${report.completedTours}',
                    icon: Icons.event_busy_outlined,
                    color: AppColors.textSecondary,
                  ),
                  _StatCard(
                    label: 'Cancelled Bookings',
                    value: '${report.cancelledBookings}',
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),
              const SectionHeader(title: 'Revenue Trend (Last 6 Months)'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s12,
                    AppSpacing.s20,
                    AppSpacing.s20,
                    AppSpacing.s12,
                  ),
                  child: SizedBox(
                    height: AppSpacing.s200,
                    child: _RevenueChart(data: report.monthlyRevenue),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              const SectionHeader(title: 'Bookings by Status'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Column(
                    children: report.bookingsByStatus.entries.map((entry) {
                      final total = report.totalBookings == 0
                          ? 1
                          : report.totalBookings;
                      final ratio = entry.value / total;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.s6,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: AppSpacing.s90,
                              child: Text(
                                entry.key.label,
                                style: const TextStyle(
                                  fontSize: AppFontSizes.f13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 14,
                                  backgroundColor: AppColors.divider,
                                  color: bookingStatusColor(entry.key),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s10),
                            SizedBox(
                              width: AppSpacing.s28,
                              child: Text(
                                '${entry.value}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppFontSizes.f13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              const SectionHeader(title: 'Top Performing Tours'),
              Card(
                child: Column(
                  children: report.topTours.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tour = entry.value;
                    return Column(
                      children: [
                        if (index != 0) const Divider(height: AppSpacing.s1),
                        ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: AppFontSizes.f12,
                              ),
                            ),
                          ),
                          title: Text(
                            tour.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${tour.bookings} bookings • ★ ${tour.rating.toStringAsFixed(1)}',
                          ),
                          trailing: Text(
                            Formatters.currency(tour.revenue),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              const SectionHeader(title: 'Top Destinations'),
              Card(
                child: Column(
                  children: report.topDestinations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final dest = entry.value;
                    return Column(
                      children: [
                        if (index != 0) const Divider(height: AppSpacing.s1),
                        ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.secondary.withValues(
                              alpha: 0.15,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: AppFontSizes.f12,
                              ),
                            ),
                          ),
                          title: Text(
                            dest.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: Text(
                            '${dest.bookings} bookings',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: AppFontSizes.f18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSizes.f12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<MonthlyRevenue> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxRevenue = data
        .map((d) => d.revenue)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = maxRevenue == 0 ? 100.0 : maxRevenue * 1.25;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[groupIndex].label}\n${Formatters.currency(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: AppFontSizes.f12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s8),
                  child: Text(
                    data[index].label,
                    style: const TextStyle(
                      fontSize: AppFontSizes.f11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].revenue,
                color: AppColors.primary,
                width: AppSpacing.s22,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
