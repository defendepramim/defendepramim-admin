import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'tela_login_admin.dart'; // Importação da tela que acabamos de criar

void main() async {
  // Garante que o Flutter carregou o motor gráfico antes de chamar a Web
  WidgetsFlutterBinding.ensureInitialized();
  
  // A mágica da conexão acontece aqui usando as chaves seguras
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const DefendeAdminApp());
}

class DefendeAdminApp extends StatelessWidget {
  const DefendeAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Defende Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      // ✨ Aqui está a alteração: apontando direto para a nossa nova tela!
      home: const TelaLoginAdmin(),
    );
  }
}