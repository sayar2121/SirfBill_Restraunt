import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lab_models.dart';
import '../services/lab_data_service.dart';

class LabPackagesNotifier extends AsyncNotifier<List<LabPackage>> {
  @override
  Future<List<LabPackage>> build() async {
    return LabDataService.getPackages();
  }

  Future<void> loadPackages() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => LabDataService.getPackages());
  }

  Future<void> addOrUpdatePackage(LabPackage package) async {
    await LabDataService.savePackage(package);
    await loadPackages();
  }

  Future<void> deletePackage(String id) async {
    await LabDataService.deletePackage(id);
    await loadPackages();
  }
}

class LabTestsNotifier extends AsyncNotifier<List<LabTest>> {
  @override
  Future<List<LabTest>> build() async {
    return LabDataService.getTests();
  }

  Future<void> loadTests() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => LabDataService.getTests());
  }

  Future<void> addOrUpdateTest(LabTest test) async {
    await LabDataService.saveTest(test);
    await loadTests();
  }

  Future<void> deleteTest(String id) async {
    await LabDataService.deleteTest(id);
    await loadTests();
  }
}

class LabTemplatesNotifier extends AsyncNotifier<List<LabTemplate>> {
  @override
  Future<List<LabTemplate>> build() async {
    return LabDataService.getTemplates();
  }

  Future<void> loadTemplates() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => LabDataService.getTemplates());
  }

  Future<void> addOrUpdateTemplate(LabTemplate template) async {
    await LabDataService.saveTemplate(template);
    await loadTemplates();
  }

  Future<void> deleteTemplate(String id) async {
    await LabDataService.deleteTemplate(id);
    await loadTemplates();
  }
}

class LabBookingsNotifier extends AsyncNotifier<List<LabBooking>> {
  @override
  Future<List<LabBooking>> build() async {
    return LabDataService.getBookings();
  }

  Future<void> loadBookings() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => LabDataService.getBookings());
  }

  Future<void> addOrUpdateBooking(LabBooking booking) async {
    await LabDataService.saveBooking(booking);
    await loadBookings();
  }

  Future<void> deleteBooking(String bookingId) async {
    await LabDataService.deleteBooking(bookingId);
    await loadBookings();
  }
}

class CustomCategoriesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return LabDataService.getCustomCategories();
  }

  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => LabDataService.getCustomCategories());
  }

  Future<void> addCategory(String category) async {
    await LabDataService.saveCustomCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String category) async {
    await LabDataService.deleteCustomCategory(category);
    await loadCategories();
  }

  Future<void> renameCategory(String oldName, String newName) async {
    await LabDataService.renameCustomCategory(oldName, newName);
    await loadCategories();
  }
}
