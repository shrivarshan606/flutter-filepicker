import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FilePickerApp());
}

class FilePickerApp extends StatelessWidget {
  const FilePickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple File Picker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FilePickerHomePage(),
    );
  }
}

class FilePickerHomePage extends StatefulWidget {
  const FilePickerHomePage({super.key});

  @override
  State<FilePickerHomePage> createState() => _FilePickerHomePageState();
}

class _FilePickerHomePageState extends State<FilePickerHomePage> {
  String? _fileName;
  String? _filePath;
  int? _fileSize;
  String? _fileExtension;
  bool _bulkUpload = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: _bulkUpload,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;

    setState(() {
      _fileName = file.name;
      _filePath = file.path;
      _fileSize = file.size;
      _fileExtension = file.extension;
    });
  }

  Widget _buildFileInfo() {
    if (_fileName == null) {
      return const Text('No file selected yet.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name: $_fileName'),
        const SizedBox(height: 8),
        Text('Path: ${_filePath ?? 'Unavailable'}'),
        const SizedBox(height: 8),
        Text('Size: ${_fileSize ?? 0} bytes'),
        const SizedBox(height: 8),
        Text('Extension: ${_fileExtension ?? 'Unknown'}'),
      ],
    );
  }

  Widget _buildDocumentUploadPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Icon(Icons.info_outline, size: 28, color: Colors.blue),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Simulated demo — files are processed client-side only, nothing is stored.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Upload 1–3 files to see individual per-file progress bars. Upload 4 or more files to trigger the bulk notification flow.',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DottedBorder(
            options: const RoundedRectDottedBorderOptions(
              radius: Radius.circular(20),
              strokeWidth: 1.8,
              color: Colors.blue,
              dashPattern: [8, 6],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.upload_file, size: 32, color: Colors.blue),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Drop files here or click to browse',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Any file type · Up to 20 MB per file',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Single file'),
                            selected: !_bulkUpload,
                            selectedColor: Colors.blue.shade100,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: !_bulkUpload ? Colors.blue : Colors.grey.shade700,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _bulkUpload = !selected;
                              });
                            },
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('Bulk upload'),
                            selected: _bulkUpload,
                            selectedColor: Colors.blue.shade100,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: _bulkUpload ? Colors.blue : Colors.grey.shade700,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _bulkUpload = selected;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Try 4+ files to trigger notifications',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildFileInfo(),
        ],
      ),
    );
  }

  Widget _buildAiAssistantPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'AI Assistant',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 16),
          Text(
            'Ask the assistant to summarize your selected document, extract insights, or generate a response based on the uploaded file.',
          ),
          SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No AI content yet. Upload a document in the Document Upload tab to enable AI-powered options.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.blue),
            tooltip: 'Open file picker',
            onPressed: _pickFile,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.blue),
              tooltip: 'Notifications',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No new notifications')),
                );
              },
            ),
          ],
          title: const Text(
            'SWS AI DOCUMENT HUB',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          bottom: TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'Document Upload'),
              Tab(text: 'AI Assistant'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDocumentUploadPage(),
            _buildAiAssistantPage(),
          ],
        ),
      ),
    );
  }
}
