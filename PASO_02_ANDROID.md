# Paso 2: notificación local y microlección en Android

> Esta guía documenta el paso 2 original, que usaba un ingreso simulado. La app ahora ingresa contra NestJS: usa las instrucciones y la cuenta comprobada de `PASO_03_LOGIN_REAL.md`. Los datos ficticios y el diálogo **Entendido** descritos aquí ya no pertenecen al recorrido normal.

## Punto de partida comprobado

En esta carpeta solo estaba instalado el paso 1. No estaban los archivos del ZIP Android ni la dependencia de notificaciones. El paso 2 se implementó directamente sobre el proyecto conservando la bienvenida, el repositorio de autenticación de prueba y los temas existentes.

Esta implementación prueba una notificación del sistema Android, generada por la propia app. No es una notificación push enviada desde NestJS. La lección y la evaluación de una pregunta son locales; al salir se pierde la respuesta. Tampoco se autentica al usuario ni se registra su dispositivo.

Verificación realizada: análisis sin problemas y ocho pruebas automáticas aprobadas. El APK corregido compiló e instaló en `emulator-5554`, con Android 17/API 37. En el primer APK se detectó `MissingPluginException` al iniciar: la preparación de plugins había quedado incompleta por el aviso de enlaces de Windows. Se corrigió omitiendo temporalmente el destino de escritorio Windows al preparar las dependencias, con el comando explicado abajo. La aparición y el toque de la notificación del sistema quedan pendientes de la prueba manual. Las pruebas automáticas verifican la navegación desde un ID recibido, no reemplazan esa prueba del sistema.

## Recorrido para probar

1. Inicia un emulador desde Android Studio, o conecta tu celular con depuración USB y acepta en el teléfono la autorización de tu computadora.
2. Ejecuta `flutter devices` desde la terminal de VS Code en esta carpeta. Debe aparecer un Android con su identificador.
3. Ejecuta los comandos de preparación de la sección siguiente y luego `flutter run -d IDENTIFICADOR --no-pub`, sustituyendo IDENTIFICADOR por el valor listado, por ejemplo `emulator-5554`. Este comando compila, instala y ejecuta la app en ese Android. `--no-pub` utiliza las dependencias ya descargadas y requiere que la preparación de plugins haya terminado correctamente.
4. Ingresa un código como `NOVA-2026` y un correo ficticio como `alumna@nova.example`. Pulsa **Vincular mi dispositivo**, lee el aviso de simulación y pulsa **Entendido**.
5. En **Prueba en Android**, pulsa **Mostrar notificación real** y permite las notificaciones cuando Android lo solicite.
6. Desliza desde la parte superior del teléfono para abrir la bandeja y toca **Tu microlección está lista**. Debe abrir **Reconoce un correo de phishing**.
7. Lee los consejos, selecciona una respuesta y pulsa **Comprobar respuesta**. La segunda opción es correcta. El texto explica el motivo; la respuesta queda bloqueada para esa sesión.
8. Repite la prueba colocando la app en segundo plano con Inicio antes de tocar el aviso.
9. Para probar el arranque sin proceso activo: genera otro aviso, sal con Inicio, retira la app de recientes y toca el aviso si permanece en la bandeja. No uses **Forzar detención**, que puede eliminar o bloquear el aviso.
10. Prueba negar el permiso. La pantalla debe indicar cómo activarlo en Ajustes. Si Android ya no vuelve a preguntar, activa el permiso manualmente y reintenta.
11. Cambia a tema oscuro desde la bienvenida y repite el recorrido. Las pantallas nuevas heredan el tema de `MaterialApp`.

El aviso puede aparecer en la bandeja sin una ventana emergente: depende de los ajustes del canal, del teléfono y de No molestar. El mensaje de la app indica que se solicitó mostrarlo; la comprobación visual se hace en Android.

## Qué hace cada archivo

| Archivo | Responsabilidad |
| --- | --- |
| `lib/main.dart` | Prepara Flutter antes de llamar al plugin, crea el servicio e inicializa las notificaciones. Después ejecuta la app. Si la inicialización falla, conserva la bienvenida y permite reintentar desde el botón. |
| `lib/app/app.dart` | Es el punto de composición: crea repositorios y servicio, aplica el tema y organiza la navegación. Escucha el ID pendiente y abre `LessonScreen` después de construir el `Navigator`. |
| `lib/features/auth/presentation/welcome_screen.dart` | Conserva validación y aviso de simulación. Al cerrar el aviso tras un resultado exitoso, llama a `onLinked`; la app decide qué pantalla abrir. |
| `lib/core/notifications/notification_service.dart` | Encapsula el plugin Android: inicializa, solicita permiso y muestra un aviso. El `payload` contiene el ID de lección. El callback atiende toques con la app viva; `getNotificationAppLaunchDetails` recupera el toque que inició la app. |
| `lib/features/training/presentation/notification_practice_view_model.dart` | Maneja carga, mensajes, rechazo del permiso y errores. Impide enviar dos veces mientras una operación está en curso. |
| `lib/features/training/presentation/notification_practice_screen.dart` | Dibuja las instrucciones y el botón. Observa el ViewModel con `ListenableBuilder`; no contiene llamadas al plugin ni HTTP. |
| `lib/features/training/data/lesson_repository.dart` | Define `Lesson`, la interfaz `LessonRepository` y un repositorio local con la lección `phishing-email`. Un ID desconocido devuelve `null`. |
| `lib/features/training/presentation/lesson_view_model.dart` | Carga la lección, registra la selección en memoria y compara el índice seleccionado con `correctAnswer`. Los índices comienzan en cero: `1` corresponde a la segunda opción. |
| `lib/features/training/presentation/lesson_screen.dart` | Dibuja consejos, pregunta, opciones y explicación. Delega selección y evaluación al ViewModel. Usa una lista desplazable para celulares pequeños. |
| `pubspec.yaml` y `pubspec.lock` | Declaran y fijan las dependencias. Se agregó `flutter_local_notifications` 22.3.1. |
| `android/app/build.gradle.kts` | Habilita desugaring y agrega `desugar_jdk_libs` 2.1.4: adaptación de APIs Java para Android. Mantiene Java 17 y establece Android 7/API 24 como mínimo para esta versión del plugin. |
| `android/settings.gradle.kts` | Se revisó: ya usa Android Gradle Plugin 9.1.0; no necesitó cambios. |
| `android/app/src/main/AndroidManifest.xml` | Declara el permiso de notificaciones y el nombre visible PhishWarden MJ. Declarar el permiso no equivale a que el usuario lo conceda. |
| `android/app/src/main/res/drawable/ic_notification.xml` | Icono blanco con fondo transparente para la barra de notificaciones. |
| `android/app/src/main/res/raw/keep.xml` | Conserva ese icono cuando Android optimiza los recursos de una compilación de lanzamiento. |
| `test/notification_lesson_test.dart` | Verifica la navegación con IDs al arrancar y durante uso, ID desconocido y evaluación. Estas pruebas de widgets no prueban el permiso ni el toque real del sistema Android. |

