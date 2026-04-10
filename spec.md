# device_volume spec

## Resumen

device_volume sera un paquete Flutter para pub.dev orientado a exponer control de volumen del dispositivo mediante una API Dart uniforme y una implementacion nativa por plataforma. La solucion combinara FFI, FFIgen y JNIgen segun el backend definido para cada sistema operativo.

El paquete debe ofrecer operaciones sincronas para lectura y escritura de volumen, mas homologos Compute para ejecutar las operaciones en un isolate auxiliar cuando el consumidor prefiera no ocupar el isolate principal.

## Objetivos

- Exponer una API publica simple con `setVolume`, `incrementVolume`, `decrementVolume`, `getVolume` y `streamVolume`.
- Mantener una interfaz Dart estable aunque el backend cambie por plataforma.
- Usar `JNIgen` exclusivamente en Android para integrarse con `AudioManager` y observacion de cambios.
- Usar `FFIgen` en iOS, macOS, Windows y Linux para generar bindings de las funciones C exportadas por los shims nativos.
- Preparar el paquete para publicacion en pub.dev con metadatos, ejemplo funcional, documentacion y pipeline de validacion/publicacion.

## No objetivos

- No se implementara mezcla de audio por aplicacion de terceros.
- No se garantizara paridad total entre plataformas cuando el sistema operativo no ofrezca API publica equivalente.
- No se soportaran operaciones largas mediante `compute` para flujos continuos; los streams tendran un backend dedicado.

## API publica propuesta

### Tipos principales

```dart
enum VolumeChannel {
  media,
  ring,
  alarm,
  notification,
  voiceCall,
  system,
}

class VolumeState {
  final int value;
  final int min;
  final int max;
  final double normalized;
  final bool isMuted;
  final VolumeChannel channel;

  const VolumeState({
    required this.value,
    required this.min,
    required this.max,
    required this.normalized,
    required this.isMuted,
    required this.channel,
  });
}
```

### Fachada principal

```dart
abstract final class DeviceVolume {
  static VolumeState getVolume({VolumeChannel channel = VolumeChannel.media});

  static VolumeState setVolume(
    int value, {
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  });

  static VolumeState incrementVolume({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  });

  static VolumeState decrementVolume({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  });

  static Future<VolumeState> getVolumeCompute({
    VolumeChannel channel = VolumeChannel.media,
  });

  static Future<VolumeState> setVolumeCompute(
    int value, {
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  });

  static Future<VolumeState> incrementVolumeCompute({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  });

  static Future<VolumeState> decrementVolumeCompute({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  });

  static Stream<VolumeState> get streamVolume;
}
```

## Decision tecnica importante

`compute` solo aplica bien a operaciones de ida y vuelta con una unica respuesta. Por eso el requisito de homologo Compute se aplicara a `getVolume`, `setVolume`, `incrementVolume` y `decrementVolume`.

`streamVolume` no tendra variante `streamVolumeCompute`, porque `compute` finaliza al devolver un unico valor y no sirve para sostener un stream vivo. En su lugar, `streamVolume` se implementara con un observador nativo o isolate dedicado segun la plataforma.

## Arquitectura

### Capa publica Dart

- `lib/device_volume.dart`: fachada publica y validaciones de argumentos.
- `lib/src/models/volume_state.dart`: modelos inmutables.
- `lib/src/models/volume_channel.dart`: enumeraciones y mapeos.
- `lib/src/backends/backend.dart`: contrato interno.
- `lib/src/backends/backend_selector.dart`: seleccion de backend por plataforma.
- `lib/src/compute/device_volume_compute.dart`: wrappers basados en `flutter/foundation.dart` `compute`.

### Backends por plataforma

#### Android

- Backend primario con `JNIgen`.
- Integracion con `android.media.AudioManager` para lectura y cambio de volumen.
- Observacion de cambios mediante `ContentObserver` o callback equivalente enlazado a `Settings.System` o al stream gestionado por `AudioManager`.
- `showSystemUi` se mapeara a flags de `AudioManager` cuando el sistema lo permita.
- Requerira inicializacion segura por isolate para las variantes Compute.

