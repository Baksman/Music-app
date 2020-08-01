import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:mucicapp/music_player/audio_player.dart';
import 'package:rxdart/rxdart.dart';

class MusicPlayerScreeen extends StatefulWidget {
  @override
  _MusicPlayerScreeenState createState() => _MusicPlayerScreeenState();
}

class _MusicPlayerScreeenState extends State<MusicPlayerScreeen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Audio player"),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        color: Colors.white,
        child: StreamBuilder<AudioState>(
            stream: _audioStateStream,
            builder: (context, snapshot) {
              final audioState = snapshot.data;
              final queue = audioState?.queue;
              final mediaItem = audioState?.mediaItem;
              final playbackState = audioState?.playbackState;
              final processingState =
                  playbackState?.processingState ?? AudioProcessingState.none;
              final playing = playbackState?.playing ?? false;
              return Container(
                width: MediaQuery.of(context).size.width,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      if (processingState == AudioProcessingState.none) ...[
                        _startAudioPlayButton()
                      ] else ...[
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            !playing
                                ? IconButton(
                                    icon: Icon(Icons.play_arrow),
                                    onPressed: AudioService.play)
                                : IconButton(
                                    icon: Icon(Icons.pause),
                                    onPressed: AudioService.play),
                            IconButton(
                                icon: Icon(Icons.skip_previous),
                                onPressed: () {
                                  if (mediaItem == queue.first) {
                                    return;
                                  }
                                  AudioService.skipToPrevious();
                                }),
                            IconButton(
                                icon: Icon(Icons.skip_next),
                                onPressed: () {
                                  if (mediaItem == queue.last) {
                                    return;
                                  }
                                  AudioService.skipToNext();
                                }),
                          ],
                        ),
                      ],
                    ]),
              );
            }),
      ),
    );
  }
}

_startAudioPlayButton() {
  return MaterialButton(
      child: Text("Start audio"),
      onPressed: () async {
        await AudioService.start(
            backgroundTaskEntrypoint: audioTaskEntryPoint,
            androidNotificationChannelName: "Flutter music player",
            androidNotificationColor: 0xff9999f1,
            androidNotificationIcon: "mipmap/ic_launcher");
      });
}

void audioTaskEntryPoint() {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

Stream<AudioState> get _audioStateStream {
  return Rx.combineLatest3<List<MediaItem>, MediaItem, PlaybackState,
          AudioState>(
      AudioService.queueStream,
      AudioService.currentMediaItemStream,
      AudioService.playbackStateStream,
      (queue, mediaItem, playbackState) => AudioState(
          mediaItem: mediaItem, playbackState: playbackState, queue: queue));
}
