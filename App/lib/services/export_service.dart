import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import '../models/form_model.dart';

class ExportService {
  static Future<File> exportToJson(FormModel form) async {
    final jsonData = jsonEncode(form.toMap());
    final output = await getApplicationDocumentsDirectory();
    final file = File(path.join(
      output.path,
      '${form.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.json',
    ));
    await file.writeAsString(jsonData);
    return file;
  }

  static Future<File> exportToCsv(FormModel form) async {
    final buffer = StringBuffer();
    buffer.writeln('Field,Value');
    form.formData.forEach((key, value) {
      buffer.writeln('"$key","$value"');
    });

    final output = await getApplicationDocumentsDirectory();
    final file = File(path.join(
      output.path,
      '${form.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv',
    ));
    await file.writeAsString(buffer.toString());
    return file;
  }

  static Future<void> shareForm(FormModel form, {String format = 'json'}) async {
    File file;
    if (format == 'json') {
      file = await exportToJson(form);
    } else {
      file = await exportToCsv(form);
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Form: ${form.title}',
    );
  }

  static Future<String> exportToText(FormModel form) async {
    final buffer = StringBuffer();
    buffer.writeln(form.title);
    buffer.writeln('=' * form.title.length);
    buffer.writeln();
    
    if (form.description != null) {
      buffer.writeln(form.description);
      buffer.writeln();
    }
    
    buffer.writeln('Form Data:');
    buffer.writeln('-' * 40);
    form.formData.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    
    buffer.writeln();
    buffer.writeln('Status: ${form.status}');
    buffer.writeln('Progress: ${(form.progress * 100).toStringAsFixed(0)}%');
    buffer.writeln('Created: ${form.createdAt.toString()}');
    
    return buffer.toString();
  }
}