#### iOS

- Backend FFI con shim C/Objective-C o C/Swift bridge y bindings generados por `FFIgen`.
- Lectura y observacion de volumen mediante `AVAudioSession.outputVolume`.
- Las operaciones de escritura de volumen del dispositivo no se consideran soportadas por API publica de Apple para App Store.
- `setVolume`, `incrementVolume` y `decrementVolume` deben lanzar una excepcion personalizada de operacion no soportada en iOS si se mantiene el objetivo de compliance con App Store.

#### macOS

- Backend FFI con shim C y acceso a CoreAudio desde codigo nativo puente.
- `FFIgen` generara bindings Dart desde `src/device_volume.h`.

#### Linux

- Backend FFI con shim C/C++ y acceso a PulseAudio o PipeWire segun disponibilidad en tiempo de compilacion.
- `FFIgen` generara bindings Dart desde `src/device_volume.h`.
- Si el entorno no expone una API de volumen compatible, debe devolverse una excepcion personalizada con diagnostico preciso del backend ausente.

#### Windows

- Backend FFI con shim C/C++ y acceso a `IAudioEndpointVolume`.
- `FFIgen` generara bindings Dart desde `src/device_volume.h`.

### Matriz tecnologica obligatoria

| Plataforma | Tecnologia obligatoria |
| --- | --- |
| Android | JNIgen |
| iOS | FFI + FFIgen |
| macOS | FFI + FFIgen |
| Windows | FFI + FFIgen |
| Linux | FFI + FFIgen |

### Contrato FFI

Se mantendra un ABI C pequeno y estable para las plataformas que usen FFI.

```c
typedef struct DeviceVolumeResult {
  int value;
  int min;
  int max;
  int is_muted;
  int error_code;
} DeviceVolumeResult;

DeviceVolumeResult device_volume_get(int channel);
DeviceVolumeResult device_volume_set(int channel, int value, int show_system_ui);
DeviceVolumeResult device_volume_increment(int channel, int show_system_ui);
DeviceVolumeResult device_volume_decrement(int channel, int show_system_ui);
```

### Generacion de codigo

- `FFIgen`: genera `lib/device_volume_bindings_generated.dart` desde `src/device_volume.h` para iOS, macOS, Windows y Linux.
- `JNIgen`: genera wrappers Dart internos para `AudioManager` y clases auxiliares Android.
- Los artefactos generados se versionan para evitar dependencia de generacion en tiempo de consumo.

## Comportamiento funcional

### Reglas generales

- `value` siempre debe quedar clampado entre `min` y `max`.
- `normalized` se calcula como `(value - min) / (max - min)`.
- Todas las operaciones sincronas deben ser deterministas y devolver el `VolumeState` final observado por el sistema.
- `streamVolume` debe emitir el estado inicial al suscribirse y luego solo cambios reales.
- Si una plataforma no soporta una operacion, la API debe fallar con una excepcion personalizada y un mensaje claro, accionable y especifico del backend.

### Soporte por plataforma

| Plataforma | getVolume | set/increment/decrement | streamVolume | Notas |
| --- | --- | --- | --- | --- |
| Android | Si | Si | Si | Backend JNIgen |
| iOS | Si | No | Si | Backend FFI con restricciones de Apple |
| macOS | Si | Si | Si | Backend FFI |
| Linux | Si | Si | Si | Backend FFI |
| Windows | Si | Si | Si | Backend FFI |

## Manejo de errores

- Todas las excepciones publicas deben derivar de `Exception`.
- Crear una jerarquia base con mensajes orientados a depuracion:

```dart
abstract class DeviceVolumeException implements Exception {
  final String code;
  final String message;
  final Map<String, Object?> details;

  const DeviceVolumeException(this.code, this.message, [this.details = const {}]);
}

final class UnsupportedOperationException extends DeviceVolumeException {
  const UnsupportedOperationException({
    required super.message,
    super.details,
  }) : super('unsupported_operation');
}

final class InvalidVolumeValueException extends DeviceVolumeException {
  const InvalidVolumeValueException({
    required super.message,
    super.details,
  }) : super('invalid_volume_value');
}

final class NativeBackendException extends DeviceVolumeException {
  const NativeBackendException({
    required super.message,
    super.details,
  }) : super('native_backend_failure');
}

final class VolumeObservationException extends DeviceVolumeException {
  const VolumeObservationException({
    required super.message,
    super.details,
  }) : super('volume_observation_failure');
}
```

