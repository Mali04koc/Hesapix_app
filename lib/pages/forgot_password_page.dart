import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi Unuttum')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Kullanıcı adını gir. Bu projede Firebase Auth olmadığı için şifre sıfırlama linki gönderemiyoruz.\n'
                  'İstersen bir sonraki adımda “email ile sıfırlama” veya “admin onayıyla parola yenileme” akışı ekleyebiliriz.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı adı / Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Lütfen kullanıcı adını gir';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Yönetici ile iletişime geçerek şifre yenileme talebi oluşturabilirsin.'),
                      ),
                    );
                  },
                  child: const Text('Talep Oluştur'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

