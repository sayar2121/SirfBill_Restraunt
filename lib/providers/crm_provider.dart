import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_models.dart';

class CrmState {
  final CrmPatient? selectedPatient;

  const CrmState({this.selectedPatient});

  CrmState copyWith({CrmPatient? selectedPatient}) {
    return CrmState(selectedPatient: selectedPatient ?? this.selectedPatient);
  }
}

class CrmNotifier extends Notifier<CrmState> {
  @override
  CrmState build() {
    return const CrmState();
  }

  void selectPatient(CrmPatient patient) {
    state = state.copyWith(selectedPatient: patient);
  }

  void clearPatient() {
    state = const CrmState();
  }
}

final crmProvider = NotifierProvider<CrmNotifier, CrmState>(() {
  return CrmNotifier();
});
