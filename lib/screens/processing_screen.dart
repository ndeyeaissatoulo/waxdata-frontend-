import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:async'; 
import 'package:path_provider/path_provider.dart';
import '../app_theme.dart';

class ProcessingScreen extends StatefulWidget {
  final String filePath;  // Changé de File à String

  const ProcessingScreen({super.key, required this.filePath});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _isProcessing = true;
  String? _transcriptionWolof;
  String? _transcriptionFR;
  String? _errorMessage;

  TextEditingController wolofController = TextEditingController();
  TextEditingController frController = TextEditingController();

  final AudioPlayer _audioPlayer = AudioPlayer();
  File? _audioFile;

  static const String _baseUrl = 'http://192.168.1.101:8000';
  static const String _uploadEndpoint = '/upload/';
  static const String _translateEndpoint = '/translate/';

  @override
  void initState() {
    super.initState();
    // Convertir le chemin en File
    _audioFile = File(widget.filePath);
    _transcribeWolof();
  }

  Future<void> _transcribeWolof() async {
    if (_audioFile == null || !_audioFile!.existsSync()) {
      setState(() {
        _errorMessage = 'Fichier audio introuvable';
        _isProcessing = false;
      });
      return;
    }

    setState(() => _isProcessing = true);
    
    try {
      print('Transcription du fichier: ${_audioFile!.path}');
      print('Taille du fichier: ${_audioFile!.lengthSync()} bytes');

      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$_baseUrl$_uploadEndpoint')
      );
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', 
          _audioFile!.path,
          filename: _audioFile!.path.split('/').last,
        )
      );

      // Envoyer la requête avec timeout
      var response = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw TimeoutException('Timeout lors de la transcription');
        },
      );

      final respStr = await response.stream.bytesToString();
      print('Réponse API: $respStr');

      if (response.statusCode == 200) {
        final data = json.decode(respStr);
        setState(() {
          _transcriptionWolof = data['text'] ?? data['transcription'] ?? '';
          wolofController.text = _transcriptionWolof!;
          _errorMessage = null;
        });
      } else {
        final errorData = json.decode(respStr);
        setState(() {
          _errorMessage = errorData['detail'] ?? 
                         errorData['error'] ?? 
                         'Erreur ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Erreur transcription: $e');
      setState(() {
        _errorMessage = 'Erreur: $e';
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _translateToFR() async {
    if (wolofController.text.isEmpty) {
      _showError('Aucun texte à traduire');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      var response = await http.post(
        Uri.parse('$_baseUrl$_translateEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': wolofController.text}),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _transcriptionFR = data['text'] ?? data['translation'] ?? '';
          frController.text = _transcriptionFR!;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur traduction: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur traduction: $e';
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _downloadPDF() async {
    if (wolofController.text.isEmpty) {
      _showError('Aucune transcription à exporter');
      return;
    }

    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Transcription Audio',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Fichier: ${_audioFile?.path.split('/').last ?? widget.filePath}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Transcription Wolof:',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    wolofController.text,
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 30),
                  if (_transcriptionFR != null && _transcriptionFR!.isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Traduction Française:',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          frController.text,
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/transcription_$timestamp.pdf');
      
      await file.writeAsBytes(await pdf.save());

      _showSuccess('PDF téléchargé: ${file.path}');
      
      // Optionnel: partager le fichier
      // await Share.shareFiles([file.path], text: 'Ma transcription audio');
      
    } catch (e) {
      _showError('Erreur PDF: $e');
    }
  }

  Future<void> _downloadTXT() async {
    if (wolofController.text.isEmpty) {
      _showError('Aucune transcription à exporter');
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/transcription_$timestamp.txt');

      String content = '''
=== TRANSCRIPTION AUDIO ===
Fichier: ${_audioFile?.path.split('/').last ?? widget.filePath}
Date: ${DateTime.now()}

=== TRANSCRIPTION WOLOF ===
${wolofController.text}
''';

      if (_transcriptionFR != null && _transcriptionFR!.isNotEmpty) {
        content += '''

=== TRADUCTION FRANÇAISE ===
${frController.text}
''';
      }

      await file.writeAsString(content);

      _showSuccess('TXT téléchargé: ${file.path}');
      
    } catch (e) {
      _showError('Erreur TXT: $e');
    }
  }

  void _playAudio() async {
    if (_audioFile == null || !_audioFile!.existsSync()) {
      _showError('Fichier audio introuvable');
      return;
    }
    
    try {
      await _audioPlayer.play(DeviceFileSource(_audioFile!.path));
    } catch (e) {
      _showError('Erreur lecture audio: $e');
    }
  }

  void _pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Erreur pause audio: $e');
    }
  }

  void _stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Erreur stop audio: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    wolofController.dispose();
    frController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transcription & Traduction'),
        actions: [
          if (!_isProcessing && _errorMessage == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _transcribeWolof,
              tooltip: 'Retranscrire',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _isProcessing
            ? _buildLoadingScreen()
            : _errorMessage != null
                ? _buildErrorScreen()
                : _buildResultScreen(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Transcription en cours...',
            style: GoogleFonts.inter(fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            'Cela peut prendre quelques minutes',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 20),
          Text(
            'Erreur',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _transcribeWolof,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informations du fichier
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fichier audio',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _audioFile?.path.split('/').last ?? widget.filePath,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: _playAudio,
                      color: AppColors.emerald,
                    ),
                    IconButton(
                      icon: const Icon(Icons.pause),
                      onPressed: _pauseAudio,
                      color: Colors.orange,
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: _stopAudio,
                      color: Colors.red,
                    ),
                    const Spacer(),
                    if (_audioFile != null)
                      Text(
                        '${(_audioFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Transcription Wolof
        Text(
          'Transcription Wolof',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.slateDark,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: wolofController,
          maxLines: null,
          minLines: 6,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'La transcription apparaîtra ici...',
            suffixIcon: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                // TODO: copier dans le presse-papier
              },
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Bouton de traduction
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _translateToFR,
            icon: const Icon(Icons.translate),
            label: const Text('Traduire en français'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        // Traduction Française
        if (_transcriptionFR != null && _transcriptionFR!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Traduction Française',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.slateDark,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: frController,
            maxLines: null,
            minLines: 6,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  // TODO: copier dans le presse-papier
                },
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Boutons d'exportation
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exporter la transcription',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _downloadPDF,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _downloadTXT,
                        icon: const Icon(Icons.text_snippet),
                        label: const Text('TXT'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}