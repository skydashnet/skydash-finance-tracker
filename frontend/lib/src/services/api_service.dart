import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final logger = Logger();
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
  
  Future<Map<String, String>?> checkForUpdate() async {
    try {
      final currentInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(currentInfo.version);
      logger.i('Current App Version: $currentVersion');

      final url = Uri.parse('https://api.github.com/repos/skydashnet/skydash-finance-tracker/releases/latest');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> releaseInfo = json.decode(response.body);
        
        final latestVersionStr = (releaseInfo['tag_name'] as String).replaceAll('v', '');
        final latestVersion = Version.parse(latestVersionStr);
        logger.i('Latest GitHub Version: $latestVersion');

        if (latestVersion > currentVersion) {
          final assets = releaseInfo['assets'] as List;
          final apkAsset = assets.firstWhere(
            (asset) => (asset['name'] as String).endsWith('.apk'),
            orElse: () => null,
          );

          if (apkAsset != null) {
            return {
              'version': latestVersionStr,
              'url': apkAsset['browser_download_url'],
              'notes': releaseInfo['body'] ?? 'Tidak ada catatan rilis.',
            };
          }
        }
      }
      return null;
    } catch (e) {
      logger.e('Update check failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createGoal({
    required String name,
    required double targetAmount,
    String? imageUrl,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) { return {'statusCode': 401, 'body': {'message': 'Unauthorized'}}; }
      
      final url = Uri.parse('$_baseUrl/goals');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'name': name, 'target_amount': targetAmount, 'image_url': imageUrl}),
      );
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'A network error occurred: $e'}};
    }
  }

  Future<Map<String, dynamic>> getUserGoals() async {
    try {
      final token = await _getToken();
      if (token == null) { return {'statusCode': 401, 'body': {'message': 'Unauthorized'}}; }

      final url = Uri.parse('$_baseUrl/goals');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'A network error occurred: $e'}};
    }
  }

  Future<Map<String, dynamic>> addSavingsToGoal(int goalId, double amount) async {
    try {
      final token = await _getToken();
      if (token == null) { return {'statusCode': 401, 'body': {'message': 'Unauthorized'}}; }

      final url = Uri.parse('$_baseUrl/goals/$goalId/add-savings');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'amount': amount}),
      );
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'A network error occurred: $e'}};
    }
  }
  
  Future<Map<String, dynamic>> deleteGoal(int goalId) async {
    try {
      final token = await _getToken();
      if (token == null) { return {'statusCode': 401, 'body': {'message': 'Unauthorized'}}; }

      final url = Uri.parse('$_baseUrl/goals/$goalId');
      final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'A network error occurred: $e'}};
    }
  }

  Future<Map<String, dynamic>> getUserAchievements() async {
    try {
      final token = await _getToken();
      if (token == null) { return {'statusCode': 401, 'body': {'message': 'Unauthorized'}}; }

      final url = Uri.parse('$_baseUrl/users/achievements');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'A network error occurred: $e'}};
    }
  }

  Future<Map<String, dynamic>> createRecurringRule({
    required int categoryId,
    required double amount,
    String? description,
    required String recurrenceRule,
    required String startDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) { return {'statusCode': 401, 'body': {'message': 'Unauthorized'}}; }
      
      final url = Uri.parse('$_baseUrl/recurring');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          'category_id': categoryId,
          'amount': amount,
          'description': description,
          'recurrence_rule': recurrenceRule,
          'start_date': startDate,
        }),
      );
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'A network error occurred: $e'}};
    }
  }

  Future<Map<String, dynamic>> getUserRecurringRules() async {
    try {
      final token = await _getToken();
      if (token == null) { return {'statusCode': 401, 'body': {'message': 'Unauthorized'}}; }

      final url = Uri.parse('$_baseUrl/recurring');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'A network error occurred: $e'}};
    }
  }

  Future<Map<String, dynamic>> deleteRecurringRule(int ruleId) async {
    try {
      final token = await _getToken();
      if (token == null) { return {'statusCode': 401, 'body': {'message': 'Unauthorized'}}; }

      final url = Uri.parse('$_baseUrl/recurring/$ruleId');
      final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'A network error occurred: $e'}};
    }
  }
}
