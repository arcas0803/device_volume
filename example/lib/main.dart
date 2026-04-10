import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_volume/device_volume.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const HomePage(),
    );
  }
}

/// Whether the current platform supports per-channel volume (Android only).
bool get _supportsChannels => Platform.isAndroid;

/// Channels available for the tab bar.
const _channels = VolumeChannel.values;

// ═══════════════════════════════════════════════════════════════════════════
// Home page — tabs per channel (Android) or single page (other platforms)
// ═══════════════════════════════════════════════════════════════════════════

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (_supportsChannels) {
      return DefaultTabController(
        length: _channels.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('device_volume example'),
            bottom: TabBar(
              isScrollable: true,
              tabs: [for (final ch in _channels) Tab(text: ch.name)],
            ),
          ),
          body: TabBarView(
            children: [for (final ch in _channels) ChannelPage(channel: ch)],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('device_volume example')),
      body: const ChannelPage(channel: VolumeChannel.media),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Per-channel page
// ═══════════════════════════════════════════════════════════════════════════

class ChannelPage extends StatefulWidget {
  const ChannelPage({super.key, required this.channel});
  final VolumeChannel channel;

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  int? _volume;
  StreamSubscription<int>? _sub;
  String? _error;
  bool _useCompute = false;
  String? _computeLog;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── Init & stream ────────────────────────────────────────────────────────

  void _init() {
    try {
      final v = DeviceVolume.getVolume(channel: widget.channel);
      setState(() {
        _volume = v;
        _error = null;
      });
    } on DeviceVolumeException catch (e) {
      setState(() => _error = e.toString());
    }

    _sub?.cancel();
    _sub = DeviceVolume.streamVolume(channel: widget.channel).listen(
      (v) => setState(() => _volume = v),
      onError: (Object e) => setState(() => _error = e.toString()),
    );
  }

  // ── Volume actions ───────────────────────────────────────────────────────

  Future<void> _setVolume(int value) async {
    try {
      int v;
      if (_useCompute) {
        v = await DeviceVolume.setVolumeCompute(
          value,
          channel: widget.channel,
          showSystemUi: true,
        );
        _logCompute('setVolumeCompute($value)');
      } else {
        v = DeviceVolume.setVolume(
          value,
          channel: widget.channel,
          showSystemUi: true,
        );
      }
      setState(() {
        _volume = v;
        _error = null;
      });
    } on DeviceVolumeException catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _increment() async {
    try {
      int v;
      if (_useCompute) {
        v = await DeviceVolume.incrementVolumeCompute(
          channel: widget.channel,
          showSystemUi: true,
        );
        _logCompute('incrementVolumeCompute()');
      } else {
        v = DeviceVolume.incrementVolume(
          channel: widget.channel,
          showSystemUi: true,
        );
      }
      setState(() {
        _volume = v;
        _error = null;
      });
    } on DeviceVolumeException catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _decrement() async {
    try {
      int v;
      if (_useCompute) {
        v = await DeviceVolume.decrementVolumeCompute(
          channel: widget.channel,
          showSystemUi: true,
        );
        _logCompute('decrementVolumeCompute()');
      } else {
        v = DeviceVolume.decrementVolume(
          channel: widget.channel,
          showSystemUi: true,
        );
      }
      setState(() {
        _volume = v;
        _error = null;
      });
    } on DeviceVolumeException catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _mute() async {
    await _setVolume(0);
  }

  Future<void> _getVolumeCompute() async {
    try {
      final v = await DeviceVolume.getVolumeCompute(channel: widget.channel);
      _logCompute('getVolumeCompute() → $v');
      setState(() {
        _volume = v;
        _error = null;
      });
    } on DeviceVolumeException catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _logCompute(String msg) {
    setState(() => _computeLog = '✓ $msg');
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Error banner
        if (_error != null) ...[
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (_volume case final vol?) ...[
          // ── Volume info ──────────────────────────────────────────────
          _SectionCard(
            title: 'Volume info',
            children: [
              _InfoRow('Channel', widget.channel.name),
              _InfoRow('Volume', '$vol%'),
            ],
          ),
          const SizedBox(height: 16),

          // ── Slider (0–100) ───────────────────────────────────────────
          _SectionCard(
            title: 'Set volume',
            children: [
              Row(
                children: [
                  const Text('0'),
                  Expanded(
                    child: Slider(
                      min: 0,
                      max: 100,
                      divisions: 100,
                      value: vol.toDouble(),
                      label: '$vol',
                      onChanged: (v) => _setVolume(v.round()),
                    ),
                  ),
                  const Text('100'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Increment / Decrement ────────────────────────────────────
          _SectionCard(
            title: 'Increment / Decrement (platform step)',
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _decrement,
                    icon: const Icon(Icons.remove),
                    label: const Text('Down'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _increment,
                    icon: const Icon(Icons.add),
                    label: const Text('Up'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Mute ──────────────────────────────────────────────────────
          _SectionCard(
            title: 'Mute',
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: vol > 0 ? _mute : null,
                  icon: Icon(vol == 0 ? Icons.volume_off : Icons.volume_mute),
                  label: Text(vol == 0 ? 'Already muted' : 'Mute (set to 0)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Compute section ───────────────────────────────────────────
          _SectionCard(
            title: 'Compute (background isolate)',
            children: [
              SwitchListTile(
                title: const Text('Use Compute for all actions'),
                subtitle: const Text(
                  'Slider, increment and decrement will run via compute()',
                ),
                value: _useCompute,
                onChanged: (v) => setState(() => _useCompute = v),
              ),
              const Divider(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _getVolumeCompute,
                  icon: const Icon(Icons.sync),
                  label: const Text('getVolumeCompute()'),
                ),
              ),
              if (_computeLog != null) ...[
                const SizedBox(height: 8),
                Text(
                  _computeLog!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ] else if (_error == null)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Reusable widgets
// ═══════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
