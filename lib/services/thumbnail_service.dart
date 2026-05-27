import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:pdfx/pdfx.dart';

class ThumbnailService {
  static Future<String?> generateVideoThumbnail(String videoPath) async {
    try {
      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 256,
        quality: 75,
      );
      return thumbnailPath;
    } catch (e) {
      print("Error generating video thumbnail: $e");
      return null;
    }
  }

  static Future<String?> generatePdfThumbnail(String pdfPath) async {
    try {
      final document = await PdfDocument.openFile(pdfPath);
      final page = await document.getPage(1);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.jpeg,
        quality: 75,
      );
      
      final directory = await getTemporaryDirectory();
      final String thumbnailPath = '${directory.path}/pdf_thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File file = File(thumbnailPath);
      await file.writeAsBytes(pageImage!.bytes);
      
      await page.close();
      await document.close();
      
      return thumbnailPath;
    } catch (e) {
      print("Error generating PDF thumbnail: $e");
      return null;
    }
  }

  static bool isVideo(String path) {
    final mime = path.toLowerCase();
    return mime.endsWith('.mp4') || mime.endsWith('.mov') || mime.endsWith('.avi') || mime.endsWith('.mkv');
  }

  static bool isPdf(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }
}
