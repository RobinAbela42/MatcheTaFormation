import 'package:flutter/material.dart';

class SwipeCard extends StatefulWidget {
	final Widget? child;
	final double width;
	final double height;

	const SwipeCard({
		Key? key,
		this.child,
		this.width = 320,
		this.height = 480,
	}) : super(key: key);

	@override
	_SwipeCardState createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
	Offset _offset = Offset.zero;
	late AnimationController _controller;
	late Animation<Offset> _animation;

	@override
	void initState() {
		super.initState();
		_controller = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
		_animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut))
			..addListener(() {
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
		_animation = Tween<Offset>(begin: _offset, end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
					_runResetAnimation();
				},
				child: Transform.translate(
					offset: _offset,
					child: Card(
						elevation: 8,
						shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
						child: Container(
							width: widget.width,
							height: widget.height,
							padding: EdgeInsets.all(16),
							child: widget.child ?? _defaultContent(),
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
				Icon(Icons.person, size: 96, color: Colors.grey[700]),
				SizedBox(height: 16),
				Text('SwipeCard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
				SizedBox(height: 8),
				Text('A big card that can be swiped around and snaps back.', textAlign: TextAlign.center),
			],
		);
	}
}