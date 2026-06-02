import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TelaHomeAdmin extends StatelessWidget {
  const TelaHomeAdmin({super.key});

  static const primaryColor = Color(0xFF00E676);
  static const sidebarColor = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final String hoje = DateFormat('dd/MM').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Visão Geral",
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        
        // ✨ O NOVO BLOCO DE 6 CARDS
        _buildCardsEstatisticas(hoje),

        const SizedBox(height: 30),
        
        const Text(
          "Monitoramento de Partidas (Hoje)",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // --- TABELA DE MONITORAMENTO ---
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: sidebarColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(13)),
            ),
            child: _buildGridJogosHoje(hoje),
          ),
        ),
      ],
    );
  }

  // --- O CÉREBRO DOS CARDS (Lê os dados 1x e calcula 4 cards) ---
  Widget _buildCardsEstatisticas(String dataHoje) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jogos').where('dataExibicao', isEqualTo: dataHoje).snapshots(),
      builder: (context, snapshot) {
        int totalHoje = 0;
        int andamento = 0;
        int finalizados = 0;
        int cancelados = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          totalHoje = docs.length;
          final agora = DateTime.now();

          for (var doc in docs) {
            final d = doc.data() as Map<String, dynamic>;
            final status = (d['status'] ?? '').toString().toLowerCase();

            if (status == 'finalizado') finalizados++;
            if (status == 'cancelado') cancelados++;
            
            // Lógica inteligente para achar os jogos ao vivo
            if (status == 'fechado') {
              final Timestamp? tInicio = d['dataHora'];
              final Timestamp? tFim = d['dataHoraFim'];
              if (tInicio != null && tFim != null) {
                if (agora.isAfter(tInicio.toDate()) && agora.isBefore(tFim.toDate())) {
                  andamento++;
                }
              }
            }
          }
        }

        return Column(
          children: [
            // LINHA 1
            Row(
              children: [
                _cardVisual("JOGOS HOJE", snapshot.hasData ? totalHoje.toString() : "...", Icons.sports_soccer, primaryColor),
                const SizedBox(width: 16),
                _streamCardResumo("DISPUTAS ABERTAS", FirebaseFirestore.instance.collection('jogos').where('status', isEqualTo: 'contestado').snapshots(), Icons.gavel_rounded, Colors.redAccent),
                const SizedBox(width: 16),
                _streamCardResumo("SAQUES PENDENTES", FirebaseFirestore.instance.collection('saques').where('status', isEqualTo: 'pendente').snapshots(), Icons.account_balance_wallet, Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 16),
            // LINHA 2 (Os novos!)
            Row(
              children: [
                _cardVisual("EM ANDAMENTO", snapshot.hasData ? andamento.toString() : "...", Icons.play_circle_fill_rounded, Colors.orange),
                const SizedBox(width: 16),
                _cardVisual("FINALIZADOS", snapshot.hasData ? finalizados.toString() : "...", Icons.check_circle_rounded, primaryColor),
                const SizedBox(width: 16),
                _cardVisual("CANCELADOS", snapshot.hasData ? cancelados.toString() : "...", Icons.cancel_rounded, Colors.red),
              ],
            ),
          ],
        );
      },
    );
  }

  // Card para os streams isolados (Disputas e Saques)
  Widget _streamCardResumo(String titulo, Stream<QuerySnapshot> stream, IconData icone, Color cor) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final valor = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
        return _cardVisual(titulo, valor, icone, cor);
      },
    );
  }

  // O desenho padrão do card (Diminuído para caber 6 e ficar elegante)
  Widget _cardVisual(String titulo, String valor, IconData icone, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16), // Era 24
        decoration: BoxDecoration(
          color: sidebarColor,
          borderRadius: BorderRadius.circular(12), // Era 16
          border: Border.all(color: Colors.white.withAlpha(13)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                Icon(icone, color: cor.withAlpha(200), size: 18),
              ],
            ),
            const SizedBox(height: 12), // Era 16
            Text(valor, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)), // Era 32
          ],
        ),
      ),
    );
  }

  // --- TABELA INTACTA ---
  Widget _buildGridJogosHoje(String dataHoje) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jogos')
          .where('dataExibicao', isEqualTo: dataHoje)
          .orderBy('horaExibicao', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Erro ao carregar jogos: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryColor));

        final jogos = snapshot.data?.docs ?? [];
        if (jogos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, color: Colors.white.withAlpha(20), size: 48),
                const SizedBox(height: 16),
                const Text("Nenhum jogo agendado para hoje.", style: TextStyle(color: Colors.white24, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView(
          children: [
            DataTable(
              headingRowHeight: 40,
              horizontalMargin: 0,
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text("HORA", style: TextStyle(color: Colors.white38, fontSize: 11))),
                DataColumn(label: Text("LOCAL", style: TextStyle(color: Colors.white38, fontSize: 11))),
                DataColumn(label: Text("CONTRATANTE", style: TextStyle(color: Colors.white38, fontSize: 11))),
                DataColumn(label: Text("GOLEIRO", style: TextStyle(color: Colors.white38, fontSize: 11))),
                DataColumn(label: Text("STATUS", style: TextStyle(color: Colors.white38, fontSize: 11))),
                DataColumn(label: Text("OBS", style: TextStyle(color: Colors.white38, fontSize: 11))),
              ],
              rows: jogos.map((doc) {
                final j = doc.data() as Map<String, dynamic>;
                String status = (j['status'] ?? 'aberto').toString().toLowerCase();
                
                if (status == 'fechado') {
                  final Timestamp? dataHora = j['dataHora'];
                  final Timestamp? dataHoraFim = j['dataHoraFim'];
                  if (dataHora != null && dataHoraFim != null) {
                    final agora = DateTime.now();
                    if (agora.isAfter(dataHora.toDate()) && agora.isBefore(dataHoraFim.toDate())) {
                      status = 'em_andamento';
                    }
                  }
                }

                String obs = '---';
                if (status == 'cancelado') obs = j['motivoCancelamento'] ?? 'Cancelado pelo contratante';
                if (status == 'contestado') obs = j['contestacao']?['motivo'] ?? 'Em mediação';
                if (j['finalizadoAutomaticamente'] == true) obs = 'Pagamento sistêmico (12h)';

                final nomeGoleiro = (j['idGoleiro'] != null && status != 'aberto') 
                    ? (j['nomeGoleiro'] ?? 'Nome Indisponível') 
                    : 'Buscando...';

                return DataRow(cells: [
                  DataCell(Text(j['horaExibicao'] ?? '--:--', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataCell(Text(j['local'] ?? 'Arena', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  DataCell(Text(j['nomeContratante'] ?? 'N/A', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                  DataCell(Text(
                    nomeGoleiro, 
                    style: TextStyle(
                      color: nomeGoleiro == 'Buscando...' ? Colors.orangeAccent : Colors.white, 
                      fontSize: 12,
                      fontWeight: nomeGoleiro != 'Buscando...' ? FontWeight.bold : FontWeight.normal,
                    )
                  )),
                  DataCell(_badgeStatus(status)),
                  DataCell(
                    Tooltip(
                      message: obs,
                      child: SizedBox(
                        width: 150,
                        child: Text(
                          obs, 
                          style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: obs == '---' ? FontStyle.normal : FontStyle.italic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  ),
                ]);
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _badgeStatus(String status) {
    Color cor = Colors.grey;
    if (status == 'fechado') cor = primaryColor;
    if (status == 'em_andamento') cor = Colors.orange;
    if (status == 'aberto') cor = Colors.orangeAccent;
    if (status == 'contestado') cor = Colors.redAccent;
    if (status == 'cancelado') cor = Colors.red;
    if (status == 'finalizado') cor = Colors.blueAccent;

    String texto = status.toUpperCase();
    if (status == 'em_andamento') texto = "EM ANDAMENTO";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: cor.withAlpha(20), borderRadius: BorderRadius.circular(6), border: Border.all(color: cor.withAlpha(60))),
      child: Text(texto, style: TextStyle(color: cor, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}