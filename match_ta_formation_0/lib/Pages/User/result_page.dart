import 'package:flutter/material.dart';
import 'package:match_ta_formation_0/Pages/provider.dart';
import 'package:provider/provider.dart';

import '../../DataBase/link.dart' as lnk;

import 'package:fl_chart/fl_chart.dart';

class ResultDisplay extends StatefulWidget {
  final Map<lnk.Formation, int> currentSessionFormations;
  final void Function() onSessionEnded;

  const ResultDisplay({
    super.key,
    required this.currentSessionFormations,
    required this.onSessionEnded,
  });

  @override
  State<ResultDisplay> createState() => _ResultDisplayState();
}

class _ResultDisplayState extends State<ResultDisplay> {
  bool showFormations = false;

  @override
  Widget build(BuildContext context) {
    Map<lnk.Formation, int> selectedFormations = {};
    for (var form in widget.currentSessionFormations.entries) {
      if (selectedFormations.isEmpty) {
        selectedFormations.addEntries([MapEntry(form.key, form.value)]);
      } else if (selectedFormations.values.first == form.value) {
        selectedFormations.addEntries([MapEntry(form.key, form.value)]);
      } else if (selectedFormations.values.first < form.value) {
        selectedFormations.clear();
        selectedFormations.addEntries([MapEntry(form.key, form.value)]);
      }
    }

    double _getMaxY(List<MapEntry<lnk.Formation, int>> entries) {
      if (entries.isEmpty) return 10;
      final maxVal = entries
          .map((e) => e.value)
          .reduce((a, b) => a > b ? a : b);
      return (maxVal * 1.15);
    }

    Widget? bodyWidget;

    final entries = widget.currentSessionFormations.entries.toList();

    if (!showFormations) {
      bodyWidget = Center(
        // 1. SingleChildScrollView prevents layout crashes on small devices
        // if the centered block becomes taller than the screen.
        child: SingleChildScrollView(
          child: Column(
            // 2. Force the column to only take up as much space as its children need.
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      'Vous avez ${selectedFormations.length} matche${selectedFormations.length > 1 ? 's' : ''} !',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.equalizer, color: Colors.green, size: 32),
                        SizedBox(width: 8),
                        Text(
                          'Résultats de la session:',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...selectedFormations.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Card(
                          elevation: 15,
                          shape: const ContinuousRectangleBorder(),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              entry
                                  .key
                                  .name, // Removed redundant string interpolation
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.black,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1.0, 1.0),
                                    blurRadius: 2.0,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Chart Container
              SizedBox(
                height: 300,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, left: 8, top: 16),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(entries),
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= entries.length) {
                                return const SizedBox.shrink();
                              }
                              final formation = entries[index].key;
                              return SideTitleWidget(
                                meta: meta,
                                space: 10,
                                child: Transform.rotate(
                                  angle: -0.5,
                                  child: Text(
                                    formation.name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: entries.asMap().entries.map((mapEntry) {
                        final index = mapEntry.key;
                        final value = mapEntry.value.value;

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: value.toDouble(),
                              color: Theme.of(context).colorScheme.primary,
                              width: 22,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 35),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showFormations = !showFormations;
                  });
                },
                child: Text('Montrer toute les formations'),
              ),

              const SizedBox(height: 24), // Add some spacing before the button

              ElevatedButton(
                onPressed: () {
                  lnk.DatabaseHelper().insertResult(
                    lnk.Result(
                      id: null,
                      formations: selectedFormations,
                      time: DateTime.now(),
                      category: Provider.of<CategoryProvider>(
                        context,
                        listen: false,
                      ).selectedCategory,
                    ),
                  );
                  widget.onSessionEnded();
                },
                child: const Text('Recommencer'),
              ),
              const SizedBox(
                height: 32,
              ), // Add visual padding at the very bottom
            ],
          ),
        ),
      );
    } else {
      bodyWidget = Center(
        // 1. Wrap the Column in a Center widget
        child: Column(
          mainAxisSize: MainAxisSize
              .min, // 2. Tell the Column to shrink-wrap its children vertically
          mainAxisAlignment: MainAxisAlignment
              .center, // 3. Center the children inside the column
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final formation = entries[index].key;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(top: 3, right: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formation.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formation.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(
              height: 24,
            ), // Added a little spacing above the button for better UI
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showFormations = !showFormations;
                });
              },
              child: const Text('Retourner sur le graph'),
            ),
          ],
        ),
      );
    }

    return bodyWidget;
  }
}
