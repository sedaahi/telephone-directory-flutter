import 'package:equatable/equatable.dart';
import '../../domain/entities/contact_entity.dart';

abstract class ContactsEvent extends Equatable {
  const ContactsEvent();

  @override
  List<Object?> get props => [];
}

/// Ekran açıldığında ya da ilk defa kişileri yüklemek istediğinde
class LoadContacts extends ContactsEvent {
  const LoadContacts();
}

/// Kullanıcı aşağı çekip refresh yaptığında vs.
class RefreshContacts extends ContactsEvent {
  const RefreshContacts();
}

/// Kullanıcı search alanına bir şey yazdığında
class SearchQueryChanged extends ContactsEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Search alanına tıkladığında daha önce yapılan aramaları göstermek için
class LoadSearchHistory extends ContactsEvent {
  const LoadSearchHistory();
}

/// Kullanıcı eski arama kayıtlarından birine tıkladığında
class SearchFromHistory extends ContactsEvent {
  final String query;

  const SearchFromHistory(this.query);

  @override
  List<Object?> get props => [query];
}

class AddSearchToHistory extends ContactsEvent {
  final String query;

  const AddSearchToHistory(this.query);

  @override
  List<Object?> get props => [query];
}

/// Kullanıcı kişiyi sola kaydırıp 'Sil' dediğinde
class DeleteContact extends ContactsEvent {
  final String contactId;

  const DeleteContact(this.contactId);

  @override
  List<Object?> get props => [contactId];
}

/// Kullanıcı bir kişiye tıkladığında (Profile ekranına gitmek için)
class ContactTapped extends ContactsEvent {
  final String contactId;

  const ContactTapped(this.contactId);

  @override
  List<Object?> get props => [contactId];
}

class AddContact extends ContactsEvent {
  final ContactEntity contact;

  const AddContact(this.contact);

  @override
  List<Object?> get props => [contact];
}

class UpdateContact extends ContactsEvent {
  final ContactEntity contact;

  const UpdateContact(this.contact);

  @override
  List<Object?> get props => [contact];
}

class MarkAsSavedInDevice extends ContactsEvent {
  final String contactId;

  const MarkAsSavedInDevice(this.contactId);
}




