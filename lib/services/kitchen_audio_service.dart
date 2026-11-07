import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for playing KDS audio alerts on new incoming orders.
class KitchenAudioService {
  KitchenAudioService._();

  static final AudioPlayer _player = AudioPlayer();

  /// Play the order ring alert sound from assets/audio/order_ring.mp3 (looping until stopped)
  static Future<void> playNewOrderAlert({bool loop = false}) async {
    try {
      await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      // Stop previous playback if any, then play freshly
      await _player.stop();
      await _player.play(AssetSource('audio/order_ring.mp3'));
      debugPrint('[KitchenAudioService] Successfully played order_ring.mp3 (loop=$loop)');
    } catch (e) {
      debugPrint('[KitchenAudioService] Error playing kitchen alert: $e');
    }
  }

  /// Stop sound playback
  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }
}

