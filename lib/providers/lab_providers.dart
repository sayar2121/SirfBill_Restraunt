import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lab_models.dart';
import '../notifiers/lab_notifier.dart';

final labPackagesProvider =
    AsyncNotifierProvider<LabPackagesNotifier, List<LabPackage>>(
      () => LabPackagesNotifier(),
    );

final labTestsProvider = AsyncNotifierProvider<LabTestsNotifier, List<LabTest>>(
  () => LabTestsNotifier(),
);

final labTemplatesProvider =
    AsyncNotifierProvider<LabTemplatesNotifier, List<LabTemplate>>(
      () => LabTemplatesNotifier(),
    );

final labBookingsProvider =
    AsyncNotifierProvider<LabBookingsNotifier, List<LabBooking>>(
      () => LabBookingsNotifier(),
    );

final labCustomCategoriesProvider =
    AsyncNotifierProvider<CustomCategoriesNotifier, List<String>>(
      () => CustomCategoriesNotifier(),
    );
