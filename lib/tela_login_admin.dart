import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'tela_dashboard_admin.dart'; // Importação do Dashboard

class TelaLoginAdmin extends StatefulWidget {
  const TelaLoginAdmin({super.key});

  @override
  State<TelaLoginAdmin> createState() => _TelaLoginAdminState();
}

class _TelaLoginAdminState extends State<TelaLoginAdmin> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;

  // Cores identidade do Defende Pra Mim
  static const primaryColor = Color(0xFF00E676);
  static const cardColor = Color(0xFF1E1E1E);

  Future<void> _fazerLogin() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      _mostrarErro("Preencha todos os campos.");
      return;
    }

    setState(() => _carregando = true);

    try {
      // 1. Tenta autenticar o e-mail e senha no Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final uid = userCredential.user?.uid;

      if (uid != null) {
        // 2. Busca o documento do usuário no Firestore para checar o "pedágio" de Admin
        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();

        if (doc.exists) {
          final dados = doc.data() as Map<String, dynamic>;
          final bool isAdmin = dados['isAdmin'] ?? false;

          if (isAdmin) {
            // ✨ SE FOR ADMIN: Abre o painel
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const TelaDashboardAdmin()),
              );
            }
          } else {
            // ❌ SE NÃO FOR ADMIN: Desloga imediatamente por segurança
            await FirebaseAuth.instance.signOut();
            _mostrarErro("Acesso Negado: Esta conta não tem permissões administrativas.");
          }
        } else {
          await FirebaseAuth.instance.signOut();
          _mostrarErro("Erro: Perfil de usuário não encontrado no banco de dados.");
        }
      }
    } on FirebaseAuthException catch (e) {
      String erroMsg = "Erro ao fazer login.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        erroMsg = "E-mail ou senha incorretos.";
      }
      _mostrarErro(erroMsg);
    } catch (e) {
      _mostrarErro("Ocorreu um erro inesperado: $e");
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarErro(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  void _mostrarSucesso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: primaryColor, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: 400, // Largura fixa ideal para telas de PC/Navegador
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
        // ... dentro do build da TelaLoginAdmin
child: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.center, // ✨ Mudamos para centralizar tudo
  children: [
    Center(
      child: Column(
        children: [
          Image.asset(
            'assets/logo.png',
            height: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            "DEFENDE ADMIN",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
          ),
        ],
      ),
    ),
    const SizedBox(height: 8),
    // ✨ Texto centralizado agora:
    const Text(
      "Área restrita para gerenciamento do ecossistema.", 
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white38, fontSize: 13)
    ),
    const SizedBox(height: 30),
    
    // E-MAIL
    const Align(
      alignment: Alignment.centerLeft,
      child: Text("E-MAIL CORPORATIVO", style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
    ),
    const SizedBox(height: 8),
    TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      textInputAction: TextInputAction.next, // ✨ Faz o enter ir para o próximo campo
      decoration: InputDecoration(
        hintText: "admin@defendepramim.com",
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        filled: true,
        fillColor: Colors.black26,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor)),
      ),
    ),
    const SizedBox(height: 20),
    
    // SENHA
    const Align(
      alignment: Alignment.centerLeft,
      child: Text("SENHA DE ACESSO", style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
    ),
    const SizedBox(height: 8),
    TextField(
      controller: _senhaController,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      textInputAction: TextInputAction.done, // ✨ Ícone de "Check" ou "Pronto" no teclado
      onSubmitted: (_) => _fazerLogin(), // 🔥 A MÁGICA AQUI: Chama o login ao apertar Enter
      decoration: InputDecoration(
        hintText: "••••••••",
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        filled: true,
        fillColor: Colors.black26,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor)),
      ),
    ),
    const SizedBox(height: 35),
    
    // BOTÃO ACESSAR
    SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _carregando ? null : _fazerLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _carregando
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : const Text("ACESSAR PAINEL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
    ),
  ],
),  
        ),
      ),
    );
  }
}