import '../../domain/entities/contact_entity.dart';

class ContactModel extends ContactEntity {
  const ContactModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.phone,
    super.photoUrl,
    required super.isInDeviceContacts,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'].toString(),
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phoneNumber'] ?? '',
      photoUrl: json['profileImageUrl'],
      isInDeviceContacts: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "phoneNumber": phone,
      "profileImageUrl": photoUrl,
    };
  }
}
