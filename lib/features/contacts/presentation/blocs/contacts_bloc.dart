import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

import '../../domain/entities/contact_entity.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';
import '../../data/datasources/contacts_remote_data_source.dart';
import '../../data/models/contact_model.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final ContactsRemoteDataSource remoteDataSource;

  ContactsBloc({required this.remoteDataSource})
      : super(ContactsState.initial()) {
    on<LoadContacts>(_onLoadContacts);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<LoadSearchHistory>(_onLoadSearchHistory);
    on<SearchFromHistory>(_onSearchFromHistory);
    on<AddSearchToHistory>(_onAddSearchToHistory);
    on<AddContact>(_onAddContact);
    on<UpdateContact>(_onUpdateContact);
    on<DeleteContact>(_onDeleteContact);
  }

  // ---- LISTEYI ÇEKEN METOT ----
  Future<void> _onLoadContacts(
    LoadContacts event,
    Emitter<ContactsState> emit,
  ) async {
    emit(state.copyWith(status: ContactsStatus.loading, errorMessage: null));

    try {
      // 1) Backend'den kişiler
      final models = await remoteDataSource.getContacts();
      final backendContacts = List<ContactEntity>.from(models);

      // 2) Cihaz rehberindeki telefonlar (normalize edilmiş set)
      final devicePhones = await _loadDevicePhoneSet();

      // 3) Her backend kişisi için isInDeviceContacts flag'ini set et
      final updated = backendContacts
          .map(
            (c) => ContactEntity(
              id: c.id,
              firstName: c.firstName,
              lastName: c.lastName,
              phone: c.phone,
              photoUrl: c.photoUrl,
              isInDeviceContacts: devicePhones.contains(
                _normalizePhone(c.phone),
              ),
            ),
          )
          .toList();

      emit(state.copyWith(status: ContactsStatus.success, contacts: updated));
    } catch (e) {
      emit(
        state.copyWith(
          status: ContactsStatus.failure,
          errorMessage: 'Kişiler alınırken bir hata oluştu.',
        ),
      );
    }
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<ContactsState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onLoadSearchHistory(
    LoadSearchHistory event,
    Emitter<ContactsState> emit,
  ) {
    emit(state);
  }

  void _onSearchFromHistory(
    SearchFromHistory event,
    Emitter<ContactsState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onAddSearchToHistory(
    AddSearchToHistory event,
    Emitter<ContactsState> emit,
  ) {
    final text = event.query.trim();
    if (text.isEmpty) return;

    final history = List<String>.from(state.searchHistory);

    history.remove(text);
    history.insert(0, text);

    if (history.length > 10) {
      history.removeLast();
    }

    emit(state.copyWith(searchHistory: history));
  }

  Future<void> _onAddContact(
    AddContact event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      final c = event.contact;

      // 1) Foto local path ise upload et, url’i al
      String? photoUrl = c.photoUrl;
      if (photoUrl != null &&
          photoUrl.isNotEmpty &&
          !photoUrl.startsWith('http')) {
        final file = File(photoUrl);
        if (await file.exists()) {
          final uploaded = await remoteDataSource.uploadImage(file);
          if (uploaded != null && uploaded.isNotEmpty) {
            photoUrl = uploaded;
          }
        }
      }

      // 2) Backend’e JSON olarak gönder
      final model = ContactModel(
        id: c.id,
        firstName: c.firstName,
        lastName: c.lastName,
        phone: c.phone,
        photoUrl: photoUrl,
        isInDeviceContacts: c.isInDeviceContacts,
      );

      await remoteDataSource.createContact(model);

      // 3) Listeyi tazele
      await _onLoadContacts(const LoadContacts(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          status: ContactsStatus.failure,
          errorMessage: 'Kişi kaydedilirken bir hata oluştu.',
        ),
      );
    }
  }

  // ---- UPDATE ----
  Future<void> _onUpdateContact(
    UpdateContact event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      final c = event.contact;

      String? photoUrl = c.photoUrl;
      if (photoUrl != null &&
          photoUrl.isNotEmpty &&
          !photoUrl.startsWith('http')) {
        final file = File(photoUrl);
        if (await file.exists()) {
          final uploaded = await remoteDataSource.uploadImage(file);
          if (uploaded != null && uploaded.isNotEmpty) {
            photoUrl = uploaded;
          }
        }
      }

      final model = ContactModel(
        id: c.id,
        firstName: c.firstName,
        lastName: c.lastName,
        phone: c.phone,
        photoUrl: photoUrl,
        isInDeviceContacts: c.isInDeviceContacts,
      );

      await remoteDataSource.updateContact(model);
      await _onLoadContacts(const LoadContacts(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          status: ContactsStatus.failure,
          errorMessage: 'Kişi güncellenirken bir hata oluştu.',
        ),
      );
    }
  }

  // ---- DELETE ----
  Future<void> _onDeleteContact(
    DeleteContact event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      await remoteDataSource.deleteContact(event.contactId);
      await _onLoadContacts(const LoadContacts(), emit);
    } catch (e) {
      emit(
        state.copyWith(
          status: ContactsStatus.failure,
          errorMessage: 'Kişi silinirken bir hata oluştu.',
        ),
      );
    }
  }

  // ---- Cihaz rehberi ile eşleştirme için yardımcılar ----

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('90') && digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  Future<Set<String>> _loadDevicePhoneSet() async {
  // 1) İzin iste
  final granted = await fc.FlutterContacts.requestPermission();
  if (!granted) {
    return {};
  }

  // 2) Rehberdeki kişileri al (telefon numaralarıyla birlikte)
  final contacts = await fc.FlutterContacts.getContacts(withProperties: true);

  final set = <String>{};

  for (final c in contacts) {
    for (final p in c.phones) {
      final normalized = _normalizePhone(p.number);
      if (normalized.isNotEmpty) {
        set.add(normalized);
      }
    }
  }

  return set;
}

}
