import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../app_theme.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isCleaning = false;

  @override
  void initState() {
    super.initState();
    // Texte d'exemple
    _textController.text = '''
Bonjour, aujourd'hui nous allons parler de l'importance de la traduction.
Le wolof est une langue riche avec une culture profonde.
Cette application permet de transformer la parole en texte écrit avec précision.

Exemple de phrase traduite : "Nanga def" devient "Comment allez-vous ?"
''';
  }

  Future<void> _cleanText() async {
    setState(() {
      _isCleaning = true;
    });
    
    // Simulation du nettoyage
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isCleaning = false;
      // Texte "nettoyé"
      _textController.text = '''
Bonjour, aujourd'hui nous allons parler de l'importance de la traduction.

Le wolof est une langue riche avec une culture profonde.

Cette application permet de transformer la parole en texte écrit avec précision.

Exemple de phrase traduite : "Nanga def" devient "Comment allez-vous ?"
''';
    });
    
    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Texte nettoyé avec succès !'),
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: () {
              // TODO: Implémenter le partage
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Bouton nettoyer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCleaning ? null : _cleanText,
                    icon: const Icon(LucideIcons.sparkles),
                    label: const Text('Nettoyer le texte'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Éditeur de texte
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Votre texte traduit apparaîtra ici...',
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Lecteur audio
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.play),
                        onPressed: () {
                          // TODO: Implémenter la lecture audio
                        },
                      ),
                      Expanded(
                        child: Slider(
                          value: 0.5,
                          onChanged: (value) {
                            // TODO: Implémenter le contrôle de la lecture
                          },
                        ),
                      ),
                      Text(
                        '2:45',
                        style: GoogleFonts.inter(
                          color: AppColors.slateLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Overlay de chargement
          if (_isCleaning)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.emerald),
                ),
              ),
            ),
        ],
      ),
    );
  }
}