import 'dart:async';
import 'package:flutter/material.dart';

/// Data model for banner items
class BannerItem {
  final String image;
  final String title;
  final String subtitle;
  final String description;

  const BannerItem({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}

/// Optimized banner carousel with const constructor for better performance
class OptimizedBannerCarousel extends StatefulWidget {
  final List<BannerItem> bannerData;
  final bool isWeb;
  final bool isTablet;
  final Duration autoScrollDuration;
  final double? height;

  const OptimizedBannerCarousel({
    super.key,
    required this.bannerData,
    this.isWeb = false,
    this.isTablet = false,
    this.autoScrollDuration = const Duration(seconds: 3),
    this.height,
  });

  @override
  State<OptimizedBannerCarousel> createState() =>
      _OptimizedBannerCarouselState();
}

class _OptimizedBannerCarouselState extends State<OptimizedBannerCarousel> {
  late PageController _pageController;
  late int _currentIndex;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentIndex = 0;
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(widget.autoScrollDuration, (timer) {
      if (mounted && _pageController.hasClients) {
        final nextIndex = (_currentIndex + 1) % widget.bannerData.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleFontSize = widget.isWeb ? 24.0 : (widget.isTablet ? 22.0 : 20.0);
    final bannerHeight =
        widget.height ??
        (widget.isWeb ? 280.0 : (widget.isTablet ? 250.0 : 220.0));
    final horizontalPadding = widget.isWeb ? 4.0 : 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Products',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            Row(
              children: List.generate(
                widget.bannerData.length,
                (index) => Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: widget.isWeb ? 10 : 8,
                  height: widget.isWeb ? 10 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFF1E3A8A).withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: widget.isWeb ? 20 : 16),
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.bannerData.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = widget.bannerData[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: _buildBannerItem(banner),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBannerItem(BannerItem banner) {
    return Container(
      width: double.infinity,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              banner.image,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 60, color: Colors.white),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
          ),
          Positioned(
            bottom: widget.isWeb ? 32 : 24,
            left: widget.isWeb ? 32 : 24,
            right: widget.isWeb ? 32 : 24,
            child: _buildBannerContent(banner),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerContent(BannerItem banner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isWeb ? 16 : 12,
            vertical: widget.isWeb ? 8 : 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            banner.subtitle,
            style: TextStyle(
              fontSize: widget.isWeb ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: widget.isWeb ? 16 : 12),
        Text(
          banner.title,
          style: TextStyle(
            fontSize: widget.isWeb ? 28 : (widget.isTablet ? 26 : 24),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        SizedBox(height: widget.isWeb ? 12 : 8),
        Text(
          banner.description,
          style: TextStyle(
            fontSize: widget.isWeb ? 16 : 14,
            color: Colors.white,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
