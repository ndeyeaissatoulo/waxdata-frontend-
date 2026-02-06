import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'recording_screen.dart';
import 'upload_screen.dart';
import '../app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pattern de fond géométrique
          Positioned.fill(
            child: CustomPaint(
              painter: _GeometricPatternPainter(),
            ),
          ),
          
          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                
                // En-tête
                Text(
                  'WaxData',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Transformez la parole wolof en texte français',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.slateLight,
                  ),
                ),
                
                const Spacer(),
                
                // Titre principal
                Text(
                  'Parlez en Wolof,\nÉcrivez en Français.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slateDark,
                    height: 1.1,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Cartes d'action
                _ActionCard(
                  icon: LucideIcons.mic,
                  title: '🎙️ Enregistrer',
                  subtitle: 'Enregistrez un audio en Wolof',
                  color: AppColors.emerald,
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecordingScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                _ActionCard(
                  icon: LucideIcons.upload,
                  title: '📤 Importer',
                  subtitle: 'Importez un fichier audio',
                  color: Colors.white,
                  textColor: AppColors.slateDark,
                  hasBorder: true,
                  onTap: () {
                   Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UploadScreen(),
                          ),
                    );
                  },
                ),
                
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color textColor;
  final bool hasBorder;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.textColor,
    this.hasBorder = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(32),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(32),
            border: hasBorder
                ? Border.all(color: AppColors.emerald, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: textColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: textColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.emerald.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Dessiner des motifs géométriques simples
    const double step = 60;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final path = Path()
          ..addPolygon([
            Offset(x, y),
            Offset(x + step / 2, y + step / 2),
            Offset(x, y + step),
            Offset(x - step / 2, y + step / 2),
          ], true);
        
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}