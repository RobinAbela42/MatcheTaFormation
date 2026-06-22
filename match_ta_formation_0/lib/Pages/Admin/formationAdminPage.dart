import 'package:flutter/material.dart';
import 'package:match_ta_formation_0/DataBase/link.dart';

class FormationEdit extends StatefulWidget {
  final Formation formation;
  final VoidCallback onClose;

  const FormationEdit({
    super.key,
    required this.formation,
    required this.onClose,
  });

  @override
  State<FormationEdit> createState() => _FormationEditState();
}

class _FormationEditState extends State<FormationEdit> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  List<Level> _levels = [];
  List<Level> _selectedLevels = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.formation.name);
    _descriptionController = TextEditingController(
      text: widget.formation.description,
    );
    _selectedLevels = List<Level>.from(widget.formation.levels);
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    final levels = await DatabaseHelper().getLevels();
    if (!mounted) return;
    setState(() {
      _levels = levels;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Text(
                'Modifier la formation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom de la formation',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          for (var level in _levels)
            CheckboxListTile(
              title: Text(level.label),
              value: _selectedLevels.any((l) => l.id == level.id),
              // value: true,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedLevels.add(level);
                  } else {
                    _selectedLevels.remove(level);
                  }
                });
              },
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              //Update formation in the database
              DatabaseHelper().updateFormation(
                Formation(
                  id: widget.formation.id,
                  name: _nameController.text,
                  description: _descriptionController.text,
                  levels: _selectedLevels,
                ),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Formation edit screen active')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}


class FormationAdd extends StatefulWidget {
  final VoidCallback onClose;

  const FormationAdd({
    super.key,
    required this.onClose,
  });

  @override
  State<FormationAdd> createState() => _FormationAddState();
}

class _FormationAddState extends State<FormationAdd> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  List<Level> _levels = [];
  List<Level> _selectedLevels = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedLevels = [];
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    final levels = await DatabaseHelper().getLevels();
    if (!mounted) return;
    setState(() {
      _levels = levels;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Text(
                'Ajouter une formation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom de la formation',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          for (var level in _levels)
            CheckboxListTile(
              title: Text(level.label),
              value: _selectedLevels.any((l) => l.id == level.id),
              // value: true,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedLevels.add(level);
                  } else {
                    _selectedLevels.remove(level);
                  }
                });
              },
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              //Insert formation into the database
              DatabaseHelper().insertFormation(
                Formation(
                  id: null,
                  name: _nameController.text,
                  description: _descriptionController.text,
                  levels: _selectedLevels,
                ),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Formation added successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
