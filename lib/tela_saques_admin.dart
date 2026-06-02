import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TelaSaquesAdmin extends StatefulWidget {
  const TelaSaquesAdmin({super.key});

  @override
  State<TelaSaquesAdmin> createState() => _TelaSaquesAdminState();
}

class _TelaSaquesAdminState extends State<TelaSaquesAdmin> {
  static const primaryColor = Color(0xFF00E676);
  static const sidebarColor = Color(0xFF1A1A1A);

  int _limiteHistorico = 50;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Gestão de Saques",
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Monitore as solicitações pendentes e consulte o histórico de pagamentos.",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 20),
          
          // ✨ AS ABAS DE NAVEGAÇÃO
          TabBar(
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.white38,
            dividerColor: Colors.white10,
            tabs: const [
              Tab(icon: Icon(Icons.pending_actions_rounded), text: "PENDENTES"),
              Tab(icon: Icon(Icons.history_rounded), text: "HISTÓRICO"),
            ],
          ),
          const SizedBox(height: 20),
          
          // CONTEÚDO DAS ABAS
          Expanded(
            child: TabBarView(
              children: [
                _buildListaPendentes(),
                _buildListaHistorico(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ABA 1: SAQUES PENDENTES (Ação)
  // ==========================================
  Widget _buildListaPendentes() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('saques')
          .where('status', isEqualTo: 'pendente')
          .orderBy('dataSolicitacao', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryColor));

        final saquesDocs = snapshot.data?.docs ?? [];
        if (saquesDocs.isEmpty) return _buildEmptyState("Nenhum saque pendente por aqui.", Icons.check_circle_rounded);

        return ListView.builder(
          itemCount: saquesDocs.length,
          itemBuilder: (context, index) {
            final dados = saquesDocs[index].data() as Map<String, dynamic>;
            return _buildCardPendente(saquesDocs[index].id, dados);
          },
        );
      },
    );
  }

// ==========================================
  // ABA 2: HISTÓRICO DE SAQUES (Auditoria Paginada Corrigida)
  // ==========================================
  Widget _buildListaHistorico() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('saques')
          .where('status', whereIn: ['pago', 'recusado'])
          .orderBy('dataProcessamento', descending: true)
          .limit(_limiteHistorico)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryColor));

        final saquesDocs = snapshot.data?.docs ?? [];
        
        // 🛑 TRAVA DE SEGURANÇA: Se estiver vazio, mostra o aviso e para aqui! 
        // Evita a tela vermelha de tentar renderizar o botão sem ter nenhum dado.
        if (saquesDocs.isEmpty) {
          return _buildEmptyState("O histórico de pagamentos está vazio.", Icons.history_toggle_off_rounded);
        }

        return ListView.builder(
          itemCount: saquesDocs.length + 1, 
          itemBuilder: (context, index) {
            
            // Se chegou no final dos documentos, decide se mostra o botão ou o fim do histórico
            if (index == saquesDocs.length) {
              if (saquesDocs.length >= _limiteHistorico) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _limiteHistorico += 50;
                        });
                      },
                      icon: const Icon(Icons.expand_more_rounded, color: primaryColor),
                      label: const Text("CARREGAR MAIS", style: TextStyle(color: primaryColor)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text("Fim do histórico.", style: TextStyle(color: Colors.white24, fontSize: 12)),
                  ),
                );
              }
            }

            final dados = saquesDocs[index].data() as Map<String, dynamic>;
            return _buildCardHistorico(dados);
          },
        );
      },
    );
  }

  // --- CARD: PENDENTE (Com Botões) ---
  Widget _buildCardPendente(String idSaque, Map<String, dynamic> dados) {
    final double valor = (dados['valor'] ?? 0).toDouble();
    final String nomeGoleiro = dados['nomeGoleiro'] ?? 'Goleiro';
    final String chavePix = dados['chavePix'] ?? 'N/A';
    final String tipoPix = (dados['tipoPix'] ?? '').toString().toLowerCase();
    
    final data = dados['dataSolicitacao'] != null ? (dados['dataSolicitacao'] as Timestamp).toDate() : DateTime.now();
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(data);

    return _buildBaseCard(
      dados: dados,
      nomeGoleiro: nomeGoleiro,
      dataTexto: "Pedido em: $dataFormatada",
      tipoPix: tipoPix,
      chavePix: chavePix,
      valor: valor,
      acaoFinal: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => _processarVereditoSaque(idSaque, dados, false),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text("RECUSAR"),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _processarVereditoSaque(idSaque, dados, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
            child: const Text("APROVAR", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- CARD: HISTÓRICO (Com Badges e Data Final) ---
  // --- CARD: HISTÓRICO (Com Badges e as Duas Datas) ---
  Widget _buildCardHistorico(Map<String, dynamic> dados) {
    final double valor = (dados['valor'] ?? 0).toDouble();
    final String nomeGoleiro = dados['nomeGoleiro'] ?? 'Goleiro';
    final String chavePix = dados['chavePix'] ?? 'N/A';
    final String tipoPix = (dados['tipoPix'] ?? '').toString().toLowerCase();
    final String status = dados['status'] ?? '';
    
    // 📅 Data de Solicitação (Quando ele pediu)
    String dataSolicitada = "--/--";
    if (dados['dataSolicitacao'] != null) {
      final dPed = (dados['dataSolicitacao'] as Timestamp).toDate();
      dataSolicitada = DateFormat('dd/MM/yyyy HH:mm').format(dPed);
    }

    // 📅 Data de Processamento (Quando você pagou/recusou)
    String dataProcessada = "--/--";
    if (dados['dataProcessamento'] != null) {
      final dProc = (dados['dataProcessamento'] as Timestamp).toDate();
      dataProcessada = DateFormat('dd/MM/yyyy HH:mm').format(dProc);
    }

    final isPago = status == 'pago';

    return _buildBaseCard(
      dados: dados,
      nomeGoleiro: nomeGoleiro,
      // ✨ Mostra as duas datas empilhadas no histórico
      dataTexto: "Solicitado: $dataSolicitada\n${isPago ? 'Pago' : 'Recusado'}: $dataProcessada",
      tipoPix: tipoPix,
      chavePix: chavePix,
      valor: valor,
      isHistorico: true,
      acaoFinal: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isPago ? primaryColor.withAlpha(20) : Colors.redAccent.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isPago ? primaryColor.withAlpha(60) : Colors.redAccent.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isPago ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 14, color: isPago ? primaryColor : Colors.redAccent),
            const SizedBox(width: 6),
            Text(
              isPago ? "PAGO" : "RECUSADO", 
              style: TextStyle(color: isPago ? primaryColor : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }

  // --- ESQUELETO DO CARD ATUALIZADO (Para aceitar quebra de linha de datas) ---
  Widget _buildBaseCard({
    required Map<String, dynamic> dados, required String nomeGoleiro, required String dataTexto,
    required String tipoPix, required String chavePix, required double valor, required Widget acaoFinal,
    bool isHistorico = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sidebarColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Opacity(
        opacity: isHistorico ? 0.65 : 1.0, // Um pouquinho mais visível para ler as duas datas
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nomeGoleiro, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // ✨ Alinha no topo caso tenha 2 linhas de data
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.access_time, color: Colors.white38, size: 14),
                      ),
                      const SizedBox(width: 6),
                      // ✨ Permitindo que o texto tenha duas linhas sem cortar
                      Expanded(
                        child: Text(
                          dataTexto, 
                          style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.3)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(_getIconePix(tipoPix), color: Colors.cyanAccent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("PIX: ${tipoPix.toUpperCase()}", style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(chavePix, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (!isHistorico)
                      IconButton(
                        onPressed: () => _copiarPixParaAreaTransferencia(chavePix),
                        tooltip: "Copiar Chave",
                        icon: const Icon(Icons.copy_rounded, color: primaryColor, size: 18),
                        style: IconButton.styleFrom(backgroundColor: primaryColor.withAlpha(20)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 25),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("R\$ ${valor.toStringAsFixed(2)}", style: const TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  acaoFinal,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copiarPixParaAreaTransferencia(String chave) {
    Clipboard.setData(ClipboardData(text: chave));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chave PIX copiada!"), backgroundColor: Colors.cyan));
  }

  Future<void> _processarVereditoSaque(String idSaque, Map<String, dynamic> dados, bool aprovar) async {
    final String idGoleiro = dados['idGoleiro'] ?? '';
    final String idExtrato = dados['idExtrato'] ?? '';
    final double valor = (dados['valor'] ?? 0).toDouble();
    final String statusFinal = aprovar ? 'pago' : 'recusado';

    bool? confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sidebarColor,
        title: Text(aprovar ? "Confirmar Pagamento" : "Recusar Solicitação", style: const TextStyle(color: Colors.white)),
        content: Text(aprovar ? "Você confirma que efetuou o PIX com sucesso?" : "Deseja recusar? O valor será estornado ao goleiro."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: aprovar ? primaryColor : Colors.redAccent, foregroundColor: aprovar ? Colors.black : Colors.white),
            child: const Text("CONFIRMAR"),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator(color: primaryColor)));

    try {
      final db = FirebaseFirestore.instance;
      WriteBatch batch = db.batch();

      DocumentReference saqueRef = db.collection('saques').doc(idSaque);
      batch.update(saqueRef, {'status': statusFinal, 'dataProcessamento': FieldValue.serverTimestamp()});

      if (idGoleiro.isNotEmpty) {
        if (idExtrato.isNotEmpty) {
          batch.update(db.collection('usuarios').doc(idGoleiro).collection('extrato').doc(idExtrato), {'status': statusFinal, 'dataAtualizacao': FieldValue.serverTimestamp()});
        }
        if (!aprovar) {
          batch.update(db.collection('usuarios').doc(idGoleiro), {'saldo': FieldValue.increment(valor)});
        } else {
          batch.update(db.collection('usuarios').doc(idGoleiro), {'totalGanhos': FieldValue.increment(valor)});
        }
      }

      await batch.commit();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.redAccent));
    }
  }

  IconData _getIconePix(String tipo) {
    switch (tipo) {
      case 'cpf': case 'cnpj': return Icons.badge_outlined;
      case 'telefone': return Icons.phone_android_rounded;
      case 'email': return Icons.alternate_email_rounded;
      case 'aleatoria': return Icons.vpn_key_outlined;
      default: return Icons.pix_rounded;
    }
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white10, size: 80),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.white24, fontSize: 14)),
        ],
      ),
    );
  }
}