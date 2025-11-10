# Mental Wellness App 🧠💙

Aplicación móvil de bienestar emocional desarrollada con Flutter que utiliza inteligencia artificial (Google Gemini) para analizar el estado emocional de los usuarios y proporcionar apoyo personalizado.

## 📋 Descripción

Mental Wellness App es una aplicación integral de salud mental que permite a los usuarios:
- Analizar sus emociones a través de texto o voz
- Mantener un historial de su estado emocional con gráficas de evolución
- Chatear con un asistente de IA especializado en bienestar emocional
- Acceder a recursos de salud mental cercanos mediante mapas interactivos
- Compartir experiencias en una comunidad de apoyo
- Guardar contactos de emergencia (SOS)
- Recibir recomendaciones personalizadas basadas en su estado emocional

## ✨ Características Principales

- **Análisis de Emociones con IA**: Utiliza Google Gemini para analizar texto y detectar emociones, niveles de severidad y proporcionar consejos personalizados
- **Modo Offline**: Sistema de fallback heurístico cuando no hay conexión a internet
- **Chat Inteligente**: Conversaciones con IA especializada en salud mental
- **Historial Visual**: Gráficas de evolución emocional usando fl_chart
- **Reconocimiento de Voz**: Análisis de emociones mediante speech-to-text
- **Mapa de Recursos**: Localización de centros de salud mental cercanos
- **Comunidad**: Sistema de publicaciones para compartir experiencias
- **SOS**: Contactos de emergencia de fácil acceso
- **Autenticación Segura**: Sistema completo de auth con Supabase

## 🛠️ Tecnologías Utilizadas

- **Frontend**: Flutter 3.3.0+ (Dart)
- **Backend**: Supabase (PostgreSQL, Auth, Realtime)
- **IA**: Google Generative AI (Gemini 2.0 Flash)
- **Estado**: Riverpod
- **Navegación**: GoRouter
- **Gráficas**: FL Chart
- **Mapas**: Flutter Map + Geolocator
- **Voz**: Speech to Text

