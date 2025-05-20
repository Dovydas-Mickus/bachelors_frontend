// ignore_for_file: file_names, unused_catch_clause, empty_catches

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb, debugPrint;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
// Choose the correct adapter based on platform
import 'package:dio/io.dart' if (dart.library.html) 'package:dio/browser.dart';

// Import your models (ensure paths are correct)
import 'models/cloud_item.dart';
import 'models/team.dart';
import 'models/user.dart';

class APIRepository {
  final String baseUrl;
  late final Dio dio;
  String? userId; // Consider removing if not consistently used/set

  PersistCookieJar? _cookieJar;

  // Token timing constants (adjust to match backend if needed)
  final Duration tokenValidityDuration = const Duration(minutes: 15);
  final Duration tokenRefreshBuffer = const Duration(minutes: 3);

  // --- API Prefixes ---
  static const String _authPrefix = '/auth';
  static const String _filesPrefix = '/files';
  static const String _teamsPrefix = '/teams';
  static const String _adminPrefix = '/admin';
  // No prefix needed for root ('/') or specific shared routes ('/share', '/shared/...')

  APIRepository._internal({this.baseUrl = 'cloud.mickus.me/api'}) {
    dio = Dio(BaseOptions(
      baseUrl: 'https://$baseUrl',
      headers: {'content-type': 'application/json'},
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    if (kIsWeb) {
      dio.options.extra = {'withCredentials': true};
      debugPrint('[APIRepository] Web platform – using browser cookies');
    }

    // ADDING LogInterceptor HERE (after initial Dio setup but before CookieManager for detailed view)
    // This will show requests before CookieManager acts, and responses after.
    // If you want to see exactly what CookieManager sends, place this *after* CookieManager.
    // For debugging "missing cookie", seeing the raw server response (Set-Cookie) is key first.
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true, // Be careful with this in production for large responses
      error: true,
      logPrint: (object) {
        debugPrint(object.toString()); // Ensures logs go to Flutter's debug console
      },
    ));
  }

  static Future<APIRepository> create(
      {String baseUrl = 'cloud.mickus.me/api'}) async {
    final repository = APIRepository._internal(baseUrl: baseUrl);
    await repository._initialize();
    return repository;
  }

  Future<void> _initialize() async {
    debugPrint('[APIRepository] Initializing...');
    if (!kIsWeb) {
      await _setupCookieJar(); // This adds CookieManager to interceptors
    }
    // If you want LogInterceptor to see what CookieManager sends on requests,
    // you could move its addition to *after* _setupCookieJar (for non-web).
    // However, for diagnosing "Set-Cookie" issues from the server on login,
    // having LogInterceptor before CookieManager is better to see raw server response.
    // For "Cookie" header missing on refresh, LogInterceptor *after* CookieManager helps.
    // Let's keep it in the constructor for now, it will show server response headers fine.
    debugPrint('[APIRepository] Initialization complete.');
  }

