import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/contacts/presentation/blocs/contacts_bloc.dart';
import 'features/contacts/presentation/blocs/contacts_event.dart';
import 'features/contacts/presentation/pages/contacts_page.dart';

import 'core/network/api_client.dart';
import 'features/contacts/data/datasources/contacts_remote_data_source.dart';

void main() {
  runApp(const TelephoneDirectoryApp());
}

class TelephoneDirectoryApp extends StatelessWidget {
  const TelephoneDirectoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // API client ve remote data source 
    final apiClient = ApiClient();
    final remoteDataSource =
        ContactsRemoteDataSourceImpl(apiClient: apiClient);

    return BlocProvider(
      create: (_) => ContactsBloc(remoteDataSource: remoteDataSource)
        ..add(const LoadContacts()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Telephone Directory',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
        ),
        home: const ContactsPage(),
      ),
    );
  }
}

