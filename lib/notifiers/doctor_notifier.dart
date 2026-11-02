import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/doctor_service.dart';

class DoctorNotifier extends AsyncNotifier<List<Doctor>> {
  @override
  Future<List<Doctor>> build() async {
    return _fetchDoctors();
  }

  Future<void> loadDoctors() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDoctors());
  }

  Future<List<Doctor>> _fetchDoctors() async {
    return await DoctorService.fetchDoctors();
  }
}