  Future<void> _setupCookieJar() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cookieDir = Directory('${dir.path}/.cookies');
      if (!await cookieDir.exists()) await cookieDir.create(recursive: true);
      _cookieJar = PersistCookieJar(
        ignoreExpires: false,
        storage: FileStorage(cookieDir.path),
      );
      dio.interceptors.add(CookieManager(_cookieJar!));
      debugPrint('[APIRepository] CookieJar set up at ${cookieDir.path}');
    } catch (e) {
      debugPrint('[APIRepository] ❌ CookieJar init failed: $e');
      _cookieJar = null;
    }
  }

  // --- Logout Method ---
  Future<void> logout() async {
    debugPrint("[APIRepository] Attempting logout...");
    try {
      // Logout is under the auth blueprint
      await dio.post("$_authPrefix/logout"); // <-- PREFIXED
      debugPrint("[APIRepository] Server logout request sent.");
    } catch (e) {
      debugPrint("⚠️ Error sending server logout request: $e");
    }
    // Client-side cleanup remains the same
    try {
      if (!kIsWeb && _cookieJar != null) {
        await _cookieJar!.deleteAll();
        debugPrint("[APIRepository] Persisted cookies cleared.");
      } else if (kIsWeb) {
        debugPrint("[APIRepository] Web logout: Relying on server Set-Cookie headers.");
      } else {
        debugPrint("⚠️ Logout: CookieJar instance was null.");
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("access_token_expiry");
      debugPrint("[APIRepository] Local token expiry timestamp cleared.");
      debugPrint("✅ Logout cleanup complete.");
    } catch (e) {
      debugPrint("❌ Error during client-side logout cleanup: $e");
    }
  }


  // --- Token Handling Methods ---
  Future<void> _setAccessTokenTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiry = DateTime.now().add(tokenValidityDuration).millisecondsSinceEpoch;
      await prefs.setInt('access_token_expiry', expiry);
    } catch (e) {
      debugPrint('❌ _setAccessTokenTimestamp error: $e');
    }
  }

  Future<bool> ensureTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryMs = prefs.getInt('access_token_expiry');
    if (expiryMs == null) {
      debugPrint('[ensureTokenValid] No expiryMs found. Assuming invalid.');
      return false;
    }
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    final now = DateTime.now();
    if (now.isAfter(expiry)) {
      debugPrint('[ensureTokenValid] Token is EXPIRED based on local timestamp. Calling refresh...');
      return refreshAccessToken(logoutOnFail: true); // Logout if expired and refresh fails
    }
    final refreshThreshold = expiry.subtract(tokenRefreshBuffer);
    if (now.isAfter(refreshThreshold)) {
      debugPrint('[ensureTokenValid] Token nearing expiry (within buffer). Calling refresh proactively...');
      return refreshAccessToken(logoutOnFail: false);
    }
    return true;
  }

  Future<bool> refreshAccessToken({ bool logoutOnFail = false }) async {
    debugPrint('[refreshAccessToken] Attempting POST $_authPrefix/refresh...'); // <-- PREFIXED

    if (!kIsWeb && _cookieJar != null) {
      final cookiesForRefresh = await _cookieJar!.loadForRequest(
        // Ensure the URI exactly matches how Dio would form it for the request
          dio.options.baseUrl.startsWith('https://') || dio.options.baseUrl.startsWith('http://')
              ? Uri.parse('${dio.options.baseUrl}$_authPrefix/refresh')
              : Uri.parse('https://${dio.options.baseUrl}$_authPrefix/refresh') // Assuming https if not specified
      );
      debugPrint('[refreshAccessToken] Cookies loaded by PersistCookieJar for $_authPrefix/refresh BEFORE request:');
      for (var cookie in cookiesForRefresh) {
        debugPrint('  ${cookie.name}=${cookie.value}; Path=${cookie.path}; Domain=${cookie.domain}; Expires=${cookie.expires}; HttpOnly=${cookie.httpOnly}');
      }
    }

    try {
      final response = await dio.post('$_authPrefix/refresh'); // <-- PREFIXED
      debugPrint('[refreshAccessToken] Received response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        debugPrint('[refreshAccessToken] ✅ Refresh successful. Setting timestamp...');
        await _setAccessTokenTimestamp();
        return true;
      } else {
        debugPrint('[refreshAccessToken] ❌ Refresh failed with status: ${response.statusCode}. Response data: ${response.data}');
        if (logoutOnFail && (response.statusCode == 401 || response.statusCode == 422)) {
          debugPrint('[refreshAccessToken] Logging out due to ${response.statusCode} on refresh.');
          await logout();
        }
        return false;
      }
    } on DioException catch (e) {
      debugPrint('[refreshAccessToken] ❌ DioException during refresh: ${e.response?.statusCode} - ${e.message}');
      if (e.response != null) {
        debugPrint('   Response Data: ${e.response?.data}');
        if (logoutOnFail && (e.response?.statusCode == 401 || e.response?.statusCode == 422)) {
          debugPrint('[refreshAccessToken] Logging out due to DioException(${e.response?.statusCode}) on refresh.');
          await logout();
        }
      } else {
        debugPrint('   Error details: Request error or timeout.');
      }
      return false;
    } catch (e) {
      debugPrint('[refreshAccessToken] ❌ Unexpected error during refresh: $e');
      return false;
    }
  }

  // --- User / Auth Methods ---
  Future<bool> login(String email, String password) async {
    debugPrint("🔹 Login request for $email");
    try {
      final response = await dio.post("$_authPrefix/login", data: { // <-- PREFIXED
        "email": email,
        "password": password,
      });
      if (response.statusCode == 200) {
        debugPrint("✅ Login successful for $email");
        await _setAccessTokenTimestamp();

        // After successful login, explicitly check what cookies were stored (for non-web)
        if (!kIsWeb && _cookieJar != null) {
          final loginUri = dio.options.baseUrl.startsWith('https://') || dio.options.baseUrl.startsWith('http://')
              ? Uri.parse('${dio.options.baseUrl}$_authPrefix/login')
              : Uri.parse('https://${dio.options.baseUrl}$_authPrefix/login');

          final cookiesAfterLogin = await _cookieJar!.loadForRequest(loginUri);
          debugPrint('[login] Cookies loaded by PersistCookieJar AFTER login from ${loginUri.toString()}:');
          for (var cookie in cookiesAfterLogin) {
            debugPrint('  ${cookie.name}=${cookie.value}; Path=${cookie.path}; Domain=${cookie.domain}; Expires=${cookie.expires}; HttpOnly=${cookie.httpOnly}; Secure=${cookie.secure}; SameSite=${cookie.domain != null ? "N/A for PersistCookieJar" : "N/A"}');
          }
          // Check all cookies for the base domain as well, path '/'
          final allCookiesBase = await _cookieJar!.loadForRequest(
              Uri.parse(dio.options.baseUrl.startsWith('https://') || dio.options.baseUrl.startsWith('http://')
                  ? dio.options.baseUrl
                  : 'https://${dio.options.baseUrl}'));
          debugPrint('[login] ALL Cookies loaded by PersistCookieJar for base domain ${dio.options.baseUrl} AFTER login:');
          for (var cookie in allCookiesBase) {
            debugPrint('  ${cookie.name}=${cookie.value}; Path=${cookie.path}; Domain=${cookie.domain}; Expires=${cookie.expires}; HttpOnly=${cookie.httpOnly}; Secure=${cookie.secure}; SameSite=${cookie.domain != null ? "N/A for PersistCookieJar" : "N/A"}');
          }
        }
        return true;
      } else {
        debugPrint("❌ Login failed for $email with status: ${response.statusCode}. Response: ${response.data}");
        return false;
      }
    } on DioException catch (e) {
      debugPrint("❌ DioException during login for $email: ${e.response?.statusCode} - ${e.message}");
      if (e.response != null) {
        debugPrint("   Response Data: ${e.response?.data}");
      } else {
        debugPrint("   Error details: Request connection error or timeout.");
      }
      return false;
    } catch (e) {
      debugPrint("❌ Unexpected error during login for $email: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    debugPrint("[getProfile] Attempting GET $_authPrefix/profile..."); // <-- PREFIXED
    if (!await ensureTokenValid()) {
      debugPrint("[getProfile] Token invalid or refresh failed. Cannot fetch profile.");
      return null;
    }
    try {
      final response = await dio.get("$_authPrefix/profile"); // <-- PREFIXED
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        debugPrint("✅ Profile fetched successfully.");
        return Map<String, dynamic>.from(response.data);
      } else {
        debugPrint("❌ Failed to fetch profile with status: ${response.statusCode}. Response: ${response.data}");
        if(response.statusCode == 401) {
          debugPrint("[getProfile] Received unexpected 401. Logging out.");
          await logout();
        }
        if(response.statusCode == 404) {
          debugPrint("[getProfile] Received 404. User deleted? Logging out.");
          await logout();
        }
        return null;
      }
    } on DioException catch (e) {
      debugPrint("❌ DioException fetching profile: ${e.response?.statusCode} - ${e.message}");
      if (e.response?.statusCode == 401) {
        debugPrint("   Got 401 in DioException for getProfile. Logging out.");
        await logout();
      }
      if (e.response?.statusCode == 404) {
        debugPrint("   Got 404 in DioException for getProfile. Logging out.");
        await logout();
      }
      return null;
    } catch (e) {
      debugPrint("❌ Unexpected error fetching profile: $e");
      return null;
    }
  }

  Future<bool> registerUser({ required String firstName, required String lastName, required String email, required String password, required String role }) async {
    debugPrint("🔹 Register User request for: $email with role: $role");
    try {
      final response = await dio.post("$_authPrefix/register", data: { // <-- PREFIXED
        "first_name": firstName, "last_name": lastName, "email": email,
        "password": password, "role": role,
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>?;
        final userId = responseData?['user']?['id'] ?? responseData?['id'];
        debugPrint("✅ User '$email' registered successfully. ID: $userId");
        return true;
      } else {
        debugPrint("❌ User registration for '$email' returned status ${response.statusCode}. Response: ${response.data}");
        return false;
      }
    } on DioException catch (e) {
      debugPrint("❌ DioException registering user '$email': ${e.response?.statusCode} - ${e.message}");
      if (e.response != null) {
        final errorData = e.response?.data as Map<String, dynamic>?;
        final serverError = errorData?['error'];
        debugPrint("   Server Error: $serverError");
      } else { debugPrint("   Error details: Request connection error or timeout."); }
      return false;
    } catch (e) { debugPrint("❌ Generic exception registering user '$email': $e"); return false; }
  }

  // --- Admin Methods ---
  Future<List<User>> getUsers() async {
    debugPrint("[getUsers] Attempting GET $_adminPrefix/users"); // <-- PREFIXED
    if (!await ensureTokenValid()) { debugPrint("[getUsers] Token invalid. Aborting."); return []; }
    try {
      final response = await dio.get("$_adminPrefix/users"); // <-- PREFIXED
      if (response.statusCode == 200 && response.data is List) {
        final data = response.data as List;
        debugPrint("[getUsers] ✅ Received ${data.length} users.");
        List<User> parsedUsers = [];
        for (var u in data) {
          try { parsedUsers.add(User.fromJson(u as Map<String, dynamic>)); }
          catch (e) { debugPrint("  ❌ ERROR parsing user: $e. User data: $u"); }
        }
        return parsedUsers;
      } else {
        debugPrint("[getUsers] ❌ Failed with status: ${response.statusCode}. Response: ${response.data}");
        return [];
      }
    } on DioException catch (e) {
      debugPrint("❌ DioException getting users: ${e.response?.statusCode} - ${e.message}");
      return [];
    } catch (e) { debugPrint("❌ Generic exception getting users: $e"); return []; }
  }

  Future<bool> deleteUser(String userIdToDelete) async {
    final url = '$_adminPrefix/users/$userIdToDelete'; // <-- PREFIXED
    debugPrint("[deleteUser] Attempting DELETE $url");
    if (userIdToDelete.trim().isEmpty) { debugPrint("[deleteUser] User ID cannot be empty."); return false; }
    if (!await ensureTokenValid()) { debugPrint("[deleteUser] Token invalid. Aborting."); return false; }

    try {
      final response = await dio.delete(
          url,
          options: Options(
            validateStatus: (status) => status != null && (status == 200 || status == 204),
          )
      );
      debugPrint("✅ User deleted successfully (ID: $userIdToDelete). Status: ${response.statusCode}");
      return true;
    } on DioException catch (e) {
      debugPrint("❌ DioException deleting user '$userIdToDelete': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) {
      debugPrint("❌ Unexpected generic error deleting user '$userIdToDelete': $e");
      return false;
    }
  }


  // --- File/Cloud Methods ---
  Future<List<CloudItem>> fetchCloud({ String path = '', String? userId }) async {
    debugPrint('[fetchCloud] GET $_filesPrefix/cloud path="$path" userId=$userId'); // <-- PREFIXED
    if (!await ensureTokenValid()) { debugPrint('[fetchCloud] Token invalid. Aborting.'); return []; }
    try {
      final response = await dio.get(
          '$_filesPrefix/cloud', // <-- PREFIXED
          queryParameters: { 'path': path, if (userId != null) 'user_id': userId, });
      if (response.statusCode == 200 && response.data?['cloud_contents'] is List) {
        final list = response.data['cloud_contents'] as List;
        return list
            .map((e) => CloudItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('[fetchCloud] ❌ Failed with Status ${response.statusCode}: ${response.data}');
        return [];
      }
    } on DioException catch (e) {
      debugPrint('❌ fetchCloud DioException: ${e.response?.statusCode} - ${e.message}');
      return [];
    } catch (e) { debugPrint('❌ fetchCloud unexpected error: $e'); return []; }
  }

  Future<Map<String, dynamic>?> fetchFileBytes( String relativePath, { String? userId }) async {
    debugPrint('[fetchFileBytes] GET $_filesPrefix/preview path="$relativePath" userId=$userId'); // <-- PREFIXED
    if (!await ensureTokenValid()) return null;
    try {
      final response = await dio.get(
        '$_filesPrefix/preview', // <-- PREFIXED
        queryParameters: { 'path': relativePath, if (userId != null) 'user_id': userId, },
        options: Options( responseType: ResponseType.bytes, followRedirects: false, validateStatus: (s) => s != null && s >= 200 && s < 300, ),
      );
      final contentType = response.headers.value(HttpHeaders.contentTypeHeader) ?? 'application/octet-stream';
      return { 'bytes': Uint8List.fromList(response.data as List<int>), 'contentType': contentType, };
    } on DioException catch (e) {
      debugPrint('❌ fetchFileBytes DioException: ${e.response?.statusCode} - ${e.message}');
      return null;
    } catch (e) { debugPrint('❌ fetchFileBytes unexpected error: $e'); return null; }
  }

  Future<bool> uploadFile(PlatformFile file, String uploadPath, {String? userId}) async {
    debugPrint("[uploadFile] POST $_filesPrefix/upload '${file.name}' to '$uploadPath', UserID: $userId"); // <-- PREFIXED
    if (!await ensureTokenValid()) { debugPrint("[uploadFile] Token invalid. Aborting."); return false; }
    try {
      MultipartFile multipartFile;
      if (kIsWeb) {
        if (file.bytes == null) { debugPrint("❌ Upload failed: No file bytes (web)."); return false; }
        String mimeType = 'application/octet-stream';
        if (file.name.endsWith('.jpg') || file.name.endsWith('.jpeg')) mimeType = 'image/jpeg';
        if (file.name.endsWith('.png')) mimeType = 'image/png';
        if (file.name.endsWith('.pdf')) mimeType = 'application/pdf';
        multipartFile = MultipartFile.fromBytes( file.bytes!, filename: file.name, contentType: MediaType.parse(mimeType), );
      } else {
        if (file.path == null) { debugPrint("❌ Upload failed: No file path (non-web)."); return false; }
        multipartFile = await MultipartFile.fromFile( file.path!, filename: file.name );
      }
      final formData = FormData.fromMap({ "file": multipartFile, "path": uploadPath });
      final queryParams = userId != null ? {'user_id': userId} : null;

      final response = await dio.post(
          "$_filesPrefix/upload", // <-- PREFIXED
          data: formData,
          queryParameters: queryParams,
          options: Options( responseType: ResponseType.json, validateStatus: (status) => status != null && (status == 200 || status == 201) )
      );
      debugPrint("✅ File '${file.name}' uploaded. Status: ${response.statusCode}");
      return true;
    } on DioException catch (e) {
      debugPrint("❌ DioException uploading file '${file.name}': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) { debugPrint("❌ Unexpected error uploading file '${file.name}': $e"); return false; }
  }

  Future<bool> deleteItem(String path, {String? userId}) async {
    debugPrint("[deleteItem] DELETE $_filesPrefix/delete path: '$path', UserID: $userId"); // <-- PREFIXED
    if (!await ensureTokenValid()) { debugPrint("[deleteItem] Token invalid. Aborting."); return false; }
    try {
      final queryParams = userId != null ? {'user_id': userId} : null;
      final response = await dio.delete(
          "$_filesPrefix/delete", // <-- PREFIXED
          data: {"path": path},
          queryParameters: queryParams,
          options: Options( validateStatus: (status) => status != null && (status == 200 || status == 204) )
      );
      debugPrint("✅ Item deleted at path: '$path'. Status: ${response.statusCode}");
      return true;
    } on DioException catch (e) {
      debugPrint("❌ DioException deleting item at '$path': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) { debugPrint("❌ Unexpected error deleting item at '$path': $e"); return false; }
  }

  Future<List<CloudItem>> getSearch(String query, {String? userId}) async {
    if (query.trim().isEmpty) return [];
    debugPrint('[getSearch] GET $_filesPrefix/search Query="$query" userId=$userId'); // <-- PREFIXED
    if (!await ensureTokenValid()) return [];
    try {
      final response = await dio.get(
          '$_filesPrefix/search', // <-- PREFIXED
          queryParameters: { 'q': query, if (userId != null) 'user_id': userId, }
      );
      if (response.statusCode == 200 && response.data?['results'] is List) {
        final list = response.data['results'] as List;
        return list.map((e) => CloudItem.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        debugPrint('[getSearch] ❌ Failed with Status ${response.statusCode}: ${response.data}');
        return [];
      }
    } on DioException catch (e) {
      debugPrint('❌ getSearch DioException: ${e.response?.statusCode} - ${e.message}');
      return [];
    } catch (e) { debugPrint('❌ getSearch unexpected error: $e'); return []; }
  }

  Future<bool> createFolder(String path, {String? userId}) async {
    debugPrint("[createFolder] POST $_filesPrefix/mkdir path: '$path', UserID: $userId"); // <-- PREFIXED
    if (path.trim().isEmpty) { debugPrint("[createFolder] Path cannot be empty."); return false; }
    if (!await ensureTokenValid()) { debugPrint("[createFolder] Token invalid. Aborting."); return false; }
    try {
      final queryParams = userId != null ? {'user_id': userId} : null;
      final response = await dio.post(
          "$_filesPrefix/mkdir", // <-- PREFIXED
          data: {"path": path},
          queryParameters: queryParams,
          options: Options( validateStatus: (status) => status == 201 )
      );
      debugPrint("✅ Folder created at path: '$path'. Status: ${response.statusCode}");
      return true;
    } on DioException catch (e) {
      debugPrint("❌ DioException creating folder at '$path': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) { debugPrint("❌ Unexpected error creating folder at '$path': $e"); return false; }
  }

  Future<bool> renameItem(String oldPath, String newName, {String? userId}) async {
    debugPrint("[renameItem] POST $_filesPrefix/rename from '$oldPath' to '$newName', UserID: $userId"); // <-- PREFIXED
    if (oldPath.trim().isEmpty || newName.trim().isEmpty) { debugPrint("[renameItem] Paths cannot be empty."); return false; }
    if (newName.contains('/') || newName.contains('\\')) { debugPrint("[renameItem] New name cannot contain slashes."); return false; }
    if (!await ensureTokenValid()) { debugPrint("[renameItem] Token invalid. Aborting."); return false; }
    try {
      final queryParams = userId != null ? {'user_id': userId} : null;
      final response = await dio.post(
          "$_filesPrefix/rename", // <-- PREFIXED
          data: {"old_path": oldPath, "new_name": newName},
          queryParameters: queryParams,
          options: Options( validateStatus: (status) => status == 200 )
      );
      debugPrint("✅ Item renamed from '$oldPath' to '$newName'. Status: ${response.statusCode}");
      return true;
    } on DioException catch (e) {
      debugPrint("❌ DioException renaming item from '$oldPath' to '$newName': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) { debugPrint("❌ Unexpected error renaming item from '$oldPath' to '$newName': $e"); return false; }
  }

  Future<Map<String, dynamic>?> downloadFile( String relativePath, { String? userId }) async {
    debugPrint('[downloadFile] GET $_filesPrefix/download path="$relativePath" userId=$userId'); // <-- PREFIXED
    if (!await ensureTokenValid()) return null;
    try {
      final response = await dio.get<List<int>>(
        '$_filesPrefix/download', // <-- PREFIXED
        queryParameters: <String, dynamic>{ 'path': relativePath, if (userId != null) 'user_id': userId, },
        options: Options( responseType: ResponseType.bytes, followRedirects: false, validateStatus: (status) => status != null && status >= 200 && status < 300, ),
      );

      String? contentDisp = response.headers.value(HttpHeaders.contentTypeHeader); // Corrected header access
      String filename = relativePath.split('/').last;
      if (contentDisp != null) {
        RegExp regex = RegExp('filename\\*?=(?:(["\'])(.*?)\\1|([^;\\s]*))', caseSensitive: false);
        var match = regex.firstMatch(contentDisp);
        if (match != null) { filename = (match.group(2) ?? match.group(3) ?? filename).trim(); }
      }
      debugPrint('[downloadFile] Determined filename: $filename');

      if (kIsWeb) {
        return <String, dynamic>{ 'bytes': Uint8List.fromList(response.data!), 'contentType': response.headers.value(HttpHeaders.contentTypeHeader) ?? 'application/octet-stream', 'filename': filename, };
      } else {
        Directory? baseDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        if (baseDir == null) return null;
        String safeFilename = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final filePath = '${baseDir.path}/$safeFilename';
        final file = File(filePath);
        await file.writeAsBytes(response.data!, flush: true);
        debugPrint('[downloadFile] ✅ Saved to $filePath');
        return <String, dynamic>{ 'path': filePath, 'filename': safeFilename, };
      }
    } on DioException catch (e) {
      debugPrint('❌ downloadFile DioException: ${e.response?.statusCode} - ${e.message}');
      return null;
    } catch (e, stackTrace) { debugPrint('❌ downloadFile unexpected error: $e\n$stackTrace'); return null; }
  }


  // --- Team Methods ---

  // --- NEW: fetchAssociatedTeams METHOD ---
  // --- CORRECTED fetchAssociatedTeams ---
  Future<List<Team>> fetchAssociatedTeams() async {
    debugPrint('[fetchAssociatedTeams] GET $_teamsPrefix/associated');
    if (!await ensureTokenValid()) {
      debugPrint('[fetchAssociatedTeams] Token invalid or refresh failed. Aborting.');
      return [];
    }
    try {
      final response = await dio.get("$_teamsPrefix/associated");

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> dataList = response.data as List;
        debugPrint("[fetchAssociatedTeams] ✅ Received ${dataList.length} associated teams.");
        // --- CHANGE FACTORY HERE ---
        // Use Team.fromJson because the backend now sends separate 'lead' and 'members'
        return dataList
            .whereType<Map<String, dynamic>>()
            .map((item) => Team.fromJson(item)) // <-- USE fromJson
            .toList();
        // --- END CHANGE ---
      } else {
        debugPrint("[fetchAssociatedTeams] ❌ Failed with status code ${response.statusCode}. Response: ${response.data}");
        return [];
      }
    } on DioException catch (e) {
      debugPrint("[fetchAssociatedTeams] ❌ DioException: ${e.response?.statusCode} - ${e.message}");
      return [];
    } catch (e, stackTrace) {
      debugPrint("[fetchAssociatedTeams] ❌ Unexpected error: $e \n $stackTrace");
      return [];
    }
  }
  // --- END fetchAssociatedTeams METHOD ---

  Future<List<Team>> fetchMyTeams() async {
    debugPrint('[fetchMyTeams] GET $_teamsPrefix/my_teams');
    if (!await ensureTokenValid()) { debugPrint('[fetchMyTeams] Token invalid. Aborting.'); return []; }
    try {
      final response = await dio.get('$_teamsPrefix/my_teams');
      if (response.statusCode == 200 && response.data is List) {
        final dataList = response.data as List;
        debugPrint('[fetchMyTeams] ✅ Success: Received ${dataList.length} teams.');
        // --- CHANGE FACTORY HERE ---
        // Use Team.fromJson because the backend now sends separate 'lead' and 'members'
        // and uses 'id' (via the _populate_team_users helper called by db.get_teams_by_lead)
        return dataList
            .whereType<Map<String, dynamic>>()
            .map((json) => Team.fromJson(json)) // <-- USE fromJson
            .toList();
        // --- END CHANGE ---
      } else {
        debugPrint('[fetchMyTeams] ❌ Failed with status ${response.statusCode}: ${response.data}');
        return [];
      }
    } on DioException catch (e) {
      debugPrint('❌ fetchMyTeams DioException: ${e.response?.statusCode} - ${e.message}');
      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ fetchMyTeams unexpected error: $e\n$stackTrace');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchTeamOverview(String teamId) async {
    debugPrint('[fetchTeamOverview] GET $_teamsPrefix/$teamId/overview'); // <-- PREFIXED
    if (!await ensureTokenValid()) { debugPrint('[fetchTeamOverview] Token invalid. Aborting.'); return null; }
    try {
      final response = await dio.get('$_teamsPrefix/$teamId/overview'); // <-- PREFIXED
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data as Map);
      } else {
        debugPrint('[fetchTeamOverview] ❌ Failed with status ${response.statusCode}: ${response.data}');
        return null;
      }
    } on DioException catch (e) {
      debugPrint('❌ fetchTeamOverview DioException: ${e.response?.statusCode} - ${e.message}');
      return null;
    } catch (e) { debugPrint('❌ fetchTeamOverview unexpected error: $e'); return null; }
  }

  Future<bool> createTeam({ required String name, required String lead, required List<String> emails }) async {
    debugPrint("[createTeam] POST $_teamsPrefix/create for name: '$name'"); // <-- PREFIXED
    if (!await ensureTokenValid()) { debugPrint("[createTeam] Token invalid. Aborting."); return false; }
    try {
      final response = await dio.post(
          "$_teamsPrefix/create", // <-- PREFIXED
          data: { "name": name, "lead": lead, "emails": emails, },
          options: Options( validateStatus: (status) => status == 201 )
      );
      debugPrint("✅ Team '$name' created. Status: ${response.statusCode}");
      return true;
    } on DioException catch (e) {
      debugPrint("❌ DioException creating team '$name': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) { debugPrint("❌ Generic exception creating team '$name': $e"); return false; }
  }

  Future<bool> editTeam({ required String teamId, String? newName, String? newLeadEmail, List<String>? addEmails, List<String>? removeEmails }) async {
    debugPrint("[editTeam] POST $_teamsPrefix/edit for ID: '$teamId'"); // <-- PREFIXED
    if (!await ensureTokenValid()) { debugPrint("[editTeam] Token invalid. Aborting."); return false; }
    final Map<String, dynamic> requestData = {
      "team_id": teamId,
      if (newName != null && newName.isNotEmpty) "new_name": newName,
      if (newLeadEmail != null && newLeadEmail.isNotEmpty) "lead": newLeadEmail,
      if (addEmails != null && addEmails.isNotEmpty) "add_emails": addEmails,
      if (removeEmails != null && removeEmails.isNotEmpty) "remove_emails": removeEmails,
    };
    if (requestData.length <= 1) { debugPrint("[editTeam] No changes specified."); return true; }
    try {
      debugPrint('Edit Team Request Data: $requestData');
      final response = await dio.post(
          "$_teamsPrefix/edit", // <-- PREFIXED
          data: requestData,
          options: Options( validateStatus: (status) => status == 200 )
      );
      debugPrint("✅ Team '$teamId' edited. Status: ${response.statusCode}");
      return true;
    } on DioException catch (e) {
      debugPrint("❌ DioException editing team '$teamId': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) { debugPrint("❌ Generic exception editing team '$teamId': $e"); return false; }
  }

  Future<Team?> getTeam({String? teamId, String? name}) async {
    debugPrint("[getTeam] GET $_teamsPrefix/details with ID: '$teamId', Name: '$name'");
    if (teamId == null && name == null) {
      debugPrint("[getTeam] Requires either teamId or name.");
      return null;
    }
    if (!await ensureTokenValid()) {
      debugPrint("[getTeam] Token invalid. Aborting.");
      return null;
    }
    try {
      final queryParams = {
        if (teamId != null) "team_id": teamId,
        if (name != null) "name": name,
      };
      final response = await dio.get(
          "$_teamsPrefix/details", // Correct endpoint
          queryParameters: queryParams
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        debugPrint("[getTeam] ✅ Team data received.");
        // --- CHANGE FACTORY HERE ---
        // Use Team.fromJson because the backend /teams/details endpoint
        // now returns the structure with separate 'lead' and 'members' keys
        // and uses the 'id' key.
        return Team.fromJson(response.data as Map<String, dynamic>); // <-- USE fromJson
        // --- END CHANGE ---
      } else if (response.statusCode == 404) {
        debugPrint("[getTeam] ℹ️ Team not found (404)");
        return null;
      } else {
        debugPrint("[getTeam] ❌ Failed with status: ${response.statusCode}. Response: ${response.data}");
        return null;
      }
    } on DioException catch (e) {
      debugPrint("❌ DioException getting team: ${e.response?.statusCode} - ${e.message}");
      return null;
    } catch (e, stackTrace) {
      // Catch the FormatException here specifically if needed
      if (e is FormatException) {
        debugPrint("❌ FormatException parsing team in getTeam: $e\n$stackTrace");
      } else {
        debugPrint("❌ Generic exception getting team: $e\n$stackTrace");
      }
      return null;
    }
  }

  Future<List<Team>> getAllTeams() async {
    debugPrint('[getAllTeams] GET $_teamsPrefix/all');
    if (!await ensureTokenValid()) {
      debugPrint('[getAllTeams] Token invalid. Aborting.');
      return [];
    }
    try {
      final response = await dio.get("$_teamsPrefix/all");
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> dataList = response.data as List;
        debugPrint("[getAllTeams] ✅ Received ${dataList.length} teams.");
        // --- CHANGE FACTORY HERE ---
        // Use Team.fromJson because the backend now sends separate 'lead' and 'members'
        // and uses 'id' instead of '_id'.
        return dataList
            .whereType<Map<String, dynamic>>()
            .map((item) => Team.fromJson(item)) // <-- USE fromJson
            .toList();
        // --- END CHANGE ---
      } else {
        debugPrint("[getAllTeams] ❌ Failed with status code ${response.statusCode}. Response: ${response.data}");
        return [];
      }
    } on DioException catch (e) {
      debugPrint("[getAllTeams] ❌ DioException: ${e.response?.statusCode} - ${e.message}");
      return [];
    } catch (e, stackTrace) {
      debugPrint("[getAllTeams] ❌ Unexpected error: $e \n $stackTrace");
      return [];
    }
  }

  Future<bool> deleteTeam(String teamId) async {
    debugPrint("[deleteTeam] DELETE $_teamsPrefix/$teamId"); // <-- PREFIXED
    if (teamId.trim().isEmpty) { debugPrint("[deleteTeam] Team ID cannot be empty."); return false; }
    if (!await ensureTokenValid()) { debugPrint("[deleteTeam] Token invalid. Aborting."); return false; }
    final url = '$_teamsPrefix/$teamId'; // <-- PREFIXED
    try {
      final response = await dio.delete( url, options: Options( validateStatus: (status) => status != null && (status == 200 || status == 204), ) );
      debugPrint("✅ Team deleted (ID: $teamId). Status: ${response.statusCode}");
      return true;
    } on DioException catch (e) {
      debugPrint("❌ DioException deleting team '$teamId': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) { debugPrint("❌ Unexpected generic error deleting team '$teamId': $e"); return false; }
  }


  // --- Share Methods ---
  Future<String?> createShareLink({
    required String filePath,
    required String shareType,
    String? targetEmail,
    String? targetTeamId,
    int? durationDays,
    bool? allowDownload,
    String? fileOwnerId,
  }) async {
    debugPrint("[createShareLink] POST /share for path: '$filePath'"); // <-- NO PREFIX
    if (!await ensureTokenValid()) { debugPrint("[createShareLink] Token invalid. Aborting."); return null; }

    final Map<String, dynamic> requestData = {
      "file_path": filePath, "share_type": shareType,
      if (targetEmail != null) "target_email": targetEmail,
      if (targetTeamId != null) "target_team_id": targetTeamId,
      if (durationDays != null) "duration_days": durationDays,
      if (allowDownload != null) "allow_download": allowDownload,
    };
    final queryParams = fileOwnerId != null ? {'user_id': fileOwnerId} : null;

    debugPrint("[createShareLink] Data: $requestData, Query: $queryParams");
    try {
      final response = await dio.post(
        "/share", // <-- NO PREFIX
        data: requestData,
        queryParameters: queryParams,
        options: Options(validateStatus: (status) => status == 201),
      );
      if (response.data is Map<String, dynamic> && response.data['share_url'] != null) {
        final shareUrl = response.data['share_url'] as String;
        debugPrint("✅ Share link created: $shareUrl");
        return shareUrl;
      } else {
        debugPrint("❌ Share link created (201), but response unexpected: ${response.data}");
        return null;
      }
    } on DioException catch (e) {
      debugPrint("❌ DioException creating share link for '$filePath': ${e.response?.statusCode} - ${e.message}");
      return null;
    } catch (e) { debugPrint("❌ Generic exception creating share link for '$filePath': $e"); return null; }
  }


  // --- Admin Audit Log ---
  Future<String?> fetchAuditLog() async {
    debugPrint("[fetchAuditLog] GET $_adminPrefix/audit_log"); // <-- PREFIXED
    if (!await ensureTokenValid()) { debugPrint("[fetchAuditLog] Token invalid. Aborting."); return null; }

    try {
      final response = await dio.get<String>(
        "$_adminPrefix/audit_log", // <-- PREFIXED
        options: Options( responseType: ResponseType.plain, validateStatus: (status) => status == 200, ),
      );
      debugPrint("✅ Audit log fetched. Size: ${response.data?.length ?? 0} chars.");
      return response.data;
    } on DioException catch (e) {
      debugPrint("❌ DioException fetching audit log: ${e.response?.statusCode} - ${e.message}");
      return null;
    } catch (e) { debugPrint("❌ Unexpected error fetching audit log: $e"); return null; }
  }

} // End of APIRepository class