import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TelaQuadrasAdmin extends StatefulWidget {
  const TelaQuadrasAdmin({super.key});

  @override
  State<TelaQuadrasAdmin> createState() => _TelaQuadrasAdminState();
}

class _TelaQuadrasAdminState extends State<TelaQuadrasAdmin> {
  static const primaryColor = Color(0xFF00E676);
  static const sidebarColor = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 🟢 Duas abas baseadas no seu layout original
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABEÇALHO REATIVO INTEGRADO
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Gerenciamento de Quadras",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(
                "Modere as sugestões de contratantes ou altere os dados de complexos ativos no mapa.",
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 🎛️ CONTROLE DE ABAS (TABS) DESIGN PREMIUM
          const TabBar(
            labelColor: primaryColor,
            unselectedLabelColor: Colors.white54,
            indicatorColor: primaryColor,
            dividerColor: Colors.white10,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(icon: Icon(Icons.pending_actions_rounded, size: 20), text: "AGUARDANDO APROVAÇÃO"),
              Tab(icon: Icon(Icons.playlist_add_check_rounded, size: 20), text: "HISTÓRICO / ATIVAS"),
            ],
          ),
          const SizedBox(height: 25),

          // 👁️ CORPO DO STREAM DAS ABAS
          Expanded(
            child: TabBarView(
              children: [
                // ---------------- 1ª ABA: FILA DE ESPERA (aprovada == false) ----------------
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('quadras')
                      .where('aprovada', isEqualTo: false)
                      .orderBy('criadaEm', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) => _construirListaQuadras(snapshot, exibirBotoesAcao: true),
                ),

                // ---------------- 2ª ABA: HISTÓRICO NO MAPA (aprovada == true) ----------------
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('quadras')
                      .where('aprovada', isEqualTo: true)
                      .orderBy('criadaEm', descending: true) // As mais recentes ativas no topo
                      .snapshots(),
                  builder: (context, snapshot) => _construirListaQuadras(snapshot, exibirBotoesAcao: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MOTOR DE CONSTRUÇÃO DE LISTA ---
  Widget _construirListaQuadras(AsyncSnapshot<QuerySnapshot> snapshot, {required bool exibirBotoesAcao}) {
    if (snapshot.hasError) {
      return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }

    final docs = snapshot.data?.docs ?? [];

    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, color: Colors.white.withAlpha(20), size: 64),
            const SizedBox(height: 16),
            Text(
              exibirBotoesAcao ? "Fila limpa! Nenhuma quadra pendente." : "Nenhuma quadra ativa listada no mapa.",
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final idQuadra = docs[index].id;
        final dados = docs[index].data() as Map<String, dynamic>;
        return _buildCardItem(idQuadra, dados, exibirBotoesAcao);
      },
    );
  }

  // --- WIDGET UNIFICADO: CARDS DE QUADRA COM CONTROLE DE HISTÓRICO ---
  Widget _buildCardItem(String idQuadra, Map<String, dynamic> dados, bool exibirBotoesAcao) {
    final String nome = dados['nome'] ?? 'Sem nome informado';
    final String endereco = dados['endereco'] ?? 'Sem endereço informado';
    final String obs = dados['observacoes'] ?? '';
    
    String dataSugerida = "--/--";
    if (dados['criadaEm'] != null) {
      final dt = (dados['criadaEm'] as Timestamp).toDate();
      dataSugerida = DateFormat('dd/MM/yyyy HH:mm').format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sidebarColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Row(
        children: [
          // ÍCONE DE MAPA INDICATIVO DIRECIONADO
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: exibirBotoesAcao ? Colors.orangeAccent.withAlpha(15) : primaryColor.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.map_rounded, 
              color: exibirBotoesAcao ? Colors.orangeAccent : primaryColor, 
              size: 28,
            ),
          ),
          const SizedBox(width: 20),

          // BLOCO DE TEXTOS (INFORMAÇÕES COMPLETAS)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    // ✏️ EDICÃO RÁPIDA (Funciona tanto na fila quanto no Histórico!)
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: primaryColor, size: 20),
                      tooltip: "Corrigir Dados",
                      onPressed: () => _abrirModalEdicaoRapida(idQuadra, nome, endereco, obs),
                      style: IconButton.styleFrom(backgroundColor: primaryColor.withAlpha(15), padding: EdgeInsets.zero),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  endereco,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (obs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "Obs do Usuário: $obs",
                      style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  exibirBotoesAcao ? "Sugerida em: $dataSugerida" : "Ativa no sistema • Registrada em: $dataSugerida",
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                )
              ],
            ),
          ),
          const SizedBox(width: 30),

          // SISTEMA DE BOTÕES CONTEXTUAL (Ações vs Histórico)
          exibirBotoesAcao 
              ? Row(
                  children: [
                    // 🔴 RECUSAR
                    ElevatedButton.icon(
                      onPressed: () => _recusarQuadra(idQuadra),
                      icon: const Icon(Icons.delete_forever_rounded, size: 16),
                      label: const Text("RECUSAR"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withAlpha(30),
                        foregroundColor: Colors.redAccent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.redAccent, width: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 🟢 APROVAR
                    ElevatedButton.icon(
                      onPressed: () => _aprovarQuadra(idQuadra),
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text("APROVAR E LIBERAR"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withAlpha(50)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: primaryColor, size: 14),
                      SizedBox(width: 6),
                      Text("NO MAPA", style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  // --- REGRAS DE NEGÓCIO UNIFICADAS ---
  Future<void> _aprovarQuadra(String idQuadra) async {
    try {
      await FirebaseFirestore.instance.collection('quadras').doc(idQuadra).update({
        'aprovada': true,
        'aprovadaEm': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Quadra aprovada com sucesso! Já está visível no mapa."), backgroundColor: primaryColor),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao aprovar: $e")));
    }
  }

  Future<void> _recusarQuadra(String idQuadra) async {
    try {
      await FirebaseFirestore.instance.collection('quadras').doc(idQuadra).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sugestão recusada e excluída permanentemente."), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao deletar: $e")));
    }
  }

  // --- MODAL DE EDIÇÃO INTEGRAL ---
  void _abrirModalEdicaoRapida(String idQuadra, String nomeAtual, String enderecoAtual, String obs) {
    final TextEditingController nomeController = TextEditingController(text: nomeAtual);
    final TextEditingController enderecoController = TextEditingController(text: enderecoAtual);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sidebarColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
        title: const Text("Correção de Cadastro", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Nome do Complexo/Quadra",
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: enderecoController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Endereço Completo",
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
            onPressed: () async {
              if (nomeController.text.trim().isEmpty || enderecoController.text.trim().isEmpty) return;
              
              Navigator.pop(ctx);
              
              await FirebaseFirestore.instance.collection('quadras').doc(idQuadra).update({
                'nome': nomeController.text.trim(),
                'endereco': enderecoController.text.trim(),
              });
            },
            child: const Text("SALVAR CORREÇÃO", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}