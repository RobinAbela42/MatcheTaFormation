import 'package:flutter/material.dart';

import '../../DataBase/link.dart';

class ResultDisplay extends StatefulWidget {
  Map<Formation, int> currentSessionFormations;
  final void Function() onSessionEnded;

  ResultDisplay({
    super.key,
    required this.currentSessionFormations,
    required this.onSessionEnded,
  });

  @override
  State<ResultDisplay> createState() => _ResultDisplayState();
}

class _ResultDisplayState extends State<ResultDisplay> {
  @override
  Widget build(BuildContext context) {
    Map<Formation, int> selectedFormations = {};
    for (var form in widget.currentSessionFormations.entries) {
      if(selectedFormations.isEmpty) {
        selectedFormations.addEntries([MapEntry(form.key, form.value)]);
      } else 
      if (selectedFormations.values.first == form.value) {
        selectedFormations.addEntries([MapEntry(form.key, form.value)]);
      } else
      if (selectedFormations.values.first < form.value) {
        selectedFormations.clear();
        selectedFormations.addEntries([MapEntry(form.key, form.value)]);
      } 
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Column(
              children: [
                const Text(
                  'Session Completed!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 32),
                    SizedBox(width: 8),
                    Text(
                      'La session est terminée.',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.equalizer, color: Colors.green, size: 32),
                    SizedBox(width: 8),
                    
                    Text('Résultats de la session:', style: TextStyle(fontSize: 18)),
                  ],
                ),
                const Text(
                  'Formations encountered during this session:',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                ...selectedFormations.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${entry.key.name}: ${entry.value}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    )),
                const SizedBox(height: 16),
              ],
            ),
          ),

          ElevatedButton(
            onPressed: () {
              DatabaseHelper().insertResult(Result(
                id: null,
                formations: widget.currentSessionFormations.entries
                    .map((entry) => entry.key)
                    .toList(),
                time: DateTime.now(),
                category: null,
              ));

              widget.onSessionEnded();
            },
            child: const Text('Start New Session'),
          ),
        ],
      ),
    );
  }
}
