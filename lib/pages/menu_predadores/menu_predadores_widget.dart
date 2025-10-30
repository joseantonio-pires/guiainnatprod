import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class MenuPredadoresWidget extends StatefulWidget {
  const MenuPredadoresWidget({super.key});

  static String routeName = 'menuPredadores';
  static String routePath = '/menuPredadores';

  @override
  State<MenuPredadoresWidget> createState() => _MenuPredadoresWidgetState();
}

class _MenuPredadoresWidgetState extends State<MenuPredadoresWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String? selectedInsect;
  int currentImageIndex = 0;
  PageController? _pageController;
  bool isDescriptionExpanded = false;
  ScrollController? _descScrollController;
  ScrollController? _descIndivScrollController;

  // Função utilitária para normalizar nomes
  String normalizeName(String name) {
    return name
        .split(' (')
        .first
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('í', 'i')
        .replaceAll('é', 'e')
        .replaceAll('ó', 'o')
        .replaceAll('ã', 'a')
        .replaceAll('ç', 'c');
  }

  // Função utilitária para caminho do ícone
  String getIconPath(String name) {
    return 'assets/images/insetos/predadores/'
        '${normalizeName(name)}/botao_menu.jpg';
  }

  // Função utilitária para caminho das imagens
  String getImagePath(String name, int index) {
    return 'assets/images/insetos/predadores/'
        '${normalizeName(name)}/imagem${(index + 1).toString().padLeft(2, '0')}.jpg';
  }

  // Error builder extraído
  Widget iconErrorBuilder(
      BuildContext context, Object error, StackTrace? stackTrace,
      {bool selected = false}) {
    return Icon(
      Icons.bug_report,
      color: selected ? Colors.white : FlutterFlowTheme.of(context).primary,
    );
  }

  final Map<String, List<String>> predadores = {
    'Aranhas (Araneae)': List.generate(
      33,
      (i) =>
          'assets/images/insetos/predadores/aranhas/imagem${(i + 1).toString().padLeft(2, '0')}.jpg',
    ),
    'Besouro Carabídeo (Carabidae)': List.generate(
      17,
      (i) =>
          'assets/images/insetos/predadores/besouro_carabideo/imagem${(i + 1).toString().padLeft(2, '0')}.jpg',
    ),
    'Crisopídeo (Chrysopidae)': List.generate(
      16,
      (i) =>
          'assets/images/insetos/predadores/crisopideo/imagem${(i + 1).toString().padLeft(2, '0')}.jpg',
    ),
    'Joaninhas (Coccinellidae)': List.generate(
      36,
      (i) =>
          'assets/images/insetos/predadores/joaninhas/imagem${(i + 1).toString().padLeft(2, '0')}.jpg',
    ),
    'Libélulas (Odonata)': List.generate(
      20,
      (i) =>
          'assets/images/insetos/predadores/libelulas/imagem${(i + 1).toString().padLeft(2, '0')}.jpg',
    ),
    'Mosca Asilídea (Asilidae)': List.generate(
      5,
      (i) =>
          'assets/images/insetos/predadores/mosca_asilidea/imagem${(i + 1).toString().padLeft(2, '0')}.jpg',
    ),
    'Mosca Dolicopodídea (Dolichopodidae)': List.generate(
      11,
      (i) =>
          'assets/images/insetos/predadores/mosca_dolicopodidea/imagem${(i + 1).toString().padLeft(2, '0')}.jpg',
    ),
    'Mosca Sirfídea (Syrphidae)': List.generate(
      25,
      (i) =>
          'assets/images/insetos/predadores/mosca_sirfidea/imagem${(i + 1).toString().padLeft(2, '0')}.jpg',
    ),
    'Percevejo Geocoris (Geocoridae)': List.generate(
      5,
      (i) =>
          'assets/images/insetos/predadores/percevejo_geocoris/imagem${(i + 1).toString().padLeft(2, '0')}.jpg',
    ),
    'Percevejo Orius (Anthocoridae)': List.generate(
      5,
      (i) =>
          'assets/images/insetos/predadores/percevejo_orius/imagem${(i + 1).toString().padLeft(2, '0')}.jpg',
    ),
    'Percevejo Pentatomídeo (Pentatomidae)': List.generate(
      6,
      (i) =>
          'assets/images/insetos/predadores/percevejo_pentatomideo/imagem${(i + 1).toString().padLeft(2, '0')}.jpg',
    ),
    'Percevejo Reduviídeo (Reduviidae)': List.generate(
      20,
      (i) =>
          'assets/images/insetos/predadores/percevejo_reduviideo/imagem${(i + 1).toString().padLeft(2, '0')}.jpg',
    ),
    'Tesourinha (Dermaptera)': List.generate(
      10,
      (i) =>
          'assets/images/insetos/predadores/tesourinha/imagem${(i + 1).toString().padLeft(2, '0')}.jpg',
    ),
    'Vespa Predadora (Vespidae)': List.generate(
      12,
      (i) =>
          'assets/images/insetos/predadores/vespa_predadora/imagem${(i + 1).toString().padLeft(2, '0')}.jpg',
    ),
  };

  final Map<String, String> predadoresDescriptionsIndividuais = {
    'Aranhas (Araneae)': '''
**Reconhecimento:**  
Não são insetos. Possuem oito pernas, podendo ter diversas formas e cores, variando de 2-40 mm.

**Jovens:**  
As aranhas passam o estágio de larva dentro do ovo e de lá saem com uma forma similar ao adulto; a única diferença é o tamanho e os caracteres reprodutivos.

**Adultos:**  
Os adultos diferenciam-se dos jovens por possuírem 4 pares de pernas e capacidade reprodutiva.

**Função como agente de controle biológico:**  
Predadores que se alimentam de diversos insetos durante todo o seu ciclo de vida. Muitas vezes as aranhas caminham sobre as plantas para caçar as suas presas, outras vezes esperam pacientemente que elas se aproximem das suas teias ou de seus esconderijos. São inimigos naturais generalistas, ou seja, não escolhem as suas presas e alimentam-se daquelas que tiverem oportunidade e capacidade de capturarem; suas presas podem ser insetos que ao acaso se prendem nas teias ou são visitantes comuns dos locais onde elas armam suas emboscadas, como por exemplo, as flores.
''',
    'Besouro carabídeo (Carabidae)': '''
**Reconhecimento:**  
Como todos os besouros, os carabídeos se desenvolvem a partir de ovos, que se tornam larvas, depois pupas, para então se tornarem adultos.

**Jovens:**  
 As larvas possuem tamanho que varia de 2-20 mm, dependendo da espécie. Coloração preta ou marrom, com aspecto endurecido. A aparência das larvas é muito diferente da aparência dos adultos.

**Adultos:**  
2-50 mm. Coloração variada, sendo muito comum se mimetizarem com o solo, quando vivem sobre esse, tendo nesses casos coloração escura; entretanto, podem ter coloração vistosa quando estão sobre as plantas. Aparelho bucal com mandíbulas bem evidentes.

**Função como agente de controle biológico:**  
Larvas e adultos são predadores de vários insetos, principalmente os que vivem no solo, como algumas lagartas que também se alimentam de minhocas.
''',
    'Crisopídeo (Chrysopidae)': '''
**Reconhecimento:**  
Durante o seu desenvolvimento passam pelas fases de ovo, larva, pupa (casulo de seda) para se tornarem adultos.

**Ovos:**  
0,7-2,3 mm. Apresentam pedúnculo fino que os deixa acima da superfície das folhas que lhe servem de substrato. Podem ser colocados isoladamente ou em conjunto.

**Larvas:**  
6-12 mm. Corpo em forma afunilada, semelhante ao corpo de um jacaré; coloração amarronzada; aparelho bucal em forma de pinça. Podem ser chamados de "larvas lixeiras" quando carregam sobre o  corpo um amontoado de pequenas partículas que os escondem dos seus predadores.

**Adultos:**  
15-20 mm. Corpo delicado, coloração verde, asas transparentes e delicadas, com nervuras aparentes. Nessa fase, a maioria não é inimigo natural, pois consome pólen, néctar e substâncias açucaradas eliminadas por insetos sugadores.

**Função como agente de controle biológico:**  
As larvas dos crisopídeos são predadoras de pulgões, ácaros e pequenos insetos.
''',
    'Joaninhas (Coccinellidae)': '''
**Reconhecimento:**  
Para atingirem a forma adulta, as joaninhas passam pelas fases de ovo, larva e pupa.

**Jovens:**  
As larvas possuem tamanho que varia de 2-12 mm. Possuem formato de jacaré e têm pernas longas. A maioria das larvas tem corpo de coloração escura, com ou sem manchas brancas ou amarelas. A minoria possui a cor bege, com pintas escuras. Algumas vezes, as larvas são      cobertas com secreção branca, semelhante ao algodão, o que faz com que sejam confundidas com as cochonilhas de mesmo aspecto. A aparência das larvas é muito diferente da aparência
dos adultos.

**Adultos:**  
1-10 mm. Têm formato arredondado ou ovalado, podendo apresentar coloração discreta, como preta ou bege, mas a maioria possui cores vistosas. A presença de pintas ou manchas com cores contrastantes sobre as asas é comum. Sua cabeça é flexionada para baixo, ficando ligeiramente escondida. Suas antenas são curtas e possuem uma dilatação na ponta.

**Função como agente de controle biológico:**  
Larvas e adultos se alimentam, preferencialmente, de pulgões, cochonilhas, ácaros, moscas-brancas, larvas e também de ovos de diferentes insetos. As de coloração bege se alimentam de fungos.
''',
    'Libélulas (Odonata)': '''
**Reconhecimento:**  
Durante o seu desenvolvimento passam pelas fases de ovo e ninfa, para então se tornarem adultos. Os ovos são colocados na água ou em plantas localizadas na beira de rios e lagos. As ninfas são aquáticas. Para se transformar em adulto, a ninfa sai da água e procura um galho onde completa a transformação para a forma adulta (metamorfose).

**Jovens:**  
15-50 mm. Chamados de ninfas e náiades, não possuem asas e vivem na água por até cinco anos. Sua aparência é muito diferente das libélulas adultas.

**Adultos:**  
20-160 mm. Os adultos vivem cerca de dois meses. Estes insetos têm como característica uma cabeça muito grande, arredondada, extremamente móvel, quase que inteiramente  ocupada pelos olhos, e com antenas curtas. Possuem dois pares de asas longas e transparentes que se movimentam de modo independente e um abdome bastante longo. Podem ser divididas em dois grupos: Zygoptera (corpo delicado e quando em  repouso as asas ficam fechadas sobre o abdome) e Anisoptera (insetos grandes e que mantêm as asas abertas quando estão em                 repouso). Alimentam-se de outros insetos, caçando suas presas durante o voo.

**Função como agente de controle biológico:**  
Por viverem na água, durante a fase jovem se alimentam de larvas de peixe, girinos, larvas de mosquitos, dentre outros. Na fase adulta predam diversos insetos, que são capturados em pleno voo.
''',
    'Mosca Asilídea (Asilidae)': '''
**Reconhecimento:**  
Antes de se tornarem adultos passam pelas fases de ovo, larva e pupa.

**Jovens:**  
As larvas possuem tamanho que varia de 3-8 mm. A larva não  possui pernas, tem cor branco-amarelada, corpo ligeiramente achatado e afilado nas extremidades. Vivem no solo. A aparência das larvas é muito diferente da aparência dos adultos.

**Adultos:**  
2-10 mm. Corpo delicado de coloração verde, azul ou cobre metálico. Asas transparentes, com ou sem manchas.

**Função como agente de controle biológico:**  
Adultos capturam suas presas em pleno voo. Alimentam-se de ovos, larvas e outros insetos de corpo mole.
''',
    'Mosca Dolicopodídea (Dolichopodidae)': '''
**Reconhecimento:**  
Desenvolvem-se passando pelas fases de ovo, larva, pupa e adulto.

**Jovens:**  
As larvas possuem tamanho que varia de 2-5 mm. Aspecto leitoso, com anéis marcando todo o corpo. Vivem no solo, associadas à matéria orgânica em decomposição. A aparência das larvas é muito diferente da aparência dos adultos.

**Adultos:**  
Os adultos diferenciam-se dos jovens por possuírem 4 pares de pernas e capacidade reprodutiva.

**Função como agente de controle biológico:**  
Adultos e larvas são predadores de pequenos insetos.
''',
    'Mosca sirfídea (Syrphidae)': '''
**Reconhecimento:**  
As moscas se desenvolvem passando pelas fases de ovo, larva, pupa e adulto.

**Jovens:**  
As larvas possuem tamanho que varia de 8-15 mm. As larvas não possuem pernas, são semelhantes a vermes, têm aspecto gelatinoso  e coloração verde-clara ou amarelo-clara. As pupas têm aspecto de gota, com uma das extremidades bastante fina. A aparência das larvas é muito diferente da aparência dos adultos.

**Adultos:**  
6-18 mm. As espécies de moscas dessa família são muito diferentes umas das outras, no que diz respeito ao tamanho, forma e coloração, podendo ser semelhantes às abelhas, às vespas                 ou às moscas varejeiras. Entretanto, os sirfídeos têm apenas duas asas, ao invés das quatro presentes nas abelhas e nas vespas. Possuem manchas nas asas, o que as diferencia grosseiramente das varejeiras. Elas têm o hábito de fixar-se em  um ponto durante o voo dando a impressão de que estão pairando no ar.

**Função como agente de controle biológico:**  
Apenas as larvas são predadoras. Alimentam-se de pulgões e cochonilhas. 
''',
    'Percevejo geocoris (Geocoridae)': '''
**Reconhecimento:**  
Desenvolvem-se passando pelas fases de ovo, ninfa e adulto.

**Jovens:**  
1-2 mm. Nessa fase, são chamados de ninfas. Possuem coloração marrom ou amarelada, com ou sem manchas, corpo mole e sem a presença de asas.

**Adultos:**  
3-4 mm. Coloração cinza, marrom ou preta, com olhos muito grandes, localizados na lateral de uma cabeça pequena em relação ao tórax. São conhecidos como "percevejo dos olhos grandes".

**Função como agente de controle biológico:**  
Ninfas e adultos são predadores de ovos de diversas espécies de insetos, além de ácaros, pulgões, moscas-brancas, tripes e pequenas lagartas. Matam as suas presas ao injetarem o seu aparelho bucal na vítima e sugarem o líquido do seu corpo.
''',
    'Percevejo orius (Anthocoridae)': '''
**Reconhecimento:**  
Desenvolvem-se a partir de ovos que originam as ninfas e, a partir delas, tornam-se adultos. Os ovos são colocados dentro do tecido das plantas, sendo muito comum as fêmeas usarem como substrato para os ovos plantas espontâneas como caruru e picão-preto.

**Jovens:**  
0,7-2 mm. Quando jovens, esses insetos são chamados de ninfas. Possuem coloração amarelada, olhos vermelhos ou escuros, corpo mole e ausência de asas.

**Adultos:**  
2-3 mm. Percevejos escuros, muitos com faixa branca no meio das asas, que podem ter a forma de um retângulo, de um “V” ou outra qualquer, destacando-se sobre o fundo escuro.

**Função como agente de controle biológico:**  
Adultos e ninfas são predadores. Sugam o conteúdo líquido do corpo de pulgões, tripes, pequenas lagartas, ácaros e ovos de diferentes insetos.
''',
    'Percevejo pentatomídeo (Pentatomidae)': '''
**Reconhecimento:**  
Os percevejos têm três fases de desenvolvimento: ovo, ninfa e adulto.

**Jovens:**  
3-10 mm. Chamadas de ninfas. Possuem coloração diferente da dos adultos, podendo ser bem destacada em relação à vegetação. Podem ter coloração forte e presença de pintas sobre o abdome ou cor parda e uniforme.

**Adultos:**  
10-15 mm. Possuem um grande triângulo entre as asas (chamado de escutelo), difere os percevejos dessa família dos demais cujo escutelo é muito menor. São parecidos com percevejos pragas (chamados de "maria fedidas"), mas seu aparelho bucal é todo projetado para a frente (ângulo de 180 graus) quando está sugando as suas presas, enquanto as pragas projetam o aparelho bucal para baixo (ângulo de 90 graus) quando sugam as plantas.

**Função como agente de controle biológico:**  
Adultos e ninfas são predadores de insetos diversos como lagartas, ninfas, besouros e outros percevejos.
''',
    'Percevejo reduviídeo (Reduviidae)': '''
**Reconhecimento:**  
Os percevejos reduviídeos passam pelas fases de ovo, ninfa e adulto para completarem o seu desenvolvimento. 

**Jovens:**  
4-12 mm. São chamados de ninfas, sendo muito parecidos com os adultos, mas sem a presença de asas ou com as asas pouco desenvolvidas.

**Adultos:**  
10-30 mm. Coloração variada, cabeça fina e alongada formando uma espécie de “pescoço” destacado; as asas em repouso deixam à mostra a parte lateral do abdome. Muitas vezes, são confundidos com os barbeiros (sugadores de sangue), mas podem ser diferenciados pela presença de curvatura no aparelho bucal dos predadores.

**Função como agente de controle biológico:**  
Predadores vorazes e generalistas em sua fase adulta e jovem. Alimentam-se de qualquer inseto, entre eles besouros, lagartas, abelhas e outros percevejos. Assim como todo percevejo predador, os reduviídeos matam suas presas quando sugam o conteúdo líquido de seus corpos.
''',
    'Tesourinha (Dermaptera)': '''
**Reconhecimento:**  
Iniciam o seu desenvolvimento através da fase de ovo, passam pela fase de ninfa e depois se tornam adultos.

**Jovens:**  
São semelhantes aos adultos, embora sejam menores. Não possuem asas.

**Adultos:**  
8-15 mm (machos) e 14-25 mm (fêmeas). Marrons ou pretos com pinça característica no final do abdome, que se parece com uma tesoura e é responsável pelo nome vulgar do inseto                 ("tesourinha"). As asas são curtas e não cobrem o abdome. As fêmeas têm o hábito de proteger os seus ovos e as ninfas mais jovens, permanecendo sobre estes.

**Função como agente de controle biológico:**  
Ninfas e adultos são predadores de ovos, pulgões, moscas-brancas, lagartas pequenas e pupas em geral.
''',
    'Vespa predadora (Vespidae)': '''
**Reconhecimento:**  
As vespas predadoras, algumas vezes chamadas de marimbondos, são insetos que vivem em grupos (sociedade) ou são solitários. As vespas sociais constroem ninhos de formas variadas que, em geral, ficam pendurados em galhos de plantas ou em construções. As vespas solitárias são a maioria e não constroem casas; seus ninhos são construídos em buracos nos troncos de árvores, no solo ou em rachaduras nos rebocos de casas.

**Jovens:**  
As aranhas passam o estágio de larva dentro do ovo e de lá saem com uma forma similar ao adulto; a única diferença é o tamanho e os caracteres reprodutivos.

**Adultos:**  
5-25 mm. Vespas têm coloração escura, podendo apresentar listras amarelas e brancas sobre o corpo. Podem ferroar animais e humanos para se defenderem.

**Função como agente de controle biológico:**  
As vespas caçam insetos e aranhas, injetam veneno em seus corpos e conseguem paralisá-los através da ferroada. As presas são então carregadas para os seus ninhos para servir de alimento para suas larvas. As vespas predam lagartas, vaquinhas, percevejos e várias aranhas. São importantes controladoras do bicho-mineiro do cafeeiro (Leucoptera coffeella).
'''
  };

  final String predadoresDescription = """
Predadores são os inimigos naturais que se alimentam de outros insetos, ácaros e aranhas, matando-os ao mastigá-los ou ao sugar o conteúdo

Muitos insetos predadores se alimentam de suas presas apenas enquanto são jovens (larvas ou ninfas), e na fase adulta alimentam-se de substâncias adocicadas, como néctar, pólen ou líquidos liberados por outros insetos sobre as plantas. Outras espécies agem como predadores tanto na fase jovem como na adulta.

A maioria dos predadores é composta de artrópodes que não apresentam muita preferência, alimentando-se de uma infinidade de presas pertencentes a diferentes grupos. Entretanto, existem predadores que são bastante específicos e preferem somente determinadas presas.

Exemplos de predadores: aranhas, ácaros, vespas ou marimbondos, libélulas, tesourinhas, crisopídeos, joaninhas, moscas sirfídeos, dolicopodídeas e asilídeas, besouros carabídeos e estafilinídeos, percevejos orius, geocoris, reduviídeos e pentatomídeos.
""";

  // Função para buscar a descrição correta, ignorando diferenças de maiúsculas/minúsculas e acentos
  String _getDescricaoPredador(String nomeSelecionado) {
    // Normaliza para comparar sem acento e case insensitive
    String normalize(String s) => s
        .toLowerCase()
        .replaceAll('í', 'i')
        .replaceAll('é', 'e')
        .replaceAll('ó', 'o')
        .replaceAll('ã', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ê', 'e')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ú', 'u')
        .replaceAll('í', 'i')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u');
    String nomeNorm = normalize(nomeSelecionado);
    for (final entry in predadoresDescriptionsIndividuais.entries) {
      if (normalize(entry.key) == nomeNorm) {
        return entry.value;
      }
    }
    return 'Descrição não disponível.';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _descScrollController = ScrollController();
    _descIndivScrollController = ScrollController();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _descScrollController?.dispose();
    _descIndivScrollController?.dispose();
    super.dispose();
  }

  void _initializePageController() {
    if (_pageController != null) {
      if (_pageController!.hasClients) {
        _pageController!.jumpToPage(0);
      }
    } else {
      _pageController = PageController();
    }
    setState(() {
      currentImageIndex = 0;
    });
  }

  Widget _buildRichDescription(String markdown, BuildContext context) {
    final lines = markdown.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) {
          return SizedBox(height: 8);
        }

        final boldMatch = RegExp(r'^\*\*(.+?)\*\*').firstMatch(line);
        if (boldMatch != null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              boldMatch.group(1)!,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            line,
            style: FlutterFlowTheme.of(context).bodyMedium,
            textAlign: TextAlign.justify,
          ),
        );
      }).toList(),
    );
  }

  // Widget utilitário para Scrollbar sempre visível
  Widget _buildAlwaysVisibleScrollbar(BuildContext context,
      {required Widget child, required ScrollController controller}) {
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(Color(0xFF006F35)),
        thickness: WidgetStateProperty.all(12),
        radius: Radius.circular(8),
        minThumbLength: 48,
        trackColor: WidgetStateProperty.all(Colors.black12),
        trackBorderColor: WidgetStateProperty.all(Colors.black26),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        controller: controller,
        child: SingleChildScrollView(
          controller: controller,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: AppBar(
            backgroundColor: const Color(0xFF006F35),
            automaticallyImplyLeading: false,
            leading: Align(
              alignment: AlignmentDirectional(0.0, 0.0),
              child: FlutterFlowIconButton(
                borderColor: Colors.transparent,
                borderRadius: 30.0,
                borderWidth: 1.0,
                buttonSize: 60.0,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 30.0,
                ),
                onPressed: () => context.pop(),
              ),
            ),
            title: Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(0.0, 15.0, 0.0, 0.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  'assets/images/innat_cabecalho.png',
                  width: double.infinity,
                  height: 52.0,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            actions: const [],
            centerTitle: false,
            toolbarHeight: 100.0,
            elevation: 2.0,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  initiallyExpanded: isDescriptionExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() => isDescriptionExpanded = expanded);
                  },
                  title: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF006F35),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Sobre os Predadores',
                        style:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  fontFamily: 'Readex Pro',
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            screenHeight * 0.25, // menor para responsividade
                      ),
                      child: _buildAlwaysVisibleScrollbar(
                        context,
                        controller: _descScrollController!,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            predadoresDescription,
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: predadores.keys.length,
                  itemBuilder: (context, index) {
                    final insectName = predadores.keys.elementAt(index);
                    String iconPath = getIconPath(insectName);

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedInsect == insectName
                              ? FlutterFlowTheme.of(context).primary
                              : FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                          padding: const EdgeInsets.all(15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: FlutterFlowTheme.of(context).primary,
                              width: 2,
                            ),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedInsect = insectName;
                            _initializePageController();
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    iconPath,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error,
                                            stackTrace) =>
                                        iconErrorBuilder(
                                            context, error, stackTrace,
                                            selected:
                                                selectedInsect == insectName),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  insectName,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Readex Pro',
                                        color: selectedInsect == insectName
                                            ? Colors.white
                                            : FlutterFlowTheme.of(context)
                                                .primaryText,
                                      ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: selectedInsect == insectName
                                  ? Colors.white
                                  : FlutterFlowTheme.of(context).primary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (selectedInsect != null)
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PhotoViewGallery.builder(
                              scrollPhysics: const BouncingScrollPhysics(),
                              builder: (BuildContext context, int index) {
                                return PhotoViewGalleryPageOptions(
                                  imageProvider: AssetImage(
                                    predadores[selectedInsect]![index],
                                  ),
                                  minScale: PhotoViewComputedScale.contained,
                                  maxScale: PhotoViewComputedScale.covered * 2,
                                  initialScale:
                                      PhotoViewComputedScale.contained,
                                );
                              },
                              itemCount: predadores[selectedInsect]!.length,
                              loadingBuilder: (context, event) => Center(
                                child: CircularProgressIndicator(
                                  color: FlutterFlowTheme.of(context).primary,
                                ),
                              ),
                              pageController: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  currentImageIndex = index;
                                });
                              },
                              backgroundDecoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                              ),
                            ),
                            Positioned(
                              left: 10,
                              child: FlutterFlowIconButton(
                                borderColor:
                                    FlutterFlowTheme.of(context).primary,
                                borderRadius: 20,
                                borderWidth: 2,
                                buttonSize: 40,
                                fillColor: currentImageIndex > 0
                                    ? FlutterFlowTheme.of(context).primary
                                    : FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  color: currentImageIndex > 0
                                      ? Colors.white
                                      : FlutterFlowTheme.of(context).primary,
                                  size: 20,
                                ),
                                onPressed: currentImageIndex > 0
                                    ? () {
                                        _pageController?.animateToPage(
                                          currentImageIndex - 1,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                        setState(() {
                                          currentImageIndex =
                                              currentImageIndex - 1;
                                        });
                                      }
                                    : null,
                              ),
                            ),
                            Positioned(
                              right: 10,
                              child: FlutterFlowIconButton(
                                borderColor:
                                    FlutterFlowTheme.of(context).primary,
                                borderRadius: 20,
                                borderWidth: 2,
                                buttonSize: 40,
                                fillColor: currentImageIndex <
                                        predadores[selectedInsect]!.length - 1
                                    ? FlutterFlowTheme.of(context).primary
                                    : FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  color: currentImageIndex <
                                          predadores[selectedInsect]!.length - 1
                                      ? Colors.white
                                      : FlutterFlowTheme.of(context).primary,
                                  size: 20,
                                ),
                                onPressed: currentImageIndex <
                                        predadores[selectedInsect]!.length - 1
                                    ? () {
                                        _pageController?.animateToPage(
                                          currentImageIndex + 1,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                        setState(() {
                                          currentImageIndex =
                                              currentImageIndex + 1;
                                        });
                                      }
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              child: Text(
                                '${currentImageIndex + 1}/${predadores[selectedInsect]!.length}',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: screenHeight *
                            0.22, // levemente menor para responsividade
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Descrição:',
                              style: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Expanded(
                              child: _buildAlwaysVisibleScrollbar(
                                context,
                                controller: _descIndivScrollController!,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: _buildRichDescription(
                                    _getDescricaoPredador(selectedInsect!),
                                    context,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
