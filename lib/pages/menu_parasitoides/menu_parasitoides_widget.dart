import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class MenuParasitoidesWidget extends StatefulWidget {
  const MenuParasitoidesWidget({super.key});

  static String routeName = 'menuParasitoides';
  static String routePath = '/menuParasitoides';

  @override
  State<MenuParasitoidesWidget> createState() => _MenuParasitoidesWidgetState();
}

class _MenuParasitoidesWidgetState extends State<MenuParasitoidesWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Adicionar variáveis de estado
  String? selectedInsect;
  int currentImageIndex = 0;
  PageController? _pageController;
  ScrollController? _descScrollController;
  ScrollController? _descIndivScrollController;

  // Mapa completo de parasitoides
  final Map<String, List<String>> parasitoides = {
    'Mosca Taquinídea (Tachinidae)': List.generate(
        9,
        (i) =>
            'assets/images/insetos/parasitoides/mosca_taquinidea/imagem${(i + 1).toString().padLeft(2, '0')}.jpg'),
    'Vespa Parasitóide (Ichneumonidae/Braconidae)': List.generate(
        29,
        (i) =>
            'assets/images/insetos/parasitoides/vespa_parasitoide/imagem${(i + 1).toString().padLeft(2, '0')}.jpg'),
  };

  // Adicione um mapa de descrições para cada inseto parasitoide
  final Map<String, String> parasitoidesDescriptionsIndividuais = {
    'Mosca Taquinídea (Tachinidae)': '''
**Reconhecimento:**  
Assim como outras moscas, os taquinídeos passam pelas fases de  ovo, larva e pupa para completarem o seu desenvolvimento e se transformarem em adultos. Entretanto, diferentemente de outras moscas, as larvas e pupas destas vivem dentro de outro inseto, parasitando-o.

**Jovens:**  
As larvas possuem tamanho que varia de 3-7 mm. Coloração branca, amarela ou creme, de formato cilíndrico. Não possuem pernas e se parecem com um verme. Penetram no corpo do hospedeiro após a mosca adulta colocar os ovos sobre ou ao lado deste. Quando completam a fase de larva, as moscas taquinídeas geralmente saem do corpo de seu hospedeiro para passar a fase de pupa do lado externo. Entretanto, podem permanecer cobertas pelo tegumento que cobre o corpo do hospedeiro, quando todo o interior já foi devorado pela larva. A aparência das larvas é muito diferente da aparência dos adultos.

**Adultos:**  
4-15 mm. Podem ser semelhantes à mosca doméstica ou apresentar cores variadas como cinza e amarelo, com ou sem listras no tórax e abdome. Destacam-se por possuírem longos pelos no final do abdome.

**Função como agente de controle biológico:**  
 São parasitas de larvas, lagartas, besouros, percevejos e outros insetos. 
''',
    'Vespa Parasitóide (Ichneumonidae/Braconidae)': '''
**Reconhecimento:**  
Para atingirem a forma adulta, as vespas parasitóides que eclodem dos ovos passam pela fase de larva dentro do corpo do inseto hospedeiro; a fase de pupa se passa no interior ou do lado externo do corpo do hospedeiro. Os adultos têm vida livre, isto é, vivem fora do corpo do hospedeiro.

**Adultos:**  
Vespas parasitoides – 13-18 mm. Podem ter coloração variada, com ou sem manchas nas asas. Geralmente com antenas longas. Micro Vespas parasitóides – 1-4 mm. Vespinhas pretas, marrons, amarelas ou com coloração verde-azulada, com ou sem brilho metálico. As fêmeas dos dois grupos apresentam o abdome pontiagudo com um "ferrão" (chamado de ovipositor) no final deste, por meio do qual perfuram o corpo dos seus hospedeiros para colocar os seus ovos.

**Função como agente de controle biológico:**  
Parasitam ovos, larvas, ninfas, pupas ou adultos de diversos insetos pragas, como besouros, mariposas, pulgões, moscas, percevejos, etc. Assim como os predadores, existem inúmeras famílias de vespas parasitóides. As vespas ou micro vespas parasitóides são muito específicas, ou seja, os seus hospedeiros são uma espécie de parasitoide que só parasita determinado grupo de hospedeiros, o que garante grande sucesso no controle biológico.
'''
  };

  // Add this variable for expansion state
  bool isDescriptionExpanded = false;

  // Add the description text
  final String parasitoidesDescription = """
Os parasitoides são insetos que parasitam outros insetos causando-lhes a morte. O inseto parasitado é chamado de hospedeiro. Um parasitoide deposita os seus ovos dentro ou fora do corpo de outro inseto e, desses ovos, nascem as larvas, que se alimentam do corpo da vítima. Além de oferecer alimento para a larva do parasitoide, o corpo do hospedeiro oferece abrigo até que o parasitoide se torne um adulto. Quando adultos os parasitoides alimentam-se de néctar e outras substâncias açucaradas.

A morte do hospedeiro pode acontecer logo que ele é parasitado ou pode ocorrer depois, permitindo que mesmo parasitado, este continue a se locomover e se alimentar por algum tempo. De qualquer forma, quando os insetos pragas são parasitados eles morrem, deixando de causar danos às plantas cultivadas.

Após completar a fase de larva dentro do seu hospedeiro, esse tipo de inimigo natural se torna um adulto, abandonando o corpo do hospedeiro para acasalar, buscar alimento e outros hospedeiros para as novas fêmeas colocarem os seus ovos. Normalmente, as fêmeas colocam um ovo em cada novo inseto encontrado, mas pode ser mais de um.

Para os parasitoides, não é qualquer inseto que serve como hospedeiro, oferecendo alimento adequado para a suas crias. A maioria das espécies de parasitoides prefere um tipo ou fase de desenvolvimento do hospedeiro. Assim, quanto maior a variedade desses inimigos naturais na propriedade rural, mais insetos diferentes serão parasitados.

Diferentemente dos predadores, os parasitoides são geralmente pequenos e, algumas vezes, são minúsculos, podendo ser chamados de microparasitoides. Além disso, muitos desses inimigos naturais vivem boa parte da sua vida dentro de outro inseto, e por isso, passam  despercebidos aos olhos humanos. Isso só não acontece quando alguns vestígios da presença ou da saída dos parasitoides continuam no inseto que foi parasitado, como no caso dos casulos das larvas na parte externa do inseto parasitado, do aspecto de múmia dos pulgões parasitados ou dos furos de saída do parasitoide no corpo do hospedeiro.

Exemplos: algumas espécies de vespas e microvespas, moscas taquiníneas, moscas forídeos.
""";

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

  // void _navigateToImage(int index) {
  //   if (_pageController != null && _pageController!.hasClients) {
  //     _pageController!.animateToPage(
  //       index,
  //       duration: const Duration(milliseconds: 300),
  //       curve: Curves.easeInOut,
  //     );
  //     setState(() {
  //       currentImageIndex = index;
  //     });
  //   }
  // }

  // Função para buscar a descrição correta, ignorando diferenças de maiúsculas/minúsculas e acentos
  String _getDescricaoParasitoide(String nomeSelecionado) {
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
    for (final entry in parasitoidesDescriptionsIndividuais.entries) {
      if (normalize(entry.key) == nomeNorm) {
        return entry.value;
      }
    }
    return 'Descrição não disponível.';
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
              // Add the expandable description section
              Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  initiallyExpanded: isDescriptionExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      isDescriptionExpanded = expanded;
                    });
                  },
                  title: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF006F35),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Sobre os Parasitoides',
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
                            parasitoidesDescription,
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista vertical de insetos
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: parasitoides.keys.length,
                  itemBuilder: (context, index) {
                    final insectName = parasitoides.keys.elementAt(index);

                    // Substitua a linha do iconPath por:
                    String iconPath = 'assets/images/insetos/parasitoides/'
                        '${insectName.split(' (').first.toLowerCase().replaceAll(' ', '_').replaceAll('í', 'i').replaceAll('é', 'e').replaceAll('ó', 'o').replaceAll('ã', 'a').replaceAll('ç', 'c')}'
                        '/botao_menu.jpg';

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
                                // Substitui o ícone pelo botao_menu.jpg do inseto
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    iconPath,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback para o ícone padrão caso não encontre a imagem
                                      return Icon(
                                        Icons.bug_report,
                                        color: selectedInsect == insectName
                                            ? Colors.white
                                            : FlutterFlowTheme.of(context)
                                                .primary,
                                      );
                                    },
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

              // Visualizador de imagens
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
                                    parasitoides[selectedInsect]![index],
                                  ),
                                  minScale: PhotoViewComputedScale.contained,
                                  maxScale: PhotoViewComputedScale.covered * 2,
                                  initialScale:
                                      PhotoViewComputedScale.contained,
                                );
                              },
                              itemCount: parasitoides[selectedInsect]!.length,
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
                            // Left arrow
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
                            // Right arrow
                            Positioned(
                              right: 10,
                              child: FlutterFlowIconButton(
                                borderColor:
                                    FlutterFlowTheme.of(context).primary,
                                borderRadius: 20,
                                borderWidth: 2,
                                buttonSize: 40,
                                fillColor: currentImageIndex <
                                        parasitoides[selectedInsect]!.length - 1
                                    ? FlutterFlowTheme.of(context).primary
                                    : FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  color: currentImageIndex <
                                          parasitoides[selectedInsect]!.length -
                                              1
                                      ? Colors.white
                                      : FlutterFlowTheme.of(context).primary,
                                  size: 20,
                                ),
                                onPressed: currentImageIndex <
                                        parasitoides[selectedInsect]!.length - 1
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
                            // Image count
                            Positioned(
                              bottom: 10,
                              left: 10,
                              child: Text(
                                '${currentImageIndex + 1}/${parasitoides[selectedInsect]!.length}',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Descrição do inseto selecionado
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
                                    _getDescricaoParasitoide(selectedInsect!),
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
