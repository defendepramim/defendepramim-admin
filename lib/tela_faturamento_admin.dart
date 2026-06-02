import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaFaturamentoAdmin extends StatefulWidget {
  const TelaFaturamentoAdmin({super.key});

  @override
  State<TelaFaturamentoAdmin> createState() => _TelaFaturamentoAdminState();
}

class _TelaFaturamentoAdminState extends State<TelaFaturamentoAdmin> {
  static const primaryColor = Color(0xFF00E676);
  static const sidebarColor = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CABEÇALHO LIMPO (Sem referências a taxas globais, pois agora a taxa vem de cada partida)
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Faturamento da Plataforma", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                Text("Caixa da empresa calculado sobre o histórico individual de cada partida.", style: TextStyle(color: Colors.white38, fontSize: 14)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 30),

        // ✨ MOTOR FINANCEIRO (Lê Jogos e Saques)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('jogos').where('status', isEqualTo: 'finalizado').snapshots(),
            builder: (context, snapshotJogos) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('saques').where('status', isEqualTo: 'pago').snapshots(),
                builder: (context, snapshotSaques) {
                  
                  if (snapshotJogos.connectionState == ConnectionState.waiting || snapshotSaques.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: primaryColor));
                  }

                  // 🧮 CÁLCULO BASEADO NO MODELO DE TAXA FIXA (REAIS)
                  double gmvTotal = 0.0; 
                  double receitaLiquidaApp = 0.0; 
                  double repasseGoleiros = 0.0; 
                  double saquesEfetuados = 0.0; 

                  if (snapshotJogos.hasData) {
                    for (var doc in snapshotJogos.data!.docs) {
                      final j = doc.data() as Map<String, dynamic>;
                      
                      final double valorJogo = (j['valor'] ?? 0.0).toDouble();
                      // ✨ A mágica acontece aqui: Lemos o valor exato em R$ salvo pelo Mobile.
                      // Fallback para 5.0 só por segurança se encontrar algum jogo antigo corrompido.
                      final double taxaAplicadaReais = (j['taxaAplicada'] ?? 5.0).toDouble();

                      gmvTotal += valorJogo;
                      receitaLiquidaApp += taxaAplicadaReais; // Soma direto!
                    }
                    repasseGoleiros = gmvTotal - receitaLiquidaApp;
                  }

                  if (snapshotSaques.hasData) {
                    for (var doc in snapshotSaques.data!.docs) {
                      final s = doc.data() as Map<String, dynamic>;
                      saquesEfetuados += (s['valor'] ?? 0.0).toDouble();
                    }
                  }

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 📊 GRID DE CARDS
                      Row(
                        children: [
                          _buildCardFinanceiro("VOLUME BRUTO (GMV)", gmvTotal, Icons.payments_rounded, Colors.blueAccent, "Todo o dinheiro transacionado no app"),
                          const SizedBox(width: 16),
                          _buildCardFinanceiro("RECEITA DO APP", receitaLiquidaApp, Icons.insights_rounded, primaryColor, "O lucro real retido pela plataforma", emDestaque: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildCardFinanceiro("REPASSE AOS GOLEIROS", repasseGoleiros, Icons.sports_handball_rounded, Colors.orangeAccent, "Dinheiro destinado aos goleiros"),
                          const SizedBox(width: 16),
                          _buildCardFinanceiro("SAQUES CONFIRMADOS", saquesEfetuados, Icons.check_circle_rounded, Colors.redAccent, "Total pago via Pix"),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // 📝 LISTA DE AUDITORIA
                      const Text("Detalhamento de Entradas Recentes", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      
                      Container(
                        decoration: BoxDecoration(color: sidebarColor, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DataTable(
                              horizontalMargin: 20,
                              columns: const [
                                DataColumn(label: Text("PARTIDA/LOCAL")),
                                DataColumn(label: Text("VALOR BRUTO")),
                                DataColumn(label: Text("CORTE PLATAFORMA")),
                                DataColumn(label: Text("LÍQ. GOLEIRO")),
                              ],
                              rows: (snapshotJogos.data?.docs ?? []).take(10).map((doc) {
                                final j = doc.data() as Map<String, dynamic>;
                                final String local = j['local'] ?? 'Arena';
                                final String data = j['dataExibicao'] ?? '--/--';
                                
                                final double valorBruto = (j['valor'] ?? 0.0).toDouble();
                                // Lê o valor da comissão em Reais direto do documento
                                final double corteApp = (j['taxaAplicada'] ?? 5.0).toDouble();
                                final double liqGoleiro = valorBruto - corteApp;

                                return DataRow(cells: [
                                  // 1. PARTIDA
                                  DataCell(Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(local, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                      Text("Finalizado em $data", style: const TextStyle(fontSize: 10, color: Colors.white38)),
                                    ],
                                  )),
                                  
                                  // 2. BRUTO
                                  DataCell(Text("R\$ ${valorBruto.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white70))),
                                  
                                  // 3. LUCRO DO APP (Agora em Reais!)
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text("+ R\$ ${corteApp.toStringAsFixed(2)}", style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                  )),
                                  
                                  // 4. LÍQUIDO GOLEIRO
                                  DataCell(Text("R\$ ${liqGoleiro.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white54))),
                                ]);
                              }).toList(),
                            ),
                            if ((snapshotJogos.data?.docs ?? []).isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(30),
                                child: Center(child: Text("Nenhuma pelada finalizada para auditar.", style: TextStyle(color: Colors.white24))),
                              )
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- WIDGET AUXILIAR ---
  Widget _buildCardFinanceiro(String titulo, double valor, IconData icone, Color cor, String subtitulo, {bool emDestaque = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: sidebarColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: emDestaque ? cor.withAlpha(100) : Colors.white.withAlpha(13), width: emDestaque ? 1.5 : 1.0),
          boxShadow: emDestaque ? [BoxShadow(color: cor.withAlpha(15), blurRadius: 10, offset: const Offset(0, 4))] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                Icon(icone, color: cor, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text("R\$ ${valor.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitulo, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}