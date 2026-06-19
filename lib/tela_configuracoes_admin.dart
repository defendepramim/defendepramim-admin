import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaConfiguracoesAdmin extends StatefulWidget {
  const TelaConfiguracoesAdmin({super.key});

  @override
  State<TelaConfiguracoesAdmin> createState() => _TelaConfiguracoesAdminState();
}

class _TelaConfiguracoesAdminState extends State<TelaConfiguracoesAdmin> {
  static const primaryColor = Color(0xFF00E676);
  static const sidebarColor = Color(0xFF1A1A1A);

  // --- CONTROLADORES ABSOLUTOS ---
  // Card 1: Taxas do App (Lucro)
  final TextEditingController _taxaAppVarzeaController = TextEditingController();
  final TextEditingController _taxaAppInterController = TextEditingController();
  final TextEditingController _taxaAppEliteController = TextEditingController();
  
  // Card 2: Preços Totais (Contratante)
  final TextEditingController _precoVarzeaController = TextEditingController();
  final TextEditingController _precoInterController = TextEditingController();
  final TextEditingController _precoEliteController = TextEditingController();
  
  // Card 3: Regras de Saque
  final TextEditingController _saqueMinimoController = TextEditingController();
  
  // Card 4: Regras de Tempo
  final TextEditingController _antecedenciaController = TextEditingController();
  final TextEditingController _pagamentoAutoController = TextEditingController();
  final TextEditingController _multaController = TextEditingController();
  final TextEditingController _tempoDeslocamentoController = TextEditingController();

  bool _modoManutencao = false;
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  @override
  void dispose() {
    _taxaAppVarzeaController.dispose();
    _taxaAppInterController.dispose();
    _taxaAppEliteController.dispose();
    _precoVarzeaController.dispose();
    _precoInterController.dispose();
    _precoEliteController.dispose();
    _saqueMinimoController.dispose();
    _antecedenciaController.dispose();
    _pagamentoAutoController.dispose();
    _multaController.dispose();
    super.dispose();
  }

  // --- LÊ AS CONFIGURAÇÕES DO BANCO ---
  Future<void> _carregarConfiguracoes() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('configuracoes').doc('global').get();
      
