## 0.1.0

* Define public API: `DeviceVolume` façade with `getVolume`, `setVolume`,
  `incrementVolume`, `decrementVolume`, `streamVolume` and Compute variants.
* Add `VolumeState`, `VolumeChannel` models.
* Add custom exception hierarchy: `DeviceVolumeException`,
  `UnsupportedOperationException`, `InvalidVolumeValueException`,
  `NativeBackendException`, `VolumeObservationException`,
  `BackendNotAvailableException`, `PermissionDeniedException`.
* Scaffold backend contract and platform selector.
* Prepare pub.dev metadata and CI/CD workflows.
