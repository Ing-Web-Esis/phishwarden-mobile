# Paso 3: ingreso del empleado con NestJS

> Esta guía documenta la integración del ingreso. En el paso 4, la pantalla posterior se reemplazó por **Mi perfil** y la salida está en **Ajustes → Cerrar sesión**. Consulta `PASO_04_PERFIL.md` para el recorrido actual.

## Qué se decidió y qué se comprobó

La app móvil ingresa con **código de empresa y correo de un empleado existente**. Tu compañero crea las cuentas en el backend. No se agregó un registro de empresa ni un alta de empleados dentro de la app.

El backend está en `../phishwarden-backend/phishwarden-backend-nj`. Se revisaron sus controladores, DTOs, caso de uso de login, repositorio Prisma y esquema. Se consultó la base de datos en modo lectura, sin modificar registros ni imprimir contraseñas o claves del archivo `.env`.

Se encontraron dos empresas y siete empleados. Para la prueba se verificó esta cuenta activa:

- Empresa: **TechCorp Perú**.
- Código: **SALA2026**.
- Correo: **mariano.silva@techcorp.com**.

El mismo repositorio Dart que usa la app ingresó correctamente con esta cuenta contra el servidor local. Un código inexistente devolvió `401`, y usar el código de otra empresa con ese empleado también fue rechazado.

El análisis y las quince pruebas de repositorios, formularios, navegación y microlección pasaron. También pasó la prueba de integración real en `emulator-5554` (Android 17/API 37): el formulario ingresó contra NestJS, **Salir** volvió al formulario y un código inválido fue rechazado. El APK de esa prueba compiló correctamente. Esta prueba no crea ni modifica cuentas.

Después de esa prueba se compiló e instaló la app normal desde `lib/main.dart`, se comprobó su inicio sin excepciones y se dejó abierta en el emulador.

## Contrato leído del backend

Ruta: `POST /auth/login`. No hay prefijo `/api` para esta ruta. `/api/docs` corresponde a Swagger.

```json
{
  "email": "mariano.silva@techcorp.com",
  "codigoEmpresa": "SALA2026"
}
```

La respuesta móvil exitosa tiene esta estructura; el ID mostrado es ilustrativo:

```json
{
  "message": "Validación por código de empresa exitosa",
  "empresa": "TechCorp Perú",
  "user": {
    "id": "UUID_DEL_EMPLEADO",
    "email": "mariano.silva@techcorp.com"
  }
}
```

NestJS devuelve `201` porque el controlador usa `@Post()` sin cambiar su código de respuesta. La app acepta respuestas entre `200` y `299`, pero también exige que incluyan un usuario identificado y una empresa. Un simple `{"message":"ok"}` no permite ingresar.

El backend tiene dos ramas dentro del mismo login. Si se envía `password`, valida al administrador mediante bcrypt; si se envía `codigoEmpresa`, valida al empleado. **Flutter envía únicamente correo y código**, para usar la rama móvil.

El registro `POST /empresas/register` crea empresa y administrador, no una cuenta de empleado móvil. El alta de empleados está en `POST /empresas/:empresaId/empleados`; tu compañero se encarga de ella. Un administrador recién registrado no puede ingresar como empleado a menos que también exista un registro de empleado correspondiente.

## Recorrido del código, explicado

1. **`welcome_screen.dart`** dibuja el formulario y recoge código y correo. La validación local evita campos vacíos o un correo con formato inválido. El botón normal ahora dice **Ingresar**.
2. La pantalla llama a **`WelcomeViewModel.submit()`**. El ViewModel activa `isLoading`, evita envíos duplicados y pide el ingreso al repositorio. No contiene HTTP ni consulta directamente a Supabase.
3. **`ApiAuthRepository.linkDevice()`** convierte los datos de Flutter al contrato real: `companyCode` se envía como `codigoEmpresa`. Limpia espacios del código y convierte el correo a minúsculas, como el alta de empleados del backend.
4. **`ApiClient.post()`** crea la solicitud HTTP con JSON, espera hasta quince segundos y procesa la respuesta. Decodifica UTF-8 para conservar tildes. Diferencia desconexión, espera agotada, rechazo y respuesta inesperada.
5. En NestJS, **`AuthController`** recibe el JSON y el DTO valida los campos. **`LoginUseCase`** busca la empresa por código y el empleado por correo e ID de empresa. **`PrismaAuthRepository`** ejecuta esas consultas en PostgreSQL.
6. Si el backend rechaza el ingreso, el repositorio lanza `LinkFailure`. El ViewModel coloca el mensaje en `errorMessage`, quita la carga y la pantalla permite reintentar.
7. Si la respuesta es válida, se crea un **`LinkResult`** con correo, ID y nombre de empresa. `isDemo` es `false`: estos datos provienen de NestJS.
8. **`app.dart`** abre **`AccessScreen`**, que muestra la empresa y el correo confirmados y permite abrir la práctica de notificaciones. **Salir** elimina las pantallas de acceso del recorrido y crea un formulario nuevo, vacío.

