import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final List<String> _uploadedFiles = [];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _uploadedFiles.add(result.files.single.name);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _uploadedFiles.add(image.name);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/form-selection');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upload Documents',
                      style: theme.textTheme.displaySmall,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Let's gather your information",
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload documents you want Fillora.in to extract data from. We prioritize your privacy.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    // Upload Options
                    Row(
                      children: [
                        Expanded(
                          child: _UploadButton(
                            icon: Icons.upload_file_rounded,
                            label: 'Upload File',
                            onTap: _pickFile,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _UploadButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'Take Photo',
                            onTap: _pickImage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Uploaded Files
                    if (_uploadedFiles.isNotEmpty) ...[
                      Text(
                        'Uploaded Documents',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ..._uploadedFiles.map((file) => _FileItem(
                            fileName: file,
                            onRemove: () {
                              setState(() {
                                _uploadedFiles.remove(file);
                              });
                            },
                          )),
                    ],
                    const SizedBox(height: 32),
                    // Privacy Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your documents are encrypted and secure',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Proceed Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _uploadedFiles.isNotEmpty
                      ? () => context.go('/conversational-form?from=document-upload')
                      : null,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Proceed to Form'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileItem extends StatelessWidget {
  final String fileName;
  final VoidCallback onRemove;

  const _FileItem({
    required this.fileName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.description_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(fileName),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

