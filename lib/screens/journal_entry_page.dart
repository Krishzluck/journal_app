import 'package:flutter/material.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:journal_app/widgets/common_text_field.dart';
import 'package:journal_app/widgets/custom_button.dart';
import 'package:provider/provider.dart';

class JournalEntryPage extends StatefulWidget {
  final JournalEntry? entry;

  JournalEntryPage({this.entry});

  @override
  _JournalEntryPageState createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String _selectedMood = 'Happy';
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(text: widget.entry?.content ?? '');
    if (widget.entry != null) {
      _selectedMood = widget.entry!.mood;
      _isPublic = widget.entry!.isPublic;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New Journal' : 'Edit Journal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              CommonTextField(
                controller: _titleController,
                labelText: 'Title',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              CommonTextField(
                controller: _contentController,
                labelText: 'What happened today?',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some content';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Text('How are you feeling?', 
                style: Theme.of(context).textTheme.titleMedium
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: moodColors.keys.map((mood) {
                  final isSelected = _selectedMood == mood;
                  final moodColor = moodColors[mood]!;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMood = mood;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? moodColor : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? moodColor : Colors.black,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Text(
                        mood,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Make this entry public'),
                value: _isPublic,
                onChanged: (bool value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
              ),
              SizedBox(height: 16),
              CustomButton(
                text: 'Save Journal',
                onPressed: _saveEntry,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      final journalProvider = Provider.of<JournalProvider>(context, listen: false);
      
      if (widget.entry == null) {
        await journalProvider.addEntry(
          _titleController.text,
          _contentController.text,
          _selectedMood,
          _isPublic,
        );
      } else {
        await journalProvider.updateEntry(
          widget.entry!.id,
          _titleController.text,
          _contentController.text,
          _selectedMood,
          _isPublic,
        );
      }
      
      Navigator.of(context).pop();
    }
  }
}

