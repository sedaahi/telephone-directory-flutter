import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../domain/entities/contact_entity.dart';
import '../blocs/contacts_bloc.dart';
import '../blocs/contacts_event.dart';
import 'contact_form_page.dart';

class ContactProfilePage extends StatefulWidget {
  final ContactEntity contact;

  const ContactProfilePage({super.key, required this.contact});

  @override
  State<ContactProfilePage> createState() => _ContactProfilePageState();
}

class _ContactProfilePageState extends State<ContactProfilePage> {
  Color? _shadowColor;
  String? _currentPhotoPath;
  late bool _isInDeviceContacts;
  final ImagePicker _picker = ImagePicker();

  bool get isSaved => _isInDeviceContacts;

  bool _isBadPhotoValue(String? s) {
    if (s == null) return true;
    final t = s.trim();
    return t.isEmpty ||
        t.toLowerCase() == 'string' ||
        t.toLowerCase() == 'null';
  }

  bool _isHttpUrl(String s) {
    final t = s.trim();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  bool _fileExists(String s) {
    final t = s.trim();
    return File(t).existsSync();
  }

  @override
  void initState() {
    super.initState();
    _currentPhotoPath = widget.contact.photoUrl;
    _isInDeviceContacts = widget.contact.isInDeviceContacts;
    _generatePalette();
  }

  Future<void> _generatePalette() async {
    final photoPath = _currentPhotoPath;

    // ✅ Guard’lar: string/null/url/boş/yok dosya -> palette üretme
    if (_isBadPhotoValue(photoPath)) return;
    final p = photoPath!.trim();
    if (_isHttpUrl(p)) return;
    if (!_fileExists(p)) return;

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        FileImage(File(p)),
        size: const Size(200, 200),
      );

      final dominant = palette.dominantColor?.color;
      if (!mounted || dominant == null) return;

      setState(() {
        _shadowColor = dominant.withValues(alpha: 0.6);
      });
    } catch (_) {
      // sessiz geç
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (picked == null || !mounted) return;

    setState(() {
      _currentPhotoPath = picked.path;
    });

    await _generatePalette();

    final old = widget.contact;
    final updated = ContactEntity(
      id: old.id,
      firstName: old.firstName,
      lastName: old.lastName,
      phone: old.phone,
      photoUrl: _currentPhotoPath, // local path
      isInDeviceContacts: _isInDeviceContacts,
    );

    context.read<ContactsBloc>().add(UpdateContact(updated));
  }

  void _openEditMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openEditForm();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete'),
                  textColor: Colors.red,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _confirmDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showChangePhotoSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _pickImage(ImageSource.camera);
                },
                child: const Text('Camera'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _pickImage(ImageSource.gallery);
                },
                child: const Text('Gallery'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveToDeviceContacts() async {
    final permission = await FlutterContacts.requestPermission();
    if (!permission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rehbere erişim izni verilmedi.')),
      );
      return;
    }

    final c = widget.contact;

    final contact = Contact()
      ..name.first = c.firstName
      ..name.last = c.lastName
      ..phones = [Phone(c.phone)];

    await contact.insert();

    if (!mounted) return;

    setState(() {
      _isInDeviceContacts = true;
    });

    context.read<ContactsBloc>().add(const LoadContacts());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kişi cihaz rehberine kaydedildi.')),
    );
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Delete Contact',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to delete this contact?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('No'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Yes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete == true && mounted) {
      context.read<ContactsBloc>().add(DeleteContact(widget.contact.id));
      Navigator.of(context).pop();
    }
  }

  void _openEditForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContactFormPage(initialContact: widget.contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;
    final theme = Theme.of(context);

    // ✅ Avatar karar değişkenleri (UI’dan hemen önce)
    final pRaw = _currentPhotoPath;
    final p = pRaw?.trim();

    final isBad = _isBadPhotoValue(p);
    final isUrl = !isBad && _isHttpUrl(p!);
    final fileOk = !isBad && !isUrl && _fileExists(p!);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          contact.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _openEditMenu,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _shadowColor ?? Colors.black26,
                              blurRadius: 32,
                              spreadRadius: 6,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey.shade200,
                          child: ClipOval(
                            child: !isBad
                                ? (isUrl
                                      ? Image.network(
                                          p,
                                          width: 110,
                                          height: 110,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _LetterAvatar(contact: contact),
                                        )
                                      : (fileOk
                                            ? Image.file(
                                                File(p),
                                                width: 110,
                                                height: 110,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return _LetterAvatar(
                                                        contact: contact,
                                                      );
                                                    },
                                              )
                                            : _LetterAvatar(contact: contact)))
                                : _LetterAvatar(contact: contact),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _showChangePhotoSheet,
                        child: const Text(
                          'Change Photo',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  initialValue: contact.firstName,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: contact.lastName,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: contact.phone,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: isSaved
                      ? FilledButton.icon(
                          onPressed: null,
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          label: const Text('Save to My Phone Contact'),
                        )
                      : OutlinedButton.icon(
                          onPressed: _saveToDeviceContacts,
                          icon: const Icon(Icons.contact_phone),
                          label: const Text('Save to My Phone Contact'),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSaved ? 'This contact is already saved your phone.' : '',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  final ContactEntity contact;
  const _LetterAvatar({required this.contact});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Center(
        child: Text(
          contact.fullName.isNotEmpty ? contact.fullName[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
