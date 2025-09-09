import 'package:get_it/get_it.dart';
import '../services/analytics_service.dart';
import '../services/qr_scanner_service.dart';
import '../controllers/home_controller.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Setup dependency injection
Future<void> setupServiceLocator() async {
  // Register services as singletons
  getIt.registerLazySingleton<AnalyticsService>(() => AnalyticsService());
  getIt.registerLazySingleton<QRScannerService>(() => QRScannerService());

  // Register controllers as factory (new instance each time)
  getIt.registerFactory<HomeController>(
    () => HomeController(
      analyticsService: getIt<AnalyticsService>(),
      qrScannerService: getIt<QRScannerService>(),
    ),
  );
}

/// Get service instances
AnalyticsService get analyticsService => getIt<AnalyticsService>();
QRScannerService get qrScannerService => getIt<QRScannerService>();
HomeController get homeController => getIt<HomeController>();
