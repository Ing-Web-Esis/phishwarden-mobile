# Paso 4: Mi perfil en claro y oscuro

## Resultado de este paso

Se implementó la vista **03 · Perfil personal** a partir de los PNG claros y oscuros que proporcionaste. Después del ingreso real aparece **Mi perfil**, en lugar de la pantalla provisional **Acceso validado**.

Se conservan la paleta azul petróleo, dorado y blanco, las tarjetas con bordes redondeados, el avatar, riesgo, puntos, racha, simulaciones, microlección y medallas. La navegación inferior usa los nombres de tus imágenes: **Perfil, Capacitación y Ranking**.

No se copiaron los datos ficticios de Lucía Mora. El login de NestJS actualmente devuelve **correo, ID del empleado y nombre de empresa**, pero no su nombre personal, departamento ni estadísticas. Por eso el saludo es **Hola, bienvenido** y los datos pendientes muestran **—** o **Sin datos**. Un dato desconocido no equivale a cero ni a riesgo bajo.

## Qué puedes tocar ahora

- **Engranaje / Ajustes:** abre las opciones Claro, Oscuro y Sistema, más Cerrar sesión. Es un panel pequeño para este paso, no la pantalla completa de ajustes del mockup 12.
- **Microlección de práctica:** abre directamente la lección existente sobre phishing y permite responder su pregunta.
- **Capacitación:** abre la práctica existente de notificación Android. El centro de capacitación del mockup 05 se implementará en otro paso.
- **Cerrar sesión:** cierra el panel y vuelve al formulario vacío. El backend todavía no emite tokens ni tiene una ruta de revocación; es la salida local ya explicada en el paso 3.

**Ver historial**, **Ver logros** y **Ranking** están deshabilitados porque sus pantallas y contratos aún no están implementados. Las tres medallas muestran ejemplos de categorías del diseño, no medallas ganadas. No se agregó un total de microlecciones pendientes ni puntos o rachas ficticios.

## Archivos y responsabilidades

| Archivo | Qué hace |
| --- | --- |
| `lib/features/profile/data/profile_repository.dart` | Define `EmployeeProfile`, la interfaz `ProfileRepository` y `SessionProfileRepository`. Este último entrega únicamente los datos confirmados por el login. Las estadísticas permanecen en `null`. |
| `lib/features/profile/presentation/profile_view_model.dart` | Controla carga, perfil y errores. Permite reintentar, evita cargas duplicadas y no notifica después de cerrar la pantalla. |
| `lib/features/profile/presentation/profile_screen.dart` | Dibuja la pantalla, la barra inferior y el panel de apariencia. Escucha al ViewModel y recibe callbacks para navegar y cerrar sesión. No hace HTTP ni consultas a Supabase. |
| `lib/app/app.dart` | Después del ingreso crea `SessionProfileRepository` con el resultado y abre `ProfileScreen`. Centraliza la apertura de lecciones y conserva la navegación desde notificaciones. |
| `lib/core/theme/app_theme.dart` | Agrega el color de superficie de las tarjetas y los colores verde, amarillo y rojo de la leyenda de riesgo. Conserva los temas compartidos del proyecto. |
| `test/profile_screen_test.dart` | Comprueba identidad, ausencia de estadísticas inventadas, reintento, cambio de tema, botones y adaptación a una pantalla pequeña con texto al doble. También genera capturas para revisión visual con fuentes del SDK. |
| `test/employee_login_test.dart` | Se actualizó para esperar Mi perfil tras un login exitoso y salir mediante Ajustes → Cerrar sesión. |
| `integration_test/employee_login_test.dart` | Se actualizó el recorrido Android con NestJS para la nueva pantalla y su salida. |

`access_screen.dart` conserva el código anterior, pero ya no es la pantalla que abre el ingreso. El código HTTP y el contrato de login del paso 3 no cambiaron.

## Cómo entender el código

### Modelo y repositorio

`EmployeeProfile` describe los datos que la pantalla puede representar. Por ejemplo, `int? riskScore` permite un número o `null`. Aquí `null` significa **no disponible**.

`ProfileRepository` es una interfaz: define que un repositorio debe tener `Future<EmployeeProfile> load()`. La pantalla y el ViewModel no necesitan conocer de dónde vienen los datos.

`SessionProfileRepository` usa el resultado del login existente. No es una consulta nueva al servidor ni obtiene información directamente de PostgreSQL. Cuando tu compañero defina una ruta de perfil, se podrá crear un repositorio HTTP que implemente la misma interfaz y cambiarlo en `app.dart`.

### ViewModel

`ProfileViewModel.load()` establece `isLoading`, espera al repositorio y guarda el perfil o un error. `notifyListeners()` avisa a la interfaz y `ListenableBuilder` reconstruye lo necesario.

`dispose()` indica que la pantalla se cerró. Si una carga termina después, el ViewModel evita intentar notificar a una pantalla que ya no existe.

