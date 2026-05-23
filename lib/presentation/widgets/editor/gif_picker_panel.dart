import 'package:flutter/material.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:provider/provider.dart';
import '../../providers/editor_provider.dart';

class GifPickerPanel extends StatelessWidget {
  // Replace with your Giphy API key from developers.giphy.com
  static const String _giphyApiKey = 'YOUR_GIPHY_API_KEY';

  const GifPickerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    if (_giphyApiKey == 'bBZQqETWozCakzjDvMoDmVvPjUpkP52q') {
      return _buildApiKeyPrompt(context);
    }
    return _buildGiphyPicker(context);
  }

  Widget _buildApiKeyPrompt(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text('🎬', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          const Text(
            'GIF Picker',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add your Giphy API key in gif_picker_panel.dart\nGet a free key at developers.giphy.com',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          // Demo GIFs to still let user insert
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Demo GIFs:', style: TextStyle(color: Colors.white38, fontSize: 11)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: const [
                '🎉', '🔥', '💫', '✨', '🌟', '🎊', '💥', '🎈',
              ].map((e) => GestureDetector(
                onTap: () {
                  context.read<EditorProvider>().addEmoji(e);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(e, style: const TextStyle(fontSize: 30)),
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiphyPicker(BuildContext context) {
    return GiphyGetWrapper(
      giphy_api_key: _giphyApiKey,
      builder: (stream, giphyGetWrapper) {
        stream.listen((gif) {
          if (gif.images?.original?.url != null) {
            context.read<EditorProvider>().addGif(gif.images!.original!.url);
            Navigator.pop(context);
          }
        });
        return GestureDetector(
          onTap: () => giphyGetWrapper.getGif(
            '',
            context,
          ),
          child: Container(
            padding: EdgeInsets.only(
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Icon(Icons.gif_box_rounded, color: Colors.white54, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Tap to open GIF picker',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Search trending GIFs from Giphy',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
