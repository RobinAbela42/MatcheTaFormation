import 'dart:io';

import 'package:flutter/material.dart';
import 'package:match_ta_formation_0/DataBase/link.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;

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
  XFile? _pendingImage;

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

  Future<void> _save() async {
    final updatedFormation = Formation(
      id: widget.formation.id,
      name: _nameController.text,
      description: _descriptionController.text,
      levels: _selectedLevels,
      imagePath: widget.formation.imagePath,
    );

    await DatabaseHelper().updateFormation(
      updatedFormation,
      pickedImage: _pendingImage, // 👈 this is the missing piece
    );

    // stderr.writeln(widget.formation.imagePath);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formation modifiée avec succes.')),
    );

    widget.onClose(); // optional: close the edit view after saving
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
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

            style: Theme.of(context).textTheme.titleLarge,
            decoration: const InputDecoration(
              labelText: 'Nom de la formation',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,

            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          for (var level in _levels)
            CheckboxListTile(
              title: Text(level.label, style: Theme.of(context).textTheme.titleLarge,),
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
          FormationImagePicker(
            initialImage: widget.formation.image, // null when creating
            onImagePicked: (xfile) => setState(() => _pendingImage = xfile),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _save();
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

  const FormationAdd({super.key, required this.onClose});

  @override
  State<FormationAdd> createState() => _FormationAddState();
}

class _FormationAddState extends State<FormationAdd> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  List<Level> _levels = [];
  List<Level> _selectedLevels = [];

  // File? _selectedImage;
  // final ImagePicker _picker = ImagePicker();

  // Future _pickImage(ImageSource source) async {
  //   final XFile? pickedFile = await _picker.pickImage(
  //     source: source,
  //     imageQuality: 85, // Simple compression optimization
  //   );

  //   if (pickedFile != null) {
  //     setState(() {
  //       _selectedImage = File(pickedFile.path);
  //     });
  //   }
  // }

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
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

            style: Theme.of(context).textTheme.titleLarge,
            decoration: const InputDecoration(
              labelText: 'Nom de la formation',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,

            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          for (var level in _levels)
            CheckboxListTile(
              title: Text(level.label, style: Theme.of(context).textTheme.titleLarge),
              value: _selectedLevels.any((l) => l.id == level.id),
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

          // Center(
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Container(
          //         width: 50,
          //         height: 70,
          //         decoration: BoxDecoration(
          //           color: Colors.grey[200],
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //         child: _selectedImage != null
          //             ? ClipRRect(
          //                 borderRadius: BorderRadius.circular(12),
          //                 child: Image.file(_selectedImage!, fit: BoxFit.cover),
          //               )
          //             : const Icon(Icons.image, size: 20, color: Colors.grey),
          //       ),
          //       const SizedBox(height: 24),
          //       ElevatedButton.icon(
          //         onPressed: () => _pickImage(ImageSource.gallery),
          //         icon: const Icon(Icons.photo_library),
          //         label: const Text('Gallery'),
          //       ),
          //     ],
          //   ),
          // ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isEmpty ||
                  _descriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez remplir les champs correctement.'),
                  ),
                );
              } else {
                DatabaseHelper().insertFormation(
                  Formation(
                    id: null,
                    name: _nameController.text,
                    description: _descriptionController.text,
                    levels: _selectedLevels,
                  ),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Formation ajoutée avec succes'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class FormationImagePicker extends StatefulWidget {
  final File? initialImage;
  final ValueChanged<XFile> onImagePicked;

  const FormationImagePicker({
    super.key,
    this.initialImage,
    required this.onImagePicked,
  });

  @override
  State<FormationImagePicker> createState() => _FormationImagePickerState();
}

class _FormationImagePickerState extends State<FormationImagePicker> {
  final ImagePicker _picker = ImagePicker();
  File? _displayFile; // local preview only; actual persistence happens on save

  @override
  void initState() {
    super.initState();
    final initial = widget.initialImage;
    if (initial != null && initial.existsSync()) {
      _displayFile = initial;
    }
  }

  Future<void> _pick(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _displayFile = File(picked.path));
    widget.onImagePicked(picked);
  }

  void _showSourceSheet() {
    _pick(ImageSource.gallery);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showSourceSheet,
      child: CircleAvatar(
        radius: 56,
        backgroundImage: _displayFile != null ? FileImage(_displayFile!) : null,
        child: _displayFile == null
            ? const Icon(Icons.add_a_photo, size: 36)
            : null,
      ),
    );
  }
}
