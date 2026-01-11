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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChannelListScreen(),
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
  String debugText = 'Loading...';

  @override
  void initState() {
    super.initState();
    _debugLoad();
  }

  Future<void> _debugLoad() async {
    const playlistUrl =
        'https://iptv-org.github.io/iptv/index.m3u';

    try {
      final res = await http.get(Uri.parse(playlistUrl));

      final buffer = StringBuffer();
      final parsed = M3uUtils.parse(res.body);
      buffer.writeln(parsed);
      setState(() {
        debugText = buffer.toString();
      });
    } catch (e, st) {
      setState(() {
        debugText = 'ERROR:\n$e\n\nSTACKTRACE:\n$st';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IPTV DEBUG')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SelectableText(
          debugText,
          style: const TextStyle(fontSize: 12),
        ),
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
  late VideoPlayerController _vc;
  ChewieController? _cc;

  @override
  void initState() {
    super.initState();

    _vc = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _vc.initialize().then((_) {
      _cc = ChewieController(
        videoPlayerController: _vc,
        autoPlay: true,
        allowFullScreen: true,
      );
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
        child: _cc == null
            ? const CircularProgressIndicator()
            : Chewie(controller: _cc!),
      ),
    );
  }
}
