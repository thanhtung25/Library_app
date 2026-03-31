import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  // web: http://127.0.0.1:5000
  // android emulator: http://10.0.2.2:5000

  static const String baseUrl = "http://10.0.2.2:5000";

  // =========================
  // POST
  // =========================

  static Future<dynamic> post(
      String endpoint,
      Map<String, dynamic> body,
      ) async {

    final url = Uri.parse("$baseUrl$endpoint");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // =========================
  // GET
  // =========================

  static Future<dynamic> get(String endpoint) async {

    final url = Uri.parse("$baseUrl$endpoint");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    );

    return _handleResponse(response);
  }

  // =========================
  // PUT
  // =========================

  static Future<dynamic> put(
      String endpoint,
      Map<String, dynamic> body,
      ) async {

    final url = Uri.parse("$baseUrl$endpoint");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // =========================
  // DELETE
  // =========================

  static Future<dynamic> delete(String endpoint) async {

    final url = Uri.parse("$baseUrl$endpoint");

    final response = await http.delete(url);

    return _handleResponse(response);
  }

  // =========================
  // HANDLE RESPONSE
  // =========================

  static dynamic _handleResponse(http.Response response) {

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      final msg = data["message"] ?? data["error"] ?? "API error";
      throw Exception(msg);
    }
  }
}