import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

class RefuerzoController {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ConfettiController confettiController;

  RefuerzoController({required this.confettiController});

  Future<void> reproducirAplauso() async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('sonidos/applause.mp3'));
  }

  Future<void> reproducirError() async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('sonidos/error.mp3'));
  }

  void lanzarConfetti() {
    confettiController.play();
  }
}