import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/theme/app_colors.dart';
import 'package:got_report/features/form_dinamis/domain/entities/task_form.dart';
import 'package:got_report/features/form_dinamis/presentation/bloc/task_form_cubit.dart';
import 'package:got_report/features/kamera/presentation/pages/camera_capture_page.dart';
import 'package:got_report/features/mulai_tugas/presentation/pages/qr_scan_page.dart';

/// Renders one schema field by its `type`. Unknown types show
/// "Field tidak didukung" instead of failing.
class FormFieldView extends StatelessWidget {
  final FormStepDef step;
  final FormFieldDef field;

  const FormFieldView({super.key, required this.step, required this.field});

  @override
  Widget build(BuildContext context) {
    final key = fieldKey(step.id, field.id);
    final cubit = context.read<TaskFormCubit>();
    final state = context.watch<TaskFormCubit>().state;
    final value = state.answers[key];
    final error = state.fieldErrors[key];
    void set(dynamic v) => cubit.setAnswer(step.id, field.id, v);

    final Widget input = switch (field.type) {
      FieldType.section => const SizedBox.shrink(),
      FieldType.photo => _PhotoInput(step: step, field: field),
      FieldType.checklist => _ChecklistInput(
          options: field.options,
          value: value is List ? value.cast<String>() : const [],
          onChanged: set,
        ),
      FieldType.choice => _ChoiceInput(
          options: field.options,
          value: value?.toString(),
          onChanged: set,
        ),
      FieldType.number => _TextInput(
          initial: value?.toString() ?? '',
          number: true,
          hint: _rangeHint(field),
          onChanged: set,
        ),
      FieldType.text => _TextInput(
          initial: value?.toString() ?? '',
          onChanged: set,
        ),
      FieldType.qr => _QrInput(value: value?.toString(), onChanged: set),
      FieldType.signature => const _Info(
          icon: Icons.draw_outlined,
          text: 'Tanda tangan klien diminta setelah semua langkah selesai '
              'dan hasil dikirim.',
        ),
      _ => const _Info(
          icon: Icons.help_outline,
          text: 'Field tidak didukung',
        ),
    };

    if (field.type == FieldType.section) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          field.label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      );
    }

    return _FieldFrame(
      label: field.label,
      required: field.required,
      hint: field.hint,
      error: error,
      badge: switch (field.pairRole) {
        'before' => 'Sebelum',
        'after' => 'Sesudah',
        _ => null,
      },
      child: input,
    );
  }

  static String? _rangeHint(FormFieldDef f) {
    if (f.min != null && f.max != null) return '${f.min} – ${f.max}';
    if (f.min != null) return 'Minimal ${f.min}';
    if (f.max != null) return 'Maksimal ${f.max}';
    return null;
  }
}

class _FieldFrame extends StatelessWidget {
  final String label;
  final bool required;
  final String? hint;
  final String? error;
  final String? badge;
  final Widget child;

  const _FieldFrame({
    required this.label,
    required this.required,
    required this.child,
    this.hint,
    this.error,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: error == null ? scheme.outline : scheme.error,
          width: error == null ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: label,
                    children: [
                      if (required)
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: scheme.error),
                        ),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          if (hint != null && hint!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 10),
          child,
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: TextStyle(color: scheme.error, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _ChecklistInput extends StatelessWidget {
  final List<String> options;
  final List<String> value;
  final ValueChanged<List<String>> onChanged;

  const _ChecklistInput({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final o in options)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(o),
            value: value.contains(o),
            onChanged: (checked) => onChanged(
              checked == true
                  ? [...value, o]
                  : value.where((v) => v != o).toList(),
            ),
          ),
      ],
    );
  }
}

class _ChoiceInput extends StatelessWidget {
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _ChoiceInput({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final o in options)
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            title: Text(o),
            value: o,
            groupValue: value,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

/// Text / number input that keeps its own controller (the cubit holds the
/// value; rebuilding must not reset the cursor).
class _TextInput extends StatefulWidget {
  final String initial;
  final bool number;
  final String? hint;
  final ValueChanged<String> onChanged;

  const _TextInput({
    required this.initial,
    required this.onChanged,
    this.number = false,
    this.hint,
  });

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      keyboardType: widget.number
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.multiline,
      inputFormatters: widget.number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))]
          : null,
      minLines: widget.number ? 1 : 3,
      maxLines: widget.number ? 1 : 6,
      decoration: InputDecoration(
        hintText: widget.hint ?? (widget.number ? 'Angka' : 'Tulis catatan'),
      ),
    );
  }
}

