/// Audio stream channels available on the device.
///
/// Not all channels are supported on every platform. Attempting to use an
/// unsupported channel will throw an [UnsupportedOperationException].
enum VolumeChannel {
  /// Music, video, games, and other media playback.
  media,

  /// Ringtone volume.
  ring,

  /// Alarm volume.
  alarm,

  /// Notification sounds.
  notification,

  /// Voice call (in-call) volume.
  voiceCall,

  /// System sounds (key clicks, etc.).
  system,
}
