import 'package:flutter/material.dart';
import 'AdminPage.dart';
import 'package:flutter/widgets.dart';
import 'package:match_ta_formation_0/DataBase/link.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({Key? key}) : super(key: key);

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
        title: const Text('Admin Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
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
                // final List<Admin> adminList = await admins();
                //   for (var admin in adminList) {
                //   if (_usernameController.text == admin.login && _passwordController.text == admin.password) {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(builder: (context) => const AdminPage()),
                //     );
                //     return; // Exit the loop if a match is found
                //   }
                // }
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
