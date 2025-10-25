import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/repositories/sos_repository.dart';

class SosPage extends StatefulWidget {
  const SosPage({super.key});
  @override
  State<SosPage> createState() => _Sos();
}

class _Sos extends State<SosPage> {
  final _repo = SosRepository();
  List<Map<String, dynamic>> contacts = [];
  final _label = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    contacts = await _repo.list();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS Contacts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Add Contact'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: _label, decoration: const InputDecoration(labelText: 'Label')),
                  TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone (tel:+57...)')),
                  TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    await _repo.add(label: _label.text, phone: _phone.text, email: _email.text);
                    if (context.mounted) Navigator.pop(context);
                    await _load();
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (_, i) {
          final c = contacts[i];
          return ListTile(
            title: Text(c['label'] ?? 'Contact'),
            subtitle: Text([
              if ((c['phone'] ?? '').isNotEmpty) c['phone'],
              if ((c['email'] ?? '').isNotEmpty) c['email'],
            ].join(' · ')),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if ((c['phone'] ?? '').isNotEmpty)
                IconButton(icon: const Icon(Icons.call), onPressed: () => launchUrl(Uri.parse(c['phone']))),
              if ((c['email'] ?? '').isNotEmpty)
                IconButton(icon: const Icon(Icons.email), onPressed: () => launchUrl(Uri.parse('mailto:${c['email']}'))),
            ]),
          );
        },
      ),
    );
  }
}
