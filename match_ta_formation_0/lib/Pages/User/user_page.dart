// import 'dart:ui';

// import 'dart:js_interop';

import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:match_ta_formation_0/DataBase/link.dart';
import 'package:path/path.dart';

import 'result_page.dart';
// import 'package:match_ta_formation_0/Pages/Admin/admin_page.dart';
// import 'package:path/path.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  Level? selectedLevel;
  List<Situation> currentSessionSituations = [];
  Situation? currentSituation;
  int sessionCounter = 0;
  Map<Formation, int> currentSessionFormations = {};
  bool endOfSession = false;
  Result currentResult = Result(
    id: null,
    formations: [],
    time: null,
    category: null,
  );

  

  // Claude :

  /// Returns true if every response in [situation] that has formations
  /// contains at least one formation whose [Formation.levels] includes [level].
  ///
  /// Responses with a null or empty formations map are exempt — they carry no
  /// formation data and therefore cannot fail this check.
  ///
  /// This is the hard eligibility gate: a situation that fails it has at least
  /// one response whose formations are all irrelevant to the current level,
  /// meaning it would be shown to the user in a context where no valid answer
  /// exists for that response.
  bool _isEligibleForLevel(Situation situation, Level level) {
    final responses = situation.responses ?? [];
    for (final response in responses) {
      final formations = response.formations;
      if (formations == null || formations.isEmpty) {
        continue; // no formations → exempt
      }
      final hasMatch = formations.keys.any((f) => f.levels.contains(level));
      if (!hasMatch) {
        return false; // this response has formations, none match level
      }
    }
    return true;
  }

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
  /// Eligibility requirement (hard gate, applied before any scoring):
  /// every response within a situation that carries formations must have at
  /// least one formation belonging to [level]. A situation that fails this —
  /// even for a single response — is excluded entirely, because it would
  /// present the user with a response that has no valid formation for the
  /// current level.
  ///
  /// Strategy — greedy + randomized:
  /// For each slot, every still-available situation is scored by how much it
  /// would help the currently most under-represented formations. Among
  /// situations tied for the best score, one is chosen at random, so results
  /// vary between calls even for identical input data.
  List<Situation> selectBalancedSituations(
    List<Situation> situations,
    Level level, {
    int count = 4,
    Random? random,
  }) {
    final rng = random ?? Random();

    // Hard gate: filter to situations where every response with formations
    // has at least one formation belonging to [level]. Do this before
    // computing weights so we never process an ineligible situation.
    final List<Situation> eligible = situations
        .where((s) => _isEligibleForLevel(s, level))
        .toList();

    // Precompute formation weights for eligible situations only.
    // Every weight map here is guaranteed non-empty (eligibility ensures it).
    final Map<Situation, Map<Formation, int>> situationWeights = {
      for (final s in eligible) s: _situationFormationWeights(s, level),
    };

    if (eligible.length <= count) {
      // Fewer eligible situations than requested — return all of them shuffled.
      // Callers should handle a shorter-than-expected result gracefully.
      return eligible..shuffle(rng);
    }

    final List<Situation> remaining = List<Situation>.from(eligible);
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
        // weights is guaranteed non-empty: eligibility ensures every
        // candidate has at least one level-matching formation.
        final weights = situationWeights[candidate]!;

        // Score this candidate:
        //  - Formations currently below the average contribute positively
        //    (deficit > 0 → picking this helps balance).
        //  - Formations already above the average contribute negatively
        //    (deficit < 0 → picking this worsens balance).
        // The weight multiplier means formations touched by many responses
        // have proportionally more influence on the score.
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

  // Fin Claude

  /// Widget build method for the UserPage. Displays either the current situation [currentSituation]
  /// from a list of situations [currentSessionSituations] get from [selectBalancedSituations] based on
  /// the [selectedLevel] or a list of levels to choose from.
  @override
  Widget build(BuildContext context) {
    if (endOfSession && currentSessionFormations.isNotEmpty) {
      return ResultDisplay(
        currentSessionFormations: currentSessionFormations,
        onSessionEnded: () {
          setState(() {            
            endOfSession = false;
            currentSessionFormations.clear();
            currentSessionSituations.clear();
            currentSituation = null;
            sessionCounter = 0;
            selectedLevel = null;
          });
        },
      );
    }

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

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No situations found.'));
          } else {
            currentSessionSituations = selectBalancedSituations(
              snapshot.data!,
              selectedLevel!,
            );
            currentSituation = currentSessionSituations[sessionCounter];
          }

          if (currentSituation != null) {
            return SwipeCard(
              situation: currentSituation!,
              onSwiped: (response) {
                // Handle the swipe action
                setState(() {
                  if (sessionCounter < currentSessionSituations.length - 1) {
                    sessionCounter++;
                    currentSituation = currentSessionSituations[sessionCounter];
                    if (response.formations != null &&
                        response.formations!.isNotEmpty) {
                      for (var form in response.formations!.entries) {
                        stderr.writeln(
                          'Formation: ${form.key.name}, Weight: ${form.value}',
                        );
                        if (currentSessionFormations.containsKey(form.key)) {
                          currentSessionFormations[form.key] =
                              currentSessionFormations[form.key]! + form.value;
                        } else {
                          currentSessionFormations.addEntries([
                            MapEntry(form.key, form.value),
                          ]);
                        }
                      }
                    }
                  } else {
                    // Handle end of session
                    endOfSession = true;
                  }
                });
              },
            );
          }
          return const Center(child: Text('Nothing to display now.'));
        },
      );
    }

    return Padding(
      padding: EdgeInsetsGeometry.all(15),
      child: Center(
        child: FutureBuilder<List<Level>>(
          future: DatabaseHelper().getLevels(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No levels found.');
            } else {
              final levels = snapshot.data!;
              return ListView.builder(
                itemCount: levels.length,

                itemBuilder: (context, index) {
                  final level = levels[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedLevel = level;
                          });
                        },
                        child: Text(level.label),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class SwipeCard extends StatefulWidget {
  final Widget? child;
  final Situation situation;
  final double width;
  final double height;

  final void Function(Response) onSwiped;

  const SwipeCard({
    super.key,
    this.child,
    this.width = 320,
    this.height = 480,
    required this.onSwiped,
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

  TickerFuture _runSwipeAnimation(Offset endOffset) {
    _animation = Tween<Offset>(
      begin: _offset,
      end: endOffset,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    return _controller.forward(from: 0);
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
            final currentOffset = _offset;
            _runSwipeAnimation(Offset(_offset.dx.sign * 1100, 0)).then((_) {
              if (currentOffset.dx > 0) {
                widget.onSwiped(widget.situation.responses![1]);
              } else {
                widget.onSwiped(widget.situation.responses![0]);
              }
            });
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
              Expanded(
                child: Text(widget.situation.responses![0].description!),
              ),
              SizedBox(height: 12, width: 12),
              Expanded(
                child: Text(widget.situation.responses![1].description!),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
