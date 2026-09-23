import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cross_file/cross_file.dart';

class ApiService {
  static const String _urlKey = 'backend_url';

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_urlKey) ?? 'http://127.0.0.1:5000';
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, url);
  }
  
  String getDownloadUrl(String baseUrl, String filename) {
    return '$baseUrl/download_model?filename=$filename';
  }

  Future<Map<String, dynamic>> predictSingle(List<double> features) async {
    final baseUrl = await getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'features': features}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get prediction: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> triggerTraining(Map<String, dynamic> config) async {
    final baseUrl = await getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/train'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(config),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to trigger training: ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> getTrainStatus() async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/train_status'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get status');
    }
  }
  
  Future<Map<String, dynamic>> uploadDataset(XFile file) async {
    final baseUrl = await getBaseUrl();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload_dataset'));
    
    // For Web XFile, we can read bytes
    final bytes = await file.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));
    
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return jsonDecode(responseData);
    } else {
      throw Exception('Upload failed: $responseData');
    }
  }
  
  Future<List<dynamic>> getHistory() async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/history'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['history'] ?? [];
    } else {
      throw Exception('Failed to load history');
    }
  }

  Future<void> cleanupModels() async {
    final baseUrl = await getBaseUrl();
    final response = await http.post(Uri.parse('$baseUrl/cleanup'));
    
    if (response.statusCode != 200) {
      throw Exception('Failed to cleanup: ${response.body}');
    }
  }

  Future<List<String>> getFeatureNames() async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/feature_names'));
    
    if (response.statusCode == 200) {
      final List<dynamic> names = jsonDecode(response.body)['feature_names'] ?? [];
      return names.cast<String>();
    } else {
      throw Exception('Failed to load feature names');
    }
  }
}
