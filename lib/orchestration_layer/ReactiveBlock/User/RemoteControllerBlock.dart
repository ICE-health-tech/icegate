import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MusicBlock.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:signals/signals.dart';

/// RemoteControllerBlock: Listens to direct Supabase Realtime commands (bypass PowerSync)
/// This enables low-latency cross-device control (e.g., controlling a focus session from web).
class RemoteControllerBlock {
  final SupabaseClient _supabase;
  final AuthBlock _authBlock;
  final FocusBlock _focusBlock;
  final MusicBlock _musicBlock;

  RealtimeChannel? _commandChannel;
  final isListening = signal<bool>(false);
  final lastCommand = signal<String?>(null);

  RemoteControllerBlock({
    required SupabaseClient supabase,
    required AuthBlock authBlock,
    required FocusBlock focusBlock,
    required MusicBlock musicBlock,
  })  : _supabase = supabase,
        _authBlock = authBlock,
        _focusBlock = focusBlock,
        _musicBlock = musicBlock;

  /// Initialize real-time listener for the current user
  void init() {
    final personId = _authBlock.personId;
    if (personId == null || personId.isEmpty) {
      debugPrint("📡 [RemoteController] personId not resolved, skipping init.");
      return;
    }

    _stopListening(); // Clean up existing channel if any

    debugPrint("📡 [RemoteController] Initializing Direct Realtime for $personId...");
    _commandChannel = _supabase
        .channel('remote_control:$personId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'remote_commands',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'person_id',
            value: personId,
          ),
          callback: (payload) {
            _handleIncomingCommand(payload.newRecord);
          },
        )
        .subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        debugPrint("📡 [RemoteController] Subscribed to remote commands.");
        isListening.value = true;
      } else if (error != null) {
        debugPrint("❌ [RemoteController] Subscription error: $error");
        isListening.value = false;
      }
    });
  }

  void _stopListening() {
    if (_commandChannel != null) {
      _supabase.removeChannel(_commandChannel!);
      _commandChannel = null;
    }
    isListening.value = false;
  }

  /// Send a command to the remote bus
  Future<void> sendCommand(String command, {Map<String, dynamic>? payload}) async {
    final personId = _authBlock.personId;
    if (personId == null) return;

    try {
      await _supabase.from('remote_commands').insert({
        'person_id': personId,
        'command': command,
        'payload': payload ?? {},
        'status': 'pending',
      });
      debugPrint("📤 [RemoteController] Sent command: $command");
    } catch (e) {
      debugPrint("❌ [RemoteController] Failed to send command: $e");
    }
  }

  void _handleIncomingCommand(Map<String, dynamic> record) async {
    final command = record['command'] as String;
    final payload = record['payload'] as Map<String, dynamic>? ?? {};
    final commandId = record['id'];

    debugPrint("📥 [RemoteController] Received command: $command");
    lastCommand.value = command;

    // Acknowledge the command via direct RPC or update
    unawaited(_acknowledgeCommand(commandId));

    try {
      switch (command) {
        case 'START_FOCUS':
          _focusBlock.startTimer();
          break;
        case 'STOP_FOCUS':
          _focusBlock.stopTimer();
          break;
        case 'PAUSE_FOCUS':
          _focusBlock.pauseTimer();
          break;
        case 'PLAY_MUSIC':
          _musicBlock.play();
          break;
        case 'PAUSE_MUSIC':
          _musicBlock.pause();
          break;
        case 'SET_THEME':
          final theme = payload['theme'] as String?;
          if (theme != null) {
            _musicBlock.setTimerTheme(theme, isRunning: _focusBlock.isRunning.value);
          }
          break;
        case 'SYNC_REPAIR':
          _authBlock.repairTenantBucket();
          break;
        case 'LOCK_APP':
          // Typically sets a locked signal or logs out
          _authBlock.status.value = AuthStatus.unauthenticated;
          break;
        default:
          debugPrint("⚠️ [RemoteController] Unknown command: $command");
      }

      // Mark as completed
      await _updateCommandStatus(commandId, 'completed');
    } catch (e) {
      debugPrint("❌ [RemoteController] Execution error: $e");
      await _updateCommandStatus(commandId, 'failed');
    }
  }

  Future<void> _acknowledgeCommand(String id) async {
    try {
      await _supabase
          .from('remote_commands')
          .update({'status': 'acknowledged'})
          .eq('id', id);
    } catch (e) {
      // Ignored
    }
  }

  Future<void> _updateCommandStatus(String id, String status) async {
    try {
      await _supabase
          .from('remote_commands')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      // Ignored
    }
  }

  void dispose() {
    _stopListening();
  }
}
