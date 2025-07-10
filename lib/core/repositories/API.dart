// ignore_for_file: file_names, unused_catch_clause, empty_catches

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb, debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'models/cloud_item.dart';
import 'models/team.dart';
import 'models/user.dart';

class APIRepository {
  final String baseUrl;
  late final Dio dio;
  String? userId;

  PersistCookieJar? _cookieJar;

  // Token timing constants
  final Duration tokenValidityDuration = const Duration(minutes: 15);
  final Duration tokenRefreshBuffer = const Duration(minutes: 3);

  // --- API Prefixes ---
  static const String _authPrefix = '/auth';
  static const String _filesPrefix = '/files';
  static const String _teamsPrefix = '/teams';
  static const String _adminPrefix = '/admin';

  APIRepository._internal({this.baseUrl = 'test.mickus.me/api'}) {
    dio = Dio(BaseOptions(
      baseUrl: 'https://$baseUrl',
      headers: {'content-type': 'application/json'},
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    if (kIsWeb) {
      dio.options.extra = {'withCredentials': true};
    }

    // dio.interceptors.add(LogInterceptor(
    //   request: true,
    //   requestHeader: true,
    //   requestBody: false,
    //   responseHeader: true,
    //   responseBody: false,
    //   error: true,
    //   logPrint: (object) => debugPrint(object.toString()),
    // ));
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
      await _setupCookieJar();
    }
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
      debugPrint('[APIRepository] CookieJar set up.');
    } catch (e) {
      debugPrint('[APIRepository] ❌ CookieJar init failed: $e');
      _cookieJar = null;
    }
  }

