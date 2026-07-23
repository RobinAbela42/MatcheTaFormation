// import 'dart:ui';

// import 'dart:js_interop';

import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:math'; 
import 'package:match_ta_formation_0/DataBase/link.dart';
import 'package:match_ta_formation_0/Pages/Admin/admin_login.dart';
import 'package:match_ta_formation_0/Pages/Admin/display_admin_page.dart';
import 'package:match_ta_formation_0/main.dart';
import 'package:provider/provider.dart';

import 'result_page.dart';
import 'package:match_ta_formation_0/Pages/Admin/admin_page.dart';
// import 'package:path/path.dart';


/// Écran principal du parcours utilisateur : sélection du niveau
/// (secondaire/tertiaire), enchaînement des situations sous forme de
/// cartes swipables ([SwipeCard]), puis affichage du résultat final
/// (formations recommandées) via [ResultDisplay].
///
/// Le flux se déroule en 3 phases, pilotées par l'état local :
/// 1. **Sélection du niveau** (`selectedLevel == null`) : affiche la
///    liste des [Level] disponibles (chargés via
///    `DatabaseHelper().getLevels()`) sous forme de boutons.
/// 2. **Session de situations** (`selectedLevel != null`,
///    `endOfSession == false`) : charge l'ensemble des [Situation] via
///    `DatabaseHelper().getSituations()`, en sélectionne un sous-ensemble
///    équilibré par formation grâce à [selectBalancedSituations], puis les
///    présente une à une dans un [ZoomedInWidget] > [SwipeCard]. Chaque
///    réponse de l'utilisateur (swipe gauche/droite) incrémente les poids
///    de formations correspondants dans [currentSessionFormations].
/// 3. **Fin de session / résultats** (`endOfSession == true`) : affiche
///    un court écran de chargement (2 secondes, via `Future.delayed`)
///    puis les résultats agrégés via [ResultDisplay]. Un bouton flottant
///    "Réinitialiser" (visible dès qu'une situation est en cours) permet
///    d'abandonner la session à tout moment et de revenir à l'accueil.
///
/// Un [FloatingActionButton] en haut à droite donne accès à la page
/// d'administration ([AdminLogin]), indépendamment de l'état du parcours.
///
/// Sélection équilibrée des situations ([selectBalancedSituations]) :
/// l'algorithme filtre d'abord les situations "éligibles" pour le
/// [Level] choisi (chaque réponse portant des formations doit en avoir
/// au moins une compatible avec le niveau — voir [_isEligibleForLevel]),
/// puis choisit glouton-aléatoirement les situations qui équilibrent le
/// mieux le poids cumulé de chaque formation (voir
/// [_situationFormationWeights]), afin d'éviter qu'une formation ne soit
/// sur-représentée dans les résultats finaux.


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

  // ... (Keep your helper methods like _isEligibleForLevel, selectBalancedSituations, etc.) ...

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
  int count = 10,
  Random? random,
}) {
  final rng = random ?? Random();

  // De-duplicate by id first. Two different Situation instances with the
  // same id represent the same underlying row and must not both be
  // eligible for selection. Situations with a null id can't be tracked
  // back to a row, so we keep at most the first occurrence we see but
  // can't guarantee uniqueness for them beyond object identity.
  final List<Situation> deduped = [];
  final Set<int> seenIds = {};
  for (final s in situations) {
    if (s.id == null) {
      deduped.add(s);
      continue;
    }
    if (seenIds.add(s.id!)) {
      deduped.add(s);
    }
  }

  // Hard gate: filter to situations where every response with formations
  // has at least one formation belonging to [level]. Do this before
  // computing weights so we never process an ineligible situation.
  final List<Situation> eligible = deduped
      .where((s) => _isEligibleForLevel(s, level))
      .toList();

  if (eligible.isEmpty) return [];

  // Precompute formation weights for eligible situations only, keyed by
  // situation id (falling back to object identity for null-id situations)
  // rather than the Situation object itself, so we don't depend on
  // Situation having value equality.
  final Map<Object, Map<Formation, int>> situationWeights = {
    for (final s in eligible) (s.id ?? s): _situationFormationWeights(s, level),
  };

  if (eligible.length <= count) {
    // Fewer eligible situations than requested — return all of them shuffled.
    // Callers should handle a shorter-than-expected result gracefully.
    return eligible..shuffle(rng);
  }

  final List<Situation> remaining = List<Situation>.from(eligible);
  final List<Situation> selected = [];
  final Map<Formation, int> totals = {};

  for (var slot = 0; slot < count; slot++) {
    if (remaining.isEmpty) break; // no more situations → stop, don't pad

    final avg = totals.isEmpty
        ? 0.0
        : totals.values.reduce((a, b) => a + b) / totals.length;

    double bestScore = double.negativeInfinity;
    final List<Situation> bestCandidates = [];

    for (final candidate in remaining) {
      final weights = situationWeights[candidate.id ?? candidate]!;

      double score = 0;
      weights.forEach((formation, weight) {
        final current = totals[formation] ?? 0;
        score += (avg - current) * weight;
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

    final chosen = bestCandidates[rng.nextInt(bestCandidates.length)];
    selected.add(chosen);
    remaining.remove(chosen); // removes this exact instance from remaining

    situationWeights[chosen.id ?? chosen]!.forEach((formation, weight) {
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

  void resetSession() {
    endOfSession = false;
    currentSessionFormations.clear();
    currentSessionSituations.clear();
    currentSituation = null;
    sessionCounter = 0;
    selectedLevel = null;
  }



bool _isLoadingResults = false;

  @override
  Widget build(BuildContext context) {
    // We define the main content body dynamically based on state
    Widget bodyContent;

    if (endOfSession && currentSessionFormations.isNotEmpty) {
      if (!_isLoadingResults) {
    // 1. Instantly show the loader
    bodyContent = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Calcul de la meilleur formation ...', style: Theme.of(context).textTheme.displaySmall ,),
          const SizedBox(height: 24,),
          const CircularProgressIndicator()

      ],),
    );

    // 2. Trigger a 3-second delay, then force a rebuild to show ResultDisplay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) { // Always safety check 'mounted' before calling setState after an async gap
        setState(() {
          _isLoadingResults = true;
        });
      }
    });
  } else {
    // 3. 3 seconds have passed, show the actual results
    bodyContent = ResultDisplay(
      currentSessionFormations: currentSessionFormations,
      onSessionEnded: () {
        setState(() {
          _isLoadingResults = false; // Reset the loader flag for the next cycle
          resetSession();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'Matche ta formation !'),
            ),
          );
        });
      },
    );
  }
    } else if (selectedLevel != null) {
      bodyContent = FutureBuilder<List<Situation>>(
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
            return ZoomedInWidget(
              child: SwipeCard(
                situation: currentSituation!,
                onSwiped: (response) {
                  setState(() {
                    if (sessionCounter < currentSessionSituations.length - 1) {
                      sessionCounter++;
                      currentSituation =
                          currentSessionSituations[sessionCounter];
                      if (response.formations != null &&
                          response.formations!.isNotEmpty) {
                        for (var form in response.formations!.entries) {
                          stderr.writeln(
                            'Formation: ${form.key.name}, Weight: ${form.value}',
                          );
                          if (currentSessionFormations.containsKey(form.key)) {
                            currentSessionFormations[form.key] =
                                (currentSessionFormations[form.key]! +
                                        form.value)
                                    .toInt();
                          } else {
                            currentSessionFormations.addEntries([
                              MapEntry(form.key, form.value),
                            ]);
                          }
                        }
                      }
                    } else {
                      endOfSession = true;
                    }
                  });
                },
              ),
            );
          }
          return const Center(child: Text('Nothing to display now.'));
        },
      );
    } else {
      // Default level selection view
      bodyContent = Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: FutureBuilder<List<Level>>(
            // Senior optimization note: If this rebuilds too often, cache this future
            // in initState instead of instantiating it inline in the build method.
            future: DatabaseHelper().getLevels(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No levels found.');
              } else {
                final levels = snapshot.data!;

                return Column(
                  // Tells the column to only take as much vertical space as its children need
                  mainAxisSize: MainAxisSize.min,
                  // Centers the items horizontally within the column layout
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Add a clean header title for better UX
                    Text(
                      'Choisissez votre niveau',
                      style: Theme.of(context).textTheme.displayMedium 
                    ),
                    const SizedBox(height: 32),

                    // Dynamically map your levels to a list of beautifully styled buttons
                    ...levels.map((level) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(
                          width:
                              280, // Gives every button a uniform, polished width
                          height:
                              56, // Modern tap-target height (Material standard is >= 48)
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 4, // Adds a subtle drop shadow
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  16.0,
                                ), // Rounded modern edges
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedLevel = level;
                              });
                            },
                            child: Text(
                              level.label,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }
            },
          ),
        ),
      );
    }

    // Wrap the entire widget output in a Scaffold so the theme applies!
    return Scaffold(
      // Your existing FAB setup (pushed to the top-right corner)
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminLogin()),
          );
        },
        tooltip: 'Admin page',
        child: const Icon(Icons.account_circle),
      ),

      // We wrap our layout in a Stack to manage multi-layered floating elements
      body: Stack(
        children: [
          // Layer 1: The main content takes up the entire screen space
          Positioned.fill(child: bodyContent),

          // Layer 2: The conditional top-left floating button
          if (currentSituation != null)
            Positioned(
              top: 16.0, // Adjust padding from the top edge
              left: 16.0, // Adjust padding from the left edge
              child: SafeArea(
                // Ensures the button stays clear of device notches/status bars
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      resetSession();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              const MyHomePage(title: 'Matche ta formation !'),
                        ),
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  icon: const Icon(Icons.reset_tv, color: Colors.white,),
                  label: Text('Réinitialiser', style: Theme.of(context).textTheme.bodyMedium,),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Carte swipable (façon "Tinder") représentant une [situation] à laquelle
/// l'utilisateur répond en glissant la carte vers la gauche ou la droite.
///
/// La [situation] doit exposer une propriété `description` (texte affiché
/// au centre de la carte) ainsi qu'une liste `responses` d'au moins deux
/// éléments, chacun avec une propriété `description` : `responses[0]`
/// correspond au choix "gauche" (swipe gauche / bouton flèche gauche) et
/// `responses[1]` au choix "droite" (swipe droite / bouton flèche droite).
///
/// Le geste de glissement est géré manuellement via [GestureDetector]
/// (`onPanUpdate` / `onPanEnd`) et déplace la carte en suivant le doigt.
/// Si le déplacement horizontal dépasse un seuil de 150px au relâchement,
/// la carte est automatiquement éjectée hors de l'écran (swipe complet) ;
/// sinon, elle revient à sa position initiale ([_runResetAnimation]).
/// Les deux boutons fléchés en bas de carte déclenchent le même
/// comportement que le swipe correspondant ([swipeLeft] / [swipeRight]),
/// sans nécessiter de geste.
///
/// Une fois le swipe (ou le clic sur bouton) validé, [onSwiped] est appelé
/// avec la réponse choisie (`responses[0]` ou `responses[1]`), puis la
/// position de la carte est réinitialisée pour la prochaine carte de la
/// pile.
///
/// L'animation de déplacement (glissement, éjection, retour au centre)
/// est pilotée par un unique [AnimationController] combiné à des
/// [Tween<Offset>] recréés à la volée selon l'action en cours.
/// 
class SwipeCard extends StatefulWidget {
  // Passing the situation structure directly to read its text content
  final dynamic situation;
  final double width;
  final double height;
  final void Function(dynamic) onSwiped;

  const SwipeCard({
    super.key,
    this.width = 520, // Polished target width
    required this.onSwiped,
    required this.situation,
    this.height = 800,
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
      duration: const Duration(milliseconds: 300),
    );

    // Setting up baseline listener
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

  // Unified logic for Swiping Left (Choice 0)
  void swipeLeft() {
    _runSwipeAnimation(const Offset(-1100, 0)).then((_) {
      widget.onSwiped(widget.situation.responses![0]);
      // Reset state position for the next arriving card card stack
      setState(() => _offset = Offset.zero);
    });
  }

  // Unified logic for Swiping Right (Choice 1)
  void swipeRight() {
    _runSwipeAnimation(const Offset(1100, 0)).then((_) {
      widget.onSwiped(widget.situation.responses![1]);
      setState(() => _offset = Offset.zero);
    });
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
          if (_offset.dx < -150) {
            swipeLeft(); // Clear left trigger threshold
          } else if (_offset.dx > 150) {
            swipeRight(); // Clear right trigger threshold
          } else {
            _runResetAnimation();
          }
        },
        child: Transform.translate(
          offset: _offset,
          child: Transform.rotate(
            angle: _offset.dx / 1000,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                // Sharp rectangular edges to match your ContinuousRectangleBorder style
                borderRadius: BorderRadius.circular(0.0),
                // Layering shadows to cleanly mimic your target elevation of 8
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8.0,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4.0,
                    offset: const Offset(0, 1),
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage(
                    'assets/1x/Swipe-card.png',
                  ), // Using your verified asset path
                  fit: BoxFit
                      .cover, // Ensures the image stretches to fill the whole card envelope cleanly
                ),
              ),
              child: _buildCenteredContent(),
            ),
          ),
        ),
      ),
    );
  }

  // The optimized layout showing centered text content and clean action buttons
  Widget _buildCenteredContent() {
    final responseLeft =
        widget.situation.responses![0].description ?? 'Option A';
    final responseRight =
        widget.situation.responses![1].description ?? 'Option B';

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top/Middle section: Centered main text description
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Text(
                widget.situation.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Bottom section: Vertically stacked, centered uniform buttons
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Plain text display of the two options
            Row(
              children: [
                Expanded(
                  child: Text(
                    responseLeft,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 50),
                Expanded(
                  child: Text(
                    responseRight,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Button (Choice 0) - Takes exactly half the space
                Expanded(
                  child: SizedBox(
                    height: 54, // Set a uniform modern height
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryFixedDim,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primaryFixed,
                          width: 2,
                        ),
                        elevation: 3,
                        // Setting the border radius to a sharp rectangle with slight modern smoothing
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: swipeLeft,
                      child: const Icon(Icons.arrow_back, size: 28),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ), // Spacer gap between the two rectangles
                // Right Button (Choice 1) - Takes exactly half the space
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryFixedDim,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primaryFixed,
                          width: 2,
                        ),
                        elevation: 3,
                        // Setting the border radius to a sharp rectangle with slight modern smoothing
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: swipeRight,
                      child: const Icon(Icons.arrow_forward, size: 28),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Écran d'onboarding (tutoriel de bienvenue) affiché au premier lancement
/// de l'application "Matche Ta Formation".
///
/// Présente une série d'étapes définies dans [_tutorialSteps], chacune
/// rendue via un [TutorialStepWidget], au sein d'un [PageView] swipable
/// contrôlé par [_pageController]. Une barre de navigation en bas de
/// l'écran affiche des indicateurs de progression (points) ainsi que des
/// boutons "Précédent" / "Suivant" (le dernier devenant "Commencer" sur
/// la dernière étape). Une image décorative est superposée en haut à
/// gauche de l'écran via un [Stack].
///
/// Une fois la dernière étape validée, [_completeOnboarding] redirige
/// l'utilisateur vers [UserPage] en remplaçant la pile de navigation
/// (retour arrière impossible vers l'onboarding).

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  // Define your steps as isolated, reusable widgets
  final List<Widget> _tutorialSteps = [
    const TutorialStepWidget(
      title: 'Bienvenue sur Matche Ta Formation !',
      description: AdminEditableText.tutoTitle1,
      icon: Icons.waving_hand,
    ),
    const TutorialStepWidget(
      title: 'Comment ça marche ?',
      description: AdminEditableText.tutoTitle2,
      icon: Icons.explore,
    ),
    const TutorialStepWidget(
      title: 'Secondaire ? Tertiaire ?',
      description: AdminEditableText.tutoTitle3,
      icon: Icons.question_mark_rounded,
    ),
    const TutorialStepWidget(
      title: 'C\'est parti !',
      description: AdminEditableText.tutoTitle4,
      icon: Icons.rocket_launch,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < _tutorialSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onPreviousPressed() {
    if (_currentPage <= _tutorialSteps.length - 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() {
    // 1. Write to SharedPreferences here: SharedPreferences.setBool('isFirstRun', false)
    // 2. Clear stack and navigate to main experience
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const UserPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // The Stack acts as the root of the screen body to layer floating elements
      body: Stack(
        children: [
          // Layer 1: Your complete tutorial and navigation layout
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // The PageView handles the step rendering and gestures
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      children: _tutorialSteps,
                    ),
                  ),
                  // Bottom navigation bar (Indicators + Action Button)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Visual page indicator (dots)
                        Row(
                          children: List.generate(
                            _tutorialSteps.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              height: 8,
                              width: _currentPage == index ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? Colors.blue
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        // Action Buttons
                        Row(
                          children: [
                            if (_currentPage != 0) ...[
                              ElevatedButton(
                                onPressed: _onPreviousPressed,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Précedent', style: TextStyle(fontSize: 34),),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            ElevatedButton(
                              onPressed: _onNextPressed,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(  
                                  _currentPage == _tutorialSteps.length - 1
                                      ? 'Commencer'
                                      : 'Suivant',style: TextStyle(fontSize: 34)
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Layer 2: The overlay image pinned to the top-left corner
          Positioned(
            top: -50.0,
            left: -50.0,
            child: SafeArea(
              // Prevents the image from being clipped by native status bars or notches
              child: Image.asset(
                'assets/1x/Bubble-2.png', // Replace with your image location
                width: 500, // Explicit width constraint
                height: 500, // Explicit height constraint
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback container in case the local asset file is missing during test builds
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.red,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dummy widget representing individual tutorial steps
class TutorialStepWidget extends StatelessWidget {
  final String title;
  final AdminEditableText description;
  final IconData icon;

  const TutorialStepWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 40),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontFamily: 'Gotham',
              fontSize: 32,
              shadows: []
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.watch<TextStore>().textFor(description),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
