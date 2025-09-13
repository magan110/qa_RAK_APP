import 'package:flutter/material.dart';
import '../../../core/controllers/home_controller.dart';
import '../../../core/widgets/optimized_metric_card.dart';
import '../../../core/widgets/optimized_banner_carousel.dart';
import '../../../core/services/analytics_service.dart' show ActivityItem;

/// Home tab widget with optimized performance and clean architecture
class HomeTab extends StatelessWidget {
  final HomeController controller;
  final bool isWeb;
  final bool isTablet;
  final bool isMobile;
  final bool isDesktop;

  const HomeTab({
    super.key,
    required this.controller,
    required this.isWeb,
    required this.isTablet,
    required this.isMobile,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = isDesktop
        ? 60.0
        : (isWeb ? 40.0 : (isTablet ? 24.0 : 16.0));
    final verticalSpacing = isDesktop
        ? 48.0
        : (isWeb ? 40.0 : (isTablet ? 28.0 : 24.0));
    final topPadding = isDesktop ? 40.0 : (isWeb ? 32.0 : 16.0);
    final bottomPadding = isDesktop
        ? 80.0
        : (isWeb ? 60.0 : (isTablet ? 120.0 : 100.0));

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 1200 : (isWeb ? 1000 : double.infinity),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: topPadding,
            bottom: bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPremiumHeader(),
              SizedBox(height: verticalSpacing),
              _buildBannerCarousel(),
              SizedBox(height: verticalSpacing),
              _buildBusinessMetrics(),
              SizedBox(height: verticalSpacing),
              _buildQuickActionsGrid(),
              SizedBox(height: verticalSpacing),
              _buildLoyaltyProgramCard(),
              SizedBox(height: verticalSpacing),
              _buildPromotionalBanner(),
              SizedBox(height: verticalSpacing),
              _buildRecentActivity(),
              SizedBox(height: verticalSpacing),
              _buildBusinessInsights(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    final padding = isDesktop
        ? 40.0
        : (isWeb ? 32.0 : (isTablet ? 28.0 : 24.0));
    final titleFontSize = isDesktop
        ? 42.0
        : (isWeb ? 36.0 : (isTablet ? 32.0 : 28.0));
    final subtitleFontSize = isDesktop
        ? 20.0
        : (isWeb ? 18.0 : (isTablet ? 17.0 : 16.0));
    final logoSize = isDesktop
        ? 140.0
        : (isWeb ? 120.0 : (isTablet ? 105.0 : 90.0));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331E3A8A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 16 : (isWeb ? 12 : 8),
                        vertical: isDesktop ? 8 : (isWeb ? 6 : 4),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: isDesktop ? 24 : (isWeb ? 20 : 16)),
                    Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 16 : (isWeb ? 12 : 8)),
                    Text(
                      'RAK White Cement & Construction Materials',
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isDesktop ? 40 : (isWeb ? 32 : 20)),
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 20 : (isWeb ? 16 : 12)),
                  child: Image.asset("assets/images/rak_logo.jpg"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    final bannerData = [
      const BannerItem(
        image: 'assets/images/main.jpeg',
        title: 'RAK White Cement',
        subtitle: 'Premium Quality',
        description: 'Experience excellence with RAK White Cement products',
      ),
      const BannerItem(
        image: 'assets/images/MBF-Product-Usage1.jpeg',
        title: 'MBF Product Range',
        subtitle: 'Advanced Solutions',
        description: 'Discover our innovative MBF product lineup',
      ),
      const BannerItem(
        image: 'assets/images/RWC-Product-Usage2-1.jpeg',
        title: 'RWC Construction',
        subtitle: 'Professional Materials',
        description: 'Trusted by professionals worldwide',
      ),
    ];

    return OptimizedBannerCarousel(
      bannerData: bannerData,
      isWeb: isWeb,
      isTablet: isTablet,
    );
  }

