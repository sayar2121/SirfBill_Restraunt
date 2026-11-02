import 'package:dio/dio.dart';
import '../models/lab_models.dart';
import '../config/api_client.dart';
import 'auth_service.dart';

class LabDataService {
  // ignore: unused_field
  static const String _testsKey = 'lab_tests';
  // ignore: unused_field
  static const String _templatesKey = 'lab_templates';
  // ignore: unused_field
  static const String _packagesKey = 'lab_packages';
  // ignore: unused_field
  static const String _customCategoriesKey = 'custom_categories';

  // --- Custom Categories (API) ---
  static Future<String?> _getCategoryIdByName(String name) async {
    try {
      final response = await ApiClient().dio.get('/api/admin/lab-category/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        for (var item in data) {
          if (item['name'] == name) return item['id'];
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting category ID: $e');
    }
    return null;
  }

  static Future<List<String>> getCustomCategories() async {
    try {
      final response = await ApiClient().dio.get('/api/admin/lab-category/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => e['name'].toString()).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting categories: $e');
    }
    return [];
  }

  static Future<void> saveCustomCategory(String category) async {
    try {
      await ApiClient().dio.post(
        '/api/admin/lab-category/',
        data: {'name': category},
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error saving category: $e');
    }
  }

  static Future<void> deleteCustomCategory(String category) async {
    final id = await _getCategoryIdByName(category);
    if (id != null) {
      try {
        await ApiClient().dio.delete('/api/admin/lab-category/$id');
      } catch (e) {
        // ignore: avoid_print
        print('Error deleting category: $e');
      }
    }
  }

  static Future<void> renameCustomCategory(
    String oldName,
    String newName,
  ) async {
    final id = await _getCategoryIdByName(oldName);
    if (id != null) {
      try {
        await ApiClient().dio.patch(
          '/api/admin/lab-category/$id',
          data: {'name': newName},
        );
      } catch (e) {
        // ignore: avoid_print
        print('Error renaming category: $e');
      }
    } else {
      await saveCustomCategory(newName);
    }
  }

  // --- Tests ---
  static Future<List<LabTest>> getTests() async {
    try {
      final response = await ApiClient().dio.get('/api/admin/lab-catalog/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .where((item) => item['type'] == 'SINGLE_TEST')
            .map((j) => LabTest.fromJson(j))
            .toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching tests: $e');
    }
    return [];
  }

  static Future<void> saveTest(LabTest test) async {
    try {
      final body = test.toJson();

      if (test.id.isEmpty) {
        await ApiClient().dio.post('/api/admin/lab-catalog/', data: body);
        return;
      }

      try {
        await ApiClient().dio.patch(
          '/api/admin/lab-catalog/${test.id}',
          data: body,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 ||
            e.response?.statusCode == 422 ||
            e.response?.statusCode == 405) {
          await ApiClient().dio.post('/api/admin/lab-catalog/', data: body);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error saving test: $e');
    }
  }

  static Future<bool> uploadCSV(List<int> fileBytes, String fileName) async {
    try {
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
      var response = await ApiClient().dio.post(
        '/api/admin/lab-catalog/upload-csv',
        data: formData,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      // ignore: avoid_print
      print('CSV upload error: $e');
      return false;
    }
  }

  static Future<void> deleteTest(String id) async {
    try {
      await ApiClient().dio.delete('/api/admin/lab-catalog/$id');
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting test: $e');
    }
  }

  // --- Templates ---
  static Future<List<LabTemplate>> getTemplates() async {
    try {
      final response = await ApiClient().dio.get('/api/admin/lab-template/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((j) => LabTemplate.fromJson(j)).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting templates: $e');
    }
    return [];
  }

  static Future<void> saveTemplate(LabTemplate template) async {
    try {
      final body = template.toJson();

      try {
        await ApiClient().dio.patch(
          '/api/admin/lab-template/${template.id}',
          data: body,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
          await ApiClient().dio.post('/api/admin/lab-template/', data: body);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error saving template: $e');
    }
  }

  static Future<void> deleteTemplate(String id) async {
    try {
      await ApiClient().dio.delete('/api/admin/lab-template/$id');
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting template: $e');
    }
  }

  // --- Packages ---
  static Future<List<LabPackage>> getPackages() async {
    try {
      final response = await ApiClient().dio.get('/api/admin/lab-catalog/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .where((item) => item['type'] == 'PACKAGE')
            .map((j) => LabPackage.fromJson(j))
            .toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching packages: $e');
    }
    return [];
  }

  static Future<bool> uploadCatalogCsv(
    List<int> fileBytes,
    String filename,
  ) async {
    try {
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: filename),
      });

      final response = await ApiClient().dio.post(
        '/api/admin/lab-catalog/upload-csv',
        data: formData,
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('Error uploading CSV: $e');
      return false;
    }
  }

  static Future<void> savePackage(LabPackage pkg) async {
    try {
      final body = pkg.toJson();

      try {
        await ApiClient().dio.patch(
          '/api/admin/lab-catalog/${pkg.id}',
          data: body,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 || e.response?.statusCode == 422) {
          await ApiClient().dio.post('/api/admin/lab-catalog/', data: body);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error saving package: $e');
    }
  }

  static Future<void> deletePackage(String id) async {
    try {
      await ApiClient().dio.delete('/api/admin/lab-catalog/$id');
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting package: $e');
    }
  }

  // --- Bookings ---
  // ignore: unused_field
  static const String _bookingsKey = 'lab_bookings';

  static Future<List<LabBooking>> getBookings() async {
    try {
      final response = await ApiClient().dio.get('/api/lab-bookings');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) {
          final formDetails = item['form_details'] ?? {};
          final bookedItems = item['booked_items'] as List<dynamic>? ?? [];
          final testIds = bookedItems
              .where((i) => i['type'] == 'TEST')
              .map((i) => i['id'].toString())
              .toList();
          final packageIds = bookedItems
              .where((i) => i['type'] == 'PACKAGE')
              .map((i) => i['id'].toString())
              .toList();

          return LabBooking(
            id: item['id'],
            patientName: formDetails['patientName'] ?? 'Unknown',
            patientPhone: formDetails['patientPhone'] ?? '',
            patientAge: formDetails['patientAge'] ?? '',
            patientGender: formDetails['patientGender'] ?? 'Other',
            bookingDate: item['preferred_date'] != null
                ? DateTime.parse(item['preferred_date'])
                : DateTime.now(),
            testIds: testIds,
            packageIds: packageIds,
            totalAmount: (item['total_amount'] ?? 0).toDouble(),
            status: item['status'] ?? 'Pending',
          );
        }).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting bookings: $e');
    }
    return [];
  }

  static Future<void> saveBooking(LabBooking booking) async {
    try {
      final userId =
          await AuthService.getUserId() ??
          ''; // Or generate UUID if not logged in

      final body = {
        'user_id': userId,
        'payment_method': 'COD',
        'item_ids': [...booking.testIds, ...booking.packageIds],
        'preferred_date': booking.bookingDate.toIso8601String().split('T')[0],
        'form_details': {
          'patientName': booking.patientName,
          'patientPhone': booking.patientPhone,
          'patientAge': booking.patientAge,
          'patientGender': booking.patientGender,
        },
      };

      final response = await ApiClient().dio.post(
        '/api/lab-bookings',
        data: body,
      );

      if (response.statusCode != 201) {
        // ignore: avoid_print
        print('Failed to save booking: ${response.data}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error saving booking: $e');
    }
  }

  static Future<void> deleteBooking(String id) async {
    try {
      final response = await ApiClient().dio.patch(
        '/api/lab-bookings/$id/cancel',
      );
      if (response.statusCode != 200) {
        // ignore: avoid_print
        print('Failed to delete booking: ${response.data}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting booking: $e');
    }
  }

  // --- Reports ---
  // ignore: unused_field
  static const String _reportsKey = 'lab_reports';

  static Future<List<LabReport>> getReports() async {
    try {
      final response = await ApiClient().dio.get('/api/lab-bookings');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) {
          final formDetails = item['form_details'] ?? {};
          final bookedItems = item['booked_items'] as List<dynamic>? ?? [];
          final packageNames = bookedItems.map((i) => i['title']).join(', ');

          return LabReport(
            id: item['id'],
            reportId: item['id']
                .toString()
                .substring(0, 8)
                .toUpperCase(), // Fake report ID
            patientName: formDetails['patientName'] ?? 'Unknown',
            patientPhone: formDetails['patientPhone'] ?? '',
            patientAge: formDetails['patientAge'] ?? '',
            patientGender: formDetails['patientGender'] ?? 'Other',
            referredBy: 'Self',
            testsPackageName: packageNames.isNotEmpty
                ? packageNames
                : 'General Tests',
            reportDate: item['created_at'] != null
                ? DateTime.parse(item['created_at'])
                : DateTime.now(),
            status: item['status'] ?? 'Pending',
            isSent: item['status'] == 'DELIVERED',
            sampleId: 'S${item['id'].toString().substring(0, 6).toUpperCase()}',
            collectionDate: item['preferred_date'] != null
                ? DateTime.parse(item['preferred_date'])
                : DateTime.now(),
          );
        }).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting reports: $e');
    }
    return [];
  }

  static Future<List<LabActivity>> getActivities() async {
    // In the future, this can be derived from booking history or an audit log
    return [];
  }
}
