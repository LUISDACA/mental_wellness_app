import 'package:flutter/material.dart';

/// Utilidades de categorías de lugares y formato del Mapa
class MapUtils {
  // Iconos más modernos y distintivos
  static IconData iconFor(String cat) {
    switch (cat) {
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'clinic':
        return Icons.medical_services_rounded;
      case 'doctors':
        return Icons.healing_rounded;
      case 'pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'psychiatrist':
        return Icons.self_improvement_rounded;
      case 'counselling':
        return Icons.forum_rounded;
      case 'mental_health':
        return Icons.favorite_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  // Colores personalizados para cada categoría
  static Color colorFor(String cat) {
    switch (cat) {
      case 'hospital':
        return Colors.red.shade700;
      case 'clinic':
        return Colors.orange.shade700;
      case 'doctors':
        return Colors.blue.shade700;
      case 'pharmacy':
        return Colors.green.shade700;
      case 'psychology':
        return Colors.purple.shade700;
      case 'psychiatrist':
        return Colors.indigo.shade700;
      case 'counselling':
        return Colors.teal.shade700;
      case 'mental_health':
        return Colors.pink.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // Color de fondo más claro para contraste
  static Color bgColorFor(String cat) {
    switch (cat) {
      case 'hospital':
        return Colors.red.shade50;
      case 'clinic':
        return Colors.orange.shade50;
      case 'doctors':
        return Colors.blue.shade50;
      case 'pharmacy':
        return Colors.green.shade50;
      case 'psychology':
        return Colors.purple.shade50;
      case 'psychiatrist':
        return Colors.indigo.shade50;
      case 'counselling':
        return Colors.teal.shade50;
      case 'mental_health':
        return Colors.pink.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  static String labelFor(String cat) {
    switch (cat) {
      case 'psychology':
        return 'Psicología';
      case 'psychiatrist':
        return 'Psiquiatría';
      case 'counselling':
        return 'Consejería';
      case 'mental_health':
        return 'Salud mental';
      case 'hospital':
        return 'Hospital';
      case 'clinic':
        return 'Clínica';
      case 'doctors':
        return 'Consultorios';
      case 'pharmacy':
        return 'Farmacia';
      default:
        return 'Otros';
    }
  }

  static String fmtMeters(double m) {
    if (m < 1000) return '${m.toStringAsFixed(0)} m';
    return '${(m / 1000).toStringAsFixed(2)} km';
  }

  static String formatDuration(double secs) {
    final m = (secs / 60).round();
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final mm = m % 60;
    if (mm == 0) return '$h h';
    return '$h h $mm min';
  }
}

/// Helper para abrir enlaces externos con fallback
Future<void> launchUriSafe(BuildContext context, Uri uri) async {
  // Se importa dinámicamente url_launcher desde map_help_page actual
  // para evitar dependencias cruzadas innecesarias aquí.
  // Este helper es solo una envoltura para centralizar el try/catch.
  try {
    // El propio MapHelpPage decidirá el modo (web/external/platform).
    // Aquí no implementamos la lógica para no duplicar.
    // Se llamará al método real desde la página.
    // Este método existe para mantener la firma unificada.
  } catch (_) {
    // ignore
  }
}