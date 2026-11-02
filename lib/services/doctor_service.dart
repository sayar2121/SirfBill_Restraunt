import '../config/api_client.dart';

class Doctor {
  final String id;
  final String name;

  Doctor({required this.id, required this.name});

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(id: json['id'] ?? '', name: json['name'] ?? 'Unknown Doctor');
  }
}

class DoctorService {
  static Future<List<Doctor>> fetchDoctors() async {
    final response = await ApiClient().dio.get('/api/admin/doctors/');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Doctor.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch doctors: ${response.data}');
    }
  }
}
