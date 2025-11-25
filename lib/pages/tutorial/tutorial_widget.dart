import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tutorial_model.dart';
export 'tutorial_model.dart';

class TutorialWidget extends StatefulWidget {
  const TutorialWidget({super.key});

  static String routeName = 'tutorial';
  static String routePath = '/tutorial';

  @override
  State<TutorialWidget> createState() => _TutorialWidgetState();
}

class _TutorialWidgetState extends State<TutorialWidget> {
  late TutorialModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TutorialModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(100.0),
          child: AppBar(
            backgroundColor: Color(0xFF006F35),
            automaticallyImplyLeading: false,
            leading: Align(
              alignment: AlignmentDirectional(0.0, 0.0),
              child: FlutterFlowIconButton(
                borderColor: Colors.transparent,
                borderRadius: 30.0,
                borderWidth: 1.0,
                buttonSize: 60.0,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 30.0,
                ),
                onPressed: () async {
                  context.pushNamed(HomePageWidget.routeName);
                },
              ),
            ),
            title: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 15.0, 0.0, 0.0),
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
            actions: [],
            centerTitle: false,
            toolbarHeight: 100.0,
            elevation: 2.0,
          ),
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsets.all(5.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    'Guia para o reconhecimento de inimigos naturais de pragas agrícolas',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.readexPro(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                        ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 5.0, 0.0, 0.0),
                    child: Text(
                      'Com esse aplicativo você pode acessar imagens de agentes naturais de controle de pragas agrícolas, informar-se sobre predadores e parasitoides, as características morfológicas das principais famílias, o ciclo de vida e a função desses artrópodes como controladores de pragas. Esse aplicativo ainda permite que você compare uma foto de inseto tirada com a câmera do celular com as imagens da galeria do InNat.\n\nPara usar o aplicativo é simples:\n\n- Clique em "Menu" para visualizar os grupos de inimigos naturais;\n\n- Clique no sinal "+" à direita do nome para saber sobre características de predadores e parasitoides;\n\n- Para ter acesso à galeria de imagens, clique na seta à direita de cada grupo de inimigo natural;\n\n- Na galeria de imagens:\na) Clique à direita da imagem para mostrar novas imagens do mesmo grupo;\nb) Clique no botão "saiba mais" localizado no canto inferior direito da tela, para obter mais detalhes sobre o grupo de inimigos naturais;\nc) Para comparar as imagens da galeria do aplicativo com uma foto tirada com sua câmera do celular, basta clicar no campo "clique aqui para fotografar" localizado abaixo da imagem da galeria e fotografar.',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.readexPro(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
