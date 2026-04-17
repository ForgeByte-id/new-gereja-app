import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$root$path').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  Map<String, String> _headers({String? token, String? deviceToken}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (deviceToken != null && deviceToken.isNotEmpty) {
      headers['X-Device-Token'] = deviceToken;
    }
    return headers;
  }

  Future<dynamic> _decode(http.Response response) async {
    dynamic body = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      body = jsonDecode(response.body);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final mapBody = body is Map<String, dynamic> ? body : <String, dynamic>{};

    throw ApiError(
      message:
          (mapBody['message'] as String?) ??
          'Request gagal (${response.statusCode})',
      errorCode: mapBody['error_code'] as String?,
      traceId: mapBody['trace_id'] as String?,
      statusCode: response.statusCode,
    );
  }

  Future<AuthSession> login({
    required String username,
    required String password,
    required String fcmToken,
  }) async {
    final response = await http.post(
      _uri('/auth/login'),
      headers: _headers(),
      body: jsonEncode({
        'username': username,
        'password': password,
        'fcm_token': fcmToken,
      }),
    );

    final payload = await _decode(response) as Map<String, dynamic>;
    final data =
        (payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    return AuthSession(
      token: (data['token'] as String?) ?? '',
      role: parseRole(data['role'] as String?),
      user: (data['user'] as Map<String, dynamic>? ?? <String, dynamic>{}),
    );
  }

  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
    required String nomorKk,
    required String phoneNumber,
    required String fcmToken,
    String? name,
    String? jenisKelamin,
    int? usia,
    String? alamat,
  }) async {
    final response = await http.post(
      _uri('/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        'username': username,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'nomor_kk': nomorKk,
        'phone_number': phoneNumber,
        'fcm_token': fcmToken,
        if (jenisKelamin != null && jenisKelamin.isNotEmpty)
          'jenis_kelamin': jenisKelamin,
        'usia': ?usia,
        if (alamat != null && alamat.trim().isNotEmpty) 'alamat': alamat.trim(),
      }),
    );

    final payload = await _decode(response) as Map<String, dynamic>;
    final data =
        (payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    return AuthSession(
      token: (data['token'] as String?) ?? '',
      role: parseRole(data['role'] as String?),
      user: (data['user'] as Map<String, dynamic>? ?? <String, dynamic>{}),
    );
  }

  Future<Map<String, dynamic>> me(String token) async {
    final response = await http.get(
      _uri('/auth/me'),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateMe(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      _uri('/auth/me'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> uploadProfilePhoto({
    required String token,
    required String filePath,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/auth/me/photo'));
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    request.files.add(await http.MultipartFile.fromPath('photo', filePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final payload = await _decode(response) as Map<String, dynamic>;

    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> uploadProfilePhotoBytes({
    required String token,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/auth/me/photo'));
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    request.files.add(
      http.MultipartFile.fromBytes('photo', bytes, filename: fileName),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final payload = await _decode(response) as Map<String, dynamic>;

    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<void> logout(String token) async {
    debugPrint('🔵 API.logout: Making POST request to /auth/logout');
    try {
      final response = await http.post(
        _uri('/auth/logout'),
        headers: _headers(token: token),
      );
      debugPrint('🔵 API.logout: Response status = ${response.statusCode}');
      debugPrint('🔵 API.logout: Response body = ${response.body}');
      await _decode(response);
      debugPrint('🟢 API.logout: Logout successful');
    } catch (e, stackTrace) {
      debugPrint('🔴 API.logout ERROR: $e');
      debugPrint('🔴 API.logout STACK TRACE: $stackTrace');
      rethrow;
    }
  }

  Future<void> registerDevice({
    required String token,
    required String deviceToken,
    required String deviceType,
    required String deviceName,
  }) async {
    final response = await http.post(
      _uri('/devices/register'),
      headers: _headers(token: token),
      body: jsonEncode({
        'fcm_token': deviceToken,
        'device_type': deviceType,
        'device_name': deviceName,
      }),
    );
    await _decode(response);
  }

  Future<List<Map<String, dynamic>>> devices(
    String token,
    String currentDeviceToken,
  ) async {
    final response = await http.get(
      _uri('/devices'),
      headers: _headers(token: token, deviceToken: currentDeviceToken),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> health() async {
    final response = await http.get(_uri('/health'), headers: _headers());
    final payload = await _decode(response);
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> churchProfile(String token) async {
    final response = await http.get(
      _uri('/church/profile'),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> upsertChurchProfile(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      _uri('/church/profile'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> events(String token) async {
    final response = await http.get(
      _uri('/events', {'per_page': 20}),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> createEvent({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final response = await http.post(
      _uri('/events'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Uint8List> downloadEventDocumentation({
    required String token,
    required int eventId,
  }) async {
    final response = await http.get(
      _uri('/events/$eventId/documentation/download'),
      headers: _headers(token: token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }

    await _decode(response);
    return Uint8List(0);
  }

  Future<Uint8List> downloadServiceCertificate({
    required String token,
    required int applicationId,
  }) async {
    final response = await http.get(
      _uri('/services/applications/$applicationId/certificate/pdf'),
      headers: _headers(token: token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }

    await _decode(response);
    return Uint8List(0);
  }

  Future<List<Map<String, dynamic>>> serviceCategories(String token) async {
    final response = await http.get(
      _uri('/services/categories'),
      headers: _headers(token: token),
    );
    final payload = await _decode(response);

    final rawList = (payload is Map<String, dynamic>)
        ? payload['data']
        : payload;
    if (rawList is! List) {
      return <Map<String, dynamic>>[];
    }

    return rawList.map((item) {
      if (item is Map<String, dynamic>) {
        return {
          'code': item['code']?.toString() ?? '',
          'name': item['name']?.toString() ?? item['code']?.toString() ?? '',
        };
      }

      final value = item.toString();
      return {'code': value, 'name': value};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> eventCategories(String token) async {
    final response = await http.get(
      _uri('/events/categories'),
      headers: _headers(token: token),
    );
    final payload = await _decode(response);

    final rawList = (payload is Map<String, dynamic>)
        ? payload['data']
        : payload;
    if (rawList is! List) {
      return <Map<String, dynamic>>[];
    }

    return rawList.map((item) {
      if (item is Map<String, dynamic>) {
        return {
          'code': item['code']?.toString() ?? '',
          'name': item['name']?.toString() ?? item['code']?.toString() ?? '',
        };
      }

      final value = item.toString();
      return {'code': value, 'name': value};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> serviceForms(String token) async {
    final response = await http.get(
      _uri('/services/forms'),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> serviceApplications(String token) async {
    final response = await http.get(
      _uri('/services/applications'),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> userFamilies(
    String token, {
    int perPage = 20,
    int page = 1,
    String? search,
  }) async {
    final query = <String, dynamic>{'per_page': perPage, 'page': page};
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await http.get(
      _uri('/users/families', query),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;

    final data = payload['data'];
    final meta = payload['meta'];
    return {
      'data': data is List
          ? data.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[],
      'meta': meta is Map<String, dynamic> ? meta : <String, dynamic>{},
    };
  }

  Future<Map<String, dynamic>> upsertServiceTemplate({
    required String token,
    String? categoryPath,
    required Map<String, dynamic> body,
  }) async {
    final response = categoryPath == null
        ? await http.post(
            _uri('/services/forms'),
            headers: _headers(token: token),
            body: jsonEncode(body),
          )
        : await http.put(
            _uri('/services/forms/$categoryPath'),
            headers: _headers(token: token),
            body: jsonEncode(body),
          );

    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<void> deleteServiceTemplate({
    required String token,
    required String category,
  }) async {
    final response = await http.delete(
      _uri('/services/forms/$category'),
      headers: _headers(token: token),
    );
    await _decode(response);
  }

  Future<Map<String, dynamic>> updateServiceStatus({
    required String token,
    required int applicationId,
    required String status,
    String? adminNote,
  }) async {
    final response = await http.patch(
      _uri('/services/applications/$applicationId/status'),
      headers: _headers(token: token),
      body: jsonEncode({'status': status, 'admin_note': adminNote}),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateServiceApplication({
    required String token,
    required int applicationId,
    required String category,
    required Map<String, dynamic> formData,
    required List<String> attachments,
  }) async {
    final response = await http.patch(
      _uri('/services/applications/$applicationId'),
      headers: _headers(token: token),
      body: jsonEncode({
        'category': category,
        'form_data': formData,
        'attachments': attachments,
      }),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<void> applyService({
    required String token,
    required String category,
    required Map<String, dynamic> formData,
    required List<String> attachments,
    int? targetUserId,
  }) async {
    final body = <String, dynamic>{
      'category': category,
      'form_data': formData,
      'attachments': attachments,
    };
    if (targetUserId != null) {
      body['target_user_id'] = targetUserId;
    }

    final response = await http.post(
      _uri('/services/apply'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    await _decode(response);
  }

  Future<Map<String, dynamic>> broadcastNotification({
    required String token,
    required String title,
    required String message,
    required String targetType,
    Map<String, dynamic>? targetFilters,
  }) async {
    final response = await http.post(
      _uri('/notifications/broadcast'),
      headers: _headers(token: token),
      body: jsonEncode({
        'title': title,
        'message': message,
        'target_type': targetType,
        if (targetFilters?.isNotEmpty ?? false) 'target_filters': targetFilters,
      }),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  // New methods for jemaat and admin management

  Future<List<Map<String, dynamic>>> userFamilyMembers(
    String token, {
    int perPage = 100,
  }) async {
    final response = await http.get(
      _uri('/users/family-members', {'per_page': perPage}),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>?;
    final members = data?['members'];
    if (members is List) {
      return members.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> users(
    String token, {
    String? role,
    int perPage = 30,
    int page = 1,
    String? search,
  }) async {
    final query = <String, dynamic>{'per_page': perPage, 'page': page};
    if (role != null) {
      query['role'] = role;
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await http.get(
      _uri('/users', query),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data =
        (payload['data'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        <Map<String, dynamic>>[];
    return data;
  }

  Future<List<Map<String, dynamic>>> kkRegistrations(
    String token, {
    int perPage = 30,
    int page = 1,
    String? search,
  }) async {
    final query = <String, dynamic>{'per_page': perPage, 'page': page};
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await http.get(
      _uri('/kk-registrations', query),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data =
        (payload['data'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        <Map<String, dynamic>>[];
    return data;
  }

  Future<Map<String, dynamic>> createKkRegistration(
    String token, {
    required String nomorKk,
    required String namaKepalaKeluarga,
    String? alamat,
    String? phoneNumber,
  }) async {
    final response = await http.post(
      _uri('/kk-registrations'),
      headers: _headers(token: token),
      body: jsonEncode({
        'nomor_kk': nomorKk,
        'nama_kepala_keluarga': namaKepalaKeluarga,
        if (alamat != null && alamat.isNotEmpty) 'alamat': alamat,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      }),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateKkRegistration(
    String token,
    String kkId, {
    required String nomorKk,
    required String namaKepalaKeluarga,
    String? alamat,
    String? phoneNumber,
  }) async {
    final response = await http.put(
      _uri('/kk-registrations/$kkId'),
      headers: _headers(token: token),
      body: jsonEncode({
        'nomor_kk': nomorKk,
        'nama_kepala_keluarga': namaKepalaKeluarga,
        if (alamat != null && alamat.isNotEmpty) 'alamat': alamat,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      }),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<void> deleteKkRegistration(String token, String kkId) async {
    final response = await http.delete(
      _uri('/kk-registrations/$kkId'),
      headers: _headers(token: token),
    );
    await _decode(response);
  }

  Future<Map<String, dynamic>> createJemaat(
    String token, {
    required String name,
    required String username,
    required String email,
    required String password,
    required String nomorKk,
    required String phoneNumber,
    String? jenisKelamin,
    int? usia,
    String? alamat,
    String? status,
  }) async {
    final response = await http.post(
      _uri('/jemaats'),
      headers: _headers(token: token),
      body: jsonEncode({
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'nomor_kk': nomorKk,
        'phone_number': phoneNumber,
        if (jenisKelamin != null && jenisKelamin.isNotEmpty)
          'jenis_kelamin': jenisKelamin,
        'usia': ?usia,
        if (alamat != null && alamat.isNotEmpty) 'alamat': alamat,
        if (status != null && status.isNotEmpty) 'status': status,
      }),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateJemaat(
    String token,
    int userId, {
    String? name,
    String? email,
    String? password,
    String? jenisKelamin,
    int? usia,
    String? alamat,
    String? phoneNumber,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (password != null) {
      body['password'] = password;
      body['password_confirmation'] = password;
    }
    if (jenisKelamin != null) body['jenis_kelamin'] = jenisKelamin;
    if (usia != null) body['usia'] = usia;
    if (alamat != null) body['alamat'] = alamat;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (status != null) body['status'] = status;

    final response = await http.put(
      _uri('/jemaats/$userId'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<void> deleteJemaat(String token, int userId) async {
    final response = await http.delete(
      _uri('/jemaats/$userId'),
      headers: _headers(token: token),
    );
    await _decode(response);
  }

  Future<Uint8List> exportServiceApplicationsCsv(
    String token, {
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (fromDate != null && fromDate.isNotEmpty) query['from_date'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) query['to_date'] = toDate;

    final response = await http.get(
      _uri('/services/applications/export/csv', query),
      headers: _headers(token: token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }

    throw ApiError(
      message: 'Gagal mengunduh file CSV',
      statusCode: response.statusCode,
    );
  }
}