## Conceptos que puedes explicar en clase

`Future` representa una operación que terminará después. `async` y `await` permiten esperar su resultado sin bloquear la interfaz. `ChangeNotifier` avisa cambios de estado y `ListenableBuilder` reconstruye la interfaz al recibirlos.

Un `Widget` describe la interfaz. El ViewModel mantiene el estado y las acciones; el repositorio obtiene los datos. El servicio de notificaciones es el adaptador al sistema operativo. Esta separación mantiene el MVVM sencillo y Repository del paso 1.

El ID viaja así: botón → servicio → notificación Android con `payload: phishing-email` → toque del aviso → ID pendiente → navegación de la app → repositorio → lección. La notificación no contiene las respuestas ni credenciales.

No se agrega HTTP en las pantallas. Cuando llegue el backend, se podrá crear una implementación de `LessonRepository` que consulte la API, e inyectarla en `app.dart`. La respuesta correcta se expone localmente para esta práctica; una evaluación real deberá decidir con el backend cómo validar y guardar resultados.

## Comandos y su propósito

Ejecuta los comandos desde la raíz del proyecto. No hace falta ejecutarlos todos cada vez.

```powershell
$env:FLUTTER_WINDOWS = 'false'
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter emulators
flutter emulators --launch Medium_Phone_API_37.0
flutter devices
flutter run -d emulator-5554 --no-pub
```

- `$env:FLUTTER_WINDOWS = 'false'`: omite el destino de escritorio Windows en esa terminal; Android y Edge siguen disponibles. Evita que la preparación de plugins Windows requiera enlaces simbólicos cuando estamos trabajando en Android. No cambia las preferencias globales de Flutter ni la configuración de seguridad de Windows. Para restaurar el comportamiento normal, cierra la terminal o ejecuta `Remove-Item Env:FLUTTER_WINDOWS`.
- `flutter pub get`: descarga las dependencias y prepara los registros de plugins. Debe terminar correctamente antes de compilar con `--no-pub`. Si se ejecuta sin la variable anterior, esta máquina muestra un aviso de enlaces simbólicos para plugins Windows. Para trabajar también con el destino Windows, habilita manualmente **Modo de desarrollador** en Configuración de Windows. No es un error de Dart.
- `flutter analyze --no-pub`: revisa tipos, imports y reglas de estilo, sin volver a resolver dependencias.
- `flutter test --no-pub`: ejecuta las pruebas automáticas, sin necesidad de celular.
- `flutter emulators`: lista los emuladores configurados.
- `flutter emulators --launch Medium_Phone_API_37.0`: inicia el emulador existente. Espera a que termine de arrancar.
- `flutter devices`: muestra destinos conectados. `offline` significa que Android todavía no está disponible para instalar la app.
- `flutter run -d emulator-5554 --no-pub`: ejecuta en ese destino; verifica su ID con `flutter devices`.

Para obtener un instalador de depuración:

```powershell
flutter build apk --debug --no-pub
```

El APK se genera en `build/app/outputs/flutter-apk/app-debug.apk`. Un APK debug es para desarrollo; la firma de producción aún está pendiente. Tras agregar plugins o cambiar Gradle, usa una ejecución completa: hot reload no aplica cambios nativos.

## Pendiente de integración con tu compañero

- Acordar si `phishing-email` será el ID aceptado por la API o sustituirlo por el ID definitivo.
- Login, verificación de empresa/correo y sesión real.
- Proveedor push, registro y renovación del token del dispositivo y envío desde NestJS.
- Rutas, JSON y errores para cargar lecciones y enviar respuestas.
- Persistencia de historial, riesgo, recompensas y ranking.
- Control de sesión al abrir una lección desde un push en producción. En este paso el contenido es público y local; la navegación directa no representa autorización de acceso a una API.

La duración de lectura es orientativa; no se implementó un temporizador. No se afirmó que el contenido local o esta pantalla de práctica sean requisitos textuales de la evaluación ni una reproducción exacta de Figma.

Referencia técnica utilizada: https://pub.dev/packages/flutter_local_notifications/versions/22.3.1
