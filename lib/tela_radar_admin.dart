import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TelaRadarAdmin extends StatefulWidget {
  const TelaRadarAdmin({super.key});

  @override
  State<TelaRadarAdmin> createState() => _TelaRadarAdminState();
}

class _TelaRadarAdminState extends State<TelaRadarAdmin> {
  String _filtroStatus = "Todos";
  int _limiteJogos = 50;
  
  static const primaryColor = Color(0xFF00E676);
  static const sidebarColor = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CABEÇALHO REATIVO
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Radar de Partidas", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            Text("Monitoramento em tempo real de todas as convocações.", style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 20),

        // ✨ FILTROS DE STATUS
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildFiltros(),
        ),

        // LISTA COM STREAM PAGINADA
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryColor));
              
              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(
                  child: Text("Nenhuma partida encontrada com este status.", style: TextStyle(color: Colors.white24)),
                );
              }

              return Container(
                width: double.infinity,
                decoration: BoxDecoration(color: sidebarColor, borderRadius: BorderRadius.circular(16)),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DataTable(
                        horizontalMargin: 20,
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text("DATA/HORA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text("VALOR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text("BOLSAS (C / G)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text("AÇÃO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                        rows: docs.map((doc) => _buildLinha(doc)).toList(),
                      ),

                      // BOTÃO CARREGAR MAIS
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: (docs.length >= _limiteJogos) 
                            ? OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _limiteJogos += 50;
                                  });
                                },
                                icon: const Icon(Icons.expand_more_rounded, color: primaryColor),
                                label: const Text("CARREGAR MAIS", style: TextStyle(color: primaryColor)),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryColor)),
                              )
                            : const Text("Fim da lista de partidas.", style: TextStyle(color: Colors.white24, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  DataRow _buildLinha(DocumentSnapshot doc) {
    final j = doc.data() as Map<String, dynamic>;
    final idJogo = doc.id;
    
    // Extraindo dados básicos com segurança
    final String status = (j['status'] ?? 'desconhecido').toString().toLowerCase();
    final String data = j['dataExibicao'] ?? '--/--';
    final String hora = j['horaExibicao'] ?? '--:--';
    final double valor = (j['valor'] ?? 0).toDouble();
    
    // IDs para facilitar auditoria
    final bool temGoleiro = j['idGoleiro'] != null && j['idGoleiro'].toString().isNotEmpty;

    return DataRow(cells: [
      // 1. DATA E HORA
      DataCell(Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          Text(hora, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      )),
      
      // 2. STATUS COM BADGE COLORIDO
      DataCell(_buildBadgeStatus(status)),
      
      // 3. VALOR DA PELADA
      DataCell(Text(
        "R\$ ${valor.toStringAsFixed(2)}", 
        style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)
      )),

      // 4. INDICADORES DE CONTRATANTE E GOLEIRO (Bolsas)
      DataCell(Row(
        children: [
          const Icon(Icons.person, size: 14, color: Colors.blueAccent),
          const SizedBox(width: 4),
          const Text("C", style: TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(width: 15),
          Icon(temGoleiro ? Icons.sports_handball : Icons.search_off_rounded, 
               size: 14, 
               color: temGoleiro ? Colors.green : Colors.white24),
          const SizedBox(width: 4),
          Text("G", style: TextStyle(color: temGoleiro ? Colors.white : Colors.white38, fontSize: 10)),
        ],
      )),

      // 5. AÇÃO (Admin pode cancelar jogos abertos)
      DataCell(
        status == 'aberto' || status == 'fechado'
        ? IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
            tooltip: "Forçar Cancelamento",
            onPressed: () => _confirmarCancelamento(idJogo),
          )
        : const Text("---", style: TextStyle(color: Colors.white10)),
      ),
    ]);
  }

  // --- WIDGET AUXILIAR: BADGE DE STATUS ---
  Widget _buildBadgeStatus(String status) {
    Color cor;
    String texto;

    switch (status) {
      case 'aberto':
        cor = Colors.orangeAccent;
        texto = 'BUSCANDO';
        break;
      case 'fechado':
        cor = Colors.greenAccent;
        texto = 'ESCALADO';
        break;
      case 'cancelado':
        cor = Colors.redAccent;
        texto = 'CANCELADO';
        break;
      case 'finalizado':
        cor = Colors.blueGrey;
        texto = 'CONCLUÍDO';
        break;
      default:
        cor = Colors.grey;
        texto = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: cor.withAlpha(20), borderRadius: BorderRadius.circular(6), border: Border.all(color: cor.withAlpha(60))),
      child: Text(texto, style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  // --- WIDGET AUXILIAR: FILTROS ---
  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ["Todos", "Aberto", "Fechado", "Finalizado", "Cancelado"].map((tipo) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(tipo),
              selected: _filtroStatus == tipo,
              selectedColor: primaryColor,
              labelStyle: TextStyle(color: _filtroStatus == tipo ? Colors.black : Colors.white),
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _filtroStatus = tipo;
                    _limiteJogos = 50; // Reseta paginação
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- REGRA DE NEGÓCIO: CANCELAMENTO FORÇADO ---
  Future<void> _confirmarCancelamento(String idJogo) async {
    bool? confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sidebarColor,
        title: const Text("Cancelar Partida?", style: TextStyle(color: Colors.white)),
        content: const Text("Deseja forçar o cancelamento deste jogo? Os usuários serão notificados automaticamente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("VOLTAR", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text("CANCELAR JOGO"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance.collection('jogos').doc(idJogo).update({'status': 'cancelado'});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jogo cancelado com sucesso!"), backgroundColor: Colors.redAccent));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao cancelar: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

// --- MOTOR DO BANCO DE DADOS ATUALIZADO ---
  Stream<QuerySnapshot> _getStream() {
    // ✨ Agora ordenamos por dataHora (as mais recentes ou futuras primeiro)
    var ref = FirebaseFirestore.instance
        .collection('jogos')
        .orderBy('dataHora', descending: true) 
        .limit(_limiteJogos);
    
    if (_filtroStatus == "Todos") return ref.snapshots();
    
    // Se filtrar por status, precisamos combinar o status com a ordenação
    return ref.where('status', isEqualTo: _filtroStatus.toLowerCase()).snapshots();
  }
}