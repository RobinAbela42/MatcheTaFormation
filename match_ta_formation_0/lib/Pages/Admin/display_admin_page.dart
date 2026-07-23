import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AdminEditableText { tutoTitle1, tutoTitle2, tutoTitle3, tutoTitle4, resultFooter }

class TextRepository {
  static const _storageKey = 'admin_editable_texts';

  Future<Map<String, String>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return _defaults();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as String));
  }

  Future<void> saveAll(Map<String, String> texts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(texts));
  }

  Map<String, String> _defaults() => {
    AdminEditableText.tutoTitle1.name: '[PLACEHOLDER]',
    AdminEditableText.tutoTitle2.name: '[PLACEHOLDER]',
    AdminEditableText.tutoTitle3.name: '[PLACEHOLDER]',
    AdminEditableText.tutoTitle4.name: '[PLACEHOLDER]',
    AdminEditableText.resultFooter.name: '[PLACEHOLDER]',
  };
}

class TextStore extends ChangeNotifier {
  final TextRepository _repo;
  Map<String, String> _texts = {};

  TextStore(this._repo);

  Future<void> init() async {
    _texts = await _repo.loadAll();
    notifyListeners();
  }

  String textFor(AdminEditableText key) => _texts[key.name] ?? '';

  Future<void> updateText(AdminEditableText key, String value) async {
    _texts = {..._texts, key.name: value};
    notifyListeners();
    await _repo.saveAll(_texts);
  }
}

class DisplayAdminPage extends StatefulWidget {
  const DisplayAdminPage({super.key});

  @override
  _DisplayAdminPageState createState() => _DisplayAdminPageState();
}

class _DisplayAdminPageState extends State<DisplayAdminPage> {
  final Map<AdminEditableText, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    final store = context.read<TextStore>();
    for (final key in AdminEditableText.values) {
      controllers[key] = TextEditingController(text: store.textFor(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: AdminEditableText.values.map((key) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(key.name, style: Theme.of(context).textTheme.labelLarge),
                TextField(controller: controllers[key], maxLines: 3),
              ],
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.save),
        onPressed: () {
          final store = context.read<TextStore>();
          for (final key in AdminEditableText.values) {
            store.updateText(key, controllers[key]!.text);
          }
        },
      ),
    );
  }
}
