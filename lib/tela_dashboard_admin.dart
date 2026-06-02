import 'package:defende_admin/tela_saques_admin.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

// Importações das telas separadas
import 'tela_login_admin.dart';
import 'tela_usuarios_admin.dart';
import 'tela_home_admin.dart'; 
import 'tela_contestacoes_admin.dart';
import 'tela_notificacoes_admin.dart';
import 'tela_radar_admin.dart';
import 'tela_configuracoes_admin.dart';
import 'tela_faturamento_admin.dart';
import 'tela_quadras_admin.dart';
import 'tela_equipe_admin.dart'; 

class TelaDashboardAdmin extends StatefulWidget {
  const TelaDashboardAdmin({super.key});

  @override
  State<TelaDashboardAdmin> createState() => _TelaDashboardAdminState();
}

class _TelaDashboardAdminState extends State<TelaDashboardAdmin> {
  int _indiceSelecionado = 0;
  bool _carregandoFaxina = false;

  static const primaryColor = Color(0xFF00E676);
  static const bgColor = Color(0xFF121212);
  static const sidebarColor = Color(0xFF1A1A1A);

  void _fazerLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TelaLoginAdmin()),
      );
    }
  }

  // Função de manutenção do banco
  Future<void> _executarFaxinaGeral() async {
    setState(() => _carregandoFaxina = true);
    try {
      final usuariosSnap = await FirebaseFirestore.instance.collection('usuarios').get();
      int processados = 0;
      for (var userDoc in usuariosSnap.docs) {
        final tipo = (userDoc.data()['tipoPerfil'] ?? '').toString().toLowerCase();
        if (tipo == 'goleiro' || tipo == 'contratante') {
          final jogosSnap = await FirebaseFirestore.instance.collection('jogos')
              .where(tipo == 'goleiro' ? 'idGoleiro' : 'idContratante', isEqualTo: userDoc.id).get();
          
          int realizados = 0; int cancelados = 0; int contestados = 0;
          for (var jogo in jogosSnap.docs) {
            final s = jogo.data()['status']?.toString().toLowerCase() ?? '';
            if (s == 'finalizado' || s == 'pago') realizados++;
            else if (s == 'cancelado') cancelados++;
            else if (s == 'contestado') contestados++;
          }
          await userDoc.reference.update({
            if (tipo == 'goleiro') 'atuadas': realizados else 'jogosRealizados': realizados,
            if (tipo == 'goleiro') 'faltas': cancelados else 'qtdDesistencias': cancelados,
            'jogosContestados': contestados,
          });
          processados++;
        }
      }
      _mostrarAviso("Sucesso! $processados perfis atualizados.");
    } catch (e) {
      _mostrarAviso("Erro: $e");
    } finally {
      if (mounted) setState(() => _carregandoFaxina = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: sidebarColor,
        elevation: 0,
        title: const Text("DEFENDE PAINEL", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        actions: [
          if (_carregandoFaxina)
            const Center(child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2)))
          else
            IconButton(
              icon: const Icon(Icons.cleaning_services, color: Colors.orangeAccent, size: 20),
              onPressed: _executarFaxinaGeral,
            ),
          const SizedBox(width: 20),
        ],
      ),
      body: Row(
        children: [
          // 1. MENU LATERAL
          Container(
            width: 250,
            color: sidebarColor,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _itemMenu(Icons.dashboard_rounded, "Dashboard", 0),
                _itemMenu(Icons.gavel_rounded, "Contestações", 1),
                _itemMenu(Icons.monetization_on_rounded, "Saques", 2),
                _itemMenu(Icons.people_alt_rounded, "Usuários", 3),
                _itemMenu(Icons.people_alt_rounded, "Broadcasting", 4),
                _itemMenu(Icons.people_alt_rounded, "Radar de Partidas", 5),
                _itemMenu(Icons.people_alt_rounded, "Configurações Globais", 6),
                _itemMenu(Icons.people_alt_rounded, "Faturamento", 7),
                _itemMenu(Icons.people_alt_rounded, "Quadras", 8),
                _itemMenu(Icons.people_alt_rounded, "TelaEquipeAdmin", 9),
                
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                  title: const Text("Sair", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: _fazerLogout,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // 2. CONTEÚDO DINÂMICO
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(40),
              child: _renderizarTelaAtiva(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemMenu(IconData icone, String titulo, int indice) {
    final sel = _indiceSelecionado == indice;
    return ListTile(
      selected: sel,
      leading: Icon(icone, color: sel ? primaryColor : Colors.white38),
      title: Text(titulo, style: TextStyle(color: sel ? Colors.white : Colors.white38, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      onTap: () => setState(() => _indiceSelecionado = indice),
    );
  }

  // ✨ O SELETOR: Agora cada caso aponta para um arquivo diferente
  Widget _renderizarTelaAtiva() {
    switch (_indiceSelecionado) {
      case 0: 
        return const TelaHomeAdmin(); 
      case 1: 
        return const TelaContestacoesAdmin(); // ✨ Sua nova sala de audiências
      case 2: 
        return const TelaSaquesAdmin(); 
      case 3: 
        return const TelaUsuariosAdmin(); 
      case 4: 
        return const TelaNotificacoesAdmin();   
      case 5: 
        return const TelaRadarAdmin(); 
      case 6: 
        return const TelaConfiguracoesAdmin(); 
      case 7: 
        return const TelaFaturamentoAdmin(); 
      case 8: 
        return const TelaQuadrasAdmin(); 
      case 9: 
        return const TelaEquipeAdmin(); 
        

      default: 
        return const SizedBox();
    }
  }

  void _mostrarAviso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: primaryColor));
  }
}