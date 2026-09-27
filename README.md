# 🛡️ PhishWarden MJ - Aplicación Móvil

Aplicación móvil orientada al usuario final. Actúa como el centro principal de alertas inmediatas ante interacciones con simulaciones de prueba, aula virtual de micro-capacitaciones interactivas (1 a 2 minutos) y centro de perfil personal gamificado.

---

## 🚀 Tecnologías y Herramientas

* **Framework Móvil:** Flutter (Dart)
* **Notificaciones Push:** Firebase Cloud Messaging (FCM)
* **Gestión de Estado:** Provider / Flutter Bloc
* **Plataformas Soportadas:** Android & iOS

---

## 💻 Características Principales

* **Recepción de Alertas Push:** Notificación instantánea tras hacer clic en un enlace de prueba.
* **Microlecciones Interactivas:** Contenido educativo de lectura rápida enfocado en los indicadores de peligro recibidos.
* **Evaluaciones (Quizzes):** Cuestionarios breves para validar la retención del aprendizaje.
* **Gamificación Integrada:** Visualización de nivel de riesgo personal, medallas/insignias obtenidas, racha de días seguros y tabla de posiciones (ranking).

---

## 👥 Integrantes Responsables

* **Jheral Jhosue Maquera Laque** — *Desarrollador Móvil y Especialista en QA*

---

## 🛠️ Instalación y Configuración Local

### Requisitos Previos
* Flutter SDK (v3.x o superior)
* Android Studio / Xcode (para emuladores y compilación)
* Dispositivo físico o emulador configurado

### Pasos
1. Clonar el repositorio:
   git clone https://github.com/Ing-Web-Esis/phishwarden-mobile
   cd phishwarden-mobile

2. Obtener las dependencias del proyecto:
   flutter pub get

3. Configurar los archivos de Firebase:
   * Colocar `google-services.json` dentro de `android/app/`
   * Colocar `GoogleService-Info.plist` dentro de `ios/Runner/`

4. Ejecutar la aplicación:
   flutter run


## 🔒 Políticas de Ramas y Contribución

* `main`: Solo recibe cambios desde `develop` mediante Pull Requests aprobados y probados.
* `develop`: Rama base de integración diaria.
* `feature/*`: Ramas individuales para cada tarea (ej. `feature/login-jwt`).
* **Regla de Oro:** Prohibido hacer `git push` directo a `main` o `develop`.