class _QrInput extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const _QrInput({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scanned = value != null && value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scanned)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.statusSelesai),
                const SizedBox(width: 8),
                Expanded(child: Text(value!)),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: () async {
            final code = await Navigator.of(context).push<String>(
              MaterialPageRoute(builder: (_) => const QrScanPage()),
            );
            if (code != null) onChanged(code);
          },
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(scanned ? 'Scan ulang' : 'Scan QR'),
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Info({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: color))),
      ],
    );
  }
}

/// Camera photo: take → upload → server watermark → show the watermarked
/// image from `/files/{fileId}`.
class _PhotoInput extends StatefulWidget {
  final FormStepDef step;
  final FormFieldDef field;

  const _PhotoInput({required this.step, required this.field});

  @override
  State<_PhotoInput> createState() => _PhotoInputState();
}

class _PhotoInputState extends State<_PhotoInput> {
  /// The photo just taken, shown until the watermarked one is ready.
  Uint8List? _local;
  String? _loadedFileId;

  /// Reading the GPS (fake GPS check) before the camera opens.
  bool _checkingGps = false;
  Future<Uint8List>? _remote;

  Future<void> _take() async {
    final cubit = context.read<TaskFormCubit>();
    // Reject a fake GPS before opening the camera.
    setState(() => _checkingGps = true);
    final ok = await cubit.checkPhotoLocation(widget.step.id, widget.field.id);
    if (!mounted) return;
    setState(() => _checkingGps = false);
    if (!ok) return;
    final jpeg = await captureEvidencePhoto(context, widget.field.label);
    if (jpeg == null || !mounted) return;
    setState(() => _local = jpeg);
    await cubit.uploadPhoto(widget.step.id, widget.field.id, jpeg);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final key = fieldKey(widget.step.id, widget.field.id);
    final state = context.watch<TaskFormCubit>().state;
    final media = state.media[key];
    final uploading = state.uploading.contains(key);
    final busy = uploading || _checkingGps;

    final fileId = media?.isReady == true ? media!.fileId : null;
    if (fileId != null && fileId != _loadedFileId) {
      _loadedFileId = fileId;
      _remote = context.read<TaskFormCubit>().fileBytes(fileId);
    }

    final Widget preview;
    if (_remote != null && fileId != null) {
      preview = FutureBuilder<Uint8List>(
        future: _remote,
        builder: (context, snap) => snap.hasData
            ? Image.memory(snap.data!, fit: BoxFit.cover)
            : _local != null
                ? Image.memory(_local!, fit: BoxFit.cover)
                : const Center(child: CircularProgressIndicator()),
      );
    } else if (_local != null) {
      preview = Image.memory(_local!, fit: BoxFit.cover);
    } else if (media != null && !media.isFailed) {
      preview = const Center(child: CircularProgressIndicator());
    } else {
      preview = Center(
        child: Icon(
          Icons.photo_camera_outlined,
          size: 48,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: scheme.surfaceContainerHighest),
                preview,
                if (busy)
                  ColoredBox(
                    color: Colors.black45,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 10),
                          Text(
                            uploading
                                ? 'Mengunggah & memberi cap waktu...'
                                : 'Memeriksa lokasi GPS...',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (media != null && media.flags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            media.flags.map(_flagLabel).join(' · '),
            style: const TextStyle(fontSize: 12, color: AppColors.orange),
          ),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: busy ? null : _take,
          icon: const Icon(Icons.photo_camera),
          label: Text(media == null ? 'Ambil foto' : 'Ambil ulang'),
        ),
      ],
    );
  }

  static String _flagLabel(String flag) => switch (flag) {
        'OUT_OF_RADIUS' => 'Di luar radius lokasi',
        'LOW_ACCURACY' => 'Akurasi GPS rendah',
        'LATE_UPLOAD' => 'Diunggah terlambat',
        'CLOCK_SKEW' => 'Jam HP tidak sesuai',
        _ => flag,
      };
}
