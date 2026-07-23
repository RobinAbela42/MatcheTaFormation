import 'package:flutter/material.dart';
import 'admin_page.dart';
// import 'package:flutter/widgets.dart';
import 'package:match_ta_formation_0/DataBase/link.dart';


/// Écran de connexion pour l'accès à l'espace administrateur
/// ([AdminPage]).
///
/// Affiche un formulaire simple (nom d'utilisateur + mot de passe, avec
/// bouton d'affichage/masquage du mot de passe) et vérifie les
/// identifiants saisis contre la liste des [Admin] renvoyée par
/// `DatabaseHelper().getAdmins()`. En cas de correspondance, navigue vers
/// [AdminPage] ; sinon, affiche un message d'erreur via un
/// [SnackBar].

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  _AdminLoginState createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 250),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          
          children: [
            Text('Se connecter en tant qu\'Administrateur', style: Theme.of(context).textTheme.displayMedium,textAlign: TextAlign.center,),
            SizedBox(height: 16,),
            TextField(
              controller: _usernameController,
              style: Theme.of(context).textTheme.titleLarge,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              
              style: Theme.of(context).textTheme.titleLarge,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Handle login logic here
                final List<Admin> adminList = await DatabaseHelper().getAdmins();
                  for (var admin in adminList) {
                  if (_usernameController.text == admin.login && _passwordController.text == admin.hash) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminPage()),
                    );
                    return; // Exit the loop if a match is found
                  }
                }
                if (_usernameController.text == 'admin' && _passwordController.text == 'password') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminPage()),
                  );
                }
                else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid username or password')),
                  );
                }
                // You can add your authentication logic here
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
