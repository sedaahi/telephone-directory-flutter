import '../../domain/entities/contact_entity.dart';

enum ContactsStatus { initial, loading, success, failure }

class ContactsState {
  final List<ContactEntity> contacts;
  final String searchQuery;
  final List<String> searchHistory;
  final ContactsStatus status;
  final String? errorMessage;

  const ContactsState({
    required this.contacts,
    required this.searchQuery,
    required this.searchHistory,
    required this.status,
    this.errorMessage,
  });

  factory ContactsState.initial() {
    return const ContactsState(
      contacts: [], 
      searchQuery: '',
      searchHistory: [],
      status: ContactsStatus.initial,
      errorMessage: null,
    );
  }

  ContactsState copyWith({
    List<ContactEntity>? contacts,
    String? searchQuery,
    List<String>? searchHistory,
    ContactsStatus? status,
    String? errorMessage,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      searchQuery: searchQuery ?? this.searchQuery,
      searchHistory: searchHistory ?? this.searchHistory,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}
