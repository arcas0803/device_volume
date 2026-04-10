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
  VolumeState? _state;
  StreamSubscription<VolumeState>? _sub;
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
      final s = DeviceVolume.getVolume(channel: widget.channel);
      setState(() {
        _state = s;
        _error = null;
      });
    } on DeviceVolumeException catch (e) {
      setState(() => _error = e.toString());
    }

    _sub?.cancel();
    _sub = DeviceVolume.streamVolume(channel: widget.channel).listen(
      (s) => setState(() => _state = s),
      onError: (Object e) => setState(() => _error = e.toString()),
    );
  }

  // ── Volume actions ───────────────────────────────────────────────────────

  Future<void> _setVolume(int value) async {
    try {
      VolumeState s;
      if (_useCompute) {
        s = await DeviceVolume.setVolumeCompute(
          value,
          channel: widget.channel,
          showSystemUi: true,
        );
        _logCompute('setVolumeCompute($value)');
      } else {
        s = DeviceVolume.setVolume(
          value,
          channel: widget.channel,
          showSystemUi: true,
        );
      }
      setState(() {
        _state = s;
        _error = null;
      });
    } on DeviceVolumeException catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _increment() async {
    try {
      VolumeState s;
      if (_useCompute) {
        s = await DeviceVolume.incrementVolumeCompute(
          channel: widget.channel,
          showSystemUi: true,
        );
        _logCompute('incrementVolumeCompute()');
      } else {
        s = DeviceVolume.incrementVolume(
          channel: widget.channel,
          showSystemUi: true,
        );
      }
      setState(() {
        _state = s;
        _error = null;
      });
    } on DeviceVolumeException catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _decrement() async {
    try {
      VolumeState s;
      if (_useCompute) {
        s = await DeviceVolume.decrementVolumeCompute(
          channel: widget.channel,
          showSystemUi: true,
        );
        _logCompute('decrementVolumeCompute()');
      } else {
        s = DeviceVolume.decrementVolume(
          channel: widget.channel,
          showSystemUi: true,
        );
      }
      setState(() {
        _state = s;
        _error = null;
      });
    } on DeviceVolumeException catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _mute() async {
    await _setVolume(_state?.min ?? 0);
  }

  Future<void> _getVolumeCompute() async {
    try {
      final s = await DeviceVolume.getVolumeCompute(channel: widget.channel);
      _logCompute('getVolumeCompute() → ${s.value}');
      setState(() {
        _state = s;
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

        if (_state case final vs?) ...[
          // ── Volume info ──────────────────────────────────────────────
          _SectionCard(
            title: 'Volume info',
            children: [
              _InfoRow('Channel', vs.channel.name),
              _InfoRow('Value', '${vs.value}'),
              _InfoRow('Range', '${vs.min} – ${vs.max}'),
              _InfoRow(
                'Normalized',
                '${(vs.normalized * 100).toStringAsFixed(0)}%',
              ),
              _InfoRow('Muted', vs.isMuted ? 'Yes' : 'No'),
            ],
          ),
          const SizedBox(height: 16),

          // ── Slider (1 by 1) ──────────────────────────────────────────
          _SectionCard(
            title: 'Set volume (1 by 1)',
            children: [
              Row(
                children: [
                  Text('${vs.min}'),
                  Expanded(
                    child: Slider(
                      min: vs.min.toDouble(),
                      max: vs.max.toDouble(),
                      divisions: vs.max - vs.min > 0 ? vs.max - vs.min : null,
                      value: vs.value.toDouble().clamp(
                        vs.min.toDouble(),
                        vs.max.toDouble(),
                      ),
                      label: '${vs.value}',
                      onChanged: (v) => _setVolume(v.round()),
                    ),
                  ),
                  Text('${vs.max}'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Increment / Decrement (5 by 5) ───────────────────────────
          _SectionCard(
            title: 'Increment / Decrement (±5 step)',
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _decrement,
                    icon: const Icon(Icons.remove),
                    label: const Text('−5'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _increment,
                    icon: const Icon(Icons.add),
                    label: const Text('+5'),
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
                  onPressed: vs.value > vs.min ? _mute : null,
                  icon: Icon(
                    vs.isMuted || vs.value <= vs.min
                        ? Icons.volume_off
                        : Icons.volume_mute,
                  ),
                  label: Text(
                    vs.isMuted || vs.value <= vs.min
                        ? 'Already muted'
                        : 'Mute (set to ${vs.min})',
                  ),
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
