import 'dart:async';

import "package:audio_service/audio_service.dart";
import "package:just_audio/just_audio.dart";

MediaControl playControl = MediaControl(
  androidIcon: 'drawable/ic_action_play_arrow',
  label: 'Play',
  action: MediaAction.play,
);
MediaControl pauseControl = MediaControl(
  androidIcon: 'drawable/ic_action_pause',
  label: 'Pause',
  action: MediaAction.pause,
);
MediaControl skipToNextControl = MediaControl(
  androidIcon: 'drawable/ic_action_skip_next',
  label: 'Next',
  action: MediaAction.skipToNext,
);
MediaControl skipToPreviousControl = MediaControl(
  androidIcon: 'drawable/ic_action_skip_previous',
  label: 'Previous',
  action: MediaAction.skipToPrevious,
);
MediaControl stopControl = MediaControl(
  androidIcon: 'drawable/ic_action_stop',
  label: 'Stop',
  action: MediaAction.stop,
);

class AudioPlayerTask extends BackgroundAudioTask {
  final _queue = <MediaItem>[
    MediaItem(
      id: "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3",
      album: "Science Friday",
      title: "A Salute To Head-Scratching Science",
      artist: "Science Friday and WNYC Studios",
      duration: Duration(milliseconds: 5739820),
      artUri:
          "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
    ),
    MediaItem(
      id: "https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3",
      album: "Science Friday",
      title: "From Cat Rheology To Operatic Incompetence",
      artist: "Science Friday and WNYC Studios",
      duration: Duration(milliseconds: 2856950),
      artUri:
          "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
    ),
  ];

  int queueIndex = -1;

  AudioPlayer _audioPlayer = AudioPlayer();

  AudioProcessingState _audioProcessingState;

  bool isPlaying;

  bool get hasNext => queueIndex + 1 < _queue.length;

  bool get hasPrevious => queueIndex > 0;

  MediaItem get mediaItem => _queue[queueIndex];

  StreamSubscription<AudioPlaybackState> _playStateSubscription;

  StreamSubscription<AudioPlaybackEvent> _eventSubscription;

  @override
  void onStart(Map<String, dynamic> params) {
    _playStateSubscription = _audioPlayer.playbackStateStream
        .where((state) => state == AudioPlaybackState.completed)
        .listen((event) {
      _handlePlaybackComplete();
    });
    _eventSubscription = _audioPlayer.playbackEventStream.listen((event) {
      final bufferingState =
          event.buffering ? AudioProcessingState.buffering : null;
      switch (event.state) {
        case AudioPlaybackState.paused:
          _setState(
              processingState: bufferingState ?? AudioProcessingState.ready,
              position: event.position);
          break;
        case AudioPlaybackState.playing:
          _setState(
              processingState: bufferingState ?? AudioProcessingState.ready,
              position: event.position);
          break;
        case AudioPlaybackState.connecting:
          _setState(
              processingState:
                  bufferingState ?? AudioProcessingState.connecting,
              position: event.position);
          break;
        default:
      }
    });
    super.onStart(params);

    AudioServiceBackground.setQueue(_queue);
    onSkipToNext();
  }

  @override
  void onPlay() {
    if (null == _audioProcessingState) {
      isPlaying = true;
      _audioPlayer.play();
    }
    super.onPlay();
  }

  @override
  void onPause() {
    isPlaying = false;
    _audioPlayer.pause();
    super.onPause();
  }

  @override
  void onSkipToNext() {
    skip(1);
    super.onSkipToNext();
  }

  void skip(int offset) async {
    int newPos = queueIndex + offset;
    if (!(newPos >= 0 && newPos < _queue.length)) {
      return;
    }

    if (isPlaying == null) {
      isPlaying = true;
    } else if (isPlaying) {
      await _audioPlayer.stop();
    }

    queueIndex = newPos;
    _audioProcessingState = offset > 0
        ? AudioProcessingState.skippingToNext
        : AudioProcessingState.skippingToPrevious;
    AudioServiceBackground.setMediaItem(mediaItem);
    await _audioPlayer.setUrl(mediaItem.id);
    _audioProcessingState = null;
    if (isPlaying) {
      onPlay();
    } else {
      //to do
    }
  }

  @override
  void onSkipToPrevious() {
    skip(-1);
    super.onSkipToPrevious();
  }

  @override
  Future<void> onStop() async {
    isPlaying = false;
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _playStateSubscription.cancel();
    _eventSubscription.cancel();
    return await super.onStop();
  }

  @override
  void onSeekTo(Duration position) {
    _audioPlayer.seek(position);
    super.onSeekTo(position);
  }

  @override
  void onClick(MediaButton button) {
    _playPause();
    super.onClick(button);
  }

  @override
  void onFastForward() async {
    await seekRelative(fastForwardInterval);
    super.onFastForward();
  }

  _playPause() {
    if (AudioServiceBackground.state.playing) {
      onPause();
    }
    onPlay();
  }

  Future<void> seekRelative(Duration offset) async {
    var newPosition = _audioPlayer.playbackEvent.position + offset;
    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    }

    if (newPosition > mediaItem.duration) {
      newPosition = mediaItem.duration;
    }
    await _audioPlayer.seek(_audioPlayer.playbackEvent.position + offset);
  }

  @override
  void onRewind() async {
    await seekRelative(rewindInterval);
    super.onRewind();
  }

  _handlePlaybackComplete() {
    if (hasNext) {
      onSkipToNext();
    } else {
      onStop();
    }
  }

  Future<void> _setState(
      {AudioProcessingState processingState,
      Duration position,
      Duration bufferedPosition}) async {
    if (position == null) {
      position = _audioPlayer.playbackEvent.position;
    }
    await AudioServiceBackground.setState(
        controls: getControls(),
        systemActions: [MediaAction.seekTo],
        position: position,
        speed: _audioPlayer.speed,
        processingState:
            processingState ?? AudioServiceBackground.state.processingState,
        playing: isPlaying);
  }

  List<MediaControl> getControls() {
    if (isPlaying) {
      return [
        skipToNextControl,
        skipToPreviousControl,
        stopControl,
        pauseControl
      ];
    } else {
      return [
        skipToNextControl,
        skipToPreviousControl,
        stopControl,
        playControl
      ];
    }
  }
}

class AudioState {
  final List<MediaItem> queue;
  final MediaItem mediaItem;
  final PlaybackState playbackState;

  AudioState({this.queue, this.mediaItem, this.playbackState});

  


}