### Pantalla y widgets pequeños

`ProfileScreen` contiene el recorrido visual y se apoya en widgets privados:

- `_Identity`: avatar, saludo, empresa y correo. No deduce el nombre real a partir del correo.
- `_RiskCard`: score, categoría, barra y leyenda. Si falta el score, dibuja una barra neutra y la describe como no disponible para accesibilidad.
- `_MetricCard`: tarjetas de puntos y racha.
- `_SimulationCount`: cada contador de simulaciones.
- `_SectionTitle`: título de sección y acción aún deshabilitada.
- `_ProfileCard`: borde, fondo y espacio interior compartidos de las tarjetas.

El guion bajo indica que la clase o función es privada dentro del archivo Dart. Separar estas piezas permite modificar una tarjeta sin reescribir toda la pantalla.

La pantalla usa `SingleChildScrollView` para poder desplazarse. `Expanded` reparte el espacio disponible, `Wrap` permite varias líneas y `LayoutBuilder` cambia las tarjetas a una columna cuando falta espacio o el texto está ampliado. No se dibujan un reloj ni una batería falsos: Android muestra sus barras reales.

### Temas y navegación

La app mantiene el tema con `ValueNotifier<ThemeMode>`. Cuando eliges Claro, Oscuro o Sistema, cambia su valor. Un `ValueListenableBuilder` reconstruye `MaterialApp` con el tema elegido; otro actualiza la selección del panel de apariencia.

`onTraining`, `onLesson` y `onLogout` son callbacks: la pantalla comunica la acción y `app.dart` decide la navegación. Esto mantiene separados el diseño y la composición de la app.

## Prueba en tu Android

Deja iniciado el backend. Enciende el emulador y confirma su ID con `flutter devices`. Desde la raíz de `phishwarden_movil`:

```powershell
$env:FLUTTER_WINDOWS = 'false'
flutter run -d emulator-5554 --no-pub --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Este comando compila e instala la app normal. `--no-pub` reutiliza las dependencias preparadas y `API_BASE_URL` apunta al backend de la PC desde el emulador. El inicio de Android y el reenvío USB para un celular físico están explicados en la guía del paso 3.

1. Ingresa con el código y correo de un empleado existente. La cuenta comprobada en el paso 3 era `SALA2026` y `mariano.silva@techcorp.com`.
2. Debes ver **Mi perfil**, tu empresa y el correo que confirmó el servidor.
3. Abre el engranaje y alterna Claro y Oscuro. Cierra el panel tocando fuera o con Atrás.
4. Desplázate y comprueba las tarjetas y las medallas. Los datos pendientes deben seguir mostrando — o Sin datos.
5. Toca la tarjeta de microlección. Lee los consejos y responde la pregunta. Al volver, no se inventan puntos, riesgo ni medallas: el resultado aún no se guarda en el servidor.
6. Toca Capacitación para acceder a la prueba de notificación local que ya implementamos.
7. Abre Ajustes → Cerrar sesión. Debe volver el formulario vacío.

Los cambios de tema no se guardan en disco en este paso. Al reiniciar la app vuelve al modo Sistema. El nombre y departamento quedan pendientes del contrato, aunque estén presentes en tablas de la base: Flutter necesita una ruta que los entregue con la autorización correspondiente.

## Verificaciones y capturas

Resultado comprobado: análisis sin problemas, veinte pruebas automáticas aprobadas, APK de Android compilado y prueba de integración real en `emulator-5554` aprobada. El login de NestJS abrió **Mi perfil**, **Ajustes → Cerrar sesión** volvió al formulario y un código inválido fue rechazado. La microlección, los cambios de tema y la adaptación a texto ampliado se verificaron en las pruebas de widgets. No se modificó la base de datos.

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

El análisis revisa el código; las pruebas verifican comportamiento; la compilación genera el APK de Android. Las capturas de QA se generan en `build/qa/profile_light.png` y `build/qa/profile_dark.png`. Esas imágenes usan una identidad ficticia de prueba y no reemplazan el login real.

Para repetir el recorrido real de ingreso y salida en Android, con el servidor disponible:

```powershell
flutter test integration_test/employee_login_test.dart -d emulator-5554 --no-pub --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=TEST_COMPANY_CODE=SALA2026 --dart-define=TEST_EMPLOYEE_EMAIL=mariano.silva@techcorp.com
```

## Acuerdo siguiente con el backend

Falta acordar la ruta autorizada de perfil y su JSON: nombre y departamento, riesgo y categoría, puntos de aprendizaje, nivel, racha, contadores de simulaciones y medallas ganadas. La UI no calcula umbrales de riesgo ni fórmulas de niveles por su cuenta. Tampoco se asumió que el texto y los valores de los PNG sean requisitos exactos del PDF universitario.

El siguiente paso visual puede ser **05 · Centro de capacitación**, manteniendo el mismo criterio: botones funcionales y datos identificados como locales hasta tener el contrato real.