El nombre `linkDevice` se conservó para no cambiar toda la interfaz del paso 1. **Ese método no registra el dispositivo ni un token push**: en este paso valida el ingreso móvil.

## Archivos nuevos y modificados

| Archivo | Para qué sirve |
| --- | --- |
| `lib/core/network/api_config.dart` | Elige la URL del servidor. Permite cambiarla al ejecutar con `--dart-define=API_BASE_URL=...`. |
| `lib/core/network/api_client.dart` | Centraliza HTTP, JSON, límite de espera y errores. No conoce pantallas. En producción exige HTTPS. |
| `lib/features/auth/data/api_auth_repository.dart` | Implementa la interfaz de autenticación usando `/auth/login` y convierte el JSON a un resultado Dart. |
| `lib/features/auth/data/models/link_models.dart` | Agrega `userId` y `companyName` al resultado. No inventa un token de sesión. |
| `lib/features/auth/data/auth_repository.dart` | Conserva la interfaz que ya utilizaba el ViewModel y aclara el alcance del método. |
| `lib/features/auth/presentation/welcome_screen.dart` | Usa **Ingresar**, muestra errores y entrega el resultado exitoso a la app. Ya no presenta el aviso de simulación en el recorrido real. |
| `lib/features/auth/presentation/access_screen.dart` | Muestra el acceso confirmado, el botón de entrenamiento y **Salir**. No consulta la base ni hace HTTP. |
| `lib/app/app.dart` | Crea `ApiClient` y `ApiAuthRepository` como dependencias normales. Organiza navegación y libera el cliente HTTP al cerrar la app. |
| `lib/features/training/presentation/notification_practice_screen.dart` | Conserva la prueba local y retira el texto antiguo que decía que el ingreso era simulado. |
| `pubspec.yaml`, `pubspec.lock` | Declaran `http` y `integration_test` (esta última es solo para desarrollo). |
| `android/app/src/main/AndroidManifest.xml` | Agrega permiso de Internet también para compilaciones de lanzamiento. |
| `android/app/src/debug/AndroidManifest.xml` | Aplica la configuración de red de desarrollo. |
| `android/app/src/debug/res/xml/network_security_config.xml` | Permite HTTP únicamente hacia los destinos locales de prueba. Solo se incluye en debug; no desactiva HTTPS en producción. |
| `test/api_auth_repository_test.dart` | Prueba el contrato, 201, 401, errores 400/500, respuestas incompletas, desconexión y espera agotada. |
| `test/employee_login_test.dart` | Prueba acceso confirmado, salida y conservación del formulario ante un rechazo. Usa respuestas controladas, no la base real. |
| `integration_test/employee_login_test.dart` | Ejecuta el formulario en Android contra NestJS, sale y prueba un código inválido. Usa una cuenta existente; no crea empleados. |
| `tool/check_login.dart` | Permite probar el mismo repositorio Dart desde la terminal, antes de diagnosticar el celular. |

`MockAuthRepository` sigue disponible para las pruebas automáticas del paso 1. **La ejecución normal de la app ya no lo usa** y un fallo de red no se convierte en una sesión simulada.

## Cómo ejecutar y entender los comandos

### Terminal del backend

El backend ya estaba iniciado en el puerto `3000` al comprobarlo. No abras una segunda instancia si sigue funcionando: `EADDRINUSE` significa que el puerto está ocupado.

