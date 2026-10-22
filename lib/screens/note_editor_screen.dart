import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../models/diary_entry.dart';
import '../models/emotion.dart';
import '../services/database_helper.dart';
import '../main.dart' show AppLocalizations;

class NoteEditorScreen extends StatefulWidget {
  final DiaryEntry entry;

  const NoteEditorScreen({super.key, required this.entry});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late List<String> _selectedEmotionTypes;
  String? _imagePath;
  Uint8List? _imageBytes;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _contentController = TextEditingController(text: widget.entry.content);
    _selectedEmotionTypes = List.from(widget.entry.emotionTypes);
    _imagePath = widget.entry.imagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imagePath = image.path;
      });
    }
  }

  void _toggleEmotion(String emotionType) {
    setState(() {
      if (_selectedEmotionTypes.contains(emotionType)) {
        _selectedEmotionTypes.remove(emotionType);
      } else {
        _selectedEmotionTypes.add(emotionType);
      }
    });
  }

  Future<void> _saveEntry() async {
    final entry = DiaryEntry(
      id: widget.entry.id,
      date: widget.entry.date,
      title: _titleController.text,
      content: _contentController.text,
      emotionTypes: _selectedEmotionTypes,
      imagePath: _imagePath,
    );

    if (widget.entry.id == 0) {
      await _databaseHelper.insertEntry(entry);
    } else {
      await _databaseHelper.updateEntry(entry);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.noteEditorTitle),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.noteEditorEntryTitleLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.noteEditorEmotionsLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Emotion.emotions.map((emotion) {
                  final isSelected = _selectedEmotionTypes.contains(emotion.name);
                  return FilterChip(
                    label: Text(Emotion.displayName(context, emotion.name)),
                    selected: isSelected,
                    onSelected: (_) => _toggleEmotion(emotion.name),
                    backgroundColor: Colors.white,
                    selectedColor: emotion.color.withOpacity(0.2),
                    checkmarkColor: emotion.color,
                    labelStyle: TextStyle(
                      color: isSelected ? emotion.color : Colors.black87,
                    ),
                    avatar: Icon(
                      emotion.icon,
                      color: emotion.color,
                      size: 18,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: _pickImage,
                    color: Colors.deepPurple,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: l10n.noteEditorContentLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.memory(
                    _imageBytes!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 