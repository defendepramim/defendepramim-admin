import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TelaUsuariosAdmin extends StatefulWidget {
  const TelaUsuariosAdmin({super.key});

  @override
  State<TelaUsuariosAdmin> createState() => _TelaUsuariosAdminState();
}

class _TelaUsuariosAdminState extends State<TelaUsuariosAdmin> {
  String _filtroTipo = "Todos";
  static const primaryColor = Color(0xFF00E676);
  static const sidebarColor = Color(0xFF1A1A1A);

  // ✨ Variável para controlar o limite de usuários na tela
  int _limiteUsuarios = 50;

  // ✨ Variáveis da Busca
  String _termoBusca = "";
  final TextEditingController _buscaController = TextEditingController();

  

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CABEÇALHO REATIVO (Limpo, sem os filtros duplicados)
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Gestão de Usuários", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            Text("Monitoramento paginado em tempo real", style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 30),

        // ✨ BARRA DE PESQUISA E FILTROS
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: TextField(
                    controller: _buscaController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Buscar usuário pelo nome (Ex: Leandro...)",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: primaryColor, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      // Botão de limpar (X) só aparece se tiver texto
                      suffixIcon: _termoBusca.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                            onPressed: () {
                              _buscaController.clear();
                              setState(() {
                                _termoBusca = "";
                                _limiteUsuarios = 50;
                              });
                            },
                          )
                        : null,
                    ),
                    onSubmitted: (valor) {
                      setState(() {
                        _termoBusca = valor.trim();
                        _limiteUsuarios = 50;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              
              // OS FILTROS APARECEM SÓ UMA VEZ AQUI!
              _buildFiltros(), 
            ],
          ),
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
                  child: Text("Nenhum usuário encontrado para este filtro.", style: TextStyle(color: Colors.white24)),
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
                        columns: const [
                          DataColumn(label: Text("USUÁRIO", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("TIPO", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("CADASTRO", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("JOGOS / DESIST.", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("AÇÃO", style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: docs.map((doc) => _buildLinha(doc)).toList(),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: (docs.length >= _limiteUsuarios) 
                            ? OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _limiteUsuarios += 50;
                                  });
                                },
                                icon: const Icon(Icons.expand_more_rounded, color: primaryColor),
                                label: const Text("CARREGAR MAIS", style: TextStyle(color: primaryColor)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: primaryColor),
                                ),
                              )
                            : const Text("Fim da lista.", style: TextStyle(color: Colors.white24, fontSize: 12)),
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
    final u = doc.data() as Map<String, dynamic>;
    final uid = doc.id;
    final bool isBan = u['banido'] ?? false;
    final String tipo = (u['tipoPerfil'] ?? 'N/A').toString().toLowerCase();
    final DateTime? data = (u['criadoEm'] as Timestamp?)?.toDate();

    final bool ehAdmin = tipo == 'admin' || (u['isAdmin'] ?? false);
    
    int realizados = 0;
    int problemas = 0;
    int contestados = u['jogosContestados'] ?? 0;

    if (!ehAdmin) {
      if (tipo == "goleiro") {
        realizados = (u['atuadas'] as num?)?.toInt() ?? 0;
        problemas = (u['faltas'] as num?)?.toInt() ?? 0;
      } else if (tipo == "contratante") {
        realizados = (u['jogosRealizados'] as num?)?.toInt() ?? 0;
        problemas = (u['qtdDesistencias'] as num?)?.toInt() ?? 0;
      }
    }

    return DataRow(cells: [
      DataCell(Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(u['nome'] ?? 'Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          Text(u['email'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      )),
      
      DataCell(Text(tipo.toUpperCase(), style: const TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.bold))),
      DataCell(Text(data != null ? DateFormat('dd/MM/yy').format(data) : '--/--')),

      DataCell(
        ehAdmin 
        ? const Text("---", style: TextStyle(color: Colors.white10)) 
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _miniCard(realizados.toString(), Colors.green, Icons.sports_soccer),
              const SizedBox(width: 8),
              _miniCard(problemas.toString(), Colors.redAccent, Icons.block_flipped),
              const SizedBox(width: 8),
              _miniCard(contestados.toString(), Colors.orangeAccent, Icons.gavel_rounded),
            ],
          )
      ),

      DataCell(IconButton(
        icon: Icon(isBan ? Icons.gavel : Icons.block, color: isBan ? Colors.green : Colors.redAccent, size: 18),
        tooltip: isBan ? "Desbanir" : "Banir",
        onPressed: () => FirebaseFirestore.instance.collection('usuarios').doc(uid).update({'banido': !isBan}),
      )),
    ]);
  }

  Widget _miniCard(String valor, Color cor, IconData icone) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 12, color: cor.withOpacity(0.7)),
        const SizedBox(width: 2),
        Text(valor, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildFiltros() {
    return Row(
      children: ["Todos", "Goleiro", "Contratante", "Admin"].map((tipo) {
        return Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: ChoiceChip(
            label: Text(tipo),
            selected: _filtroTipo == tipo,
            selectedColor: primaryColor,
            labelStyle: TextStyle(color: _filtroTipo == tipo ? Colors.black : Colors.white),
            onSelected: (val) {
              setState(() {
                _filtroTipo = tipo;
                _limiteUsuarios = 50; // ✨ Reseta o limite sempre que mudar de filtro!
              });
            },
          ),
        );
      }).toList(),
    );
  }

// ✨ Stream Misto (Busca por Nome OU Lista Paginada)
  Stream<QuerySnapshot> _getStream() {
    var ref = FirebaseFirestore.instance.collection('usuarios');

    // 1. SE O ADMIN ESTIVER BUSCANDO POR NOME:
    if (_termoBusca.isNotEmpty) {
      
      // ✨ A MÁGICA ACONTECE AQUI:
      // Transforma tudo que você digitou para minúsculo antes de ir pro banco
      String buscaFormatada = _termoBusca.toLowerCase(); 

      return ref
          // ✨ APONTA PARA O CAMPO FANTASMA (nomeBusca) em vez do (nome)
          .where('nomeBusca', isGreaterThanOrEqualTo: buscaFormatada)
          .where('nomeBusca', isLessThanOrEqualTo: '$buscaFormatada\uf8ff')
          .limit(_limiteUsuarios)
          .snapshots();
    }

    // 2. SE NÃO TIVER BUSCA (Fluxo normal ordenado por data):
    var query = ref.orderBy('criadoEm', descending: true).limit(_limiteUsuarios);
    
    if (_filtroTipo == "Todos") return query.snapshots();
    if (_filtroTipo == "Admin") return query.where('isAdmin', isEqualTo: true).snapshots();
    return query.where('tipoPerfil', isEqualTo: _filtroTipo.toLowerCase()).snapshots();
  }
}