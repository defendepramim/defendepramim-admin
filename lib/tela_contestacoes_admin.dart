import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaContestacoesAdmin extends StatefulWidget {
  const TelaContestacoesAdmin({super.key});

  @override
  State<TelaContestacoesAdmin> createState() => _TelaContestacoesAdminState();
}

class _TelaContestacoesAdminState extends State<TelaContestacoesAdmin> {
  static const primaryColor = Color(0xFF00E676);
  static const sidebarColor = Color(0xFF1A1A1A);
  static const bgColor = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tribunal de Disputas",
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const Text(
          "Monitore o conflito e decida o destino do pagamento baseado nas provas.",
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
        const SizedBox(height: 30),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jogos')
                .where('status', isEqualTo: 'contestado')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryColor));
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final jogo = docs[index].data() as Map<String, dynamic>;
                  final idJogo = docs[index].id;
                  return _buildCardContestacao(idJogo, jogo);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardContestacao(String id, Map<String, dynamic> jogo) {
    final Timestamp? dataAbertura = jogo['contestacao']?['data'];
    final String local = jogo['local'] ?? 'Arena';
    final String dataJogo = jogo['dataExibicao'] ?? '--/--';
    final String horaJogo = jogo['horaExibicao'] ?? '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: sidebarColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Column(
        children: [
          // 1. CABEÇALHO DO JOGO (Onde e Quando)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sports_soccer, color: primaryColor, size: 18),
                const SizedBox(width: 10),
                Text(
                  "$local • $dataJogo às $horaJogo",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                _buildRelogio(dataAbertura), // Contador de tempo
              ],
            ),
          ),

          // 2. CORPO DA DISPUTA (CONTRATANTE VS GOLEIRO)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LADO DO CONTRATANTE (QUEM RECLAMOU)
                Expanded(
                  child: _buildBoxDepoimento(
                    titulo: "QUEIXA DO CONTRATANTE",
                    nome: jogo['nomeContratante'] ?? "Contratante",
                    mensagem: jogo['contestacao']?['motivo'] ?? "Sem detalhes informados.",
                    cor: Colors.redAccent,
                  ),
                ),
                
                const SizedBox(width: 20),
                const Center(child: Text("VS", style: TextStyle(color: Colors.white10, fontWeight: FontWeight.w900))),
                const SizedBox(width: 20),

                // LADO DO GOLEIRO (DEFESA)
                // LADO DO GOLEIRO (DEFESA CORRIGIDA)
                Expanded(
                  child: _buildBoxDepoimento(
                    titulo: "DEFESA DO GOLEIRO",
                    nome: jogo['nomeGoleiro'] ?? "Goleiro",
                    // ✨ ALTERADO AQUI: 'respostaGoleiro' para bater com o Firebase
                    mensagem: jogo['contestacao']?['respostaGoleiro'] ?? "Aguardando resposta do goleiro...",
                    cor: primaryColor,
                    isGoleiro: true,
                    // Deixa a verificação da foto como opcional
                    urlFoto: jogo['contestacao']?['fotoProvaUrl'], 
                  ),
                ),
              ],
            ),
          ),

          // 3. BARRA DE AÇÃO FINANCEIRA
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "VALOR RETIDO: R\$ ${jogo['valor']?.toStringAsFixed(2) ?? '0.00'}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => _finalizarDisputa(id, 'reembolsado'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                      child: const Text("ESTORNAR CONTRATANTE"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _finalizarDisputa(id, 'pago_forcado'),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
                      child: const Text("PAGAR GOLEIRO", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxDepoimento({required String titulo, required String nome, required String mensagem, required Color cor, bool isGoleiro = false, String? urlFoto}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mensagem, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              if (urlFoto != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(urlFoto, height: 100, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRelogio(Timestamp? inicio) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        if (inicio == null) return const SizedBox();
        final diff = DateTime.now().difference(inicio.toDate());
        final horas = diff.inHours;
        final minutos = diff.inMinutes.remainder(60);
        final segundos = diff.inSeconds.remainder(60);
        
        Color corTempo = horas >= 24 ? Colors.redAccent : (horas >= 12 ? Colors.orangeAccent : Colors.white38);

        return Row(
          children: [
            Icon(Icons.timer_outlined, color: corTempo, size: 14),
            const SizedBox(width: 6),
            Text(
              "${horas}h ${minutos}m ${segundos}s",
              style: TextStyle(color: corTempo, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        );
      },
    );
  }

Future<void> _finalizarDisputa(String idJogo, String novoStatus) async {
    // 1. Diálogo de confirmação para evitar cliques acidentais
    bool? confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sidebarColor,
        title: const Text("Confirmar Veredito", style: TextStyle(color: Colors.white)),
        content: Text("Tem certeza que deseja aplicar o veredito de ${novoStatus.toUpperCase()} para esta disputa?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: novoStatus == 'pago_forcado' ? primaryColor : Colors.redAccent,
              foregroundColor: novoStatus == 'pago_forcado' ? Colors.black : Colors.white,
            ),
            child: const Text("CONFIRMAR VEREDITO"),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Coloca um loading na tela enquanto salva no Firebase
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      final db = FirebaseFirestore.instance;
      
      // Buscamos o jogo para saber quem são os IDs e o VALOR
      final jogoDoc = await db.collection('jogos').doc(idJogo).get();
      if (!jogoDoc.exists) throw "Jogo não encontrado.";
      final dadosJogo = jogoDoc.data() as Map<String, dynamic>;
      
      final String idContratante = dadosJogo['idContratante'] ?? '';
      final String idGoleiro = dadosJogo['idGoleiro'] ?? '';
      
      // ✨ PEGANDO O VALOR DO JOGO
      final num valorDoJogo = dadosJogo['valor'] ?? 0;

      // Criamos um WriteBatch para atualizar tudo em uma única pancada atômica
      WriteBatch batch = db.batch();

      // 🛑 PASSO 1: Atualizar o Jogo
      DocumentReference jogoRef = db.collection('jogos').doc(idJogo);
      batch.update(jogoRef, {
        'status': novoStatus,
        'contestacao.statusMediacao': 'concluido',
        'dataJulgamento': FieldValue.serverTimestamp(),
        'julgadoPor': FirebaseAuth.instance.currentUser?.email ?? 'admin_sistema',
      });

      // 🛑 PASSO 2: Ajustar estatísticas e SALDO do Contratante
      if (idContratante.isNotEmpty) {
        DocumentReference contratanteRef = db.collection('usuarios').doc(idContratante);
        final contratanteDoc = await contratanteRef.get();
        final int contestadosContratante = (contratanteDoc.data() as Map<String, dynamic>?)?['jogosContestados'] ?? 0;
        
        batch.update(contratanteRef, {
          // Só subtrai se for maior que zero, evitando números negativos
          if (contestadosContratante > 0) 'jogosContestados': FieldValue.increment(-1),
          if (novoStatus == 'reembolsado') 'saldo': FieldValue.increment(valorDoJogo),
        });

        if (novoStatus == 'reembolsado') {
          DocumentReference extratoRef = contratanteRef.collection('extrato').doc();
          batch.set(extratoRef, {
            'tipo': 'credito',
            'valor': valorDoJogo,
            'descricao': 'Veredito Admin: Reembolso de Disputa',
            'data': FieldValue.serverTimestamp(),
            'idJogo': idJogo,
          });
        }
      }

      // 🛑 PASSO 3: Ajustar estatísticas e SALDO do Goleiro
      if (idGoleiro.isNotEmpty) {
        DocumentReference goleiroRef = db.collection('usuarios').doc(idGoleiro);
        final goleiroDoc = await goleiroRef.get();
        final int contestadosGoleiro = (goleiroDoc.data() as Map<String, dynamic>?)?['jogosContestados'] ?? 0;
        
        batch.update(goleiroRef, {
          // Só subtrai se for maior que zero
          if (contestadosGoleiro > 0) 'jogosContestados': FieldValue.increment(-1),
          if (novoStatus == 'pago_forcado') 'atuadas': FieldValue.increment(1),
          if (novoStatus == 'pago_forcado') 'saldo': FieldValue.increment(valorDoJogo),
        });

        if (novoStatus == 'pago_forcado') {
          DocumentReference extratoRef = goleiroRef.collection('extrato').doc();
          batch.set(extratoRef, {
            'tipo': 'credito',
            'valor': valorDoJogo,
            'descricao': 'Veredito Admin: Ganho de Disputa',
            'data': FieldValue.serverTimestamp(),
            'idJogo': idJogo,
          });
        }
      }
      // Executa o lote no Firebase
      await batch.commit();

      // Fecha o modal de loading
      if (mounted) Navigator.pop(context);
      
      _mostrarAviso("Veredito aplicado e saldo atualizado com sucesso!");
    } catch (e) {
      // Fecha o modal de loading se der erro
      if (mounted) Navigator.pop(context);
      _mostrarAviso("Erro ao aplicar veredito: $e");
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gavel_rounded, color: Colors.white10, size: 80),
          SizedBox(height: 16),
          Text("Nenhuma contestação pendente.", style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  void _mostrarAviso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: primaryColor));
  }
}