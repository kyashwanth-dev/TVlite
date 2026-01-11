import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:m3u_utils/m3u_utils.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

void main() => runApp(const IPTVApp());

class IPTVApp extends StatelessWidget {
  const IPTVApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPTV Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChannelListScreen(),
    );
  }
}

class ChannelListScreen extends StatefulWidget {
  const ChannelListScreen({super.key});
  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  late Future<List<MapEntry<String, Map<String, String>>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadChannels();
  }

  Future<List<MapEntry<String, Map<String, String>>>> _loadChannels() async {
    const playlistUrl = 'https://raw.githubusercontent.com/Archrootsda/iptv/master/index.m3u'; // example
    final res = await http.get(Uri.parse(playlistUrl));
    if (res.statusCode != 200) throw Exception('Failed to fetch playlist');
    final parsed = M3uParser.parse(res.body);
    return parsed.entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Channels')),
      body: FutureBuilder<List<MapEntry<String, Map<String, String>>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final channels = snap.data!;
          return ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, i) {
              final entry = channels[i];
              final url = entry.key;
              final meta = entry.value;
              final name = meta['title'] ?? 'Unknown';
              return ListTile(
                title: Text(name),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlayerScreen(url: url, title: name)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  const PlayerScreen({super.key, required this.url, required this.title});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _vc;
  ChewieController? _cc;

  @override
  void initState() {
    super.initState();
    _vc = VideoPlayerController.network(widget.url);
    _vc.initialize().then((_) {
      _cc = ChewieController(videoPlayerController: _vc, autoPlay: true);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _vc.dispose();
    _cc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: _cc == null ? const CircularProgressIndicator() : Chewie(controller: _cc!),
      ),
    );
  }
}
