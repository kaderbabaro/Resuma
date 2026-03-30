import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../service/auth_service.dart';


class NewPasswordPage extends StatefulWidget {
  final AuthService authService;

  const NewPasswordPage({
    super.key,
    required this.authService,
  });

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _passwordController = TextEditingController();
  bool isLoading = false;
  bool obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final newPassword = _passwordController.text.trim();

      // 1️⃣ Mise à jour sur Supabase
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // 2️⃣ Récupérer user connecté
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null && user.email != null) {
        // 3️⃣ Synchroniser dans la base locale
        await widget.authService.syncNewPassword(
          user.email!,
          newPassword,
        );
      }

      // 4️⃣ Retour login
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 40),

                const Text(
                  "Create New Password",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => obscure = !obscure);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return "Minimum 6 characters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
                        foregroundColor:  MaterialStateProperty.all(Colors.white), ),
                    onPressed: isLoading ? null : _updatePassword,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Update Password"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}