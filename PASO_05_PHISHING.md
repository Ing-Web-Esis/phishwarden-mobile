# Paso 5: capacitación y quiz de phishing

Se implementó el recorrido de los mockups 05 (centro), 06 (microlección), 08 (quiz) y 09 (resultado), con temas claro y oscuro. Se conservan la paleta azul petróleo y dorado, las tarjetas redondeadas, el correo educativo con tres señales y la selección destacada de respuestas.

## Recorrido

1. Ingresar con una cuenta de colaborador.
2. Abrir **Capacitación**. El listado distingue pendientes, disponibles y completadas; permite filtrar y deslizar hacia abajo para recargar.
3. Abrir una lección. Para phishing se presenta un correo ficticio con remitente, urgencia y dominio sospechosos. Los dominios `.example` son texto educativo, sin navegación. El material que entrega el servidor se presenta como texto seleccionable.
4. Pulsar **Ir al quiz de refuerzo**. Las preguntas y alternativas vienen del backend; no se incluye la respuesta correcta en Flutter. Se admite más de una pregunta y se puede retroceder o repasar la lectura conservando las respuestas.
5. Completar todas las preguntas y comprobar. Mientras se envían las respuestas se bloquean los cambios y el doble envío. Si falla la conexión, se conserva la selección y se permite reintentar.
6. Ver el resultado con aciertos, puntos, riesgo y nuevas medallas devueltos por el servidor. Si no aprueba, puede repasar e intentar de nuevo. **Volver a mi perfil** selecciona Perfil y cierra el recorrido.

La tarjeta del perfil abre el ID de la lección que muestra, en lugar de la práctica local fija. Una evaluación confirmada solicita recargar perfil, ranking y catálogo. Los valores de demostración de los mockups no se usan como métricas reales ni recompensas.

## Contratos existentes usados

| Operación | Ruta | Datos |
| --- | --- | --- |
| Catálogo | `GET /mobile/lecciones` | `asignadasPendientes`, `catalogoDisponible`, `completadas` |
| Lectura y preguntas | `GET /mobile/lecciones/:id` | Título, método, duración, contenido y preguntas A–D |
| Evaluar | `POST /mobile/lecciones/:id/evaluar` | `respuestas: [{ preguntaId, respuestaSeleccionada }]` |

Todas las solicitudes llevan el JWT de colaborador. Se reutiliza `ApiClient`. No se modificó el backend ni se agregaron dependencias.

## Organización

- `training_repository.dart`: modelos y repositorio HTTP del contrato móvil.
- `training_screen.dart`: catálogo, filtros y recarga.
- `training_lesson_view_model.dart`: carga, selección, envío y errores.
- `training_lesson_screen.dart`: lectura y preguntas por pasos.
- `training_result_screen.dart`: resultado confirmado por el servidor.
- `training_widgets.dart`: encabezados, tarjetas y error con reintento compartidos.
- `test/training_test.dart`: contrato HTTP, errores, doble envío, navegación, varias preguntas y adaptación visual.

Las lecciones de smishing usan el mismo flujo con un ejemplo de SMS. Para otros métodos se presenta el contenido del servidor, sin sustituirlo por un correo de phishing.

## Límites de este paso

La recepción de notificaciones FCM aún no está integrada. El adaptador existente sigue siendo de notificaciones locales. Se admite un ID numérico de lección en ese adaptador: si llega antes del ingreso, el destino se abre después de autenticarse. La práctica local anterior permanece separada para sus pruebas y demostraciones.

El campo `contenidoMultimedia` se muestra como texto seleccionable; este paso no incorpora un reproductor de video, navegador ni intérprete HTML. El contenido educativo fijo complementa los datos del servidor y no pretende reproducir un correo real recibido por el usuario.

## Verificación

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

Las pruebas visuales generan capturas en `build/qa/phishing_lesson_light.png`, `phishing_lesson_dark.png`, `phishing_quiz_light.png`, `phishing_quiz_dark.png`, `phishing_result_light.png` y `phishing_result_dark.png`, con datos de prueba.

Verificación del 24/11/2026: 34 pruebas aprobadas (10 nuevas) ejecutadas directamente con `flutter_tester` y el servicio VM desactivado. Se usó ese recorrido porque el entorno de ejecución bloquea el socket local del comando habitual `flutter test`. Se revisaron capturas claras y oscuras. Las pruebas HTTP usan respuestas simuladas con el contrato del backend; no se ejecutó una evaluación contra la base de datos real ni se compiló un APK en este paso.
