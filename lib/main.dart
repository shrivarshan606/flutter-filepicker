import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';


const _firebaseOptions = FirebaseOptions(
  apiKey:            'AIzaSyAZpRJ8I0BRmW7XYoUobSomKmS0eXy3toQ',
  appId:             '1:578145199895:android:3cfed03aa8bf3b81a9f952',
  messagingSenderId: '',
  projectId:         'flutterfilepicker-56501',
  storageBucket:     'flutterfilepicker-56501.firebasestorage.app',
);

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: _firebaseOptions);
  runApp(const FilePickerApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// Upload item model
// ─────────────────────────────────────────────────────────────────────────────
class UploadItem {
  final String fileName;
  final int fileSize;
  double progress;
  String status; // 'uploading' | 'done' | 'error'
  String? downloadUrl;

  UploadItem({
    required this.fileName,
    required this.fileSize,
    this.progress = 0,
    this.status = 'uploading',
  });

  String get sizeLabel {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App root
// ─────────────────────────────────────────────────────────────────────────────
class FilePickerApp extends StatelessWidget {
  const FilePickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SWS AI Document Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      home: const FilePickerHomePage(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home page
// ─────────────────────────────────────────────────────────────────────────────
class FilePickerHomePage extends StatefulWidget {
  const FilePickerHomePage({super.key});

  @override
  State<FilePickerHomePage> createState() => _FilePickerHomePageState();
}

class _FilePickerHomePageState extends State<FilePickerHomePage> {
  bool _bulkUpload = false;
  final List<UploadItem> _uploads = [];

  // ── Pick files ──────────────────────────────────────────────────────────────
  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: _bulkUpload,
    );

    if (result == null || result.files.isEmpty) return;

    for (final picked in result.files) {
      if (picked.path == null) continue;

      final item = UploadItem(
        fileName: picked.name,
        fileSize: picked.size,
        progress: 0,
        status: 'uploading',
      );

      // Show row immediately before upload starts
      setState(() => _uploads.insert(0, item));

      // Start upload — non-blocking
      _uploadToFirebase(picked, item);
    }
  }

  // ── Upload one file ─────────────────────────────────────────────────────────
  Future<void> _uploadToFirebase(PlatformFile picked, UploadItem item) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('uploads/${timestamp}_${picked.name}');

      final task = ref.putFile(File(picked.path!));

      // Stream fires on every uploaded chunk
      task.snapshotEvents.listen((snapshot) {
        if (!mounted) return;
        setState(() {
          item.progress = snapshot.bytesTransferred / snapshot.totalBytes;
          item.status   = 'uploading';
        });
      });

      await task;

      final url = await ref.getDownloadURL();

      if (!mounted) return;
      setState(() {
        item.progress    = 1.0;
        item.status      = 'done';
        item.downloadUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        item.progress = 0;
        item.status   = 'error';
      });
    }
  }

  // ── Info banner ─────────────────────────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 22, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Files are uploaded to Firebase Storage. '
              'Progress is tracked live per file below the upload box.',
              style: TextStyle(fontSize: 13.5, color: Colors.black54, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Drop zone ───────────────────────────────────────────────────────────────
  Widget _buildDropZone() {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(20),
      strokeWidth: 1.8,
      color: Colors.blue,
      dashPattern: const [8, 6],
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _pickAndUpload,
          splashColor: Colors.blue.shade50,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Upload icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade100, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.upload_file_rounded,
                    size: 36,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Drop files here or click to browse',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Any file type · Up to 20 MB per file',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 28),
                // Single / Bulk toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ModeChip(
                      label: 'Single file',
                      icon: Icons.insert_drive_file_outlined,
                      selected: !_bulkUpload,
                      onTap: () => setState(() => _bulkUpload = false),
                    ),
                    const SizedBox(width: 12),
                    _ModeChip(
                      label: 'Bulk upload',
                      icon: Icons.folder_copy_outlined,
                      selected: _bulkUpload,
                      onTap: () => setState(() => _bulkUpload = true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Progress section (appears below drop zone after first upload) ───────────
  Widget _buildProgressSection() {
    if (_uploads.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Row(
          children: [
            Text(
              'UPLOADS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_uploads.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
            const Spacer(),
            if (_uploads.any((u) => u.status == 'done'))
              GestureDetector(
                onTap: () => setState(
                  () => _uploads.removeWhere((u) => u.status == 'done'),
                ),
                child: Text(
                  'Clear done',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _uploads.length,
          itemBuilder: (context, index) {
            return _UploadRow(item: _uploads[index]);
          },
        ),
      ],
    );
  }

  // ── Document Upload tab ─────────────────────────────────────────────────────
  Widget _buildDocumentUploadPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoBanner(),
          const SizedBox(height: 20),
          _buildDropZone(),
          _buildProgressSection(), // ← progress rows appear here
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── AI Assistant tab ────────────────────────────────────────────────────────
  Widget _buildAiAssistantPage() {
    final doneUploads = _uploads.where((u) => u.status == 'done').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Assistant',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Summarize or extract insights from your uploaded files.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),
          if (doneUploads.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: Colors.grey.shade400, size: 28),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'No files uploaded yet. Upload a document in the '
                      'Document Upload tab to enable AI-powered analysis.',
                      style: TextStyle(color: Colors.black54, height: 1.5),
                    ),
                  ),
                ],
              ),
            )
          else
            ...doneUploads.map(
              (u) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined,
                        color: Colors.green.shade400, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        u.fileName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Ready',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Scaffold ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final uploadingCount =
        _uploads.where((u) => u.status == 'uploading').length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          leading: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.folder_open_rounded,
                  color: Colors.blue.shade600, size: 22),
            ),
          ),
          title: const Text(
            'SWS AI DOCUMENT HUB',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 0.4,
            ),
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined,
                      color: Colors.grey.shade700),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          uploadingCount > 0
                              ? '$uploadingCount file(s) uploading…'
                              : 'No new notifications',
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
                if (uploadingCount > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            labelColor: Colors.blue.shade700,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: Colors.blue.shade600,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13.5),
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

// ─────────────────────────────────────────────────────────────────────────────
// Mode chip widget
// ─────────────────────────────────────────────────────────────────────────────
class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade600 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Upload row widget
// ─────────────────────────────────────────────────────────────────────────────
class _UploadRow extends StatelessWidget {
  final UploadItem item;
  const _UploadRow({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    final isDone  = item.status == 'done';
    final isError = item.status == 'error';

    final Color accent = isError
        ? Colors.red.shade400
        : isDone
            ? Colors.green.shade500
            : Colors.blue.shade600;

    final IconData statusIcon = isError
        ? Icons.error_outline_rounded
        : isDone
            ? Icons.check_circle_outline_rounded
            : Icons.cloud_upload_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── File name + size + status badge ───────────────────────────
          Row(
            children: [
              Icon(statusIcon, color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.sizeLabel,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isError
                      ? 'Failed'
                      : isDone
                          ? 'Done'
                          : '${(item.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Progress bar ──────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: isError ? 1.0 : item.progress,
              minHeight: 7,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),

          // ── Download URL when done ────────────────────────────────────
          if (isDone && item.downloadUrl != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.link_rounded,
                    size: 14, color: Colors.blue.shade400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.downloadUrl!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade400,
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // ── Error message ─────────────────────────────────────────────
          if (isError) ...[
            const SizedBox(height: 8),
            Text(
              'Upload failed. Check your connection or Storage rules.',
              style: TextStyle(fontSize: 12, color: Colors.red.shade400),
            ),
          ],
        ],
      ),
    );
  }
}