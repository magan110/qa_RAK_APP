import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../services/qr_scanner_service.dart';
import '../utils/app_logger.dart';

/// State of the home screen
enum HomeState { loading, loaded, error }

/// Controller for managing home screen state and business logic
class HomeController extends ChangeNotifier {
  final AnalyticsService _analyticsService;
  final QRScannerService _qrScannerService;
  final AppLogger _logger = AppLogger();

  HomeState _state = HomeState.loading;
  String? _errorMessage;
  int _currentIndex = 0;
  int _currentBannerIndex = 0;

  // Business data
  BusinessMetrics? _businessMetrics;
  List<ActivityItem> _recentActivities = [];
  Map<String, dynamic> _businessInsights = {};

  HomeController({
    required AnalyticsService analyticsService,
    required QRScannerService qrScannerService,
  }) : _analyticsService = analyticsService,
       _qrScannerService = qrScannerService {
    _initialize();
  }

  // Getters
  HomeState get state => _state;
  String? get errorMessage => _errorMessage;
  int get currentIndex => _currentIndex;
  int get currentBannerIndex => _currentBannerIndex;
  BusinessMetrics? get businessMetrics => _businessMetrics;
  List<ActivityItem> get recentActivities => _recentActivities;
  Map<String, dynamic> get businessInsights => _businessInsights;

  /// Initialize the controller
  Future<void> _initialize() async {
    try {
      _logger.info('Initializing HomeController');
      _state = HomeState.loading;
      notifyListeners();

      // Load initial data
      await Future.wait([
        _loadBusinessMetrics(),
        _loadRecentActivities(),
        _loadBusinessInsights(),
      ]);

      _state = HomeState.loaded;
      _logger.info('HomeController initialized successfully');
    } catch (e) {
      _state = HomeState.error;
      _errorMessage = e.toString();
      _logger.error('Failed to initialize HomeController', e);
    } finally {
      notifyListeners();
    }
  }

  /// Load business metrics
  Future<void> _loadBusinessMetrics() async {
    try {
      _businessMetrics = await _analyticsService.getBusinessMetrics();
      _logger.debug('Business metrics loaded', {
        'totalScans': _businessMetrics?.totalScans,
        'redeemedPoints': _businessMetrics?.redeemedPoints,
      });
    } catch (e) {
      _logger.error('Failed to load business metrics', e);
      rethrow;
    }
  }

  /// Load recent activities
  Future<void> _loadRecentActivities() async {
    try {
      _recentActivities = await _analyticsService.getRecentActivities(limit: 3);
      _logger.debug('Recent activities loaded', {
        'count': _recentActivities.length,
      });
    } catch (e) {
      _logger.error('Failed to load recent activities', e);
      rethrow;
    }
  }

  /// Load business insights
  Future<void> _loadBusinessInsights() async {
    try {
      _businessInsights = await _analyticsService.getBusinessInsights();
      _logger.debug('Business insights loaded', _businessInsights);
    } catch (e) {
      _logger.error('Failed to load business insights', e);
      rethrow;
    }
  }

  /// Change current tab index
  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      _logger.debug('Tab changed', {'newIndex': index});
      notifyListeners();
    }
  }

  /// Change current banner index
  void setCurrentBannerIndex(int index) {
    if (_currentBannerIndex != index) {
      _currentBannerIndex = index;
      _logger.debug('Banner changed', {'newIndex': index});
      notifyListeners();
    }
  }

  /// Start QR scanning
  Future<void> startQRScanning(void Function(VoidCallback) setState) async {
    try {
      _logger.info('Starting QR scanning');
      _qrScannerService.initialize(setState);
      await _qrScannerService.startScanning();
    } catch (e) {
      _logger.error('Failed to start QR scanning', e);
      rethrow;
    }
  }

  /// Stop QR scanning
  void stopQRScanning() {
    try {
      _logger.info('Stopping QR scanning');
      _qrScannerService.stopScanning();
    } catch (e) {
      _logger.error('Failed to stop QR scanning', e);
    }
  }

  /// Handle QR code detection
  Future<void> handleQRCode(String code) async {
    try {
      _logger.info('Handling QR code', {'code': code});

      // Track the scan
      await _analyticsService.trackQRScan(code, pointsEarned: 70);

      // Refresh data after scan
      await _loadBusinessMetrics();
      await _loadRecentActivities();

      _logger.debug('QR code handled successfully');
    } catch (e) {
      _logger.error('Failed to handle QR code', e);
      rethrow;
    }
  }

  /// Track user interaction
  Future<void> trackInteraction(
    String action, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _analyticsService.trackUserInteraction(action, metadata: metadata);
    } catch (e) {
      _logger.error('Failed to track interaction', e);
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    try {
      _logger.info('Refreshing home data');
      _state = HomeState.loading;
      notifyListeners();

      await Future.wait([
        _loadBusinessMetrics(),
        _loadRecentActivities(),
        _loadBusinessInsights(),
      ]);

      _state = HomeState.loaded;
      _logger.info('Home data refreshed successfully');
    } catch (e) {
      _state = HomeState.error;
      _errorMessage = e.toString();
      _logger.error('Failed to refresh home data', e);
    } finally {
      notifyListeners();
    }
  }

  /// Get QR scanner service for direct access
  QRScannerService get qrScannerService => _qrScannerService;

  /// Check if QR scanner is currently scanning
  bool get isScanning => _qrScannerService.isScanning;

  @override
  void dispose() {
    _qrScannerService.dispose();
    _logger.info('HomeController disposed');
    super.dispose();
  }
}
