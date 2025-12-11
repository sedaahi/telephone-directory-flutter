import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'package:telephone_directory/core/network/api_client.dart';
import '../models/contact_model.dart';

abstract class ContactsRemoteDataSource {
  Future<List<ContactModel>> getContacts();
  Future<void> createContact(ContactModel contact);
  Future<void> updateContact(ContactModel contact);
  Future<void> deleteContact(String id);

  /// Resmi upload edip dönen imageUrl’i ver
  Future<String?> uploadImage(File file);
}

class ContactsRemoteDataSourceImpl implements ContactsRemoteDataSource {
  final ApiClient apiClient;

  ContactsRemoteDataSourceImpl({required this.apiClient});

  Map<String, dynamic> _normalizeResponse(dynamic data) {
    if (data is String) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return data as Map<String, dynamic>;
  }

  @override
  Future<List<ContactModel>> getContacts() async {
    final response = await apiClient.dio.get('/api/User/GetAll');

    final json = _normalizeResponse(response.data);
    final users = json['data']['users'] as List<dynamic>;

    return users
        .map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createContact(ContactModel contact) async {
    await apiClient.dio.post(
      '/api/User',
      data: contact.toJson(),
    );
  }

  @override
  Future<void> updateContact(ContactModel contact) async {
    await apiClient.dio.put(
      '/api/User/${contact.id}',
      data: contact.toJson(),
    );
  }

  @override
  Future<void> deleteContact(String id) async {
    await apiClient.dio.delete('/api/User/$id');
  }

  @override
  Future<String?> uploadImage(File file) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        file.path,
        filename: p.basename(file.path),
      ),
    });

    final response = await apiClient.dio.post(
      '/api/User/UploadImage',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final json = _normalizeResponse(response.data);
    final data = json['data'];
    final imageUrl = data?['imageUrl'] as String?;

    return imageUrl;
  }
}