- Los mensajes deben identificar plataforma, operacion, backend y motivo tecnico. Ejemplo: `setVolume no soportado en iOS: AVAudioSession no expone una API publica para escritura de volumen del sistema`.
- `details` debe incluir, cuando exista, `platform`, `operation`, `backend`, `channel`, `nativeCode`, `nativeMessage` y `suggestedAction`.
- Mapear errores nativos a codigos Dart estables: `unsupported_operation`, `permission_denied`, `native_backend_failure`, `invalid_volume_value`, `volume_observation_failure`, `backend_not_available`.

## Preparacion para pub.dev

### Requisitos de metadatos

- Completar en `pubspec.yaml`: `description`, `homepage`, `repository`, `issue_tracker`, `topics`, `screenshots` si aplica.
- Sustituir placeholders de podspec (`summary`, `description`, `author`, `homepage`).
- Añadir ejemplo real en `example/` con UI para leer, cambiar y observar volumen.
- Documentar limitaciones por plataforma en README.
- Mantener licencia, changelog y versionado semantico.

### Requisitos de calidad

- `flutter analyze` sin warnings relevantes.
- `dart format` limpio.
- `flutter test` para API publica y validaciones.
- `flutter pub publish --dry-run` limpio.
- Verificacion de bindings generados sin diffs pendientes.
- Cobertura de tests para excepciones y mensajes de error especificos.

## CI/CD

### CI de validacion

Pipeline en cada `pull_request` y `push` a ramas principales:

1. Checkout.
2. Setup de Flutter estable.
3. `flutter pub get`.
4. `dart format --output=none --set-exit-if-changed .`.
5. `flutter analyze`.
6. `flutter test`.
7. `dart run ffigen --config ffigen.yaml`.
8. Validacion de artefactos generados sin cambios.
9. `flutter pub publish --dry-run`.
10. Validacion de Linux en entorno dedicado cuando el backend nativo este implementado.

### CD de despliegue

Pipeline por tag semantico `v*.*.*`:

1. Ejecutar primero el mismo set minimo de validaciones.
2. Autenticar con pub.dev mediante secreto `PUB_DEV_PUBLISH_ACCESS_TOKEN`.
3. Ejecutar publicacion no interactiva.
4. Crear release en GitHub con notas basadas en `CHANGELOG.md`.

## Hitos de implementacion

### Fase 1

- Redefinir la API publica y modelos.
- Reemplazar el ejemplo `sum` por esqueletos de volumen.
- Ajustar metadatos para pub.dev.

### Fase 2

- Implementar backend Android con JNIgen.
- Implementar wrappers Compute para operaciones one-shot.
- Implementar `streamVolume` en Android.

### Fase 3

- Implementar backends FFI para iOS, macOS, Linux y Windows.
- Implementar jerarquia de excepciones y mapeo de errores nativos.
- Completar pruebas unitarias y de integracion.

### Fase 4

- Afinar README, ejemplo y changelog.
- Activar publicacion automatizada por tag.
- Ejecutar `publish --dry-run` y checklist final de pub.dev.

## Criterios de aceptacion

- La API publica expone exactamente las operaciones acordadas y los homologos Compute aplicables.
- Android soporta lectura, escritura incremental y stream de cambios sobre volumen.
- iOS, macOS, Linux y Windows usan FFI con bindings generados por FFIgen.
- Android usa JNIgen como unico backend.
- macOS, Linux y Windows soportan la misma API a traves de FFI.
- iOS documenta y aplica sus limitaciones sin comportamiento ambiguo y con excepciones explicitas.
- Las excepciones publicas derivan de `Exception` y exponen mensajes especificos para depuracion.
- El paquete supera `flutter pub publish --dry-run`.
- La publicacion a pub.dev queda automatizada mediante tag y secreto.