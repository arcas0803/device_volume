## 0.1.1

* **Breaking:** All public API methods now return `int` (0–100) instead of
  `VolumeState`. Volume values are normalized across all platforms.
* `VolumeState` is no longer exported (still used internally).
* `setVolume` / `setVolumeCompute` now validate that the value is between
  0 and 100, throwing `InvalidVolumeValueException` if not.
* Android backend: native volume ranges (e.g. 0–15) are mapped to 0–100.
* Added unit tests for `VolumeState`, exceptions, and error-code mapping.
* Updated example app, README and doc comments for the new int API.

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
