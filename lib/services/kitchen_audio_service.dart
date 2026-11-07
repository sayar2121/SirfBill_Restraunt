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
      await _player.setVolume(1.0);
      await _player.stop();

      // On Flutter Web, audioplayers looks up assets from the web server root.
      // Trying AssetSource followed by UrlSource fallback guarantees web audio plays properly.
      try {
        await _player.play(AssetSource('audio/order_ring.mp3'));
      } catch (assetErr) {
        debugPrint('[KitchenAudioService] AssetSource fallback to assets/audio/order_ring.mp3: $assetErr');
        await _player.play(UrlSource('assets/assets/audio/order_ring.mp3'));
      }
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