Si está detenido, abre una terminal en `phishwarden-backend/phishwarden-backend-nj`. Si cambiaron su código, compílalo primero:

```powershell
npm run build
node --env-file=.env dist/main.js
```

- `npm run build`: convierte TypeScript a JavaScript dentro de `dist/`.
- `node --env-file=.env dist/main.js`: carga la configuración de base de datos y puerto desde `.env` y ejecuta el servidor compilado. Deja esa terminal abierta. Este comando funciona con el Node 22 instalado en esta máquina.
- No copies `.env`, las claves de Supabase o la conexión PostgreSQL a Flutter. La app habla con NestJS, y NestJS habla con la base.
- Swagger se puede consultar en `http://localhost:3000/api/docs`.

### Terminal de Flutter

Desde la carpeta `phishwarden_movil`:

```powershell
$env:FLUTTER_WINDOWS = 'false'
flutter pub get
flutter devices
flutter run -d emulator-5554 --no-pub --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

- La primera línea omite la preparación del destino de escritorio Windows en esta terminal. Evita el problema de enlaces de plugins que vimos en el paso 2. No cambia la configuración global. Cierra la terminal o ejecuta `Remove-Item Env:FLUTTER_WINDOWS` para restaurarlo.
- `flutter pub get` descarga dependencias y prepara los plugins. Debe terminar sin errores.
- `flutter devices` muestra los identificadores disponibles. Si el emulador no aparece, inicia `Medium_Phone_API_37.0` desde Android Studio o con `flutter emulators --launch Medium_Phone_API_37.0`.
- `flutter run` compila, instala y abre la app en el Android indicado.
- `--no-pub` usa las dependencias ya preparadas.
- `--dart-define=API_BASE_URL=...` configura el servidor durante la compilación. Después de cambiar esta opción vuelve a ejecutar la app; hot reload no cambia este valor.

**Por qué `10.0.2.2`:** `localhost` dentro del emulador corresponde al emulador. `10.0.2.2` apunta a tu PC, donde corre NestJS. La app ya usa esa dirección por defecto para Android; se escribe explícitamente aquí para que puedas entender y cambiar la conexión.

### Celular Android por USB

Para un celular físico usa el reenvío de puerto de Android en lugar de `10.0.2.2`:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s IDENTIFICADOR reverse tcp:3000 tcp:3000
flutter run -d IDENTIFICADOR --no-pub --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

Sustituye `IDENTIFICADOR` por el celular listado con `flutter devices`. El primer comando hace que el puerto `3000` del celular se comunique por USB con el puerto `3000` de tu PC. Debes mantener el backend iniciado y la depuración USB autorizada en el celular. Para retirar ese reenvío, usa el mismo comando `adb` con `reverse --remove tcp:3000`.

### Revisiones automáticas

```powershell
flutter analyze --no-pub
flutter test --no-pub
dart run tool/check_login.dart http://127.0.0.1:3000 SALA2026 mariano.silva@techcorp.com
```

- `flutter analyze` revisa tipos e instrucciones de estilo.
- `flutter test` ejecuta las pruebas en `test/`, sin necesitar servidor ni celular.
- `dart run tool/check_login.dart ...` consulta el backend real desde tu PC, usando el repositorio de la app. El primer argumento es la URL, el segundo el código y el tercero el correo. Un rechazo termina con código de salida `1`; un éxito con `0`.

La prueba completa de Android requiere servidor y emulador encendidos:

```powershell
flutter test integration_test/employee_login_test.dart -d emulator-5554 --no-pub --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=TEST_COMPANY_CODE=SALA2026 --dart-define=TEST_EMPLOYEE_EMAIL=mariano.silva@techcorp.com
```

Los valores `TEST_...` se usan únicamente por la prueba de integración. No se agregó esta cuenta como una credencial predeterminada del formulario.

## Tu prueba manual

1. Abre la app y usa el código y correo comprobados arriba.
2. Pulsa **Ingresar**. Debes ver **Acceso validado**, **TechCorp Perú** y el correo.
3. Pulsa **Salir**. Debe aparecer un formulario vacío.
4. Prueba un código inventado: debe indicar **Código de empresa o sala inválido** y permitir reintentar.
5. Usa `SALA2026` con un correo no registrado: debe rechazarlo.
6. Detén temporalmente tu backend y reintenta. La app debe mostrar el error de conexión, sin permitir el acceso. Reinicia el backend después.
7. Con el acceso válido, abre **Probar notificación y microlección**. Esta función sigue siendo local; la integración del login no convirtió el aviso en un push remoto.

## Límites reales del backend actual

### Incidencia comprobada el 13 de octubre: emulador y red

El emulador quedó abierto pero `offline`. Se cerró esa instancia y se recuperó mediante un arranque completo, sin cargar el estado guardado ni borrar los datos. Después Flutter detectó `emulator-5554`, compiló e inició la app correctamente.

Si vuelve a ocurrir, cierra el emulador y usa **Cold Boot** en el Device Manager de Android Studio. También puedes iniciarlo desde una terminal con:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Medium_Phone_API_37.0 -no-snapshot-load
```

