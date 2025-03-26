import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/constants/colors.dart';
import 'package:staff_admin/core/services/auth_service.dart';
import 'package:staff_admin/features/admin/screens/admin_home_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height / 2.2,
              width: double.infinity,
              child: Image.asset(
                'assets/images/logo_annexx_fond_blanc.png',
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _loginKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'nom@annexx.com',
                        border: OutlineInputBorder(),
                      ),
                      validator: (input) {
                        if (input!.isEmpty) {
                          return 'Entrer une adresse email valide';
                        } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(input)) {
                          return "Le format de l'adresse mail n'est pas valide";
                        }
                        return null;
                      },
                      onSaved: (input) => _emailController.text = input!,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureText,
                      onFieldSubmitted: (value) {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        _submitForm(authService);
                      },
                      validator: (input) {
                        if (input!.length < 6) {
                          return 'Le mot de passe doit contenir au moins 6 caractères';
                        }
                        return null;
                      },
                      onSaved: (input) => _passwordController.text = input!,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showForgotPasswordDialog(context, authService),
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(color: redAnnexx),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: redAnnexx,
                      ),
                      onPressed: () => {_submitForm(authService)},
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        child: Text(
                          'Se connecter',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm(AuthService authService) async {
    if (_loginKey.currentState!.validate()) {
      _loginKey.currentState!.save();
      var credential = Credential(
        email: _emailController.text,
        password: _passwordController.text,
      );

      String result = await authService.login(credential);
      if (!mounted) return;
      if (result == "Vous êtes connecté !") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminHomeScreen(),
          ),
        );
      } else {
        _showErrorDialog(context, result);
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Une erreur est survenue',
            style: TextStyle(color: redAnnexx),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showForgotPasswordDialog(BuildContext context, AuthService authService) {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Réinitialisation du mot de passe',
            style: TextStyle(color: redAnnexx),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Entrez votre adresse email pour recevoir un lien de réinitialisation',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                if (emailController.text.isNotEmpty) {
                  final result = await authService.resetPassword(emailController.text);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  _showMessageDialog(
                    context,
                    'Réinitialisation du mot de passe',
                    result,
                  );
                }
              },
              child: const Text(
                'Envoyer',
                style: TextStyle(color: redAnnexx),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessageDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(color: redAnnexx),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
