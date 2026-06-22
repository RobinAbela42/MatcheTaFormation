import 'package:flutter/material.dart';
import 'package:match_ta_formation_0/DataBase/link.dart';

class SituationEdit extends StatefulWidget {
  final Situation situation;
  final VoidCallback onClose;

  const SituationEdit({
    super.key,
    required this.situation,
    required this.onClose,
  });

  @override
  State<SituationEdit> createState() => _SituationEditState();
}

class _SituationEditState extends State<SituationEdit> {
  late final TextEditingController _descriptionController;
  late final List<TextEditingController> _responseControllers;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.situation.description,
    );
    final List<Response> responses = widget.situation.responses ?? <Response>[];
    _responseControllers = responses
        .map((r) => TextEditingController(text: r.description.toString()))
        .toList();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    for (final c in _responseControllers) {
      c.dispose();
    }
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
                'Edit Situation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Situation :',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              _responseControllers.length,
              (index) => SizedBox(
                width:
                    MediaQuery.of(context).size.width *
                        1 /
                        _responseControllers.length -
                    20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Text(
                        'Reponse : ${widget.situation.responses?[index].type.label ?? 'Unknown'} :',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _responseControllers[index],
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget
                            .situation
                            .responses?[index]
                            .formations
                            ?.isNotEmpty ??
                        false) ...[
                      const Text(
                        'Formations:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget
                            .situation
                            .responses?[index]
                            .formations
                            ?.entries
                            .map(
                              (entry) => SituationFormationCard(
                                text: entry.key.name,
                                onDelete: () {
                                  setState(() {
                                    widget.situation.responses?[index].formations?.remove(entry.key);
                                  });
                                },
                              ),
                            )
                            .toList() ??
                        [],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SituationFormationCard extends StatelessWidget {
  final String text;
  final VoidCallback onDelete;

  const SituationFormationCard({
    super.key,
    required this.text,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(text, style: Theme.of(context).textTheme.titleSmall),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );

    // IconButton(
    //   onPressed: onDelete,S
    //   icon: const Icon(Icons.delete),
    //   tooltip: 'Delete',
    // ),
  }
}
