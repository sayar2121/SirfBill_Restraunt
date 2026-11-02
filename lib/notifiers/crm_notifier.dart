import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_models.dart';
import '../services/crm_data_service.dart';

class CrmPatientsNotifier extends AsyncNotifier<List<CrmPatient>> {
  @override
  Future<List<CrmPatient>> build() async {
    return CrmDataService.getPatients();
  }

  Future<void> loadPatients() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => CrmDataService.getPatients());
  }

  Future<void> addPatient(CrmPatient patient) async {
    await CrmDataService.addPatient(patient);
    await loadPatients();
  }

  Future<void> updatePatient(CrmPatient patient) async {
    await CrmDataService.updatePatient(patient);
    await loadPatients();
  }

  Future<void> deletePatient(String id) async {
    await CrmDataService.deletePatient(id);
    await loadPatients();
  }
}

class CrmAppointmentsNotifier extends AsyncNotifier<List<CrmAppointment>> {
  @override
  Future<List<CrmAppointment>> build() async {
    return CrmDataService.getAppointments();
  }

  Future<void> loadAppointments() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => CrmDataService.getAppointments());
  }
}

class CrmDoctorsNotifier extends AsyncNotifier<List<CrmDoctor>> {
  @override
  Future<List<CrmDoctor>> build() async {
    return CrmDataService.getDoctors();
  }

  Future<void> loadDoctors() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => CrmDataService.getDoctors());
  }
}

class CrmOrdersNotifier extends AsyncNotifier<List<CrmOrder>> {
  @override
  Future<List<CrmOrder>> build() async {
    return CrmDataService.getOrders();
  }

  Future<void> loadOrders() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => CrmDataService.getOrders());
  }
}