  Widget _buildBusinessMetrics() {
    final titleFontSize = isDesktop
        ? 28.0
        : (isWeb ? 24.0 : (isTablet ? 22.0 : 20.0));
    final crossAxisCount = isDesktop ? 4 : (isWeb ? 3 : 2);
    final spacing = isDesktop ? 24.0 : (isWeb ? 20.0 : 16.0);
    final aspectRatio = isDesktop
        ? 1.1
        : (isWeb ? 1.2 : (isTablet ? 1.25 : 1.3));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Business Overview',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : (isWeb ? 16 : 14),
                      color: const Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 8 : (isWeb ? 6 : 4)),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: isDesktop ? 18 : (isWeb ? 16 : 14),
                    color: const Color(0xFF3B82F6),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isDesktop ? 28 : (isWeb ? 24 : 16)),
        (isDesktop || isWeb)
            ? Row(
                children: [
                  if (isDesktop)
                    Expanded(
                      child: OptimizedMetricCard(
                        title: 'Total Scans',
                        value:
                            controller.businessMetrics?.totalScans.toString() ??
                            '0',
                        change: '+12.5%',
                        color: const Color(0xFF10B981),
                        icon: Icons.qr_code_scanner,
                        onTap: () {},
                        isWeb: isWeb,
                        isTablet: isTablet,
                      ),
                    ),
                  if (isDesktop) SizedBox(width: spacing),
                  if (isWeb || isDesktop)
                    Expanded(
                      child: OptimizedMetricCard(
                        title: 'Redeemed Points',
                        value:
                            controller.businessMetrics?.redeemedPoints
                                .toString() ??
                            '0',
                        change: '+8.2%',
                        color: const Color(0xFF60A5FA),
                        icon: Icons.redeem,
                        onTap: () {},
                        isWeb: isWeb,
                        isTablet: isTablet,
                      ),
                    ),
                  if (isWeb || isDesktop) SizedBox(width: spacing),
                  if (isWeb || isDesktop)
                    Expanded(
                      child: OptimizedMetricCard(
                        title: 'Active Campaigns',
                        value:
                            controller.businessMetrics?.activeCampaigns
                                .toString() ??
                            '0',
                        change: '+2',
                        color: const Color(0xFFF59E0B),
                        icon: Icons.campaign,
                        onTap: () {},
                        isWeb: isWeb,
                        isTablet: isTablet,
                      ),
                    ),
                  if (isDesktop) SizedBox(width: spacing),
                  if (isDesktop)
                    Expanded(
                      child: OptimizedMetricCard(
                        title: 'Monthly Target',
                        value:
                            '${controller.businessMetrics?.monthlyTargetProgress.toString() ?? '0'}%',
                        change: '+15%',
                        color: const Color(0xFF1E3A8A),
                        icon: Icons.trending_up,
                        onTap: () {},
                        isWeb: isWeb,
                        isTablet: isTablet,
                      ),
                    ),
                ],
              )
            : GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: aspectRatio,
                children: [
                  OptimizedMetricCard(
                    title: 'Total Scans',
                    value:
                        controller.businessMetrics?.totalScans.toString() ??
                        '0',
                    change: '+12.5%',
                    color: const Color(0xFF10B981),
                    icon: Icons.qr_code_scanner,
                    onTap: () {},
                    isWeb: isWeb,
                    isTablet: isTablet,
                  ),
                  OptimizedMetricCard(
                    title: 'Redeemed Points',
                    value:
                        controller.businessMetrics?.redeemedPoints.toString() ??
                        '0',
                    change: '+8.2%',
                    color: const Color(0xFF60A5FA),
                    icon: Icons.redeem,
                    onTap: () {},
                    isWeb: isWeb,
                    isTablet: isTablet,
                  ),
                  OptimizedMetricCard(
                    title: 'Active Campaigns',
                    value:
                        controller.businessMetrics?.activeCampaigns
                            .toString() ??
                        '0',
                    change: '+2',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.campaign,
                    onTap: () {},
                    isWeb: isWeb,
                    isTablet: isTablet,
                  ),
                  if (!isWeb)
                    OptimizedMetricCard(
                      title: 'Monthly Target',
                      value:
                          '${controller.businessMetrics?.monthlyTargetProgress.toString() ?? '0'}%',
                      change: '+15%',
                      color: const Color(0xFF1E3A8A),
                      icon: Icons.trending_up,
                      onTap: () {},
                      isWeb: isWeb,
                      isTablet: isTablet,
                    ),
                ],
              ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    final titleFontSize = isDesktop
        ? 28.0
        : (isWeb ? 24.0 : (isTablet ? 22.0 : 20.0));
    final spacing = isDesktop ? 24.0 : (isWeb ? 20.0 : 12.0);
    final crossAxisCount = isDesktop ? 4 : (isWeb ? 4 : 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: isDesktop ? 28 : (isWeb ? 24 : 16)),
        (isDesktop || isWeb)
            ? Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Scan QR',
                      Icons.qr_code_scanner,
                      const Color(0xFF3B82F6),
                      () => controller.trackInteraction('scan_qr_tapped'),
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Products',
                      Icons.inventory_2,
                      const Color(0xFF10B981),
                      () => controller.trackInteraction('products_tapped'),
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Rewards',
                      Icons.card_giftcard,
                      const Color(0xFFF59E0B),
                      () => controller.trackInteraction('rewards_tapped'),
                    ),
                  ),
                  if (isDesktop) SizedBox(width: spacing),
                  if (isDesktop)
                    Expanded(
                      child: _buildQuickActionCard(
                        'Reports',
                        Icons.bar_chart,
                        const Color(0xFF60A5FA),
                        () => controller.trackInteraction('reports_tapped'),
                      ),
                    ),
                ],
              )
            : GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: 1.0,
                children: [
                  _buildQuickActionCard(
                    'Scan QR',
                    Icons.qr_code_scanner,
                    const Color(0xFF3B82F6),
                    () => controller.trackInteraction('scan_qr_tapped'),
                  ),
                  _buildQuickActionCard(
                    'Products',
                    Icons.inventory_2,
                    const Color(0xFF10B981),
                    () => controller.trackInteraction('products_tapped'),
                  ),
                  _buildQuickActionCard(
                    'Rewards',
                    Icons.card_giftcard,
                    const Color(0xFFF59E0B),
                    () => controller.trackInteraction('rewards_tapped'),
                  ),
                  if (!isWeb)
                    _buildQuickActionCard(
                      'Reports',
                      Icons.bar_chart,
                      const Color(0xFF60A5FA),
                      () => controller.trackInteraction('reports_tapped'),
                    ),
                ],
              ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final iconSize = isDesktop
        ? 80.0
        : (isWeb ? 64.0 : (isTablet ? 56.0 : 48.0));
    final iconInnerSize = isDesktop
        ? 40.0
        : (isWeb ? 32.0 : (isTablet ? 28.0 : 24.0));
    final titleFontSize = isDesktop
        ? 18.0
        : (isWeb ? 16.0 : (isTablet ? 14.0 : 12.0));
    final spacing = isDesktop ? 20.0 : (isWeb ? 16.0 : 12.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: iconInnerSize),
            ),
            SizedBox(height: spacing),
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyProgramCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331E3A8A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Loyalty Program',
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Gold Member',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 24 : 20),
          Row(
            children: [
              Expanded(
                child: _buildLoyaltyStat(
                  'Total Points',
                  controller.businessMetrics?.totalPoints.toString() ?? '0',
                  Icons.star,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLoyaltyStat(
                  'Monthly Scans',
                  '${controller.businessMetrics?.monthlyScans.toString() ?? '0'}/200',
                  Icons.qr_code_scanner,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLoyaltyStat(
                  'Rewards Earned',
                  controller.businessMetrics?.rewardsEarned.toString() ?? '0',
                  Icons.card_giftcard,
                  const Color(0xFF60A5FA),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 24 : 20),
          Container(
            width: double.infinity,
            height: isDesktop ? 12 : 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.62,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 12 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '62% to next level',
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 12,
                  color: const Color(0xB3FFFFFF),
                ),
              ),
              Text(
                '1,550 points needed',
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 12,
                  color: const Color(0xB3FFFFFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isDesktop ? 28 : 24),
          SizedBox(height: isDesktop ? 12 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isDesktop ? 8 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 14 : 12,
              color: const Color(0xB3FFFFFF),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanner() {
    return Container(
      width: double.infinity,
      height: isDesktop ? 220 : 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isDesktop ? 32 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LIMITED TIME OFFER',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: isDesktop ? 16 : 12),
                Text(
                  'Fragrance Putty Bumper Prizes',
                  style: TextStyle(
                    fontSize: isDesktop ? 26 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isDesktop ? 12 : 8),
                Text(
                  'Win amazing prizes with every purchase',
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isDesktop ? 20 : 16),
                ElevatedButton(
                  onPressed: () =>
                      controller.trackInteraction('promo_learn_more'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFF59E0B),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 28 : 24,
                      vertical: isDesktop ? 16 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Learn More',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 16 : 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: isDesktop ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              TextButton(
                onPressed: () =>
                    controller.trackInteraction('view_all_activity'),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    color: const Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.recentActivities.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final activity = controller.recentActivities[index];
              return _buildActivityItem(activity);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem activity) {
    final iconData = _getIconData(activity.iconName);
    final color = _getColor(activity.colorName);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 12 : 8),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 56 : 48,
            height: isDesktop ? 56 : 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: color, size: isDesktop ? 28 : 24),
          ),
          SizedBox(width: isDesktop ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: isDesktop ? 6 : 4),
                Text(
                  activity.subtitle,
                  style: TextStyle(
                    fontSize: isDesktop ? 15 : 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${activity.points > 0 ? '+' : ''}${activity.points}',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: isDesktop ? 6 : 4),
              Text(
                _formatTimeAgo(activity.timestamp),
                style: TextStyle(
                  fontSize: isDesktop ? 13 : 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInsights() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Insights',
            style: TextStyle(
              fontSize: isDesktop ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  'Top Product',
                  controller.businessInsights['topProduct']?['name'] ??
                      'White Cement',
                  '${controller.businessInsights['topProduct']?['percentage'] ?? 45}%',
                  Icons.trending_up,
                  const Color(0xFF10B981),
                ),
              ),
              SizedBox(width: isDesktop ? 24 : 16),
              Expanded(
                child: _buildInsightCard(
                  'Peak Hours',
                  controller.businessInsights['peakHours']?['timeRange'] ??
                      '10 AM - 2 PM',
                  controller.businessInsights['peakHours']?['description'] ??
                      'Highest activity',
                  Icons.access_time,
                  const Color(0xFF60A5FA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: isDesktop ? 24 : 20),
              SizedBox(width: isDesktop ? 12 : 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 16 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: isDesktop ? 8 : 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isDesktop ? 14 : 12,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'qr_code_scanner':
        return Icons.qr_code_scanner;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.info;
    }
  }

  Color _getColor(String colorName) {
    switch (colorName) {
      case 'successGreen':
        return const Color(0xFF10B981);
      case 'warningAmber':
        return const Color(0xFFF59E0B);
      case 'accentBlue':
        return const Color(0xFF60A5FA);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}