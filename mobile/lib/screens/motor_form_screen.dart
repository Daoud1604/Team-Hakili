import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/motor_provider.dart';
import '../providers/config_provider.dart';
import '../providers/auth_provider.dart';
import '../models/motor.dart';

class MotorFormScreen extends StatefulWidget {
  final Motor? motor;

  const MotorFormScreen({super.key, this.motor});

  @override
  State<MotorFormScreen> createState() => _MotorFormScreenState();
}

class _MotorFormScreenState extends State<MotorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _esp32UidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.motor != null) {
      _nameController.text = widget.motor!.name;
      _codeController.text = widget.motor!.code;
      _locationController.text = widget.motor!.location ?? '';
      _descriptionController.text = widget.motor!.description ?? '';
      _esp32UidController.text = widget.motor!.esp32Uid ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _esp32UidController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final motorProvider = Provider.of<MotorProvider>(context, listen: false);
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final motor = Motor(
      id: widget.motor?.id,
      name: _nameController.text.trim(),
      code: _codeController.text.trim().toUpperCase(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      esp32Uid: _esp32UidController.text.trim().isEmpty
          ? null
          : _esp32UidController.text.trim(),
    );

    final success = widget.motor == null
        ? await motorProvider.createMotor(motor,
            configProvider: configProvider, authProvider: authProvider)
        : await motorProvider.updateMotor(motor,
            configProvider: configProvider, authProvider: authProvider);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.motor == null
                ? 'Machine créée avec succès'
                : 'Machine mise à jour',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la sauvegarde'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.motor == null ? 'Nouvelle machine' : 'Modifier machine'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  hintText: 'Ex: Broyeur Principal',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code *',
                  hintText: 'Ex: M001',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le code est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Localisation',
                  hintText: 'Ex: Atelier 3, Ligne 2',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _esp32UidController,
                decoration: const InputDecoration(
                  labelText: 'ESP32 UID (optionnel)',
                  hintText: 'Ex: ESP32_001',
                  border: OutlineInputBorder(),
                  helperText: 'Identifiant du boîtier ESP32',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
