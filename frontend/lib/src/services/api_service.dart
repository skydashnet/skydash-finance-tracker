import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String _baseUrl = 'https://api.skydashnet.my.id/api';

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final responseBody = json.decode(response.body);
      return {'statusCode': response.statusCode, 'body': responseBody};
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'A network error occurred: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseBody = json.decode(response.body);
      return {'statusCode': response.statusCode, 'body': responseBody};
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'A network error occurred: $e'},
      };
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> getSummary() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'statusCode': 401, 'body': {'message': 'Unauthorized'}};
      }

      final url = Uri.parse('$_baseUrl/reports/summary');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = json.decode(response.body);
      return {'statusCode': response.statusCode, 'body': responseBody};
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'A network error occurred: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> getTransactions({
    int? year,
    int? month,
    int? categoryId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'statusCode': 401, 'body': {'message': 'Unauthorized'}};
      }

      final uri = Uri.parse('$_baseUrl/transactions').replace(
        queryParameters: {
          if (year != null) 'year': year.toString(),
          if (month != null) 'month': month.toString(),
          if (categoryId != null) 'category_id': categoryId.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = json.decode(response.body);
      return {'statusCode': response.statusCode, 'body': responseBody};
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'A network error occurred: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> getCategories() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'statusCode': 401, 'body': {'message': 'Unauthorized'}};
      }

      final url = Uri.parse('$_baseUrl/categories');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = json.decode(response.body);
      return {'statusCode': response.statusCode, 'body': responseBody};
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'A network error occurred: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> createTransaction({
    required int categoryId,
    required double amount,
    String? description,
    required String transactionDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'statusCode': 401, 'body': {'message': 'Unauthorized'}};
      }

      final url = Uri.parse('$_baseUrl/transactions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'category_id': categoryId,
          'amount': amount,
          'description': description,
          'transaction_date': transactionDate,
        }),
      );

      final responseBody = json.decode(response.body);
      return {'statusCode': response.statusCode, 'body': responseBody};
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'A network error occurred: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> deleteTransaction(int transactionId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'statusCode': 401, 'body': {'message': 'Unauthorized'}};
      }

      final url = Uri.parse('$_baseUrl/transactions/$transactionId');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {
          'statusCode': 200,
          'body': {'message': 'Transaction deleted successfully'},
        };
      }

      final responseBody = json.decode(response.body);
      return {'statusCode': response.statusCode, 'body': responseBody};
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'A network error occurred: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> createCategory({
    required String name,
    required String type,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'statusCode': 401, 'body': {'message': 'Unauthorized'}};
      }

      final url = Uri.parse('$_baseUrl/categories');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'name': name, 'type': type}),
      );

      final responseBody = json.decode(response.body);
      return {'statusCode': response.statusCode, 'body': responseBody};
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'A network error occurred: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> updateCategory({
    required int categoryId,
    required String name,
    required String type,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return {'statusCode': 401, 'body': {'message': 'Unauthorized'}};
      
      final url = Uri.parse('$_baseUrl/categories/$categoryId');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode({'name': name, 'type': type}),
      );
      
      final responseBody = json.decode(response.body);
      return {'statusCode': response.statusCode, 'body': responseBody};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'A network error occurred: $e'}};
    }
  }

  Future<Map<String, dynamic>> deleteCategory(int categoryId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'statusCode': 401, 'body': {'message': 'Unauthorized'}};
      }

      final url = Uri.parse('$_baseUrl/categories/$categoryId');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {
          'statusCode': 200,
          'body': {'message': 'Category deleted successfully'},
        };
      }

      final responseBody = json.decode(response.body);
      return {'statusCode': response.statusCode, 'body': responseBody};
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'A network error occurred: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return {'statusCode': 401, 'body': {'message': 'Unauthorized'}};
      
      final url = Uri.parse('$_baseUrl/users/change-password');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      
      final responseBody = json.decode(response.body);
      return {'statusCode': response.statusCode, 'body': responseBody};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'A network error occurred: $e'}};
    }
  }

  Future<Map<String, dynamic>> updateTransaction({
    required int transactionId,
    required int categoryId,
    required double amount,
    String? description,
    required String transactionDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return {'statusCode': 401, 'body': {'message': 'Unauthorized'}};

      final url = Uri.parse('$_baseUrl/transactions/$transactionId');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          'category_id': categoryId,
          'amount': amount,
          'description': description,
          'transaction_date': transactionDate,
        }),
      );

      final responseBody = json.decode(response.body);
      return {'statusCode': response.statusCode, 'body': responseBody};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'A network error occurred: $e'}};
    }
  }
  
}
