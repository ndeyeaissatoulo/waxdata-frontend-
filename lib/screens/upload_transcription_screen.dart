import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:async' ;
import 'package:file_picker/file_picker.dart';
import '../app_theme.dart';

class UploadTransScreen extends StatefulWidget {
  const UploadTransScreen({super.key});

  @override
  State<UploadTransScreen> createState() => _UploadTransScreenState();
}

class _UploadTransScreenState extends State<UploadTransScreen> {
  File? _selectedFile;
  String? _fileName;
  double? _fileSize;
  String? _fileExtension;
  bool _isUploading = false;
  bool _isTranscribing = false;
  double _progress = 0;
  String? _transcription;
  String? _errorMessage;

  // TESTER CES ADRESSES UNE PAR UNE
  // static const String _baseUrl = 'http://10.0.2.2:8000';  // Émulateur Android
  static const String _baseUrl = 'http://192.168.1.101:8000';  // IP locale de votre PC
  // static const String _baseUrl = 'http://127.0.0.1:8000';  // Pour iOS Simulator
  static const String _uploadEndpoint = '/upload/';

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'flac', 'ogg', 'mp4'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        print('Fichier sélectionné: ${file.path}');
        print('Taille: ${file.lengthSync()} bytes');
        
        setState(() {
          _selectedFile = file;
          _fileName = result.files.single.name;
          _fileSize = result.files.single.size / (1024 * 1024);
          _fileExtension = result.files.single.extension;
          _progress = 0;
          _transcription = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('Erreur pick file: $e');
      _showError('Erreur lors de la sélection du fichier: $e');
    }
  }

