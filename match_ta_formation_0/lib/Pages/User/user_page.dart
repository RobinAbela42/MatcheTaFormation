// import 'dart:ui';

// import 'dart:js_interop';

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

  // / Returns the aggregated formation weights for a [Situation]:
  // / the union of every Formation found across all of its Responses,
  // / summed by weight (a formation appearing in multiple responses,
  // / or with weight > 1, contributes more).
  // /
  // / A response with no formations (or a null/empty map) simply
  // / contributes nothing — that's fine and expected.
  Map<int, int> _situationFormationWeights(Situation situation) {
    final Map<int, int> weights = {};
    final responses = situation.responses ?? [];
    for (final response in responses) {
      final formations = response.formations;
      if (formations == null) continue;
      formations.forEach((formation, weight) {
        final id = formation.id;
        if (id == null) return; // can't tally a formation without an id
        weights.update(
          id,
          (existing) => existing + weight,
          ifAbsent: () => weight,
        );
      });
    }
    return weights;
  }

  // / Picks [count] distinct situations from [situations], trying to keep
  // / the cumulative formation weight (summed across all selected situations'
  // / responses) as balanced as possible across all formations encountered.
  // /
  // / Strategy: greedy + randomized.
  // / For each slot, score every still-available situation by how it would
  // / affect balance if added (it's rewarded for touching formations that
  // / are currently under-represented, and penalized for adding more weight
  // / to formations that are already ahead). Among the situations tied for
  // / the best (or near-best) score, one is chosen at random, so the result
  // / isn't fully deterministic and varies between calls.

  List<Situation> selectBalancedSituations(
    List<Situation> situations, {
    int count = 12,
    Random? random,
  }) {
    final rng = random ?? Random();

    if (situations.length <= count) {
      // Not enough to choose from — just shuffle and return what's available.
      final pool = List<Situation>.from(situations)..shuffle(rng);
      return pool;
    }

    // Precompute each situation's formation weights once.
    final Map<Situation, Map<int, int>> situationWeights = {
      for (final s in situations) s: _situationFormationWeights(s),
    };

    final List<Situation> remaining = List<Situation>.from(situations);
    final List<Situation> selected = [];

    // Running totals: formationId -> cumulative weight selected so far.
    final Map<int, int> totals = {};

    for (var slot = 0; slot < count; slot++) {
      if (remaining.isEmpty) break;

      // Current average weight across formations seen so far (0 if none yet).
      final avg = totals.isEmpty
          ? 0.0
          : totals.values.reduce((a, b) => a + b) / totals.length;

      double bestScore = double.negativeInfinity;
      final List<Situation> bestCandidates = [];

      for (final candidate in remaining) {
        final weights = situationWeights[candidate]!;

        if (weights.isEmpty) {
          // A situation with no formations at all is neutral: it never
          // unbalances anything. Give it a modest, constant score so it's
          // still eligible but doesn't dominate situations that actively
          // help balance.
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

        // Score: for each formation this situation touches, compare the
        // formation's current total to the running average.
        // - Formations currently below average => adding weight there is
        //   good (positive contribution), more so the further below average.
        // - Formations already above average => adding more weight there
        //   is bad (negative contribution).
        // Formations not yet seen at all count as "infinitely under
        // represented", approximated here by treating their current total
        // as 0 and comparing directly to avg (or to a small baseline if
        // avg is 0 too, so brand-new formations are still preferred).
        double score = 0;
        weights.forEach((formationId, weight) {
          final current = totals[formationId] ?? 0;
          final deficit = avg - current; // positive = under-represented
          score += deficit * weight;
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

      // Random pick among equally-good candidates to keep variety run to run.
      final chosen = bestCandidates[rng.nextInt(bestCandidates.length)];
      selected.add(chosen);
      remaining.remove(chosen);

      // Update running totals with the chosen situation's contribution.
      situationWeights[chosen]!.forEach((formationId, weight) {
        totals.update(
          formationId,
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
            currentSessionSituations = selectBalancedSituations(snapshot.data!);
            currentSituation = currentSessionSituations[sessionCounter];
          }
          return Center(child: Wrap(
            children: [
              ElevatedButton.icon(onPressed: () {setState(() {
                
              });}, label: Text('Refresh'), icon: Icon(Icons.refresh)),
            ],
          ));
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
                        selectedLevel = Level(id: 5, label: 'label');
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
        Text(
          'A big card that can be swiped around and snaps back.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
