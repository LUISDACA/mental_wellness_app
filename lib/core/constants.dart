// Application-wide constants for the Mental Wellness App

/* Removed duplicate AppConstants definition; unified below */
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ============================================================================
  // EMOTIONS
  // ============================================================================

  /// Valid emotion types recognized by the system
  static const String emotionHappiness = 'happiness';
  static const String emotionSadness = 'sadness';
  static const String emotionAnxiety = 'anxiety';
  static const String emotionAnger = 'anger';
  static const String emotionNeutral = 'neutral';

  /// List of all valid emotions
  static const List<String> validEmotions = [
    emotionHappiness,
    emotionSadness,
    emotionAnxiety,
    emotionAnger,
    emotionNeutral,
  ];

  // ============================================================================
  // VALIDATION RANGES
  // ============================================================================

  /// Minimum score value (0.0 = no confidence)
  static const double scoreMin = 0.0;

  /// Maximum score value (1.0 = full confidence)
  static const double scoreMax = 1.0;

  /// Minimum severity level (0 = very mild)
  static const int severityMin = 0;

  /// Maximum severity level (100 = critical)
  static const int severityMax = 100;

  // ============================================================================
  // LOCATION SERVICES
  // ============================================================================

  /// Default search radius in meters for finding nearby places
  static const double defaultSearchRadiusMeters = 2000.0;
  /// Same radius as integer for components that require int
  static const int defaultSearchRadiusMetersInt = 2000;

  /// Maximum number of places to return in search results
  static const int maxPlacesResults = 20;
  /// Maximum number of places to return in Overpass queries
  static const int maxPlacesLimit = 80;

  /// Overpass public endpoints with CORS enabled
  static const List<String> overpassEndpoints = <String>[
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.ru/api/interpreter',
  ];

  /// Network timeout for external requests
  static const Duration networkTimeout = Duration(seconds: 25);

  /// OSRM routing base (public demo server)
  static const String osrmRouteBase =
      'https://router.project-osrm.org/route/v1';

  /// Google Maps base for directions
  static const String googleMapsDirBase =
      'https://www.google.com/maps/dir/?api=1';

  // ============================================================================
  // STORAGE
  // ============================================================================

  /// Supabase storage bucket name for post media (images, PDFs)
  static const String postMediaBucket = 'post_media';

  /// Supabase storage bucket name for user avatars
  static const String avatarsBucket = 'avatars';

  // ============================================================================
  // FILE UPLOAD LIMITS
  // ============================================================================

  /// Maximum file size in bytes (10MB)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Maximum file size in megabytes (for display)
  static const int maxFileSizeMB = 10;

  /// Allowed image file extensions
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  /// Allowed document file extensions
  static const List<String> allowedDocumentExtensions = ['pdf'];

  // ============================================================================
  // EMERGENCY CONTACTS
  // ============================================================================

  /// Emergency phone number for Spain
  static const String emergencyNumberSpain = '112';

  /// Emergency phone number for United States
  static const String emergencyNumberUS = '911';

  /// International suicide prevention hotline
  static const String suicidePreventionHotline = '1-800-273-8255';

  // ============================================================================
  // CRISIS DETECTION
  // ============================================================================

  /// Keywords that trigger crisis detection (Spanish)
  static const List<String> crisisKeywords = [
    'suicid',
    'matarme',
    'quitarme la vida',
    'quiero morir',
    'no quiero vivir',
  ];

  /// Severity threshold for crisis situations
  static const int crisisSeverityThreshold = 90;

  // ============================================================================
  // AI MODELS
  // ============================================================================

  /// Fallback models to try if primary model fails
  static const List<String> geminiModelFallbacks = [
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
  ];

  /// Maximum tokens for emotion analysis responses
  static const int emotionAnalysisMaxTokens = 256;

  /// Maximum tokens for chat responses
  static const int chatMaxTokens = 512;

  /// Temperature for emotion analysis (lower = more deterministic)
  static const double emotionAnalysisTemperature = 0.2;

  /// Temperature for chat (higher = more creative)
  static const double chatTemperature = 0.7;

  // ============================================================================
  // DATABASE
  // ============================================================================

  /// Maximum number of emotion entries to fetch at once
  static const int maxEmotionEntriesLimit = 50;

  /// Avatar URL cache duration in minutes
  static const int avatarUrlCacheDurationMinutes = 30;

  // ============================================================================
  // MEDIA TYPES
  // ============================================================================

  /// Media type identifier for images
  static const String mediaTypeImage = 'image';

  /// Media type identifier for PDFs
  static const String mediaTypePdf = 'pdf';

  // ============================================================================
  // CONTENT TYPES
  // ============================================================================

  /// Content type for JPEG images
  static const String contentTypeJpeg = 'image/jpeg';

  /// Content type for PNG images
  static const String contentTypePng = 'image/png';

  /// Content type for GIF images
  static const String contentTypeGif = 'image/gif';

  /// Content type for WebP images
  static const String contentTypeWebp = 'image/webp';

  /// Content type for PDF documents
  static const String contentTypePdf = 'application/pdf';

  /// Default content type for unknown files
  static const String contentTypeOctetStream = 'application/octet-stream';

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================

  /// Error message when user is not authenticated
  static const String errorNoSession = 'No hay sesión activa. Por favor inicia sesión.';

  /// Error message when file is too large
  static String errorFileTooLarge(double actualSizeMB) =>
      'El archivo es demasiado grande. Tamaño: ${actualSizeMB.toStringAsFixed(2)}MB. Máximo: ${maxFileSizeMB}MB';

  /// Error message for invalid file type
  static const String errorInvalidFileType =
      'Solo se admiten imágenes (JPG, PNG, GIF, WebP) o documentos PDF';

  /// Error message when text input is empty
  static const String errorEmptyText = 'El texto es obligatorio';

  /// Error message when file cannot be read
  static const String errorFileReadFailed = 'No se pudo leer el archivo';

  /// Error message for unexpected Supabase response
  static const String errorUnexpectedResponse = 'Respuesta inesperada del servidor';

  /// Generic network error message
  static const String errorNetwork = 'Error de red. Verifica tu conexión.';

  /// Generic unexpected error message
  static const String errorUnexpected = 'Ocurrió un error inesperado.';

  /// Error message when Gemini API key is missing
  static const String errorMissingGeminiKey =
      'GEMINI_API_KEY no configurada. Agrégala al archivo .env y ejecuta con --dart-define-from-file=.env';

  /// Error message when no Gemini models are available
  static const String errorNoGeminiModels =
      'No hay modelos de Gemini disponibles con esta API key. Verifica tu clave de Google AI Studio.';

  // ============================================================================
  // SUCCESS MESSAGES
  // ============================================================================

  /// Success message after creating a post
  static const String successPostCreated = 'Publicación creada exitosamente';

  /// Success message after updating a post
  static const String successPostUpdated = 'Publicación actualizada';

  /// Success message after deleting a post
  static const String successPostDeleted = 'Publicación eliminada';

  /// Success message after adding SOS contact
  static const String successSosContactAdded = 'Contacto de emergencia agregado';

  /// Success message after updating SOS contact
  static const String successSosContactUpdated = 'Contacto de emergencia actualizado';

  /// Success message after deleting SOS contact
  static const String successSosContactDeleted = 'Contacto de emergencia eliminado';
}
