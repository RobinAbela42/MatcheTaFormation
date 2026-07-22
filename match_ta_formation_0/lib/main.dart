import 'package:flutter/material.dart';
import 'Pages/Admin/admin_login.dart';
import 'Pages/User/user_page.dart';
import 'package:provider/provider.dart';
import 'package:match_ta_formation_0/DataBase/link.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'dart:io';

import 'Pages/provider.dart';

// Make sure you have your imports for sqflite, provider, dart:io, etc.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for Desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the global database factory
    databaseFactory = databaseFactoryFfi;
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 2. Await the database initialization here
  final Database db = await DatabaseHelper.initDb();

  // 3. Use MultiProvider to inject both your existing provider and the new database
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CategoryProvider()),
        Provider<Database>.value(value: db),
      ],
      child: const MyApp(),
    ),
  );
}

// Currently, this is the level of formations the user will face during this session. It will be updated after choosing it when choosing the level at the begining of the session.
int currentSessionLevel = 0;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',

      theme: ThemeData(
        fontFamily: 'Gotham',
        scaffoldBackgroundColor: Color.fromARGB(255, 28, 42, 175),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFFF2B83),
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
        ),
        cardTheme: CardThemeData(
          color: Color.fromARGB(255, 255, 43, 131),
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(0.0),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            labelStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            fillColor: Color.fromARGB(255, 255, 43, 131),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            color: Color(0xFF1C2AAF),
            // shadows: [
            //   Shadow(
            //     offset: Offset(1.0, 1.0),
            //     blurRadius: 2.0,
            //     color: Color.fromARGB(255, 0, 0, 0),
            //   ),
            // ],
          ),
          bodyMedium: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 2.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ],
          ),
          bodySmall: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 2.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ],
          ),
          titleSmall: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 2.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ],
          ),
          titleLarge: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 2.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ],
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 255, 43, 131),
            foregroundColor: Color.fromARGB(255, 255, 255, 255),
            textStyle: TextStyle(
              fontFamily: 'Gotham',
              fontSize: 16.0,
              fontWeight: FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
        listTileTheme: ListTileThemeData(
          style: ListTileStyle.list,
          textColor: Color.fromARGB(255, 255, 255, 255),
        ),

        tabBarTheme: TabBarThemeData(
          unselectedLabelColor: Color.fromARGB(255, 255, 255, 255),
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              width: 5.0,
              color: Color.fromARGB(255, 255, 43, 131),
            ),
            insets: EdgeInsets.symmetric(horizontal: 16.0),
            borderRadius: BorderRadius.circular(2.0), // rounds the line ends
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.amber,
          labelStyle: TextStyle(color: Colors.white),
        ),

        
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 43, 131),
          primary: Color.fromARGB(255, 255, 43, 131),
          secondary: Color.fromARGB(255, 28, 42, 175),
        ),
      ),
      home: const MyHomePage(title: 'Matche ta formation !'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
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
      ), // This trailing comma makes auto-formatting nicer for build methods.
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [Expanded(child: OnboardingScreen())],
        ),
      ),
    );
  }
}


/// Widget qui affiche son [child] avec un effet de zoom d'entrée (scale-in)
/// lors de son premier affichage à l'écran.
///
/// L'animation part d'une échelle de 0 (invisible/réduit) jusqu'à 1
/// (taille normale), en utilisant une [CurvedAnimation] pilotée par un
/// [AnimationController].
///
/// Exemple d'utilisation :
/// ```dart
/// ZoomedInWidget(
///   duration: const Duration(milliseconds: 600),
///   curve: Curves.elasticOut,
///   child: Text('Bonjour !'),
/// )
/// ```
///
/// ⚠️ Remarque : l'animation démarre automatiquement dans [initState] et
/// ne se relance pas si les propriétés du widget changent (par exemple
/// si [child] est remplacé). Si un redémarrage de l'animation est
/// nécessaire à chaque changement, il faudra surcharger [didUpdateWidget].
/// 
class ZoomedInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Alignment alignment;
  final Curve curve;

  const ZoomedInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.alignment = Alignment.center,
    this.curve = Curves.easeIn
  });

  @override
  State<ZoomedInWidget> createState() => _ZoomedInWidgetState();
}

class _ZoomedInWidgetState extends State<ZoomedInWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Set up the animation controller
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Apply the ease-in-out curve to a 0 to 1 scale range
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    // Trigger the animation forward immediately on display
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      alignment: widget.alignment,
      child: widget.child,
    );
  }
}
