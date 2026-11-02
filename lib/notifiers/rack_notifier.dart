import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rack_service.dart';

class RackNotifier extends AsyncNotifier<List<Rack>> {
  @override
  FutureOr<List<Rack>> build() async {
    return _fetchRacks();
  }

  Future<List<Rack>> _fetchRacks() async {
    try {
      return await RackService.getRacks();
    } catch (e, st) {
      if (kDebugMode) {
        print('RackNotifier Error: $e\n$st');
      }
      return [];
    }
  }

  Future<Rack?> createRack(String rackNumber, String? details) async {
    try {
      final newRack = await RackService.createRack(rackNumber, details);
      // Update state optimistically
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newRack]);
      } else {
        state = AsyncValue.data([newRack]);
      }
      return newRack;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchRacks());
  }

  Future<void> deleteRack(String id) async {
    try {
      await RackService.deleteRack(id);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.where((rack) => rack.id != id).toList(),
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
