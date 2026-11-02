import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_models.dart';
import '../notifiers/crm_notifier.dart';
import '../services/crm_data_service.dart';

final crmPatientsProvider =
    AsyncNotifierProvider<CrmPatientsNotifier, List<CrmPatient>>(
      () => CrmPatientsNotifier(),
    );

final crmAppointmentsProvider =
    AsyncNotifierProvider<CrmAppointmentsNotifier, List<CrmAppointment>>(
      () => CrmAppointmentsNotifier(),
    );

final crmDoctorsProvider =
    AsyncNotifierProvider<CrmDoctorsNotifier, List<CrmDoctor>>(
      () => CrmDoctorsNotifier(),
    );

final crmOrdersProvider =
    AsyncNotifierProvider<CrmOrdersNotifier, List<CrmOrder>>(
      () => CrmOrdersNotifier(),
    );

final crmPatientNotesProvider = FutureProvider.family<List<CrmNote>, String>((
  ref,
  patientId,
) async {
  return CrmDataService.getNotesForPatient(patientId);
});
