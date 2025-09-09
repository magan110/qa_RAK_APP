import '../utils/app_logger.dart';

/// Business metrics data model
class BusinessMetrics {
  final int totalScans;
  final int redeemedPoints;
  final int activeCampaigns;
  final double monthlyTargetProgress;
  final int totalPoints;
  final int monthlyScans;
  final int rewardsEarned;

  const BusinessMetrics({
    required this.totalScans,
    required this.redeemedPoints,
    required this.activeCampaigns,
    required this.monthlyTargetProgress,
    required this.totalPoints,
    required this.monthlyScans,
    required this.rewardsEarned,
  });

  /// Create metrics with sample data
  factory BusinessMetrics.sample() {
    return const BusinessMetrics(
      totalScans: 1234,
      redeemedPoints: 856,
      activeCampaigns: 5,
      monthlyTargetProgress: 78.0,
      totalPoints: 2450,
      monthlyScans: 124,
      rewardsEarned: 18,
    );
  }

  /// Calculate percentage change for a metric
  static double calculateChange(double current, double previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }
}

/// Activity data model
class ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String iconName;
  final String colorName;
  final int points;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.iconName,
    required this.colorName,
    required this.points,
  });
}

/// Service for handling analytics and business metrics
class AnalyticsService {
  final AppLogger _logger = AppLogger();

  /// Get current business metrics
  Future<BusinessMetrics> getBusinessMetrics() async {
    try {
      _logger.info('Fetching business metrics');

      // In a real app, this would fetch from an API
      // For now, return sample data
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Simulate network delay

      final metrics = BusinessMetrics.sample();
      _logger.debug('Business metrics loaded', {
        'totalScans': metrics.totalScans,
        'redeemedPoints': metrics.redeemedPoints,
        'activeCampaigns': metrics.activeCampaigns,
      });

      return metrics;
    } catch (e) {
      _logger.error('Failed to fetch business metrics', e);
      rethrow;
    }
  }

  /// Get recent activities
  Future<List<ActivityItem>> getRecentActivities({int limit = 10}) async {
    try {
      _logger.info('Fetching recent activities', {'limit': limit});

      // In a real app, this would fetch from an API
      await Future.delayed(
        const Duration(milliseconds: 150),
      ); // Simulate network delay

      final activities = [
        ActivityItem(
          id: '1',
          title: 'QR Code Scanned',
          subtitle: 'Birla White Primacoat Primer - +70 points',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          iconName: 'qr_code_scanner',
          colorName: 'successGreen',
          points: 70,
        ),
        ActivityItem(
          id: '2',
          title: 'Reward Redeemed',
          subtitle: 'Amazon Gift Card - 500 points',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          iconName: 'card_giftcard',
          colorName: 'warningAmber',
          points: -500,
        ),
        ActivityItem(
          id: '3',
          title: 'Level Up',
          subtitle: 'Reached Gold Member Status',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          iconName: 'emoji_events',
          colorName: 'accentBlue',
          points: 100,
        ),
      ];

      _logger.debug('Recent activities loaded', {'count': activities.length});
      return activities;
    } catch (e) {
      _logger.error('Failed to fetch recent activities', e);
      rethrow;
    }
  }

  /// Track QR code scan event
  Future<void> trackQRScan(String qrCode, {int pointsEarned = 0}) async {
    try {
      _logger.info('Tracking QR scan', {
        'qrCode': qrCode,
        'pointsEarned': pointsEarned,
      });

      // In a real app, this would send analytics to a service
      await Future.delayed(const Duration(milliseconds: 50));

      _logger.debug('QR scan tracked successfully');
    } catch (e) {
      _logger.error('Failed to track QR scan', e);
      rethrow;
    }
  }

  /// Track reward redemption
  Future<void> trackRewardRedemption(String rewardName, int pointsSpent) async {
    try {
      _logger.info('Tracking reward redemption', {
        'rewardName': rewardName,
        'pointsSpent': pointsSpent,
      });

      // In a real app, this would send analytics to a service
      await Future.delayed(const Duration(milliseconds: 50));

      _logger.debug('Reward redemption tracked successfully');
    } catch (e) {
      _logger.error('Failed to track reward redemption', e);
      rethrow;
    }
  }

  /// Track user interaction
  Future<void> trackUserInteraction(
    String action, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.info('Tracking user interaction', {
        'action': action,
        'metadata': metadata,
      });

      // In a real app, this would send analytics to a service
      await Future.delayed(const Duration(milliseconds: 50));

      _logger.debug('User interaction tracked successfully');
    } catch (e) {
      _logger.error('Failed to track user interaction', e);
      rethrow;
    }
  }

  /// Get business insights
  Future<Map<String, dynamic>> getBusinessInsights() async {
    try {
      _logger.info('Fetching business insights');

      // In a real app, this would fetch from an API
      await Future.delayed(const Duration(milliseconds: 100));

      final insights = {
        'topProduct': {
          'name': 'White Cement',
          'percentage': 45.0,
          'description': 'of total scans',
        },
        'peakHours': {
          'timeRange': '10 AM - 2 PM',
          'description': 'Highest activity',
        },
      };

      _logger.debug('Business insights loaded', insights);
      return insights;
    } catch (e) {
      _logger.error('Failed to fetch business insights', e);
      rethrow;
    }
  }

  /// Calculate metrics change over time
  Future<Map<String, double>> getMetricsChange() async {
    try {
      _logger.info('Calculating metrics change');

      // In a real app, this would compare current vs previous period
      await Future.delayed(const Duration(milliseconds: 50));

      final changes = {
        'totalScans': 12.5,
        'redeemedPoints': 8.2,
        'activeCampaigns': 2.0,
        'monthlyTarget': 15.0,
      };

      _logger.debug('Metrics change calculated', changes);
      return changes;
    } catch (e) {
      _logger.error('Failed to calculate metrics change', e);
      rethrow;
    }
  }
}
