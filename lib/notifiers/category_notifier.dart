import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/category_service.dart';

class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  FutureOr<List<Category>> build() async {
    return _fetchCategories();
  }

  Future<List<Category>> _fetchCategories() async {
    try {
      return await CategoryService.getCategories();
    // ignore: unused_catch_stack
    } catch (e, st) {
      return [];
    }
  }

  Future<Category?> createCategory(String name, String? description) async {
    try {
      final newCategory = await CategoryService.createCategory(name, description);
      // Update state optimistically
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newCategory]);
      } else {
        state = AsyncValue.data([newCategory]);
      }
      return newCategory;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCategories());
  }

  Future<void> deleteCategory(String id) async {
    try {
      await CategoryService.deleteCategory(id);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.where((cat) => cat.id != id).toList(),
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
