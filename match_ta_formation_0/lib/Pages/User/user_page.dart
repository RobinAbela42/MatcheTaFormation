// import 'dart:ui';

// import 'dart:js_interop';

import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:match_ta_formation_0/DataBase/link.dart';
// import 'package:match_ta_formation_0/Pages/Admin/admin_page.dart';
// import 'package:path/path.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  List<Response> responses = [];
  Level? selectedLevel;
  List<Situation> currentSessionSituations = [];
  Situation? currentSituation;
  int sessionCounter = 0;

/// Returns the aggregated formation weights for a [Situation], considering
/// only formations that include [level] in their [Formation.levels] list.
///
/// Every formation found across all of a situation's responses is summed by
/// its weight value. A response with no formations, or with formations that
/// don't match the required level, simply contributes nothing.
Map<Formation, int> _situationFormationWeights(
  Situation situation,
  Level level,
) {
  final Map<Formation, int> weights = {};
  final responses = situation.responses ?? [];
 
  for (final response in responses) {
    final formations = response.formations;
    if (formations == null) continue;
 
    formations.forEach((formation, weight) {
      if (formation.id == null) return; // no id → can't track this formation
      if (!formation.levels.contains(level)) return; // level filter
      weights.update(
        formation,
        (existing) => existing + weight,
        ifAbsent: () => weight,
      );
    });
  }
  return weights;
}
 
/// Picks [count] distinct situations from [situations], trying to keep
/// the cumulative formation weight as balanced as possible across all
/// formations that include [level].
///
/// Formations that don't belong to [level] are ignored entirely, so the
/// balancing only considers what's relevant to the current session's level.
///
/// Strategy — greedy + randomized:
/// For each slot, every still-available situation is scored by how much it
/// would help the currently most under-represented formations. Among
/// situations tied for the best score, one is chosen at random, so results
/// vary between calls even for identical input data.
List<Situation> selectBalancedSituations(
  List<Situation> situations,
  Level level, {
  int count = 12,
  Random? random,
}) {
  final rng = random ?? Random();
 
  if (situations.length <= count) {
    // Not enough distinct situations — shuffle and return everything.
    return List<Situation>.from(situations)..shuffle(rng);
  }
 
  // Precompute each situation's level-filtered formation weights once,
  // so we don't re-traverse all responses on every scoring loop iteration.
  final Map<Situation, Map<Formation, int>> situationWeights = {
    for (final s in situations) s: _situationFormationWeights(s, level),
  };
 
  final List<Situation> remaining = List<Situation>.from(situations);
  final List<Situation> selected = [];
 
  // Running totals: Formation → cumulative weight contributed by selected
  // situations so far. Only formations matching [level] appear here.
  final Map<Formation, int> totals = {};
 
  for (var slot = 0; slot < count; slot++) {
    if (remaining.isEmpty) break;
 
    // Average weight across all formations seen so far.
    // Starts at 0.0 when nothing has been selected yet.
    final avg = totals.isEmpty
        ? 0.0
        : totals.values.reduce((a, b) => a + b) / totals.length;
 
    double bestScore = double.negativeInfinity;
    final List<Situation> bestCandidates = [];
 
    for (final candidate in remaining) {
      final weights = situationWeights[candidate]!;
 
      if (weights.isEmpty) {
        // This situation has no formations matching the required level.
        // It's neutral — it can't help or hurt balance — so give it a
        // constant score of 0.0. It remains eligible but won't beat a
        // situation that genuinely helps an under-represented formation.
        const neutralScore = 0.0;
        if (neutralScore > bestScore) {
          bestScore = neutralScore;
          bestCandidates
            ..clear()
            ..add(candidate);
        } else if (neutralScore == bestScore) {
          bestCandidates.add(candidate);
        }
        continue;
      }
 
      // Score this candidate:
      //  - Formations currently below the average contribute positively
      //    (deficit is positive → good to pick this situation).
      //  - Formations already above the average contribute negatively
      //    (deficit is negative → picking this would worsen balance).
      // The weight multiplier means a formation touched by many responses
      // has a proportionally larger influence on the score.
      double score = 0;
      weights.forEach((formation, weight) {
        final current = totals[formation] ?? 0;
        score += (avg - current) * weight; // deficit × weight
      });
 
      if (score > bestScore) {
        bestScore = score;
        bestCandidates
          ..clear()
          ..add(candidate);
      } else if (score == bestScore) {
        bestCandidates.add(candidate);
      }
    }
 
    // Pick randomly among equally-scored candidates for run-to-run variety.
    final chosen = bestCandidates[rng.nextInt(bestCandidates.length)];
    selected.add(chosen);
    remaining.remove(chosen);
 
    // Commit the chosen situation's weights to the running totals.
    situationWeights[chosen]!.forEach((formation, weight) {
      totals.update(
        formation,
        (existing) => existing + weight,
        ifAbsent: () => weight,
      );
    });
  }
 
  return selected;
}

  //Jeu de test
  @override
  Widget build(BuildContext context) {
    if (selectedLevel != null) {
      return FutureBuilder<List<Situation>>(
        future: DatabaseHelper().getSituations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (currentSituation != null) {
            return SwipeCard(situation: currentSituation!);
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No situations found.'));
          } else {
            currentSessionSituations = selectBalancedSituations(snapshot.data!, selectedLevel!);
            currentSituation = currentSessionSituations[sessionCounter];
            for (var situation in currentSessionSituations) {
              stderr.write('\nSituation n°${situation.id ?? 0}   ');
              for (var response in situation.responses!) {
                stderr.write(' R ');
                for (var formation in response.formations!.keys) {
                  stderr.write(' F ');
                  for (var level in formation.levels) {
                    stderr.write(' ${level.label} ');
                  }
                }
              }
            }
            return SwipeCard(situation: currentSituation!);
          }
        },
      );
    }

    return Padding(
      padding: EdgeInsetsGeometry.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        selectedLevel = Level(id: 1, label: 'Secondaire');
                        setState(() {
                          
                        });
                      },
                      icon: Icon(Icons.start),
                      label: Text('Start session'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SwipeCard extends StatefulWidget {
  final Widget? child;
  final Situation situation;
  final double width;
  final double height;

  const SwipeCard({
    super.key,
    this.child,
    this.width = 320,
    this.height = 480,
    required this.situation,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  Offset _offset = Offset.zero;
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation =
        Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        )..addListener(() {
          setState(() {
            _offset = _animation.value;
          });
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runResetAnimation() {
    _animation = Tween<Offset>(
      begin: _offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0);
  }

  void _runSwipeAnimation(Offset endOffset) {
    _animation = Tween<Offset>(
      begin: _offset,
      end: endOffset,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _offset += details.delta;
          });
        },
        onPanEnd: (details) {
          if (_offset.dx.abs() > 300) {
            // If the card is swiped far enough, you can implement logic to remove it or perform an action.
            // For now, we'll just reset it back to the center.
            _runSwipeAnimation(Offset(_offset.dx.sign * 1100, 0));
          } else {
            _runResetAnimation();
          }
        },
        child: Transform.translate(
          offset: _offset,
          child: Transform.rotate(
            angle: _offset.dx / 1000,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: widget.width,
                height: widget.height,
                padding: EdgeInsets.all(16),
                child: widget.child ?? _defaultContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 16),

        Text(
          widget.situation.description,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(child: Text(widget.situation.responses![0].description!)),
              SizedBox(height: 12, width: 12,),
              Expanded(child: Text(widget.situation.responses![1].description!))
            ],
          ),
        )
      ],
    );
  }
}
