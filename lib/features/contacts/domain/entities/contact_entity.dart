class ContactEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? photoUrl;          // backend'in döndüğü URL
  final bool isInDeviceContacts;   // rehberde de var mı

  const ContactEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.photoUrl,
    required this.isInDeviceContacts,
  });

  String get fullName => '$firstName $lastName';
  String get firstLetter => fullName.trim().isNotEmpty
      ? fullName.trim()[0].toUpperCase()
      : '#';
}