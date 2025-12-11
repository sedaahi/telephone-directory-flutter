import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../domain/entities/contact_entity.dart';
import '../blocs/contacts_bloc.dart';
import '../blocs/contacts_event.dart';

class ContactFormPage extends StatefulWidget {
  final ContactEntity? initialContact;

  const ContactFormPage({super.key, this.initialContact});

  bool get isEdit => initialContact != null;

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Eğer edit modundaysak alanları doldur
    final contact = widget.initialContact;
    if (contact != null) {
      _firstNameController.text = contact.firstName;
      _lastNameController.text = contact.lastName;
      _phoneController.text = contact.phone;
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _selectedImage = picked;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isEdit) {
      final old = widget.initialContact!;
      final updatedContact = ContactEntity(
        id: old.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: _selectedImage?.path ?? old.photoUrl,
        isInDeviceContacts: old.isInDeviceContacts,
      );

      context.read<ContactsBloc>().add(UpdateContact(updatedContact));
    } else {
      final newContact = ContactEntity(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: _selectedImage?.path,
        isInDeviceContacts: false,
      );

      context.read<ContactsBloc>().add(AddContact(newContact));
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset('assets/animations/Done.json', repeat: false),
                const SizedBox(height: 12),
                Text(
                  widget.isEdit ? 'The profile has been updated!' : 'The profile has been saved!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Okay'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? 'Edit Contact' : 'New Contact';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // FOTOĞRAF / AVATAR 
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                    child: _selectedImage != null
                        ? ClipOval(
                            child: Image.file(
                              File(_selectedImage!.path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (widget.initialContact?.photoUrl != null &&
                              widget.initialContact!.photoUrl!.isNotEmpty)
                        ? ClipOval(
                            child:
                                widget.initialContact!.photoUrl!.startsWith(
                                  'http',
                                )
                                ? Image.network(
                                    widget.initialContact!.photoUrl!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(widget.initialContact!.photoUrl!),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : const Icon(Icons.camera_alt, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // AD
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name required!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // SOYAD
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // TELEFON
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone Required';
                  }
                  return null;
                },
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _onSave,
                  icon: const Icon(Icons.check),
                  label: Text(widget.isEdit ? 'Edit' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