Ese comando mantiene ocupada su terminal mientras el emulador está abierto. Ejecuta `flutter devices` y `flutter run` en otra terminal, después de que Android termine de iniciar. No intentes abrir una segunda instancia del mismo emulador.

En esta comprobación el backend no pudo arrancar: Prisma devolvió `P1001`. El nombre de la base configurada tenía un registro IPv6, y la prueba de conexión a los puertos 6543 y 5432 falló con `ENETUNREACH`. Los dominios públicos sí resolvían. Esto indica un problema de alcance IPv6 de esta red, independiente de Flutter.

Para usar esta red, el responsable del backend debe obtener la conexión **Session pooler** desde el panel **Connect** del proyecto Supabase y actualizar `DATABASE_URL` en el `.env` del backend con la conexión exacta del proyecto. No se modificó ese archivo durante el diagnóstico. El nombre de usuario del pooler y su host pueden diferir de la conexión directa; no basta cambiar el puerto. Después debe reiniciar el backend y comprobar que aparezca **Nest application successfully started**. La prueba de ingreso aprobada antes de esta incidencia sigue documentada arriba; el ingreso actual requiere resolver esta conexión.

Referencias: [arranque completo del emulador](https://developer.android.com/studio/run/emulator-commandline), [conexiones de Supabase e IPv4/IPv6](https://supabase.com/docs/guides/database/connecting-to-postgres).

### Alcance de la autenticación implementada

- Comprueba que correo y código correspondan a registros existentes. No verifica por correo que quien escribe sea el propietario de esa cuenta.
- El login actual **no emite JWT ni otro token**, no tiene renovación de sesión ni endpoint de cierre de sesión. La app conserva los datos de acceso solo mientras está abierta; **Salir** descarta ese acceso local y no revoca nada en el servidor. Al volver a iniciar la app se pide ingresar de nuevo.
- El repositorio de login no filtra el campo `estado` del empleado. La cuenta usada en la prueba está activa, pero el backend necesita aplicar esa regla si deben bloquearse cuentas inactivas.
- Los controladores revisados no tienen guardias de autenticación para las rutas administrativas. Mostrar **Acceso validado** no protege por sí mismo las demás rutas de la API.
- No se modificó el código del backend ni la base. Con tu compañero queda acordar cómo emitir y verificar la sesión y cómo proteger cada ruta antes de considerar completa la autenticación para producción.
- No se implementó persistencia del login, registro de token push ni guardado de resultados de entrenamiento.
- La excepción HTTP se limita a desarrollo local. Una compilación de producción debe usar una URL HTTPS con `API_BASE_URL`.

Para exponerlo puedes decir: **“La pantalla delega el estado al ViewModel; este llama a un repositorio HTTP. NestJS valida el empleado contra PostgreSQL y Flutter usa la respuesta para permitir el acceso. Las solicitudes no están dentro de los widgets. La sesión protegida con token es el siguiente acuerdo con el backend.”**

Referencias técnicas: [cliente HTTP de Dart](https://pub.dev/packages/http), [red del emulador Android](https://developer.android.com/studio/run/emulator-networking-address), [configuración de seguridad de red Android](https://developer.android.com/privacy-and-security/security-config).
