import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for playing KDS audio alerts on new incoming orders.
class KitchenAudioService {
  KitchenAudioService._();

  static final AudioPlayer _player = AudioPlayer();
  static bool _isInitialized = false;

  /// Play the order ring alert sound from assets/audio/order_ring.mp3
  static Future<void> playNewOrderAlert() async {
    try {
      if (!_isInitialized) {
        await _player.setReleaseMode(ReleaseMode.stop);
        _isInitialized = true;
      }
      // Stop previous playback if any, then play freshly
      await _player.stop();
      await _player.play(AssetSource('audio/order_ring.mp3'));
      debugPrint('[KitchenAudioService] Successfully played order_ring.mp3');
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

