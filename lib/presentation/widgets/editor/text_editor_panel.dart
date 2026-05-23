import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/moment_overlay.dart';
import '../../providers/editor_provider.dart';

class TextEditorPanel extends StatefulWidget {
  const TextEditorPanel({super.key});

  @override
  State<TextEditorPanel> createState() => _TextEditorPanelState();
}

class _TextEditorPanelState extends State<TextEditorPanel> {
  final _textCtrl = TextEditingController();
  Color _selectedColor = Colors.white;
  double _fontSize = 28;
  bool _bold = false;
  bool _italic = false;
  bool _hasShadow = true;
  TextStylePreset _preset = TextStylePreset.normal;
  TextAlign _align = TextAlign.center;

  static const _colors = [
    Colors.white,
    Colors.black,
    Color(0xFFFF6B35),
    Color(0xFF00D4FF),
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.pinkAccent,
    Colors.cyanAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
  ];

  static const _presets = [
    (TextStylePreset.normal, 'Normal', Colors.white),
    (TextStylePreset.neon, 'Neon', Colors.cyanAccent),
    (TextStylePreset.glow, 'Glow', Colors.white),
    (TextStylePreset.dark, 'Dark', Colors.white),
    (TextStylePreset.white, 'Light', Colors.black87),
    (TextStylePreset.gradient, 'Color', Color(0xFFFF6B35)),
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Text input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _textCtrl,
                  autofocus: true,
                  maxLines: 3,
                  maxLength: 120,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: _align,
                  decoration: InputDecoration(
                    hintText: 'Add text...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                    counterStyle: const TextStyle(color: Colors.white24, fontSize: 10),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8, top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _iconToggle(Icons.format_bold, _bold, () => setState(() => _bold = !_bold)),
                          _iconToggle(Icons.format_italic, _italic, () => setState(() => _italic = !_italic)),
                          _iconToggle(Icons.format_align_center, _align == TextAlign.center,
                            () => setState(() => _align = _align == TextAlign.center ? TextAlign.left : TextAlign.center)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Style presets
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _presets.length,
                itemBuilder: (context, i) {
                  final (preset, name, color) = _presets[i];
                  final isSelected = _preset == preset;
                  return GestureDetector(
                    onTap: () => setState(() => _preset = preset),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF6B35) : const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : color,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Color row
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _colors.length,
                itemBuilder: (context, i) {
                  final color = _colors[i];
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white24,
                          width: isSelected ? 3 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withAlpha(150), blurRadius: 8)]
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Font size slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('A', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 16,
                      max: 72,
                      activeColor: const Color(0xFFFF6B35),
                      inactiveColor: Colors.white12,
                      onChanged: (v) => setState(() => _fontSize = v),
                    ),
                  ),
                  const Text('A', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Shadow & Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _hasShadow = !_hasShadow),
                    child: Row(
                      children: [
                        Icon(
                          _hasShadow ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          color: _hasShadow ? const Color(0xFFFF6B35) : Colors.white38,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        const Text('Shadow', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      final text = _textCtrl.text.trim();
                      if (text.isEmpty) {
                        Navigator.pop(context);
                        return;
                      }
                      context.read<EditorProvider>().addText(
                        text: text,
                        color: _selectedColor,
                        fontSize: _fontSize,
                        bold: _bold,
                        italic: _italic,
                        hasShadow: _hasShadow,
                        preset: _preset,
                        align: _align,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    ),
                    child: const Text('Add Text', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconToggle(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          icon,
          color: active ? const Color(0xFFFF6B35) : Colors.white38,
          size: 20,
        ),
      ),
    );
  }
}
