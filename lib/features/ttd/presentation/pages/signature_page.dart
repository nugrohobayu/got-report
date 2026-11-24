import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:got_report/core/theme/app_colors.dart';
import 'package:signature/signature.dart';

/// What the client entered on [SignaturePage].
class SignatureResult {
  final String signerName;
  final String? signerTitle;

  /// Signature as PNG (black on white).
  final Uint8List png;

  const SignatureResult({
    required this.signerName,
    required this.signerTitle,
    required this.png,
  });
}

/// Client signature: name (required), title (optional) and a drawing
/// canvas, with Hapus and Selesai. Pops with a [SignatureResult] via
/// [onSubmit], which returns `true` when the signature was accepted.
class SignaturePage extends StatefulWidget {
  final String taskTitle;

  /// Sends the signature; returns `true` on success (the page then closes).
  final Future<bool> Function(SignatureResult result) onSubmit;

  /// Error from the last submit, shown above the button.
  final ValueListenable<String?> error;

  const SignaturePage({
    super.key,
    required this.taskTitle,
    required this.onSubmit,
    required this.error,
  });

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  final _name = TextEditingController();
  final _title = TextEditingController();
  final _signature = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _signature.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _signature.dispose();
    super.dispose();
  }

  bool get _ready =>
      _name.text.trim().isNotEmpty && _signature.isNotEmpty && !_sending;

  Future<void> _submit() async {
    final png = await _signature.toPngBytes();
    if (png == null || !mounted) return;
    setState(() => _sending = true);
    final ok = await widget.onSubmit(
      SignatureResult(
        signerName: _name.text.trim(),
        signerTitle: _title.text.trim().isEmpty ? null : _title.text.trim(),
        png: png,
      ),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tanda tangan klien')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(
            widget.taskTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Minta klien memeriksa hasil pekerjaan, lalu menandatangani di '
            'bawah ini.',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama penanda tangan',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Jabatan (opsional)',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tanda tangan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed:
                    _signature.isEmpty || _sending ? null : _signature.clear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // White pad in both themes: the PNG is black on white.
          // Border outside the canvas: the white pad would paint over it.
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: scheme.primary, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Signature(
                controller: _signature,
                height: 240,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tanda tangani di dalam kotak putih.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          ValueListenableBuilder<String?>(
            valueListenable: widget.error,
            builder: (context, error, _) => error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      error,
                      style: TextStyle(color: scheme.error, fontSize: 14),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
          onPressed: _ready ? _submit : null,
          icon: _sending
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check),
          label: Text(_sending ? 'Mengirim...' : 'Selesai'),
        ),
      ),
    );
  }
}