  Future<void> logout() async {
    debugPrint("[APIRepository] Logging out...");
    try {
      await dio.post("$_authPrefix/logout");
    } catch (e) {
      debugPrint(
          "⚠️ Could not reach server for logout, cleaning up client-side. Error: $e");
    }
    try {
      if (!kIsWeb && _cookieJar != null) {
        await _cookieJar!.deleteAll();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("access_token_expiry");
      debugPrint("✅ Logout complete.");
    } catch (e) {
      debugPrint("❌ Error during client-side logout cleanup: $e");
    }
  }

  Future<void> _setAccessTokenTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiry =
          DateTime.now().add(tokenValidityDuration).millisecondsSinceEpoch;
      await prefs.setInt('access_token_expiry', expiry);
    } catch (e) {
      debugPrint('❌ _setAccessTokenTimestamp error: $e');
    }
  }

  Future<bool> ensureTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryMs = prefs.getInt('access_token_expiry');
    if (expiryMs == null) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    final now = DateTime.now();
    if (now.isAfter(expiry)) {
      debugPrint('[ensureTokenValid] Token expired. Refreshing...');
      return refreshAccessToken(logoutOnFail: true);
    }
    if (now.isAfter(expiry.subtract(tokenRefreshBuffer))) {
      return refreshAccessToken(logoutOnFail: false);
    }
    return true;
  }

  Future<bool> refreshAccessToken({bool logoutOnFail = false}) async {
    try {
      final response = await dio.post('$_authPrefix/refresh');
      if (response.statusCode == 200) {
        await _setAccessTokenTimestamp();
        return true;
      } else {
        debugPrint(
            '[refreshAccessToken] ❌ Refresh failed with status: ${response.statusCode}');
        if (logoutOnFail) await logout();
        return false;
      }
    } on DioException catch (e) {
      debugPrint(
          '[refreshAccessToken] ❌ DioException during refresh: ${e.response?.statusCode} - ${e.message}');
      if (logoutOnFail &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 422)) {
        await logout();
      }
      return false;
    } catch (e) {
      debugPrint('[refreshAccessToken] ❌ Unexpected error during refresh: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    debugPrint("🔹 Logging in $email...");
    try {
      final response = await dio.post("$_authPrefix/login",
          data: {"email": email, "password": password});
      if (response.statusCode == 401) {
        return false;
      }
      if (response.statusCode == 200) {
        debugPrint("✅ Login successful for $email");
        await _setAccessTokenTimestamp();
        return true;
      } else {
        debugPrint(
            "❌ Login failed for $email with status: ${response.statusCode}");
        return false;
      }
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException during login for $email: ${e.response?.statusCode} - ${e.response?.data?['error'] ?? e.message}");
      return false;
    } catch (e) {
      debugPrint("❌ Unexpected error during login for $email: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    debugPrint("[getProfile] Fetching user profile...");
    if (!await ensureTokenValid()) return null;
    try {
      final response = await dio.get("$_authPrefix/profile");
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException fetching profile: ${e.response?.statusCode} - ${e.message}");
      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        await logout();
      }
      return null;
    } catch (e) {
      debugPrint("❌ Unexpected error fetching profile: $e");
      return null;
    }
  }

  Future<bool> registerUser(
      {required String firstName,
      required String lastName,
      required String email,
      required String password,
      required String role}) async {
    debugPrint("🔹 Registering user: $email");
    try {
      await dio.post("$_authPrefix/register", data: {
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "password": password,
        "role": role
      });
      debugPrint("✅ User '$email' registered successfully.");
      return true;
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException registering user '$email': ${e.response?.statusCode} - ${e.response?.data?['error'] ?? e.message}");
      return false;
    } catch (e) {
      debugPrint("❌ Unexpected error registering user '$email': $e");
      return false;
    }
  }

  Future<List<User>> getUsers() async {
    debugPrint("[getUsers] Fetching users...");
    if (!await ensureTokenValid()) return [];
    try {
      final response = await dio.get("$_adminPrefix/users");
      final data = response.data as List;
      return data.map((u) => User.fromJson(u as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException getting users: ${e.response?.statusCode} - ${e.message}");
      return [];
    } catch (e) {
      debugPrint("❌ Unexpected error getting users: $e");
      return [];
    }
  }

  Future<bool> deleteUser(String userIdToDelete) async {
    debugPrint("[deleteUser] Deleting user $userIdToDelete...");
    if (userIdToDelete.trim().isEmpty) return false;
    if (!await ensureTokenValid()) return false;
    try {
      await dio.delete('$_adminPrefix/users/$userIdToDelete');
      debugPrint("✅ User deleted successfully (ID: $userIdToDelete).");
      return true;
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException deleting user '$userIdToDelete': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) {
      debugPrint("❌ Unexpected error deleting user '$userIdToDelete': $e");
      return false;
    }
  }

  Future<List<CloudItem>> fetchCloud({String path = '', String? userId}) async {
    if (!await ensureTokenValid()) return [];
    try {
      final response = await dio.get('$_filesPrefix/cloud', queryParameters: {
        'path': path,
        if (userId != null) 'user_id': userId
      });
      final list = response.data['cloud_contents'] as List;
      return list
          .map((e) => CloudItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint(
          '❌ fetchCloud DioException: ${e.response?.statusCode} - ${e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ fetchCloud unexpected error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchFileBytes(String relativePath,
      {String? userId}) async {
    if (!await ensureTokenValid()) return null;
    try {
      final response = await dio.get('$_filesPrefix/preview',
          queryParameters: {
            'path': relativePath,
            if (userId != null) 'user_id': userId
          },
          options: Options(responseType: ResponseType.bytes));
      final contentType =
          response.headers.value(HttpHeaders.contentTypeHeader) ??
              'application/octet-stream';
      return {
        'bytes': Uint8List.fromList(response.data as List<int>),
        'contentType': contentType
      };
    } on DioException catch (e) {
      debugPrint(
          '❌ fetchFileBytes DioException: ${e.response?.statusCode} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ fetchFileBytes unexpected error: $e');
      return null;
    }
  }

  Future<bool> uploadFile(PlatformFile file, String uploadPath,
      {String? userId}) async {
    debugPrint("[uploadFile] Uploading '${file.name}' to '$uploadPath'...");
    if (!await ensureTokenValid()) return false;
    try {
      MultipartFile multipartFile;
      if (kIsWeb) {
        if (file.bytes == null) {
          debugPrint("❌ Upload failed: No file bytes (web).");
          return false;
        }
        multipartFile =
            MultipartFile.fromBytes(file.bytes!, filename: file.name);
      } else {
        if (file.path == null) {
          debugPrint("❌ Upload failed: No file path (non-web).");
          return false;
        }
        multipartFile =
            await MultipartFile.fromFile(file.path!, filename: file.name);
      }
      final formData =
          FormData.fromMap({"file": multipartFile, "path": uploadPath});
      await dio.post("$_filesPrefix/upload",
          data: formData,
          queryParameters: userId != null ? {'user_id': userId} : null);
      debugPrint("✅ File '${file.name}' uploaded.");
      return true;
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException uploading file '${file.name}': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) {
      debugPrint("❌ Unexpected error uploading file '${file.name}': $e");
      return false;
    }
  }

  Future<bool> deleteItem(String path, {String? userId}) async {
    debugPrint("[deleteItem] Deleting '$path'...");
    if (!await ensureTokenValid()) return false;
    try {
      await dio.delete("$_filesPrefix/delete",
          data: {"path": path},
          queryParameters: userId != null ? {'user_id': userId} : null);
      debugPrint("✅ Item deleted at path: '$path'.");
      return true;
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException deleting item at '$path': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) {
      debugPrint("❌ Unexpected error deleting item at '$path': $e");
      return false;
    }
  }

  Future<List<CloudItem>> getSearch(String query, {String? userId}) async {
    if (query.trim().isEmpty) return [];
    if (!await ensureTokenValid()) return [];
    try {
      final response = await dio.get('$_filesPrefix/search',
          queryParameters: {'q': query, if (userId != null) 'user_id': userId});
      final list = response.data['results'] as List;
      return list
          .map((e) => CloudItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint(
          '❌ getSearch DioException: ${e.response?.statusCode} - ${e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ getSearch unexpected error: $e');
      return [];
    }
  }

  Future<bool> createFolder(String path, {String? userId}) async {
    debugPrint("[createFolder] Creating folder '$path'...");
    if (path.trim().isEmpty) return false;
    if (!await ensureTokenValid()) return false;
    try {
      await dio.post("$_filesPrefix/mkdir",
          data: {"path": path},
          queryParameters: userId != null ? {'user_id': userId} : null);
      debugPrint("✅ Folder created at path: '$path'.");
      return true;
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException creating folder at '$path': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) {
      debugPrint("❌ Unexpected error creating folder at '$path': $e");
      return false;
    }
  }

  Future<bool> renameItem(String oldPath, String newName,
      {String? userId}) async {
    debugPrint("[renameItem] Renaming '$oldPath' to '$newName'...");
    if (oldPath.trim().isEmpty ||
        newName.trim().isEmpty ||
        newName.contains('/')) {
      return false;
    }
    if (!await ensureTokenValid()) return false;
    try {
      await dio.post("$_filesPrefix/rename",
          data: {"old_path": oldPath, "new_name": newName},
          queryParameters: userId != null ? {'user_id': userId} : null);
      debugPrint("✅ Item renamed from '$oldPath' to '$newName'.");
      return true;
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException renaming item from '$oldPath': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) {
      debugPrint("❌ Unexpected error renaming item from '$oldPath': $e");
      return false;
    }
  }

  // --- FINAL CORRECTED METHOD ---
  Future<Map<String, dynamic>?> downloadFile(String relativePath,
      {String? userId}) async {
    debugPrint('[downloadFile] Downloading "$relativePath"...');
    if (!await ensureTokenValid()) return null;
    try {
      final response = await dio.get<List<int>>(
        '$_filesPrefix/download',
        queryParameters: <String, dynamic>{
          'path': relativePath,
          if (userId != null) 'user_id': userId,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      String filename = relativePath.split('/').last;

      final String? contentDisp = response.headers.value('content-disposition');
      if (contentDisp != null) {
        RegExp regex =
            RegExp('filename\\*?=UTF-8\'\'([^;]+)|filename="([^"]+)"');

        var match = regex.firstMatch(contentDisp);
        if (match != null) {
          String foundName =
              (match.group(2) ?? match.group(3) ?? filename).trim();
          filename = Uri.decodeComponent(foundName);
        }
      }

      if (kIsWeb) {
        return <String, dynamic>{
          'bytes': Uint8List.fromList(response.data!),
          'contentType':
              response.headers.value(HttpHeaders.contentTypeHeader) ??
                  'application/octet-stream',
          'filename': filename
        };
      } else {
        Directory baseDir = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        String safeFilename = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final filePath = '${baseDir.path}/$safeFilename';
        await File(filePath).writeAsBytes(response.data!, flush: true);
        debugPrint('[downloadFile] ✅ Saved to $filePath');
        return <String, dynamic>{'path': filePath, 'filename': safeFilename};
      }
    } on DioException catch (e) {
      debugPrint(
          '❌ downloadFile DioException: ${e.response?.statusCode} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ downloadFile unexpected error: $e');
      return null;
    }
  }

  // --- Team Methods ---
  Future<List<Team>> fetchAssociatedTeams() async {
    if (!await ensureTokenValid()) return [];
    try {
      final response = await dio.get("$_teamsPrefix/associated");
      final List<dynamic> dataList = response.data as List;
      return dataList
          .whereType<Map<String, dynamic>>()
          .map(Team.fromJson)
          .toList();
    } on DioException catch (e) {
      debugPrint(
          "[fetchAssociatedTeams] ❌ DioException: ${e.response?.statusCode} - ${e.message}");
      return [];
    } catch (e) {
      debugPrint("[fetchAssociatedTeams] ❌ Unexpected error: $e");
      return [];
    }
  }

  Future<List<Team>> fetchMyTeams() async {
    if (!await ensureTokenValid()) return [];
    try {
      final response = await dio.get('$_teamsPrefix/my_teams');
      final dataList = response.data as List;
      return dataList
          .whereType<Map<String, dynamic>>()
          .map(Team.fromJson)
          .toList();
    } on DioException catch (e) {
      debugPrint(
          '❌ fetchMyTeams DioException: ${e.response?.statusCode} - ${e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ fetchMyTeams unexpected error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchTeamOverview(String teamId) async {
    if (!await ensureTokenValid()) return null;
    try {
      final response = await dio.get('$_teamsPrefix/$teamId/overview');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      debugPrint(
          '❌ fetchTeamOverview DioException: ${e.response?.statusCode} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ fetchTeamOverview unexpected error: $e');
      return null;
    }
  }

  Future<bool> createTeam(
      {required String name,
      required String lead,
      required List<String> emails}) async {
    debugPrint("[createTeam] Creating team '$name'...");
    if (!await ensureTokenValid()) return false;
    try {
      await dio.post("$_teamsPrefix/create",
          data: {"name": name, "lead": lead, "emails": emails});
      debugPrint("✅ Team '$name' created.");
      return true;
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException creating team '$name': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) {
      debugPrint("❌ Unexpected error creating team '$name': $e");
      return false;
    }
  }

  Future<bool> editTeam(
      {required String teamId,
      String? newName,
      String? newLeadEmail,
      List<String>? addEmails,
      List<String>? removeEmails}) async {
    debugPrint("[editTeam] Editing team ID '$teamId'...");
    if (!await ensureTokenValid()) return false;
    final Map<String, dynamic> requestData = {
      "team_id": teamId,
      if (newName != null && newName.isNotEmpty) "new_name": newName,
      if (newLeadEmail != null && newLeadEmail.isNotEmpty) "lead": newLeadEmail,
      if (addEmails != null && addEmails.isNotEmpty) "add_emails": addEmails,
      if (removeEmails != null && removeEmails.isNotEmpty)
        "remove_emails": removeEmails,
    };
    if (requestData.length <= 1) return true; // No changes
    try {
      await dio.post("$_teamsPrefix/edit", data: requestData);
      debugPrint("✅ Team '$teamId' edited.");
      return true;
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException editing team '$teamId': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) {
      debugPrint("❌ Unexpected error editing team '$teamId': $e");
      return false;
    }
  }

  Future<Team?> getTeam({String? teamId, String? name}) async {
    if (teamId == null && name == null) return null;
    if (!await ensureTokenValid()) return null;
    try {
      final queryParams = {
        if (teamId != null) "team_id": teamId,
        if (name != null) "name": name,
      };
      final response =
          await dio.get("$_teamsPrefix/details", queryParameters: queryParams);
      return Team.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException getting team: ${e.response?.statusCode} - ${e.message}");
      return null;
    } catch (e) {
      debugPrint("❌ Unexpected error getting team: $e");
      return null;
    }
  }

  Future<List<Team>> getAllTeams() async {
    debugPrint('[getAllTeams] Fetching all teams...');
    if (!await ensureTokenValid()) return [];
    try {
      final response = await dio.get("$_teamsPrefix/all");
      final List<dynamic> dataList = response.data as List;
      return dataList
          .whereType<Map<String, dynamic>>()
          .map(Team.fromJson)
          .toList();
    } on DioException catch (e) {
      debugPrint(
          "[getAllTeams] ❌ DioException: ${e.response?.statusCode} - ${e.message}");
      return [];
    } catch (e) {
      debugPrint("[getAllTeams] ❌ Unexpected error: $e");
      return [];
    }
  }

  Future<bool> deleteTeam(String teamId) async {
    debugPrint("[deleteTeam] Deleting team $teamId...");
    if (teamId.trim().isEmpty) return false;
    if (!await ensureTokenValid()) return false;
    try {
      await dio.delete('$_teamsPrefix/$teamId');
      debugPrint("✅ Team deleted (ID: $teamId).");
      return true;
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException deleting team '$teamId': ${e.response?.statusCode} - ${e.message}");
      return false;
    } catch (e) {
      debugPrint("❌ Unexpected error deleting team '$teamId': $e");
      return false;
    }
  }

  Future<String?> createShareLink(
      {required String filePath,
      required String shareType,
      String? targetEmail,
      String? targetTeamId,
      int? durationDays,
      bool? allowDownload,
      String? fileOwnerId}) async {
    debugPrint("[createShareLink] Creating share link for '$filePath'...");
    if (!await ensureTokenValid()) return null;
    final Map<String, dynamic> requestData = {
      "file_path": filePath,
      "share_type": shareType,
      if (targetEmail != null) "target_email": targetEmail,
      if (targetTeamId != null) "target_team_id": targetTeamId,
      if (durationDays != null) "duration_days": durationDays,
      if (allowDownload != null) "allow_download": allowDownload,
    };
    try {
      final response = await dio.post("/share",
          data: requestData,
          queryParameters:
              fileOwnerId != null ? {'user_id': fileOwnerId} : null);
      final shareUrl = response.data['share_url'] as String;
      debugPrint("✅ Share link created: $shareUrl");
      return shareUrl;
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException creating share link for '$filePath': ${e.response?.statusCode} - ${e.message}");
      return null;
    } catch (e) {
      debugPrint("❌ Unexpected error creating share link for '$filePath': $e");
      return null;
    }
  }

  Future<String?> fetchAuditLog() async {
    debugPrint("[fetchAuditLog] Fetching audit log...");
    if (!await ensureTokenValid()) return null;
    try {
      final response = await dio.get<String>("$_adminPrefix/audit_log",
          options: Options(responseType: ResponseType.plain));
      debugPrint("✅ Audit log fetched.");
      return response.data;
    } on DioException catch (e) {
      debugPrint(
          "❌ DioException fetching audit log: ${e.response?.statusCode} - ${e.message}");
      return null;
    } catch (e) {
      debugPrint("❌ Unexpected error fetching audit log: $e");
      return null;
    }
  }
}
