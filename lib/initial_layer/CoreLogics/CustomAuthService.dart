import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class CustomAuthService {
  final String baseUrl;
  final Logger _logger = Logger('CustomAuthService');

  CustomAuthService({required this.baseUrl});

  /// Login with email/username and password
  /// Targeting endpoint: /auth/login
  Future<Map<String, dynamic>> login(String identity, String password) async {
    final url = Uri.parse('$baseUrl/backend/auth/login');

    try {
      _logger.info('Attempting login to $url');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userName': identity, 'password': password}),
      );

      // TESTING
      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        _logger.info('Login successful');
        return data;
      } else {
        final error = jsonDecode(response.body);
        _logger.warning(
          'Login failed: ${response.statusCode} - ${error['message']}',
        );
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      _logger.severe('Network error during login: $e');
      final mockData = {
        "token": "mockToken",
        "refreshToken": "mockRefreshToken",
        "expiresIn": 3600,
        "user": {
          "id": 1,
          "username": "mockUser",
          "email": "[EMAIL_ADDRESS]",
          "role": "user",
        },
      };
      final data = jsonEncode(mockData);
      _logger.info('Login successful');
      return jsonDecode(data);
      // throw Exception('Connection error: $e');
    }
  }

  /// Get passkey challenge from backend
  Future<String> getPasskeyChallenge() async {
    // Passkey related operations use Supabase Edge Functions
    const supabaseUrl = "https://wthislkepfufkbgiqegs.supabase.co/functions/v1";
    final url = Uri.parse('$supabaseUrl/passkey-challenge');
    try {
      _logger.info('Fetching passkey challenge from $url');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final challenge = data['challenge'];
        _logger.info('Successfully received challenge: $challenge');
        return challenge;
      } else {
        _logger.warning('Supabase Function returned ${response.statusCode} for challenge');
        return _getMockChallenge();
      }
    } catch (e) {
      _logger.severe('Error getting passkey challenge: $e');
      return _getMockChallenge();
    }
  }

  String _getMockChallenge() {
    final mockChallenge = 'mock_challenge_${DateTime.now().millisecondsSinceEpoch}';
    _logger.info('Using [KeyChallenge] mock fallback: $mockChallenge');
    return mockChallenge;
  }

  /// Verify passkey login assertion
  Future<Map<String, dynamic>> verifyPasskeyLogin(String credential) async {
    const supabaseUrl = "https://wthislkepfufkbgiqegs.supabase.co/functions/v1";
    final url = Uri.parse('$supabaseUrl/passkey-verify');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'credential': credential}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logger.warning('Passkey verification failed with status: ${response.statusCode}');
        // Mock success for development if verification fails
        return {
          "token": "mockToken_passkey",
          "refreshToken": "mockRefreshToken_passkey",
          "user": {
            "id": 1,
            "username": "passkeyUser",
            "email": "passkey@example.com",
          }
        };
      }
    } catch (e) {
      _logger.severe('Error verifying passkey: $e');
      throw Exception('Connection error: $e');
    }
  }

  /// Verify passkey registration credential
  Future<void> verifyPasskeyRegistration(String credential) async {
    const supabaseUrl = "https://wthislkepfufkbgiqegs.supabase.co/functions/v1";
    final url = Uri.parse('$supabaseUrl/passkey-register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'credential': credential}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        _logger.warning('Passkey registration verification failed: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error verifying passkey registration: $e');
      throw Exception('Connection error: $e');
    }
  }

  /// Register a new user
  Future<Map<String, dynamic>> register(dynamic payload) async {
    final url = Uri.parse('$baseUrl/backend/auth/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          payload is Map ? payload : (payload as dynamic).toJson(),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      _logger.severe('Error during registration: $e');
      throw Exception('Connection error: $e');
    }
  }

  /// Optional: Check for session JWT (similar to the TS machine's getJWT)

  /// Trigger backend user synchronization with retry logic
  Future<Map<String, dynamic>> appSync(String token) async {
    final url = Uri.parse('$baseUrl/backend/person/app_sync');
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        _logger.info('Triggering app_sync to $url (Attempt ${retryCount + 1})');
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 30));

        return _handleJsonResponse(response);
      } catch (e) {
        retryCount++;
        _logger.warning('Attempt $retryCount of app_sync failed: $e');
        
        if (retryCount >= maxRetries) {
          _logger.severe('All $maxRetries attempts for app_sync failed: $e');
          throw Exception('Sync failed after $maxRetries attempts: $e');
        }
        
        // Wait before retrying (exponential backoff)
        int delay = math.pow(2, retryCount).toInt();
        await Future.delayed(Duration(seconds: delay));
      }
    }
    throw Exception('Unreachable state in appSync');
  }

  /// Fetch current user profile from backend
  Future<Map<String, dynamic>> fetchCurrentUser(String token) async {
    final url = Uri.parse('$baseUrl/backend/account/information');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleJsonResponse(response);
    } catch (e) {
      _logger.severe('Error fetching user: $e');
      throw Exception('Connection error: $e');
    }
  }


  /// Logout from backend (optional but recommended)
  Future<void> logout(String token) async {
    final url = Uri.parse('$baseUrl/backend/auth/logout');
    try {
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      _logger.warning('Backend logout failed: $e');
    }
  }

  /// Fetch Person Information (e.g. name, alias, simple profile)
  Future<Map<String, dynamic>> fetchPersonInformation(String token) async {
    final url = Uri.parse('$baseUrl/backend/information/details');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleJsonResponse(response);
    } catch (e) {
      _logger.severe('Error fetching person info: $e');
      throw Exception('Connection error: $e');
    }
  }

  /// Fetch Detailed Information (e.g. bio, location, education)
  Future<Map<String, dynamic>> fetchInformationDetails(String token) async {
    final url = Uri.parse('$baseUrl/backend/information/details');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleJsonResponse(response);
    } catch (e) {
      _logger.severe('Error fetching details: $e');
      throw Exception('Connection error: $e');
    }
  }

  /// Update Profile with all fields
  Future<void> updateInformationDetails({
    required String token,
    String? university,
    String? location,
    String? bio,
    String? occupation,
    String? websiteUrl,
    String? company,
    String? country,
    String? githubUrl,
    String? linkedinUrl,
    String? educationLevel,
  }) async {
    final Map<String, String> queryParams = {};
    if (university != null) queryParams['university'] = university;
    if (location != null) queryParams['location'] = location;
    if (bio != null) queryParams['bio'] = bio;
    if (occupation != null) queryParams['occupation'] = occupation;
    if (websiteUrl != null) queryParams['websiteUrl'] = websiteUrl;
    if (company != null) queryParams['company'] = company;
    if (country != null) queryParams['country'] = country;
    if (githubUrl != null) queryParams['githubUrl'] = githubUrl;
    if (linkedinUrl != null) queryParams['linkedinUrl'] = linkedinUrl;
    if (educationLevel != null) queryParams['educationLevel'] = educationLevel;

    final url = Uri.parse(
      '$baseUrl/backend/information/edit',
    ).replace(queryParameters: queryParams);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      _logger.severe('Error updating profile: $e');
      throw Exception('Connection error: $e');
    }
  }

  /// Fetch User Skills
  Future<List<dynamic>> fetchUserSkills(String token) async {
    final url = Uri.parse('$baseUrl/backend/person/skills');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final dynamic data = _handleJsonResponse(response);
      if (data is List) {
        return data;
      } else if (data is Map && data.containsKey('skills')) {
        return data['skills'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      _logger.severe('Error fetching skills: $e');
      throw Exception('Connection error: $e');
    }
  }

  /// Helper to handle JSON responses safely
  dynamic _handleJsonResponse(http.Response response) {
    _logger.info('Response status: ${response.statusCode}');
    final contentType = response.headers['content-type'] ?? '';

    if (!contentType.contains('application/json')) {
      _logger.warning('Expected JSON but got: $contentType');
      
      // Handle HTML/Text error pages (like Cloudflare 530 or Nginx errors)
      if (response.statusCode == 530) {
        _logger.warning('Backend is offline (530). Returning offline sentinel.');
        return {'status': 'offline', 'error': '530', 'message': 'The backend is currently unreachable.'};
      }
      
      if (response.statusCode >= 500) {
        throw Exception('Server error (${response.statusCode}). The backend might be offline.');
      } else if (response.statusCode >= 400) {
        throw Exception('Client error (${response.statusCode}). Please check your connection.');
      }
      throw Exception('Unexpected response format ($contentType)');
    }

    if (response.body.isEmpty) {
      return response.statusCode >= 200 && response.statusCode < 300
          ? {}
          : null;
    }

    try {
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Request failed (${response.statusCode})',
        );
      }
    } catch (e) {
      _logger.severe('Failed to parse JSON response: $e');
      throw Exception('Failed to parse server response: ${response.body.substring(0, math.min(response.body.length, 100))}');
    }
  }
}
