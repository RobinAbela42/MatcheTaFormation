// import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:match_ta_formation_0/DataBase/link.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  List<Response> responses = [];
  //Jeu de test
  Situation situation = Situation(id: 12, description: 'DEm', responses: [
    Response(id:1 ,type: ResponseType(id: 1, label: 'Gauche' ), description: 'Reponse de gauche'),
    Response(id:2 ,type: ResponseType(id: 2, label: 'Droite' ), description: 'Reponse de droite', formations: <Formation, int>{ Formation(name: 'INFO', description: 'Informatique', levels: [Level(id: 1, label: 'tertiaire')]) : 1 }),
  ]);

  @override
  Widget build(BuildContext context) {
    return SwipeCard( width: 600, height: 800, situation:situation,  );
  }
}

class SwipeCard extends StatefulWidget {
  final Widget? child;
  final Situation situation;
  final double width;
  final double height;

  const SwipeCard({super.key, this.child, this.width = 320, this.height = 480, required this.situation});

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
