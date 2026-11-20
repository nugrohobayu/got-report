import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Longest side of the uploaded photo; keeps uploads fast and well under
/// the server's 10 MB limit.
const _maxPhotoSide = 1920;

/// Opens the camera and pops with the photo as upright JPEG bytes, or
/// `null` when closed. Camera only: there is no gallery option.
Future<Uint8List?> captureEvidencePhoto(BuildContext context, String title) {
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CameraCapturePage(title: title),
    ),
  );
}

/// The server does not read EXIF, so the rotation is applied to the pixels
/// here, then the photo is scaled down and re-encoded as JPEG.
Uint8List prepareEvidenceJpeg(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  var image = img.bakeOrientation(decoded);
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > _maxPhotoSide) {
    image = image.width >= image.height
        ? img.copyResize(image, width: _maxPhotoSide)
        : img.copyResize(image, height: _maxPhotoSide);
  }
  return img.encodeJpg(image, quality: 85);
}

class CameraCapturePage extends StatefulWidget {
  final String title;

  const CameraCapturePage({super.key, required this.title});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'Kamera tidak ditemukan.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.code == 'CameraAccessDenied'
            ? 'Izin kamera ditolak. Aktifkan izin kamera di pengaturan HP.'
            : 'Kamera tidak dapat dibuka.';
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      final raw = await file.readAsBytes();
      final jpeg = await compute(prepareEvidenceJpeg, raw);
      if (mounted) Navigator.of(context).pop(jpeg);
    } on CameraException {
      if (!mounted) return;
      setState(() => _capturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil foto. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    )
                  : controller == null || !controller.value.isInitialized
                      ? const CircularProgressIndicator(color: Colors.white)
                      : CameraPreview(controller),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Text(
                    'Jam dan lokasi dicap oleh server setelah diunggah.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  // Large shutter button for field use.
                  Semantics(
                    button: true,
                    label: 'Ambil foto',
                    child: GestureDetector(
                      onTap: controller == null ? null : _capture,
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 5),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: _capturing
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
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
}
