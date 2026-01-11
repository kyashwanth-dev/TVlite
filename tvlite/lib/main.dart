import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:m3u_utils/m3u_utils.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

void main() {
  runApp(const IPTVApp());
}

class IPTVApp extends StatelessWidget {
  const IPTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPTV Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChannelListScreen(),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                             CHANNEL LIST SCREEN                             */
/* -------------------------------------------------------------------------- */

class ChannelListScreen extends StatefulWidget {
  const ChannelListScreen({super.key});

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  late Future<List<MapEntry<String, Map<String, dynamic>>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadChannels();
  }

  Future<List<MapEntry<String, Map<String, dynamic>>>> _loadChannels() async {
    const playlistUrl =
        'https://raw.githubusercontent.com/Archrootsda/iptv/master/index.m3u';

    final res = await http.get(Uri.parse(playlistUrl));
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch playlist');
    }

    // m3u_utils returns Map<String, dynamic>
    final parsed =
        M3uUtils.parse(res.body) as Map<String, Map<String, dynamic>>;

    return parsed.entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Channels')),
      body: FutureBuilder<List<MapEntry<String, Map<String, dynamic>>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final channels = snap.data!;

          return ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, i) {
              final entry = channels[i];
              final url = entry.key;
              final meta = entry.value;

              final name = meta['title']?.toString() ?? 'Unknown Channel';

              return ListTile(
                title: Text(name),
                subtitle: Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        url: url,
                        title: name,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                PLAYER SCREEN                                */
/* -------------------------------------------------------------------------- */

class PlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PlayerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();

    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.url));

    _videoController.initialize().then((_) {
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: _chewieController == null
            ? const CircularProgressIndicator()
            : Chewie(controller: _chewieController!),
      ),
    );
  }
}
