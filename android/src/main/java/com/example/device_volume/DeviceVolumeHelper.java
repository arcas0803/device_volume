package com.example.device_volume;

import android.content.Context;
import android.media.AudioManager;

/**
 * Thin wrapper around {@link AudioManager} for JNIgen.
 *
 * <p>
 * Exposes only the subset of AudioManager that the Dart
 * {@code device_volume} plugin needs.
 * </p>
 */
public class DeviceVolumeHelper {

    private final AudioManager audioManager;

    public DeviceVolumeHelper(Context context) {
        audioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
    }

    // ── Volume queries ──────────────────────────────────────────

    public int getStreamVolume(int streamType) {
        return audioManager.getStreamVolume(streamType);
    }

    public int getStreamMaxVolume(int streamType) {
        return audioManager.getStreamMaxVolume(streamType);
    }

    public int getStreamMinVolume(int streamType) {
        return audioManager.getStreamMinVolume(streamType);
    }

    public boolean isStreamMute(int streamType) {
        return audioManager.isStreamMute(streamType);
    }

    // ── Volume control ──────────────────────────────────────────

    public void setStreamVolume(int streamType, int index, int flags) {
        audioManager.setStreamVolume(streamType, index, flags);
    }

    public void adjustStreamVolume(int streamType, int direction, int flags) {
        audioManager.adjustStreamVolume(streamType, direction, flags);
    }

    // ── Constants (exposed as static fields for JNIgen) ─────────

    public static final int STREAM_MUSIC = AudioManager.STREAM_MUSIC;
    public static final int STREAM_RING = AudioManager.STREAM_RING;
    public static final int STREAM_ALARM = AudioManager.STREAM_ALARM;
    public static final int STREAM_NOTIFICATION = AudioManager.STREAM_NOTIFICATION;
    public static final int STREAM_VOICE_CALL = AudioManager.STREAM_VOICE_CALL;
    public static final int STREAM_SYSTEM = AudioManager.STREAM_SYSTEM;

    public static final int FLAG_SHOW_UI = AudioManager.FLAG_SHOW_UI;

    public static final int ADJUST_RAISE = AudioManager.ADJUST_RAISE;
    public static final int ADJUST_LOWER = AudioManager.ADJUST_LOWER;
}
