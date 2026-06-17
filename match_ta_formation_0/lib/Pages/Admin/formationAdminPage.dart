import 'package:flutter/material.dart';
import 'package:match_ta_formation_0/DataBase/link.dart';

// class FormatinoEdit extends StatefulWidget {
//   final Formation formation;

//   const FormatinoEdit({Key? key, required this.formation}) : super(key: key);

//   @override
//   _FormatinoEditState createState() => _FormatinoEditState();
// }

// class _FormatinoEditState extends State<FormatinoEdit> {
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Column(
//         children: [
//           Text('Formation ID: ${widget.formation.id}'),
//           Text('Name: ${widget.formation.name}'),
//           Text('Description: ${widget.formation.description}'),
//           Text('Levels: ${widget.formation.levels.join(', ')}'),
//         ],
//       ),
//     );
//   }
// }





class FormationEdit extends StatefulWidget {
  final Formation formation;
  final VoidCallback onClose;

  const FormationEdit({super.key, required this.formation, required this.onClose});

  @override
  State<FormationEdit> createState() => _FormationEditState();
}

class _FormationEditState extends State<FormationEdit> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  List<dynamic> _levels = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.formation.name);
    _descriptionController = TextEditingController(text: widget.formation.description);
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
                'Edit Formation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Formation name',
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
          
          ElevatedButton(
            onPressed: () {
              //Update formation in the database  
              DatabaseHelper().updateFormation(
                Formation(
                  id: widget.formation.id,
                  name: _nameController.text,
                  description: _descriptionController.text,
                  levels: widget.formation.levels,
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
