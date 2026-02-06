import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../app_theme.dart';
import 'processing_screen.dart';
import 'recording_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedFile;
  String? _fileName;
  double? _fileSize;
  String? _fileExtension;
  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
    );


      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        
        setState(() {
          _selectedFile = file;
          _fileName = result.files.single.name;
          _fileSize = result.files.single.size / (1024 * 1024); // Convertir en MB
          _fileExtension = result.files.single.extension;
          _uploadProgress = 0;
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection du fichier: $e');
    }
  }

  void _simulateUpload() {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    // Simulation d'upload progressif
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _uploadProgress = 0.1;
      });
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _uploadProgress = 0.3;
      });
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        _uploadProgress = 0.6;
      });
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      setState(() {
        _uploadProgress = 0.9;
      });
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      setState(() {
        _uploadProgress = 1.0;
        _isUploading = false;
      });

      // Naviguer vers l'écran de traitement
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProcessingScreen(filePath: _selectedFile!.path),
        ),
      );
    });
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileSize = null;
      _fileExtension = null;
      _uploadProgress = 0;
    });
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

  String _formatFileSize(double sizeInMB) {
    if (sizeInMB < 1) {
      return '${(sizeInMB * 1024).toStringAsFixed(1)} KB';
    } else {
      return '${sizeInMB.toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importer un fichier'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Text(
              'Importer un fichier audio',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.slateDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez un fichier audio pour le transcrire (MP3, WAV, M4A, AAC, FLAC)',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),

            // Zone de dépôt
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFile != null ? AppColors.emerald : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null ? LucideIcons.checkCircle : LucideIcons.upload,
                      size: 48,
                      color: _selectedFile != null ? AppColors.emerald : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFile != null ? 'Fichier sélectionné' : 'Cliquez pour choisir un fichier',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: _selectedFile != null ? AppColors.emerald : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ou glissez-déposez votre fichier ici',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Informations du fichier sélectionné
            if (_selectedFile != null) ...[
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
                      size: 32,
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
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_fileExtension?.toUpperCase()} • ${_formatFileSize(_fileSize!)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _removeFile,
                      icon: const Icon(LucideIcons.x, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Barre de progression (pendant l'upload)
              if (_isUploading) ...[
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[200],
                      color: AppColors.emerald,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: TextStyle(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ],

            const Spacer(),

            // Bouton d'action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedFile != null && !_isUploading
                    ? _simulateUpload
                    : null,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.sparkles),
                label: Text(
                  _isUploading ? 'Import en cours...' : 'Transcrire le fichier',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  backgroundColor: _selectedFile != null && !_isUploading
                    ? AppColors.emerald
                    : Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Option pour enregistrer au lieu d'importer
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecordingScreen(),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.mic),
                label: const Text('Enregistrer un audio'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  side: BorderSide(color: AppColors.emerald),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String? extension) {
  switch (extension?.toLowerCase()) {
    case 'mp3':
    case 'wav':
    case 'm4a':
    case 'aac':
    case 'flac':
      return LucideIcons.music;
    default:
      return LucideIcons.file;
  }
}
}