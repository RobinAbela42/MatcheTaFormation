import 'dart:io';

import 'package:flutter/material.dart';
import 'package:match_ta_formation_0/Pages/provider.dart';
import 'package:provider/provider.dart';

import '../../DataBase/link.dart' as lnk;

import 'package:fl_chart/fl_chart.dart';

/// Écran de fin de session affichant les résultats du "matching" de
/// formation, calculés à partir de [currentSessionFormations] (map de
/// [lnk.Formation] → poids cumulé, construite par [UserPage] au fil des
/// réponses de l'utilisateur).
///
/// Propose deux vues, basculables via le bouton "Montrer toute les
/// formations" / "Retourner sur le graph" (état [showFormations]) :
/// - **Vue graphique (par défaut)** : détermine la ou les formation(s)
///   "gagnante(s)" (celles ayant le poids maximal, stockées dans
///   `selectedFormations`), les affiche sous forme de cartes en tête de
///   page, puis un [BarChart] (package `fl_chart`) représentant le poids
///   de **toutes** les formations de la session pour comparaison visuelle.
///   Un bouton "Recommencer" enregistre le résultat en base via
///   `lnk.DatabaseHelper().insertResult(...)` (avec la catégorie active
///   récupérée via [CategoryProvider]) puis appelle [onSessionEnded] pour
///   permettre au parent ([UserPage]) de réinitialiser la session.
/// - **Vue liste** : présente l'ensemble des formations de la session
///   (`entries`, non filtrées) sous forme de liste détaillée avec nom et
///   description, pour consultation exhaustive avant de revenir au
///   graphique.
///
/// Points d'attention pour les développeurs :
/// - La logique de sélection des formations "gagnantes" (`selectedFormations`)
///   est recalculée à **chaque** appel de `build` (boucle en début de
///   méthode), ce qui est redondant : à extraire dans une méthode dédiée
///   ou à calculer une seule fois (ex. dans `initState` ou via un
///   `late final` recalculé uniquement quand `currentSessionFormations`
///   change).
/// - Cette logique de sélection suppose que `currentSessionFormations`
///   n'est pas vide ; si c'est le cas, `selectedFormations` restera vide
///   et le texte "Vous avez 0 matche" s'affichera — comportement à
///   confirmer comme voulu.
/// - `insertResult` est appelé uniquement au moment de cliquer sur
///   "Recommencer" : si l'utilisateur ferme l'app ou navigue autrement
///   avant ce clic, le résultat de la session ne sera jamais persisté.
/// - Le bouton "Montrer toute les formations" contient une faute
///   d'accord ("toute" → "toutes").
/// - `_getMaxY` est une fonction locale redéfinie à chaque `build` :
///   à extraire en méthode privée de la classe si des optimisations de
///   performance sont nécessaires plus tard.

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

    double getMaxY(List<MapEntry<lnk.Formation, int>> entries) {
      if (entries.isEmpty) return 10;
      final maxVal = entries
          .map((e) => e.value)
          .reduce((a, b) => a > b ? a : b);
      return (maxVal * 1.15);
    }

    double getLeftInterval(List<MapEntry<lnk.Formation, int>> entries) {
      final maxY = getMaxY(entries);
      if (maxY <= 5) return 1;
      if (maxY <= 20) return 2;
      if (maxY <= 50) return 5;
      return (maxY / 10).ceilToDouble(); // roughly 10 labels max
    }

    Widget? bodyWidget;

    final entries = widget.currentSessionFormations.entries.toList();

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

    if (!showFormations) {
      bodyWidget = Center(
        // 1. SingleChildScrollView prevents layout crashes on small devices
        // if the centered block becomes taller than the screen.
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
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
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.equalizer,
                            color: Theme.of(context).primaryColor,
                            size: 64,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Résultats de la session:',
                            style: Theme.of(context).textTheme.displayMedium,
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
                                '${entry.key.name} (${entry.key.description})', // Removed redundant string interpolation
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Color(0xFF1C2AAF),
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
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine:
                              false, // vertical lines rarely help on a bar chart
                          horizontalInterval: getLeftInterval(
                            entries,
                          ), // match the label spacing
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                              strokeWidth:
                                  1, // solid, not dashed — omit dashArray entirely
                            );
                          },
                        ),
                        alignment: BarChartAlignment.spaceAround,
                        maxY: getMaxY(entries),
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 64,
                              interval: getLeftInterval(
                                entries,
                              ), // see helper below
                              getTitlesWidget: (double value, TitleMeta meta) {
                                // Only show whole numbers, skip anything that rounds oddly
                                if (value != value.roundToDouble())
                                  return const SizedBox.shrink();
                                return Text(
                                  '${(value * 100 / 11 * 2).toInt()} %',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.displaySmall,
                                );
                              },
                            ),
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.displaySmall,
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

                const SizedBox(
                  height: 24,
                ), // Add some spacing before the button

                ElevatedButton(
                  onPressed: () {
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Add padding so cards don't clip flush against screen edges while scrolling
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final entry in selectedFormations.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _FormationScoreCard(
                        formation: entry.key,
                        score: entry.value,
                      ),
                    ),
                ],
              ),
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
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                widget.onSessionEnded();
              },
              child: const Text('Recommencer'),
            ),
          ],
        ),
      );
    }

    return bodyWidget;
  }
}

class _FormationScoreCard extends StatefulWidget {
  final lnk.Formation formation;
  final int score;

  const _FormationScoreCard({required this.formation, required this.score});

  @override
  State<_FormationScoreCard> createState() => _FormationScoreCardState();
}

class _FormationScoreCardState extends State<_FormationScoreCard> {
  @override
  Widget build(BuildContext context) {
    final image = widget.formation.image;
    final hasImage = image != null && image.existsSync();

    stderr.write('Image : ${widget.formation.imagePath} ');
    return SizedBox(
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasImage
                ? Image.file(image, width: 300, height: 450, fit: BoxFit.cover)
                : Container(
                    width: 350,
                    height: 525,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.formation.description,
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${(widget.score * 100 / 11 * 2).toInt()} %',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