  Future<void> _uploadTrans() async {
    if (_selectedFile == null) {
      _showError('Veuillez sélectionner un fichier audio');
      return;
    }

    // Vérifier que le fichier existe
    if (!_selectedFile!.existsSync()) {
      _showError('Le fichier n\'existe pas');
      return;
    }

    print('Début upload vers: $_baseUrl$_uploadEndpoint');
    print('Fichier: ${_selectedFile!.path}');
    print('Taille réelle: ${_selectedFile!.lengthSync()} bytes');

    setState(() {
      _isUploading = true;
      _isTranscribing = true;
      _progress = 0;
      _transcription = null;
      _errorMessage = null;
    });

    try {
      // Créer la requête
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$_uploadEndpoint'),
      );

      // Ajouter le fichier avec timeout
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _selectedFile!.path,
          filename: _fileName,
        ),
      );

      print('Envoi de la requête...');

      // Envoyer avec timeout
      var response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Timeout lors de l\'upload');
        },
      );

      print('Réponse reçu: ${response.statusCode}');

      // Lire la réponse
      final responseString = await response.stream.bytesToString();
      print('Réponse body: $responseString');

      final responseData = json.decode(responseString);

      if (response.statusCode == 200) {
        print('Transcription réussie');
        setState(() {
          _progress = 1.0;
          _transcription = responseData['text'] ?? responseData['transcription'] ?? 'Aucun texte retourné';
          _isUploading = false;
          _isTranscribing = false;
        });
        _showSuccess('Transcription terminée !');
      } else {
        print('Erreur API: ${response.statusCode}');
        setState(() {
          _errorMessage = responseData['detail'] ?? 
                          responseData['error'] ?? 
                          responseData['message'] ??
                          'Erreur ${response.statusCode}: ${responseString.length > 100 ? responseString.substring(0, 100) : responseString}';
          _isUploading = false;
          _isTranscribing = false;
        });
        _showError(_errorMessage!);
      }
    } catch (e) {
      print('Exception: $e');
      print('Type: ${e.runtimeType}');
      
      String errorMsg;
      if (e is SocketException) {
        errorMsg = 'Erreur de connexion. Vérifiez que:\n1. Le serveur est démarré\n2. L\'adresse IP est correcte\n3. Le port 8000 est ouvert\n\nDétail: $e';
      } else if (e is TimeoutException) {
        errorMsg = 'Timeout: Le serveur met trop de temps à répondre';
      } else {
        errorMsg = 'Erreur: $e';
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _isUploading = false;
        _isTranscribing = false;
      });
      _showError(errorMsg);
    }
  }

  void _testConnection() async {
    print('Test de connexion à $_baseUrl');
    try {
      final response = await http.get(Uri.parse('$_baseUrl/')).timeout(
        const Duration(seconds: 5),
      );
      print('Statut: ${response.statusCode}');
      print('Body: ${response.body}');
      _showSuccess('Connexion réussie: ${response.statusCode}');
    } catch (e) {
      print('Échec connexion: $e');
      _showError('Échec connexion: $e');
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileSize = null;
      _fileExtension = null;
      _progress = 0;
      _transcription = null;
      _errorMessage = null;
    });
  }

  void _copyToClipboard() {
    if (_transcription != null) {
      // TODO: Implémenter avec clipboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Texte copié dans le presse-papier'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showError(String message) {
    print('Erreur: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: Colors.red, 
        duration: const Duration(seconds: 6),
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

  String _formatFileSize(double sizeInMB) {
    if (sizeInMB < 1) return '${(sizeInMB * 1024).toStringAsFixed(1)} KB';
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'mp3':
        return LucideIcons.music;
      case 'wav':
      case 'm4a':
      case 'aac':
      case 'flac':
      case 'ogg':
      case 'mp4':
        return LucideIcons.fileAudio;
      default:
        return LucideIcons.fileAudio;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importer un fichier'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x), 
          onPressed: () => Navigator.pop(context)
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.wifi, size: 20),
            onPressed: _testConnection,
            tooltip: 'Tester la connexion',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transcription audio', 
              style: GoogleFonts.inter(
                fontSize: 28, 
                fontWeight: FontWeight.bold, 
                color: AppColors.slateDark
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Téléchargez un fichier audio pour le transcrire en texte', 
              style: TextStyle(fontSize: 16, color: Colors.grey[600])
            ),
            
            // Info de débogage
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'API: $_baseUrl$_uploadEndpoint',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            
            const SizedBox(height: 32),

            // Zone de sélection de fichier
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFile != null 
                      ? AppColors.emerald 
                      : Colors.grey[300]!, 
                    width: 2
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null 
                        ? LucideIcons.checkCircle 
                        : LucideIcons.upload, 
                      size: 48, 
                      color: _selectedFile != null 
                        ? AppColors.emerald 
                        : Colors.grey[400]
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFile != null 
                        ? 'Fichier sélectionné' 
                        : 'Choisir un fichier audio', 
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.w500, 
                        color: _selectedFile != null 
                          ? AppColors.emerald 
                          : Colors.grey[600]
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MP3, WAV, M4A, AAC, FLAC', 
                      style: TextStyle(fontSize: 14, color: Colors.grey[500])
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Info fichier
            if (_selectedFile != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.emerald.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(_fileExtension), 
                      color: AppColors.emerald, 
                      size: 32
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fileName!, 
                            style: const TextStyle(
                              fontWeight: FontWeight.w500, 
                              fontSize: 16
                            ), 
                            overflow: TextOverflow.ellipsis
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_fileExtension?.toUpperCase()} • ${_formatFileSize(_fileSize!)}', 
                            style: TextStyle(
                              color: Colors.grey[600], 
                              fontSize: 14
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _removeFile, 
                      icon: const Icon(LucideIcons.x, color: Colors.grey)
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Progression
            if (_isUploading || _isTranscribing)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress, 
                    backgroundColor: Colors.grey[200], 
                    color: AppColors.emerald, 
                    minHeight: 8, 
                    borderRadius: BorderRadius.circular(4)
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isTranscribing 
                          ? 'Transcription en cours...' 
                          : 'Upload en cours...', 
                        style: TextStyle(
                          color: AppColors.emerald, 
                          fontWeight: FontWeight.w500
                        )
                      ),
                      Text(
                        '${(_progress * 100).toInt()}%', 
                        style: TextStyle(
                          color: AppColors.emerald, 
                          fontWeight: FontWeight.w600
                        )
                      ),
                    ],
                  ),
                ],
              ),

            // Bouton de transcription
            if (_selectedFile != null && !_isUploading && !_isTranscribing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploadTrans,
                  icon: const Icon(LucideIcons.sparkles),
                  label: const Text(
                    'Transcrire le fichier', 
                    style: TextStyle(fontSize: 16)
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32)
                    ), 
                    backgroundColor: AppColors.emerald
                  ),
                ),
              ),

            // Message d'erreur
            if (_errorMessage != null && !_isUploading)
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Erreur',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Réessayer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Résultat
            if (_transcription != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50], 
                  borderRadius: BorderRadius.circular(12), 
                  border: Border.all(color: Colors.grey[300]!)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        Text(
                          'Transcription', 
                          style: GoogleFonts.inter(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold, 
                            color: AppColors.slateDark
                          )
                        ),
                        IconButton(
                          onPressed: _copyToClipboard, 
                          icon: const Icon(LucideIcons.copy, size: 20),
                          tooltip: 'Copier',
                        ),
                      ]
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(8), 
                        border: Border.all(color: Colors.grey[200]!)
                      ),
                      child: SelectableText(
                        _transcription!, 
                        style: const TextStyle(fontSize: 16, height: 1.6)
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_transcription!.length} caractères',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}