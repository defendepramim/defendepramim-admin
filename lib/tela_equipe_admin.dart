import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaEquipeAdmin extends StatefulWidget {
  const TelaEquipeAdmin({super.key});

  @override
  State<TelaEquipeAdmin> createState() => _TelaEquipeAdminState();
}

class _TelaEquipeAdminState extends State<TelaEquipeAdmin> {
  static const primaryColor = Color(0xFF00E676);
  static const sidebarColor = Color(0xFF1A1A1A);
  
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // 🔥 GRAVA NA FILA PARA A CLOUD FUNCTION CRIAR O ACESSO
  Future<void> _solicitarCriacaoAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    final emailAlvo = _emailController.text.trim().toLowerCase();
    final nomeAlvo = _nomeController.text.trim();
    final senhaAlva = _senhaController.text.trim();

    try {
      // Cria um documento na fila. O backend vai ler isso e criar o Admin de verdade
      await FirebaseFirestore.instance.collection('solicitacoes_admin').add({
        'nome': nomeAlvo,
        'email': emailAlvo,
        'senha': senhaAlva,
        'solicitadoEm': FieldValue.serverTimestamp(),
        'status': 'pendente',
      });

      _exibirSnackBar("Solicitação enviada! O servidor está criando o acesso...", primaryColor);
      
      _nomeController.clear();
      _emailController.clear();
      _senhaController.clear();
    } catch (e) {
      _exibirSnackBar("Erro ao processar criação: $e", Colors.redAccent);
    } finally {
      setState(() => _salvando = false);
    }
  }

  Future<void> _revogarAcessoAdmin(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({'isAdmin': false});
      await FirebaseFirestore.instance.collection('administradores').doc(uid).delete();
      _exibirSnackBar("Acesso de administrador revogado.", Colors.redAccent);
    } catch (e) {
      _exibirSnackBar("Erro ao revogar: $e", Colors.redAccent);
    }
  }

  void _exibirSnackBar(String mensagem, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: cor));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Gerenciar Equipe Admin", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const Text("Crie perfis administrativos exclusivos para o painel com e-mail e senha cravados.", style: TextStyle(color: Colors.white38, fontSize: 14)),
        const SizedBox(height: 30),

        // 📝 FORMULÁRIO DE CRIAÇÃO COMPLETO
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: sidebarColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: primaryColor, size: 20),
                    SizedBox(width: 10),
                    Text("Cadastrar Novo Perfil Administrativo", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nomeController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _decorarInput("Nome do Admin", Icons.badge_outlined),
                        validator: (val) => val == null || val.trim().isEmpty ? "Digite o nome" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _decorarInput("E-mail do Admin", Icons.mail_outline_rounded),
                        validator: (val) => val == null || !val.contains("@") ? "E-mail inválido" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _senhaController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _decorarInput("Senha Inicial", Icons.lock_open_rounded),
                        validator: (val) => val == null || val.trim().length < 6 ? "Mínimo 6 caracteres" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor, foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          onPressed: _salvando ? null : _solicitarCriacaoAdmin,
                          icon: _salvando 
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Icon(Icons.add_moderator_rounded, size: 18),
                          label: const Text("CRIAR ADMIN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 35),

        const Text("Administradores Ativos no Painel", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),

        // LISTA REATIVA DE ADMINS
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('administradores').orderBy('criadoEm', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryColor));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text("Nenhum administrador listado.", style: TextStyle(color: Colors.white24)));
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final adminData = docs[index].data() as Map<String, dynamic>;
                  final idAdmin = docs[index].id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: sidebarColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withAlpha(10))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(backgroundColor: primaryColor.withAlpha(20), child: const Icon(Icons.admin_panel_settings_rounded, color: primaryColor, size: 20)),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(adminData['nome'] ?? 'Sem nome', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(adminData['email'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.no_accounts_rounded, color: Colors.redAccent, size: 22),
                          onPressed: () => _revogarAcessoAdmin(idAdmin),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  InputDecoration _decorarInput(String label, IconData icone) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      prefixIcon: Icon(icone, color: primaryColor, size: 18),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}