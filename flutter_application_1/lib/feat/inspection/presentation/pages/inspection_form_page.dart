import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_application_1/core/database/app_database.dart';
import 'package:flutter_application_1/core/database/dao/inspection_dao.dart';
import 'package:flutter_application_1/core/network/api_client.dart';
import 'package:flutter_application_1/core/storage/token_storage.dart';
import 'package:flutter_application_1/feat/inspection/data/models/inspection.dart';
import 'package:flutter_application_1/feat/inspection/services/inspection_service.dart';
import 'package:flutter_application_1/feat/inspection/services/inspection_sync_service.dart';

class InspectionFormPage extends StatefulWidget {
  const InspectionFormPage({
    super.key,
    required this.database,
    required this.workOrderId,
    required this.workOrderCode,
    required this.workOrderTitle,
    required this.onSessionInvalid,
    this.initialInspection,
  });

  final AppDatabase database;
  final String workOrderId;
  final String workOrderCode;
  final String workOrderTitle;
  final Future<void> Function() onSessionInvalid;
  final InspectionModel? initialInspection;

  @override
  State<InspectionFormPage> createState() => _InspectionFormPageState();
}

class _InspectionFormPageState extends State<InspectionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _observationController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _tokenStorage = const TokenStorage();
  late final InspectionDao _inspectionDao;
  late final InspectionSyncService _syncService;

  InspectionModel? _existing;
  String? _clientId;
  String? _condition;
  String? _photoPath;
  double? _latitude;
  double? _longitude;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    _inspectionDao = InspectionDao(widget.database);
    _syncService = InspectionSyncService(
      _inspectionDao,
      InspectionService(ApiClient()),
    );
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final provided = widget.initialInspection;
    var existing = provided;
    if (existing == null) {
      final row = await _inspectionDao.getDraftForWorkOrder(widget.workOrderId);
      if (row != null) existing = InspectionModel.fromDatabase(row);
    }
    if (!mounted) return;
    setState(() {
      _existing = existing;
      _clientId = existing?.clientId ?? const Uuid().v4();
      _observationController.text = existing?.observation ?? '';
      _condition = existing?.condition;
      _photoPath = existing?.photoPath;
      _latitude = existing?.latitude;
      _longitude = existing?.longitude;
      _locationMessage = _latitude == null
          ? null
          : 'Localização capturada: ${_latitude!.toStringAsFixed(5)}, '
                '${_longitude!.toStringAsFixed(5)}';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (image == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final photosDirectory = Directory(
        path.join(directory.path, 'inspection_photos'),
      );
      await photosDirectory.create(recursive: true);
      final extension = path.extension(image.path).isEmpty
          ? '.jpg'
          : path.extension(image.path);
      final destination = path.join(
        photosDirectory.path,
        '${_clientId ?? const Uuid().v4()}$extension',
      );
      await File(image.path).copy(destination);
      if (mounted) setState(() => _photoPath = destination);
    } catch (_) {
      _showMessage('Não foi possível preservar a foto no dispositivo.');
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _locationMessage = 'Obtendo localização...');
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const _LocationFailure(
          'Ative o GPS para capturar a localização.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const _LocationFailure('Permissão de localização negada.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw const _LocationFailure(
          'Permissão de localização bloqueada nas configurações.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationMessage =
            'Localização capturada: ${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
      });
    } on _LocationFailure catch (error) {
      if (mounted) setState(() => _locationMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _locationMessage = 'Não foi possível obter a localização.',
        );
      }
    }
  }

  Future<void> _save({required bool conclude}) async {
    if (_isSaving) return;
    if (conclude && !(_formKey.currentState?.validate() ?? false)) return;
    if (conclude && (_photoPath == null || !File(_photoPath!).existsSync())) {
      _showMessage('Adicione uma foto antes de concluir.');
      return;
    }
    if (conclude && (_latitude == null || _longitude == null)) {
      _showMessage('Capture a localização antes de concluir.');
      return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();
    final existing = _existing;
    final inspection = InspectionModel(
      id: existing?.id,
      clientId: _clientId ?? const Uuid().v4(),
      workOrderId: widget.workOrderId,
      observation: _observationController.text.trim(),
      condition: _condition,
      photoPath: _photoPath,
      latitude: _latitude,
      longitude: _longitude,
      capturedAt: existing?.capturedAt ?? now,
      status: conclude ? InspectionStatus.pending : InspectionStatus.draft,
      serverId: existing?.serverId,
      errorMessage: null,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await _inspectionDao.saveInspection(inspection.toCompanion());
      if (conclude) {
        final token = await _tokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          try {
            await _syncService.syncPendingInspections(
              accessToken: token,
              onlyClientId: inspection.clientId,
            );
          } on InspectionException catch (error) {
            if (error.shouldClearSession) {
              await widget.onSessionInvalid();
              return;
            }
          }
        }
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      _showMessage('Não foi possível salvar a inspeção.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.workOrderCode)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    widget.workOrderTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _observationController,
                    minLines: 4,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'Observação',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 10
                        ? 'Informe uma observação com pelo menos 10 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _condition,
                    decoration: const InputDecoration(labelText: 'Condição'),
                    items: const ['bom', 'regular', 'ruim', 'crítico']
                        .map(
                          (condition) => DropdownMenuItem(
                            value: condition,
                            child: Text(condition),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _condition = value),
                  ),
                  const SizedBox(height: 20),
                  if (_photoPath case final photoPath?) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(photoPath),
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          height: 100,
                          child: Center(child: Text('Foto não encontrada')),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: _choosePhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      _photoPath == null ? 'Adicionar foto' : 'Trocar foto',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _captureLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Capturar localização'),
                  ),
                  if (_locationMessage case final message?) ...[
                    const SizedBox(height: 8),
                    Text(message, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 28),
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => _save(conclude: false),
                    child: const Text('Salvar rascunho'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _isSaving ? null : () => _save(conclude: true),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Concluir inspeção'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _LocationFailure implements Exception {
  const _LocationFailure(this.message);

  final String message;
}
