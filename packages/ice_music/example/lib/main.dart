import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ice_music/ice_music.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _iceMusic = IceMusic.instance;
  final _controller = TextEditingController(text: 'audio/bgm.mp3');
  String? _nowPlaying;

  @override
  void dispose() {
    _controller.dispose();
    unawaited(_iceMusic.stop());
    super.dispose();
  }

  Future<void> _toggle(String asset) async {
    if (_nowPlaying == asset) {
      await _iceMusic.stop();
      setState(() => _nowPlaying = null);
    } else {
      await _iceMusic.playLoopAsset(asset);
      setState(() => _nowPlaying = asset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ice_music example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(labelText: 'Asset path'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _toggle(_controller.text),
                child: Text(
                  _nowPlaying == null ? 'Play loop' : 'Stop',
                ),
              ),
              const SizedBox(height: 8),
              Text('Now playing: ${_nowPlaying ?? 'nothing'}'),
            ],
          ),
        ),
      ),
    );
  }
}