      if (doc.exists) {
        final d = doc.data()!;
        
        // Taxas do App
        _taxaAppVarzeaController.text = (d['taxaAppVarzea'] ?? 5.0).toString();
        _taxaAppInterController.text = (d['taxaAppInter'] ?? 6.0).toString();
        _taxaAppEliteController.text = (d['taxaAppElite'] ?? 8.0).toString();
        _tempoDeslocamentoController.text = (d['tempoDeslocamentoMinutos'] ?? 30).toString();

        // Preços Totais
        _precoVarzeaController.text = (d['precoVarzea'] ?? 35.0).toString();
        _precoInterController.text = (d['precoInter'] ?? 36.0).toString();
        _precoEliteController.text = (d['precoElite'] ?? 38.0).toString();

        // Financeiro e Operacional
        _saqueMinimoController.text = (d['saqueMinimo'] ?? 50.0).toString();
        _antecedenciaController.text = (d['horasAntecedencia'] ?? 2).toString();
        _pagamentoAutoController.text = (d['horasPagamentoAuto'] ?? 12).toString();
        _multaController.text = (d['horasMultaCancelamento'] ?? 4).toString();

        _modoManutencao = d['emManutencao'] ?? false;
      } else {
        // Padrão de Fábrica
        _taxaAppVarzeaController.text = "5.0"; _taxaAppInterController.text = "6.0"; _taxaAppEliteController.text = "8.0";
        _precoVarzeaController.text = "35.0"; _precoInterController.text = "36.0"; _precoEliteController.text = "38.0";
        _saqueMinimoController.text = "50.0"; _antecedenciaController.text = "2"; 
        _pagamentoAutoController.text = "12"; _multaController.text = "4"; _tempoDeslocamentoController.text = "30";
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao carregar: $e")));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // --- SALVA AS ALTERAÇÕES ---
  Future<void> _salvarConfiguracoes() async {
    setState(() => _salvando = true);

    try {
      await FirebaseFirestore.instance.collection('configuracoes').doc('global').set({
        // Taxas App
        'taxaAppVarzea': double.tryParse(_taxaAppVarzeaController.text.replaceAll(',', '.')) ?? 5.0,
        'taxaAppInter': double.tryParse(_taxaAppInterController.text.replaceAll(',', '.')) ?? 6.0,
        'taxaAppElite': double.tryParse(_taxaAppEliteController.text.replaceAll(',', '.')) ?? 8.0,
        // Preços Totais
        'precoVarzea': double.tryParse(_precoVarzeaController.text.replaceAll(',', '.')) ?? 35.0,
        'precoInter': double.tryParse(_precoInterController.text.replaceAll(',', '.')) ?? 36.0,
        'precoElite': double.tryParse(_precoEliteController.text.replaceAll(',', '.')) ?? 38.0,
        // Operacional
        'saqueMinimo': double.tryParse(_saqueMinimoController.text.replaceAll(',', '.')) ?? 50.0,
        'horasAntecedencia': int.tryParse(_antecedenciaController.text) ?? 2,
        'horasPagamentoAuto': int.tryParse(_pagamentoAutoController.text) ?? 12,
        'horasMultaCancelamento': int.tryParse(_multaController.text) ?? 4,
        'tempoDeslocamentoMinutos': int.tryParse(_tempoDeslocamentoController.text) ?? 30,
        'emManutencao': _modoManutencao,
        'ultimaAtualizacao': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Controle Remoto atualizado!"), backgroundColor: primaryColor));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator(color: primaryColor));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Configurações Globais", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const Text("Pilote a inteligência de negócios e precificação do aplicativo em tempo real.", style: TextStyle(color: Colors.white38, fontSize: 14)),
        const SizedBox(height: 30),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // 📊 1. PRECIFICAÇÃO: 3 CAMPOS EMPILHADOS LADO A LADO
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CARD 1: TAXAS DO APP (LUCRO) - EMPILHADO
                    Expanded(
                      child: _buildCardAgrupado("Sua Taxa (Lucro por Hora)", Icons.diamond, [
                        _buildCampoTexto(_taxaAppVarzeaController, "Taxa Goleiro Várzea (R\$)", "Ex: 5.0", Icons.star_border),
                        const SizedBox(height: 16),
                        _buildCampoTexto(_taxaAppInterController, "Taxa Goleiro Inter (R\$)", "Ex: 6.0", Icons.star_half),
                        const SizedBox(height: 16),
                        _buildCampoTexto(_taxaAppEliteController, "Taxa Goleiro Elite (R\$)", "Ex: 8.0", Icons.star),
                      ]),
                    ),
                    const SizedBox(width: 20),
                    
                    // CARD 2: PREÇO TOTAL (CONTRATANTE) - EMPILHADO
                    Expanded(
                      child: _buildCardAgrupado("Preço Total (Pago pelo Contratante)", Icons.sports_handball_rounded, [
                        _buildCampoTexto(_precoVarzeaController, "Várzea Total (R\$)", "Ex: 35.0", Icons.star_border),
                        const SizedBox(height: 16),
                        _buildCampoTexto(_precoInterController, "Inter Total (R\$)", "Ex: 40.0", Icons.star_half),
                        const SizedBox(height: 16),
                        _buildCampoTexto(_precoEliteController, "Elite Total (R\$)", "Ex: 50.0", Icons.star),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 💳 2. CARD: REGRAS DE SAQUE
                _buildCardAgrupado("Regras de Saque e Retiradas", Icons.account_balance_wallet_rounded, [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCampoTexto(_saqueMinimoController, "Valor Mínimo para Solicitação de Saque (R\$)", "Ex: 50.0", Icons.account_balance_rounded),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 20),

                // ⏱️ 3. CARD: RELÓGIO DE REGRAS DE TEMPO
// ⏱️ 3. CARD: RELÓGIO DE REGRAS E LOGÍSTICA
_buildCardAgrupado("Relógio de Regras e Logística", Icons.access_time_filled_rounded, [
  Row(
    children: [
      Expanded(child: _buildCampoTexto(_antecedenciaController, "Antecedência Criação (h)", "Ex: 2", Icons.add_circle_outline)),
      const SizedBox(width: 16),
      Expanded(child: _buildCampoTexto(_multaController, "Trava de Multa (h)", "Ex: 4", Icons.warning_amber_rounded)),
      const SizedBox(width: 16),
      Expanded(child: _buildCampoTexto(_pagamentoAutoController, "Pagto Automático (h)", "Ex: 12", Icons.monetization_on_outlined)),
    ],
  ),
  const SizedBox(height: 16), // Espaço entre as linhas
  Row(
    children: [
      Expanded(
        child: _buildCampoTexto(_tempoDeslocamentoController, "Tempo Deslocamento entre Jogos (Minutos)", "Ex: 30", Icons.route_rounded)
      ),
      const Spacer(flex: 2), // Joga o campo para a esquerda e não deixa ele ficar gigante
    ],
  ),
]),
                const SizedBox(height: 20),

                // 🚨 4. MODO MANUTENÇÃO
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _modoManutencao ? Colors.redAccent.withAlpha(20) : sidebarColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _modoManutencao ? Colors.redAccent.withAlpha(60) : Colors.white.withAlpha(15)),
                  ),
                  child: SwitchListTile(
                    activeColor: Colors.redAccent,
                    title: const Text("Modo Manutenção", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Bloqueia temporariamente o uso do app exibindo uma tela de aviso.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: _modoManutencao,
                    onChanged: (bool value) => setState(() => _modoManutencao = value),
                  ),
                ),
                const SizedBox(height: 30),

                // 💾 BOTÃO SALVAR CONFIGURAÇÕES
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0), // 🟢 O seu "margin right" está aqui!
                    child: ElevatedButton.icon(
                      onPressed: _salvando ? null : _salvarConfiguracoes,
                      icon: _salvando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.save_rounded),
                      label: Text(_salvando ? "SALVANDO..." : "SALVAR CONFIGURAÇÕES"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor, foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGETS AUXILIARES COM O CROSSAXIS CORRIGIDO ---
  Widget _buildCardAgrupado(String titulo, IconData icone, List<Widget> filhos) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: sidebarColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 🟢 Aqui está lisinho e correto!
        children: [
          Row(
            children: [
              Icon(icone, color: primaryColor, size: 22),
              const SizedBox(width: 10),
              Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ...filhos,
        ],
      ),
    );
  }

  Widget _buildCampoTexto(TextEditingController controller, String label, String hint, IconData icone) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icone, color: primaryColor, size: 18),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}