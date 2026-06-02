import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TelaNotificacoesAdmin extends StatefulWidget {
  const TelaNotificacoesAdmin({super.key});

  @override
  State<TelaNotificacoesAdmin> createState() => _TelaNotificacoesAdminState();
}

class _TelaNotificacoesAdminState extends State<TelaNotificacoesAdmin> {
  static const primaryColor = Color(0xFF00E676);
  static const sidebarColor = Color(0xFF1A1A1A);

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _mensagemController = TextEditingController();
  
  String _publicoAlvo = "todos"; // 'todos', 'goleiro', 'contratante'
  bool _enviando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _mensagemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Central de Notificações",
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const Text(
          "Engaje sua base enviando mensagens em massa para os usuários.",
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
        const SizedBox(height: 30),

        // 1. ÁREA DE COMPOSIÇÃO DA MENSAGEM
        _buildCompositor(),

        const SizedBox(height: 30),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 20),

        const Text(
          "Histórico de Disparos",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),

        // 2. LISTA DE HISTÓRICO
        Expanded(child: _buildHistorico()),
      ],
    );
  }

  // --- WIDGET: O MEGAFONE (Formulário) ---
  Widget _buildCompositor() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sidebarColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded, color: primaryColor, size: 24),
              const SizedBox(width: 10),
              const Text("Nova Mensagem", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          
          // Campo de Título
          TextField(
            controller: _tituloController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Título da Notificação",
              labelStyle: const TextStyle(color: Colors.white54),
              hintText: "Ex: Fim de semana chegando! ⚽",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 15),

          // Campo de Mensagem
          TextField(
            controller: _mensagemController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Mensagem",
              labelStyle: const TextStyle(color: Colors.white54),
              hintText: "Escreva o texto que vai aparecer no celular dos usuários...",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),

          // Seleção de Público Alvo e Botão de Envio
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("Enviar para: ", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(width: 10),
                  _buildChipAlvo("Todos", "todos"),
                  const SizedBox(width: 8),
                  _buildChipAlvo("Só Goleiros", "goleiro"),
                  const SizedBox(width: 8),
                  _buildChipAlvo("Só Contratantes", "contratante"),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _enviando ? null : _dispararNotificacao,
                icon: _enviando 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 18),
                label: Text(_enviando ? "Enviando..." : "DISPARAR"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipAlvo(String label, String valor) {
    final selecionado = _publicoAlvo == valor;
    return ChoiceChip(
      label: Text(label),
      selected: selecionado,
      selectedColor: primaryColor.withAlpha(40),
      backgroundColor: Colors.black26,
      labelStyle: TextStyle(color: selecionado ? primaryColor : Colors.white54, fontWeight: selecionado ? FontWeight.bold : FontWeight.normal),
      side: BorderSide(color: selecionado ? primaryColor : Colors.transparent),
      onSelected: (bool selected) {
        if (selected) setState(() => _publicoAlvo = valor);
      },
    );
  }

  // --- WIDGET: O HISTÓRICO DE ENVIOS ---
  Widget _buildHistorico() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notificacoes')
          .orderBy('dataEnvio', descending: true)
          .limit(30) // Mostra as últimas 30
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Erro ao carregar histórico.", style: TextStyle(color: Colors.redAccent)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryColor));

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text("Nenhuma notificação enviada ainda.", style: TextStyle(color: Colors.white24)));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final dados = docs[index].data() as Map<String, dynamic>;
            final titulo = dados['titulo'] ?? 'Sem Título';
            final mensagem = dados['mensagem'] ?? '';
            final alvo = dados['publicoAlvo'] ?? 'todos';
            
            String dataFormatada = "--/--";
            if (dados['dataEnvio'] != null) {
              final data = (dados['dataEnvio'] as Timestamp).toDate();
              dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(data);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(10)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                    child: Icon(
                      alvo == 'todos' ? Icons.groups_rounded : (alvo == 'goleiro' ? Icons.sports_handball_rounded : Icons.sports_soccer_rounded),
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(mensagem, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                        child: Text(alvo.toUpperCase(), style: const TextStyle(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      Text(dataFormatada, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- LÓGICA DE SALVAMENTO ---
  Future<void> _dispararNotificacao() async {
    final titulo = _tituloController.text.trim();
    final mensagem = _mensagemController.text.trim();

    if (titulo.isEmpty || mensagem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha título e mensagem!"), backgroundColor: Colors.orangeAccent));
      return;
    }

    setState(() => _enviando = true);

    try {
      await FirebaseFirestore.instance.collection('notificacoes').add({
        'titulo': titulo,
        'mensagem': mensagem,
        'publicoAlvo': _publicoAlvo,
        'dataEnvio': FieldValue.serverTimestamp(),
        'status': 'enviado',
      });

      _tituloController.clear();
      _mensagemController.clear();
      setState(() => _publicoAlvo = 'todos');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notificação disparada com sucesso!"), backgroundColor: primaryColor));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }
}