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
  Response? _isEditingResponsesFormation;

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

  OverlayEntry? _overlayEntry;

  void _showOverlay() {
    _removeOverlay();
    Future<List<Formation>> formations = DatabaseHelper().getFormations();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.black38,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _removeOverlay,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add Formation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Select a formation from the list below.'),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Formation>>(
                      future: formations,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final formationList = snapshot.data ?? <Formation>[];
                        if (formationList.isEmpty) {
                          return const Text('No formations available.');
                        }
                        return Wrap(
                          children: [
                            for (final formation in formationList)
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      final editingResponse =
                                          _isEditingResponsesFormation;
                                      if (editingResponse != null) {
                                        final responseIndex =
                                            widget.situation.responses
                                                ?.indexWhere(
                                                  (response) =>
                                                      response.id ==
                                                      editingResponse.id,
                                                ) ??
                                            -1;
                                        if (responseIndex != -1) {
                                          widget
                                              .situation
                                              .responses?[responseIndex]
                                              .formations
                                              ?.addEntries(
                                                <MapEntry<Formation, int>>[
                                                  MapEntry(formation, 1),
                                                ],
                                              );
                                        }
                                      }
                                      _isEditingResponsesFormation = null;
                                      _removeOverlay();
                                    });
                                  },
                                  child: Text(formation.name),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () {
                        _isEditingResponsesFormation = null;
                        _removeOverlay();
                      },
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, debugRequiredFor: widget).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    // _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
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
                'Editer une situation',
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
                    const Text(
                      'Formations:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (_isEditingResponsesFormation !=
                              widget.situation.responses?[index]) {
                            _isEditingResponsesFormation =
                                widget.situation.responses?[index];
                            _showOverlay();
                          }
                        });
                      },
                      child: Icon(Icons.add),
                    ),

                    if (widget.situation.responses?[index].formations?.isNotEmpty ??false) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            widget
                                .situation
                                .responses?[index]
                                .formations
                                ?.entries
                                .map(
                                  (entry) => SituationFormationCard(
                                    text: entry.key.name,
                                    onDelete: () {
                                      setState(() {
                                        widget
                                            .situation
                                            .responses?[index]
                                            .formations
                                            ?.remove(entry.key);
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
          ElevatedButton(
            onPressed: () {
              final responses = widget.situation.responses;
              final updatedResponses = responses?.asMap().entries.map((entry) {
                final index = entry.key;
                final response = entry.value;
                return Response(
                  id: response.id,
                  type: response.type,
                  description: _responseControllers[index].text,
                  formations: response.formations,
                );
              }).toList();

              DatabaseHelper().updateSituation(
                Situation(
                  id: widget.situation.id,
                  description: _descriptionController.text,
                  responses: updatedResponses ?? responses,
                ),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Situation edited successfuly')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class SituationAdd extends StatefulWidget {
  final VoidCallback onClose;

  const SituationAdd({super.key, required this.onClose});

  @override
  State<SituationAdd> createState() => _SituationAddState();
}

class _SituationAddState extends State<SituationAdd> {
  late final TextEditingController _descriptionController;
  final List<TextEditingController> _responseControllers = [];
  final List<Response> responses = <Response>[];
  Response? _isEditingResponsesFormation;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();

    DatabaseHelper().getResponseType().then((responseTypes) {
      // 2. Always check if the widget is still mounted after an async gap
      // before calling setState to prevent memory leaks/crashes.
      if (!mounted) return;

      // 3. Wrap the state changes in setState
      setState(() {
        for (final responseType in responseTypes) {
          final newResponse = Response(
            type: responseType,
            description: '',
            formations: <Formation, int>{},
          );

          responses.add(newResponse);

          // 4. Create the controller at the same time you create the response
          _responseControllers.add(
            TextEditingController(text: newResponse.description),
          );
        }
      });
    });
  }

  OverlayEntry? _overlayEntry;

  void _showOverlay() {
    _removeOverlay();
    Future<List<Formation>> formations = DatabaseHelper().getFormations();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.black38,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _removeOverlay,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add Formation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Select a formation from the list below.'),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Formation>>(
                      future: formations,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final formationList = snapshot.data ?? <Formation>[];
                        if (formationList.isEmpty) {
                          return const Text('No formations available.');
                        }
                        return Wrap(
                          children: [
                            for (final formation in formationList)
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      final editingResponse =
                                          _isEditingResponsesFormation;
                                      if (editingResponse != null) {
                                        final responseIndex = responses
                                            .indexWhere(
                                              (response) =>
                                                  response.id ==
                                                  editingResponse.id,
                                            );
                                        if (responseIndex != -1) {
                                          responses[responseIndex].formations
                                              ?.addEntries(
                                                <MapEntry<Formation, int>>[
                                                  MapEntry(formation, 1),
                                                ],
                                              );
                                        }
                                      }
                                      _isEditingResponsesFormation = null;
                                      _removeOverlay();
                                    });
                                  },
                                  child: Text(formation.name),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () {
                        _isEditingResponsesFormation = null;
                        _removeOverlay();
                      },
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, debugRequiredFor: widget).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    // _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
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
                'Ajouter une situation',
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
                        'Reponse : ${responses[index].type.label} :',
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

                    const Text(
                      'Formations:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (_isEditingResponsesFormation != responses[index]) {
                            _isEditingResponsesFormation = responses[index];
                            _showOverlay();
                          }
                        });
                      },
                      child: Icon(Icons.add),
                    ),
                    if (responses[index].formations?.isNotEmpty ?? false) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            responses[index].formations?.entries
                                .map(
                                  (entry) => SituationFormationCard(
                                    text: entry.key.name,
                                    onDelete: () {
                                      setState(() {
                                        responses[index].formations?.remove(
                                          entry.key,
                                        );
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
          ElevatedButton(
            onPressed: () {
              final updatedResponses = responses.asMap().entries.map((entry) {
                final index = entry.key;
                final response = entry.value;
                return Response(
                  id: response.id,
                  type: response.type,
                  description: _responseControllers[index].text,
                  formations: response.formations,
                );
              }).toList();

              DatabaseHelper().insertSituation(
                Situation(
                  id: null,
                  description: _descriptionController.text,
                  responses: updatedResponses,
                ),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Situation added successfuly')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// This is the widget for the formations under a formation's response. It contains the formation name store on [text], and a button to delete it, called [onDelete].
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
  }
}
