import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:media_store_plus/media_store_plus.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
//import 'package:http/http.dart' as http;
//import 'dart:convert';
//import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import '../../services/feedback_service.dart';
import '../../services/tflite_classifier.dart';
import '../../widgets/feedback_dialog.dart';
//import '../../services/ml_config.dart';

class MenuMinhasfotosIaWidget extends StatefulWidget {
  const MenuMinhasfotosIaWidget({super.key});

  static String routeName = 'menuMinhafotosIa';
  static String routePath = '/menuMinhasfotosIa';

  @override
  State<MenuMinhasfotosIaWidget> createState() =>
      _MenuMinhasfotosIaWidgettState();
}

class _MenuMinhasfotosIaWidgettState extends State<MenuMinhasfotosIaWidget> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _showPreview = false;
  // Altere para armazenar um Map<String, String> (path -> nome)
  List<Map<String, String>> _savedPhotos = [];
  String? _galleryFolderPath;

  bool _isClassifying = false;
  String? _classificationResult;
  String? _currentImageId;
  String? _currentPredictedClass;
  double? _currentConfidence;

  // ✅ Timer para debounce de classificação
  Timer? _classificationTimer;
  final List<String> _allClasses = [
    'Nenhuma espécie',
    'aranhas',
    'besouro_carabideo',
    'crisopideo',
    'joaninhas',
    'libelulas',
    'mosca_asilidea',
    'mosca_dolicopodidea',
    'mosca_sirfidea',
    'mosca_taquinidea',
    'percevejo_geocoris',
    'percevejo_orius',
    'percevejo_pentatomideo',
    'percevejo_reduviideo',
    'tesourinha',
    'vespa_parasitoide',
    'vespa_predadora'
  ];

  @override
  void initState() {
    super.initState();
    _initGalleryFolder();
    _initializeTFLite();
  }

  @override
  void dispose() {
    // ✅ Cleanup para evitar memory leaks
    _classificationTimer?.cancel();
    _imageFile = null;
    _classificationResult = null;
    TFLiteClassifier.dispose(); // Limpar recursos do TensorFlow
    super.dispose();
  }

  Future<void> _initializeTFLite() async {
    final success = await TFLiteClassifier.initialize();
    if (success) {
      debugPrint('✅ TensorFlow Lite inicializado com sucesso!');
    } else {
      debugPrint('❌ Falha ao inicializar TensorFlow Lite');
    }
  }

  Future<void> _initGalleryFolder() async {
    // Na web, não há um diretório de galeria persistente, então pulamos a inicialização
    if (kIsWeb) {
      return;
    }
    // Obtém o caminho da pasta Pictures/MinhasFotosIA
    Directory? picturesDir;
    if (Platform.isAndroid) {
      picturesDir = await getExternalStorageDirectory();
      // Caminho típico: /storage/emulated/0/Android/data/<package>/files
      // Queremos /storage/emulated/0/Pictures/MinhasFotosIA
      final root = Directory('/storage/emulated/0/Pictures/MinhasFotosIA');
      if (!(await root.exists())) {
        await root.create(recursive: true);
      }
      _galleryFolderPath = root.path;
    } else {
      picturesDir = await getApplicationDocumentsDirectory();
      final root = Directory('${picturesDir.path}/MinhasFotosIA');
      if (!(await root.exists())) {
        await root.create(recursive: true);
      }
      _galleryFolderPath = root.path;
    }
    await _loadSavedPhotos();
  }

  Future<void> _classifyImage(XFile imageFile) async {
    setState(() {
      _isClassifying = true;
      _classificationResult = null;
    });

    try {
      // Ler bytes da imagem
      final fileBytes = await imageFile.readAsBytes();

      // Classificar usando TensorFlow Lite local
      final result = await TFLiteClassifier.classifyImage(fileBytes);

      if (result != null) {
        final predictedClass = result['predicted_class'];
        final confidence = result['confidence'];
        final top3Predictions = result['top3_predictions'] as List<dynamic>?;

        String resultText =
            '🥇 $predictedClass\nConfiança: ${(confidence * 100).toStringAsFixed(1)}%\n\n';

        if (top3Predictions != null && top3Predictions.length >= 3) {
          resultText += '🏆 Top 3 Predições:\n';
          for (int i = 0; i < 3; i++) {
            final pred = top3Predictions[i] as Map<String, dynamic>;
            final className = pred['class'] as String;
            final conf = pred['confidence'] as double;
            final emoji = i == 0
                ? '🥇'
                : i == 1
                    ? '🥈'
                    : '🥉';
            resultText +=
                '$emoji $className: ${(conf * 100).toStringAsFixed(1)}%\n';
          }
        }

        setState(() {
          _currentImageId = const Uuid().v4();
          _currentPredictedClass = predictedClass as String?;
          _currentConfidence = confidence as double?;
          _classificationResult = resultText;
        });
      } else {
        setState(() {
          _classificationResult = 'Erro ao classificar a imagem';
        });
      }
    } catch (e) {
      setState(() {
        _classificationResult = 'Erro na classificação: $e';
      });
    } finally {
      setState(() {
        _isClassifying = false;
      });
      if (_classificationResult != null && mounted) {
        _showFeedbackDialog();
      }
    }
  }

  Future<void> _loadSavedPhotos() async {
    if (kIsWeb || _galleryFolderPath == null) return;
    final dir = Directory(_galleryFolderPath!);
    final files =
        dir.existsSync() ? dir.listSync().whereType<File>().toList() : <File>[];
    final prefs = await SharedPreferences.getInstance();
    final namesMap = <String, String>{};
    final list = prefs.getStringList('minhas_fotos_ia') ?? <String>[];
    for (final e in list) {
      final map =
          Map<String, String>.from(jsonDecode(e) as Map<String, dynamic>);
      namesMap[map['path'] ?? ''] = map['name'] ?? '';
    }
    setState(() {
      _savedPhotos = files
          .map(
            (f) => <String, String>{
              'path': f.path,
              'name': (namesMap[f.path] ?? f.uri.pathSegments.last),
            },
          )
          .toList();
    });
  }

  Future<void> _addPhotoToPrefs(String realPath, String name) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    // Remove duplicados
    _savedPhotos.removeWhere((e) => e['path'] == realPath);
    _savedPhotos.add({'path': realPath, 'name': name});
    await prefs.setStringList(
      'minhas_fotos_ia',
      _savedPhotos.map((e) => jsonEncode(e)).toList(),
    );
    setState(() {});
  }

  Future<void> _removePhotoFromPrefs(String path) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    _savedPhotos.removeWhere((e) => e['path'] == path);
    await prefs.setStringList(
      'minhas_fotos_ia',
      _savedPhotos.map((e) => jsonEncode(e)).toList(),
    );
    setState(() {});
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _imageFile = photo;
        _showPreview = true;
      });
      await _classifyImage(photo);
    }
  }

  // ignore: use_build_context_synchronously
  void _savePhoto() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Salvar fotos não é suportado na web.')),
      );
      return;
    }
    if (_imageFile != null && _galleryFolderPath != null) {
      if (await Permission.photos.request().isDenied) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permissão para acessar fotos negada.')),
        );
        return;
      }
      // ignore: use_build_context_synchronously
      String? photoName = await showDialog<String>(
        context: context,
        barrierDismissible: false, // Impede fechar clicando fora
        builder: (context) {
          final controller = TextEditingController();
          String? errorText;

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Nome da foto'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      maxLength: 50, // Limite razoável
                      decoration: InputDecoration(
                        hintText: 'Digite o nome da foto',
                        errorText: errorText,
                        border: OutlineInputBorder(),
                        counterText: '', // Remove contador de caracteres
                      ),
                      onChanged: (value) {
                        // Limpa erro quando usuário digita
                        if (errorText != null && value.trim().isNotEmpty) {
                          setState(() {
                            errorText = null;
                          });
                        }
                      },
                      onSubmitted: (value) {
                        // Permite salvar pressionando Enter
                        if (value.trim().isNotEmpty) {
                          Navigator.of(context).pop(value.trim());
                        } else {
                          setState(() {
                            errorText = 'O nome da foto não pode ser vazio.';
                          });
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final text = controller.text.trim();
                      if (text.isEmpty) {
                        setState(() {
                          errorText = 'O nome da foto não pode ser vazio.';
                        });
                      } else {
                        Navigator.of(context).pop(text);
                      }
                    },
                    child: Text('Salvar'),
                  ),
                ],
              );
            },
          );
        },
      );
      if (photoName == null || photoName.isEmpty) return;
      // Garante extensão .jpg
      String fileName =
          photoName.endsWith('.jpg') ? photoName : '$photoName.jpg';

      // Verifica se já existe foto com esse nome
      bool nameExists = _savedPhotos.any((photo) => photo['name'] == fileName);
      if (nameExists) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Já existe uma foto com esse nome. Escolha outro nome.')),
        );
        return;
      }

      final newPath = '${_galleryFolderPath!}/$fileName';
      await File(_imageFile!.path).copy(newPath);
      setState(() {
        _showPreview = false;
        _imageFile = null;
      });
      await _addPhotoToPrefs(newPath, fileName);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto salva na galeria com sucesso!')),
      );
      await _loadSavedPhotos();
    }
  }

  void _cancelPhoto() {
    setState(() {
      _imageFile = null;
      _showPreview = false;
    });
  }

  // ignore: use_build_context_synchronously
  void _deletePhoto(String path) async {
    if (kIsWeb) return;
    // ignore: use_build_context_synchronously
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir foto'),
        content: Text('Tem certeza que deseja excluir esta foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Erro ao deletar foto: $e');
    }
    await _removePhotoFromPrefs(path);
    await _loadSavedPhotos();
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Foto excluída!')));
  }

  // ✅ Função auxiliar para verificar duplicidade de nomes
  bool _isPhotoNameDuplicate(String newName, String currentPath) {
    final newFileName = newName.endsWith('.jpg') ? newName : '$newName.jpg';

    // Verifica se já existe uma foto com o mesmo nome (exceto a foto atual)
    return _savedPhotos.any((photo) {
      final photoName = photo['name'] ?? '';
      final photoPath = photo['path'] ?? '';
      return photoName.toLowerCase() == newFileName.toLowerCase() &&
          photoPath != currentPath;
    });
  }

  Future<void> _editPhotoName(String path, String currentName) async {
    if (kIsWeb) return;
    final controller =
        TextEditingController(text: currentName.replaceAll('.jpg', ''));
    // ignore: use_build_context_synchronously
    String? newName = await showDialog<String>(
      context: context,
      barrierDismissible: false, // Impede fechar clicando fora
      builder: (context) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Editar nome da foto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 50, // Limite razoável
                    decoration: InputDecoration(
                      hintText: 'Digite o novo nome da foto',
                      errorText: errorText,
                      border: OutlineInputBorder(),
                      counterText: '', // Remove contador de caracteres
                    ),
                    onChanged: (value) {
                      // Limpa erro quando usuário digita
                      if (errorText != null && value.trim().isNotEmpty) {
                        setState(() {
                          errorText = null;
                        });
                      }
                    },
                    onSubmitted: (value) {
                      // ✅ Validação completa no Enter
                      final text = value.trim();
                      if (text.isEmpty) {
                        setState(() {
                          errorText = 'O nome da foto não pode ser vazio.';
                        });
                      } else if (_isPhotoNameDuplicate(text, path)) {
                        setState(() {
                          errorText = 'Já existe uma foto com este nome.';
                        });
                      } else {
                        Navigator.of(context).pop(text);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) {
                      setState(() {
                        errorText = 'O nome da foto não pode ser vazio.';
                      });
                    } else if (_isPhotoNameDuplicate(text, path)) {
                      setState(() {
                        errorText = 'Já existe uma foto com este nome.';
                      });
                    } else {
                      Navigator.of(context).pop(text);
                    }
                  },
                  child: Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (newName != null && newName.isNotEmpty) {
      // ✅ Validação final de segurança antes de renomear
      if (_isPhotoNameDuplicate(newName, path)) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: Já existe uma foto com este nome.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String newFileName = newName.endsWith('.jpg') ? newName : '$newName.jpg';
      final file = File(path);
      final newPath = '${file.parent.path}/$newFileName';

      // ✅ Verifica se o arquivo de destino já existe fisicamente
      if (await File(newPath).exists() && newPath != path) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: Arquivo com este nome já existe.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        if (await file.exists()) {
          await file.rename(newPath);
        }
        await _removePhotoFromPrefs(path);
        await _addPhotoToPrefs(newPath, newFileName);
        await _loadSavedPhotos();

        // ✅ Feedback de sucesso
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nome da foto alterado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // ✅ Tratamento de erro
        debugPrint('Erro ao renomear foto: $e');
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao renomear a foto. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
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
                  context.pushNamed('menu');
                },
              ),
            ),
            title: Align(
              alignment: AlignmentDirectional(0.0, 1.0),
              child: Padding(
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
            ),
            actions: [],
            centerTitle: false,
            toolbarHeight: 100.0,
            elevation: 2.0,
          ),
        ),
        body: SafeArea(
          top: true,
          child: Center(
            child: _showPreview && _imageFile != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          kIsWeb
                              ? Image.network(_imageFile!.path, height: 300)
                              : Image.file(File(_imageFile!.path), height: 300),
                          if (_isClassifying)
                            Container(
                              height: 300,
                              color: Colors.black.withValues(alpha: 0.5),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _isClassifying ? null : _savePhoto,
                            child: Text('Salvar'),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isClassifying ? null : _cancelPhoto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: Text('Cancelar'),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _takePhoto,
                        icon: Icon(Icons.camera_alt),
                        label: Text('Tirar Foto'),
                      ),
                      SizedBox(height: 24),
                      Expanded(
                        child: _savedPhotos.isEmpty
                            ? const Center(
                                child: Text('Nenhuma foto salva ainda.'))
                            : ListView.builder(
                                // ✅ Otimizações de performance
                                physics: const AlwaysScrollableScrollPhysics(),
                                shrinkWrap: false,
                                addAutomaticKeepAlives: true,
                                addRepaintBoundaries: true,
                                addSemanticIndexes: true,
                                itemCount: _savedPhotos.length,
                                itemBuilder: (context, index) {
                                  final photo = _savedPhotos[index];
                                  final path = photo['path']!;
                                  final name = photo['name']!;
                                  Widget imageWidget;
                                  // Na web, não podemos acessar arquivos locais.
                                  if (kIsWeb) {
                                    imageWidget = Icon(Icons.image, size: 56.0);
                                  } else {
                                    imageWidget = ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(path),
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        // ✅ Otimizações de performance
                                        cacheWidth: 56,
                                        cacheHeight: 56,
                                        filterQuality: FilterQuality.low,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.broken_image,
                                          size: 56,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  }
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 16,
                                    ),
                                    child: ListTile(
                                      leading: imageWidget,
                                      title: Text(name),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () => _editPhotoName(
                                              path,
                                              name,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _deletePhoto(path),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        if (kIsWeb) {
                                          return; // Não abre a imagem na web
                                        }
                                        showDialog<void>(
                                          context: context,
                                          builder: (_) => Dialog(
                                            backgroundColor: Colors.black,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Expanded(
                                                  child: InteractiveViewer(
                                                    child: Image.file(
                                                      File(
                                                        path,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(),
                                                  child: Text(
                                                    'Fechar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    if (_currentImageId == null ||
        _currentPredictedClass == null ||
        _currentConfidence == null) {
      return;
    }

    // Sempre mostrar o diálogo de feedback, independente da confiança
    showDialog<void>(
      context: context,
      builder: (context) => FeedbackDialog(
        imageId: _currentImageId!,
        predictedClass: _currentPredictedClass!,
        confidence: _currentConfidence!,
        allClasses: _allClasses,
        onFeedback: _handleFeedback,
      ),
    );
  }

  void _handleFeedback(String feedback, String? correctClass) async {
    if (_currentImageId == null ||
        _currentPredictedClass == null ||
        _currentConfidence == null) {
      return;
    }

    // Obter informações do dispositivo
    final deviceInfo = {
      'platform': Platform.isAndroid ? 'Android' : 'iOS',
      'version': Platform.version,
    };

    // Salvar feedback localmente
    await FeedbackService.saveFeedbackLocally(
      imageId: _currentImageId!,
      predictedClass: _currentPredictedClass!,
      userFeedback: feedback,
      confidence: _currentConfidence!,
      correctClass: correctClass,
      deviceInfo: deviceInfo,
    );

    // Feedback salvo localmente - funciona offline!

    // Mostrar confirmação
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            feedback == 'correct'
                ? 'Obrigado pelo feedback! Classificação confirmada.'
                : 'Obrigado pelo feedback! A correção foi registrada.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
