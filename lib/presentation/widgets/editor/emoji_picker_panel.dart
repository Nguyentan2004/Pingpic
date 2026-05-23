import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/editor_provider.dart';

class EmojiPickerPanel extends StatelessWidget {
  const EmojiPickerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                context.read<EditorProvider>().addEmoji(emoji.emoji);
                Navigator.pop(context);
              },
              config: Config(
                emojiViewConfig: const EmojiViewConfig(
                  emojiSizeMax: 32,
                  backgroundColor: Color(0xFF1C1C1E),
                  columns: 8,
                ),
                categoryViewConfig: const CategoryViewConfig(
                  backgroundColor: Color(0xFF1C1C1E),
                  iconColor: Colors.white38,
                  iconColorSelected: Color(0xFFFF6B35),
                  indicatorColor: Color(0xFFFF6B35),
                ),
                bottomActionBarConfig: const BottomActionBarConfig(
                  backgroundColor: Color(0xFF1C1C1E),
                  buttonColor: Color(0xFF1C1C1E),
                  buttonIconColor: Colors.white54,
                ),
                searchViewConfig: const SearchViewConfig(
                  backgroundColor: Color(0xFF2C2C2E),
                  buttonIconColor: Colors.white54,
                  hintText: 'Search emoji...',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
