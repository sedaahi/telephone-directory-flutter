import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../blocs/contacts_bloc.dart';
import '../blocs/contacts_state.dart';
import '../blocs/contacts_event.dart';
import 'contact_profile_page.dart';
import 'contact_form_page.dart';

Map<String, List<dynamic>> groupContactsByFirstLetter(List<dynamic> contacts) {
  final Map<String, List<dynamic>> grouped = {};

  for (final contact in contacts) {
    final key = contact.firstLetter;

    if (!grouped.containsKey(key)) {
      grouped[key] = [];
    }
    grouped[key]!.add(contact);
  }

  // Harfleri alfabetik sıralama
  final sortedKeys = grouped.keys.toList()..sort();

  final Map<String, List<dynamic>> sortedGrouped = {
    for (final k in sortedKeys)
      k: grouped[k]!..sort((a, b) => a.fullName.compareTo(b.fullName)),
  };

  return sortedGrouped;
}

/// Liste ekranında avatarı çizen yardımcı widget
Widget buildContactAvatar(dynamic contact) {
  final String? photo = contact.photoUrl;

  bool isValidHttpUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  bool looksLikeBadPlaceholder(String s) =>
      s.trim().isEmpty || s.trim().toLowerCase() == 'string' || s == 'null';

  if (photo != null && !looksLikeBadPlaceholder(photo)) {
    if (isValidHttpUrl(photo)) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(photo),
        backgroundColor: Colors.grey.shade200,
      );
    } else {
      final file = File(photo);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: 20,
          backgroundImage: FileImage(file),
          backgroundColor: Colors.grey.shade200,
        );
      }
    }
  }

  final String letter = contact.fullName.isNotEmpty
      ? contact.fullName[0].toUpperCase()
      : '?';

  return CircleAvatar(
    radius: 20,
    backgroundColor: const Color(0xFFE3ECFF),
    child: Text(
      letter,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E90FF),
      ),
    ),
  );
}

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showHistory = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: BlocBuilder<ContactsBloc, ContactsState>(
          builder: (context, state) {
            // 1) Loading
            if (state.status == ContactsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2) Error
            if (state.status == ContactsStatus.failure) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'Bir hata oluştu',
                  textAlign: TextAlign.center,
                ),
              );
            }

            // 3) Filtre uygulanmadan önceki liste
            final query = state.searchQuery.trim().toLowerCase();

            final filteredContacts = query.isEmpty
                ? state.contacts
                : state.contacts.where((c) {
                    final fullName = c.fullName.toLowerCase();
                    return fullName.contains(query);
                  }).toList();

            final groupedContacts = groupContactsByFirstLetter(
              filteredContacts,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contacts',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ContactFormPage(),
                            ),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1E90FF), // mavi buton
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ------- SEARCH BAR -------
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: const InputDecoration(
                        hintText: 'Search by name',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onTap: () {
                        context.read<ContactsBloc>().add(
                          const LoadSearchHistory(),
                        );
                        setState(() {
                          _showHistory = true;
                        });
                      },
                      onChanged: (value) {
                        context.read<ContactsBloc>().add(
                          SearchQueryChanged(value),
                        );

                        if (value.isEmpty) {
                          setState(() {
                            _showHistory = true;
                          });
                        } else {
                          setState(() {
                            _showHistory = false;
                          });
                        }
                      },
                      onSubmitted: (value) {
                        context.read<ContactsBloc>().add(
                          AddSearchToHistory(value),
                        );
                        setState(() {
                          _showHistory = false;
                        });
                      },
                    ),
                  ),

                  // ------- SEARCH HISTORY -------
                  if (_showHistory &&
                      state.searchHistory.isNotEmpty &&
                      state.searchQuery.trim().isEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              'Search History',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          for (final item in state.searchHistory)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.history, size: 18),
                              title: Text(item),
                              onTap: () {
                                _searchController.text = item;
                                _searchFocusNode.unfocus();
                                context.read<ContactsBloc>().add(
                                  SearchFromHistory(item),
                                );
                                setState(() {
                                  _showHistory = false;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // ------- LİSTE -------
                  Expanded(
                    child: filteredContacts.isEmpty
                        ? const Center(child: Text('No Contacts'))
                        : ListView(
                            children: [
                              for (final entry in groupedContacts.entries) ...[
                                // Harf başlığı
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),

                                // Contact kartları
                                for (final contact in entry.value)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.02,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Slidable(
                                      key: ValueKey(contact.id),
                                      endActionPane: ActionPane(
                                        motion: const DrawerMotion(),
                                        extentRatio: 0.4,
                                        children: [
                                          SlidableAction(
                                            onPressed: (context) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ContactFormPage(
                                                        initialContact: contact,
                                                      ),
                                                ),
                                              );
                                            },
                                            icon: Icons.edit,
                                            label: 'Edit',
                                            backgroundColor: const Color(
                                              0xFF1E90FF,
                                            ),
                                            foregroundColor: Colors.white,
                                          ),
                                          SlidableAction(
                                            onPressed: (context) {
                                              context.read<ContactsBloc>().add(
                                                DeleteContact(contact.id),
                                              );
                                            },
                                            icon: Icons.delete,
                                            label: 'Delete',
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        leading: buildContactAvatar(
                                          contact,
                                        ), // 👈 avatar burada
                                        title: Text(
                                          contact.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          contact.phone,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        trailing: contact.isInDeviceContacts
                                            ? const Icon(
                                                Icons.phone_iphone,
                                                size: 18,
                                                color: Color(0xFF1E90FF),
                                              )
                                            : null,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ContactProfilePage(
                                                    contact: contact,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: null,
    );
  }
}
