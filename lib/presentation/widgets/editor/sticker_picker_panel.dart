import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/editor_provider.dart';

/// Sticker packs using emoji characters - no external assets required
class StickerPickerPanel extends StatefulWidget {
  const StickerPickerPanel({super.key});

  @override
  State<StickerPickerPanel> createState() => _StickerPickerPanelState();
}

class _StickerPickerPanelState extends State<StickerPickerPanel> {
  int _selectedPack = 0;

  static const List<_StickerPack> packs = [
    _StickerPack(
      icon: '❤️',
      name: 'Hearts',
      stickers: ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '❣️'],
    ),
    _StickerPack(
      icon: '⭐',
      name: 'Stars',
      stickers: ['⭐', '🌟', '✨', '💫', '🔯', '⚡', '🌠', '🌌', '🌃', '🌙', '☀️', '🌈', '🎇', '🎆', '🪐', '💎'],
    ),
    _StickerPack(
      icon: '🔥',
      name: 'Fire',
      stickers: ['🔥', '💥', '🌋', '☄️', '⚡', '🌪️', '🌊', '💣', '🎯', '🏆', '👑', '🎖️', '🦁', '🐉', '🦅', '🦊'],
    ),
    _StickerPack(
      icon: '🎀',
      name: 'Cute',
      stickers: ['🎀', '🌸', '🌺', '🌻', '🌷', '🍀', '🦋', '🐱', '🐶', '🐰', '🐼', '🐨', '🦄', '🍑', '🍓', '🧁'],
    ),
    _StickerPack(
      icon: '🌈',
      name: 'Vibes',
      stickers: ['🌈', '☁️', '🌤️', '🌙', '⛅', '🌊', '🏔️', '🌿', '🍃', '🌱', '🌵', '🎋', '🍂', '🌾', '🐚', '🪸'],
    ),
    _StickerPack(
      icon: '✏️',
      name: 'Fun',
      stickers: ['😂', '🤣', '😎', '🥳', '🤩', '🥰', '😍', '🤪', '🤯', '🤫', '🙈', '🙉', '🙊', '👻', '🎃', '🤖'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pack = packs[_selectedPack];

    return Container(
      height: 360,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Pack tabs
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: packs.length,
              itemBuilder: (context, i) {
                final isSelected = _selectedPack == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPack = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF6B35)
                          : const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(packs[i].icon, style: const TextStyle(fontSize: 16)),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Text(
                            packs[i].name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Sticker grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: pack.stickers.length,
              itemBuilder: (context, i) {
                return GestureDetector(
                  onTap: () {
                    context.read<EditorProvider>().addSticker(pack.stickers[i]);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        pack.stickers[i],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StickerPack {
  final String icon;
  final String name;
  final List<String> stickers;
  const _StickerPack({required this.icon, required this.name, required this.stickers});
}