## 📦 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versión 3.3.0 o superior)
- [Dart SDK](https://dart.dev/get-dart) (incluido con Flutter)
- Un editor de código (VS Code, Android Studio, IntelliJ IDEA)
- Git
- Una cuenta en [Supabase](https://supabase.com)
- Una API key de [Google AI Studio](https://aistudio.google.com/app/apikey) para Gemini

### Para desarrollo móvil:
- **Android**: Android Studio con SDK de Android
- **iOS**: Xcode (solo en macOS)

## 🗄️ Configuración de Supabase

### 1. Crear un proyecto en Supabase

1. Ve a [Supabase](https://supabase.com) y crea una cuenta
2. Crea un nuevo proyecto
3. Anota la URL del proyecto y la clave anónima (las necesitarás más adelante)

### 2. Ejecutar el siguiente SQL en el Editor SQL de Supabase

En el panel de Supabase, ve a **SQL Editor** y ejecuta el siguiente script para crear todas las tablas necesarias:

```sql
Esta en la raiz del proyecto "supabase.sql".

### 3. Verificar la configuración

Después de ejecutar el SQL, verifica que todas las tablas se hayan creado correctamente en la sección **Table Editor** de Supabase:

- empathy_topic_rules
- empathy_logs
- messages
- emotion_entries
- empathy_prompts
- sos_contacts
- profiles
- posts

## 🚀 Instalación y Configuración

### 1. Clonar el repositorio

```bash
git clone https://github.com/LUISDACA/mental_wellness_app.git
cd mental_wellness_app
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar variables de entorno

Crea un archivo `.env` en la raíz del proyecto con las siguientes variables:

```env
SUPABASE_URL=tu_url_de_supabase
SUPABASE_ANON_KEY=tu_clave_anonima_de_supabase
GEMINI_API_KEY=tu_api_key_de_gemini
GEMINI_MODEL=gemini-2.0-flash
OFFLINE_MODE=false
DEFAULT_SOS_LABEL=Emergency
```

**Importante**:
- Nunca commitees el archivo `.env` al repositorio
- Ya está incluido en `.gitignore`
- Obtén tu API key de Gemini en: https://aistudio.google.com/app/apikey

### 4. Verificar la instalación de Flutter

```bash
flutter doctor
```

Asegúrate de que todos los componentes necesarios estén instalados correctamente.

## 🎮 Cómo Ejecutar el Proyecto

### Ejecutar en plataformas específicas

```bash
# Android
flutter run -d android --dart-define-from-file=.env

# iOS (solo macOS)
flutter run -d ios --dart-define-from-file=.env

# Web
flutter flutter run -d chrome --dart-define-from-file=.env

## 📁 Estructura del Proyecto

```
lib/
├── core/                      # Configuración y utilidades globales
│   ├── constants.dart         # Constantes de la aplicación
│   ├── env.dart              # Variables de entorno
│   ├── theme.dart            # Tema de la aplicación
│   ├── logger.dart           # Sistema de logging
│   ├── errors.dart           # Manejo de errores
│   └── error_handler.dart    # Handler global de errores
│
├── domain/                   # Modelos de dominio
│   └── models/
│       ├── emotion_entry.dart
│       ├── chat_message.dart
│       ├── user_profile.dart
│       ├── sos_contact.dart
│       ├── post.dart
│       ├── place.dart
│       └── recommendation.dart
│
├── data/                     # Capa de datos
│   ├── services/            # Servicios externos
│   │   ├── supabase_client.dart
│   │   ├── health_service.dart
│   │   ├── profile_service.dart
│   │   ├── post_service.dart
│   │   ├── places_service.dart
│   │   ├── recommendation_service.dart
│   │   └── speech_service.dart
│   │
│   ├── repositories/        # Repositorios de datos
│   │   ├── auth_repository.dart
│   │   ├── emotion_repository.dart
│   │   ├── chat_repository.dart
│   │   └── sos_repository.dart
│   │
│   └── gemini/             # Módulo de IA
│       ├── gemini_service.dart
│       ├── gemini_client.dart
│       ├── prompt_repository.dart
│       ├── topic_filter.dart
│       ├── interaction_logger.dart
│       ├── heuristic_analyzer.dart
│       ├── emotion_result.dart
│       └── topic_rule.dart
│
├── presentation/            # Capa de presentación
│   ├── screens/
│   │   ├── welcome/        # Pantalla de bienvenida
│   │   ├── auth/           # Autenticación
│   │   ├── home/           # Dashboard principal
│   │   ├── analyze/        # Análisis de emociones
│   │   ├── history/        # Historial con gráficas
│   │   ├── chat/           # Chat con IA
│   │   ├── sos/            # Contactos de emergencia
│   │   ├── map/            # Mapa de recursos
│   │   ├── posts/          # Comunidad
│   │   └── profile/        # Perfil de usuario
│   │
│   ├── widgets/            # Widgets reutilizables
│   │   └── status_banner.dart
│   │
│   ├── routes.dart         # Configuración de rutas
│   └── app.dart           # Widget principal de la app
│
└── main.dart              # Punto de entrada
```

## 🔑 Funcionalidades Principales

### 1. Análisis de Emociones
- Entrada de texto manual o por voz
- Detección de emociones usando Gemini AI
- Clasificación de severidad (0-10)
- Consejos personalizados
- Modo offline con análisis heurístico

### 2. Chat con IA
- Conversaciones naturales con asistente de salud mental
- Contexto de historial de mensajes
- Detección de crisis con respuestas especializadas
- Filtrado de temas fuera de alcance

### 3. Historial y Estadísticas
- Visualización de entradas emocionales pasadas
- Gráficas de evolución temporal
- Análisis de tendencias

### 4. Recursos y Ayuda
- Mapa interactivo de centros de salud mental
- Geolocalización de servicios cercanos
- Contactos SOS de fácil acceso

### 5. Comunidad
- Publicaciones de experiencias
- Apoyo entre usuarios
- Sistema de likes e interacciones

## 🏗️ Arquitectura

La aplicación sigue una **arquitectura por capas** (Layered Architecture):

- **Capa de Presentación**: UI y widgets de Flutter
- **Capa de Dominio**: Modelos de negocio
- **Capa de Datos**: Servicios, repositorios y lógica de datos
- **Capa Core**: Configuración, constantes y utilidades

### Flujo de Análisis de IA:

1. Usuario ingresa texto
2. Se verifica contra `topic_rules` (emocional vs fuera de alcance)
3. Si es emocional + online → Gemini AI con prompts de BD
4. Si Gemini falla o modo offline → Análisis heurístico
5. Resultado se guarda en `emotion_entries`
6. Interacción se registra en `gemini_interactions`

## 🧪 Testing

```bash
# Ejecutar todos los tests
flutter test

# Ejecutar tests con cobertura
flutter test --coverage

# Análisis estático
flutter analyze
```

## 🔒 Seguridad

- **RLS (Row Level Security)**: Habilitado en todas las tablas de Supabase
- **Variables de entorno**: Nunca se commitean al repositorio
- **Autenticación**: Manejo seguro de sesiones con Supabase Auth
- **Validación de datos**: En cliente y servidor
- **API Keys**: No expuestas en el código cliente

## 🛠️ Herramientas de Desarrollo

```bash
# Hot reload durante desarrollo
r

# Hot restart
R

# Limpiar proyecto
flutter clean

# Actualizar dependencias
flutter pub upgrade

# Ver logs
flutter logs
```

## 📱 Plataformas Soportadas

- ✅ Android (API 21+)
- ✅ iOS (iOS 12+)
- ✅ Web
- ✅ Windows
- ✅ Linux
- ✅ macOS

## 🐛 Solución de Problemas

### Error: "Supabase URL not found"
- Verifica que el archivo `.env` exista y tenga las variables correctas
- Asegúrate de haber ejecutado `flutter pub get`

### Error: "Gemini API key invalid"
- Verifica tu API key en Google AI Studio
- Asegúrate de que la variable `GEMINI_API_KEY` esté correctamente configurada

### Error de compilación en iOS
- Ejecuta `cd ios && pod install`
- Abre el workspace en Xcode y verifica la configuración

### Error de permisos en Android
- Verifica que los permisos estén declarados en `AndroidManifest.xml`
- Acepta los permisos cuando la app los solicite

## 📄 Licencia

Este proyecto está bajo la licencia [MIT](LICENSE).

## 👥 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Haz un fork del proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commitea tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📞 Contacto

Para preguntas o soporte, por favor abre un issue en el repositorio.

---

**Nota**: Esta aplicación es una herramienta de apoyo emocional y NO sustituye la atención profesional de salud mental. Si estás en crisis, por favor contacta a servicios de emergencia o líneas de ayuda especializadas.
