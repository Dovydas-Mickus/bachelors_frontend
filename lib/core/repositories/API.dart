// ignore_for_file: file_names

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'package:dio/io.dart';
import 'package:http_parser/http_parser.dart';


import 'models/cloud_item.dart'; // Needed for IOHttpClientAdapter (non-web only)

class APIRepository {
  final String baseUrl;
  late final Dio dio;

  final Duration tokenValidityDuration = Duration(minutes: 1);

  APIRepository({this.baseUrl = 'www.mickus.me'}) {
    dio = Dio(BaseOptions(
      baseUrl: "https://$baseUrl", // no port since HTTPS is standard (443)
      headers: {"content-type": "application/json"},
    ));

    if (kIsWeb) {
      dio.options.extra = {
        "withCredentials": true,
      };
    } else {
      final cookieJar = CookieJar();
      dio.interceptors.add(CookieManager(cookieJar));

      // Only keep this for testing with self-signed certs
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          // Only allow self-signed during local dev (use proper cert in prod)
          return host == baseUrl;
        };
        return client;
      };
    }
  }

  Future<void> _setAccessTokenTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("access_token_timestamp", DateTime.now().millisecondsSinceEpoch);
    debugPrint("Access token timestamp set.");
  }

  Future<bool> login(String email, String password) async {
    debugPrint("🔹 Login request");
    try {
      final response = await dio.post("/login", data: {
        "email": email,
        "password": password,
      });
      if (response.statusCode == 200) {
        await _setAccessTokenTimestamp();
        return true;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return false;
  }

  Future<bool> ensureTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenTimestamp = prefs.getInt("access_token_timestamp");

    if (tokenTimestamp == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - tokenTimestamp >= tokenValidityDuration.inMilliseconds) {
      return await refreshAccessToken();
    }

    return true;
  }

  Future<String> getProfile() async {
    if (!await ensureTokenValid()) return "Session expired";
    try {
      final response = await dio.get("/profile");
      if (response.statusCode == 200) {
        return response.data['message'];
      } else if (response.statusCode == 401) {
        return await refreshAccessToken() ? getProfile() : "Session expired";
      }
    } catch (_) {}
    return "Error fetching profile";
  }

  Future<bool> refreshAccessToken() async {
    try {
      final response = await dio.post("/refresh");
      if (response.statusCode == 200) {
        await _setAccessTokenTimestamp();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<List<CloudItem>> fetchCloud({String path = ''}) async {
    if (!await ensureTokenValid()) return [];

    try {
      final response = await dio.get("/cloud", queryParameters: {"path": path});

      if (response.statusCode == 200) {
        final data = response.data;
        return (data['cloud_contents'] as List)
            .map((item) => CloudItem.fromJson(item))
            .toList();
      } else if (response.statusCode == 401) {
        // 🔁 Try refreshing and retrying once
        final refreshed = await refreshAccessToken();
        if (refreshed) return await fetchCloud(path: path);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    return [];
  }


  Future<void> logout() async {
    try {
      await dio.post("/logout");
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<Map<String, dynamic>?> fetchFileBytes(String relativePath) async {
    if (!await ensureTokenValid()) return null;

    try {
      final response = await dio.get(
        "/preview",
        queryParameters: {"path": relativePath},
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final contentType = response.headers.value('content-type') ?? 'application/octet-stream';
        return {
          'bytes': Uint8List.fromList(response.data),
          'contentType': contentType,
        };
      } else if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) return await fetchFileBytes(relativePath);
      }
    } catch (e) {
      debugPrint("❌ Failed to fetch file: $e");
    }

    return null;
  }

  Future<bool> uploadFile(PlatformFile file, String uploadPath) async {
    if (!await ensureTokenValid()) return false;

    try {
      MultipartFile multipartFile;

      if (kIsWeb) {
        // On Web: file.bytes must not be null
        if (file.bytes == null) {
          debugPrint("❌ Upload failed: No file bytes found for web upload.");
          return false;
        }

        multipartFile = MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
          contentType: MediaType("application", "octet-stream"), // Optional, adjust if known
        );
      } else {
        // On Mobile/Desktop
        if (file.path == null) {
          debugPrint("❌ Upload failed: No file path found for non-web upload.");
          return false;
        }

        multipartFile = await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        );
      }

      final formData = FormData.fromMap({
        "file": multipartFile,
        "path": uploadPath,
      });

      final response = await dio.post(
        "/upload",
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.json,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) return await uploadFile(file, uploadPath);
      }
    } catch (e) {
      debugPrint("❌ Upload failed: $e");
    }

    return false;
  }

  Future<List<CloudItem>> getSearch(String query) async {
    if (!await ensureTokenValid()) return [];
    if (query == '') return [];
    try {
      final response = await dio.get("/search", queryParameters: {"q": query});

      if (response.statusCode == 200) {
        final data = response.data;
        return (data['results'] as List)
            .map((item) => CloudItem.fromJson(item))
            .toList();
      } else if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) return await getSearch(query);
      }
    } catch (e) {
      debugPrint("❌ Search failed: $e");
    }

    return [];
  }


}
