/*
 * Copyright 2002-2017 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';

import '../../shared/forms/app_validators.dart';
import '../../shared/navigation/app_routes.dart';
import '../../shared/navigation/navigation_extensions.dart';
import '../../shared/widgets/page_width.dart';
import 'owner.dart';
import 'owner_service.dart';

class OwnerFormScreen extends StatefulWidget {
  const OwnerFormScreen({super.key, this.owner, this.ownerId})
    : assert(owner == null || ownerId == null);

  final Owner? owner;
  final int? ownerId;

  @override
  State<OwnerFormScreen> createState() => _OwnerFormScreenState();
}

class _OwnerFormScreenState extends State<OwnerFormScreen> {
  final OwnerService _ownerService = OwnerService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _telephoneController;

  bool _isSaving = false;
  bool _isLoading = false;
  Owner? _loadedOwner;
  String? _errorMessage;

  Owner? get _currentOwner => widget.owner ?? _loadedOwner;
  bool get _isEditing => widget.owner != null || widget.ownerId != null;
  String get _fallbackRoute {
    final ownerId = _currentOwner?.id ?? widget.ownerId;
    return ownerId == null ? AppRoutes.owners : AppRoutes.owner(ownerId);
  }

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.owner?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.owner?.lastName ?? '',
    );
    _addressController = TextEditingController(
      text: widget.owner?.address ?? '',
    );
    _cityController = TextEditingController(text: widget.owner?.city ?? '');
    _telephoneController = TextEditingController(
      text: widget.owner?.telephone ?? '',
    );
    if (widget.ownerId != null) {
      _loadOwner();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _loadOwner() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final owner = await _ownerService.getOwner(widget.ownerId!);
      if (!mounted) return;

      setState(() {
        _loadedOwner = owner;
        _firstNameController.text = owner.firstName;
        _lastNameController.text = owner.lastName;
        _addressController.text = owner.address;
        _cityController.text = owner.city;
        _telephoneController.text = owner.telephone;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final currentOwner = _currentOwner;

    final owner = Owner(
      id: currentOwner?.id ?? widget.ownerId,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      telephone: _telephoneController.text.trim(),
      pets: currentOwner?.pets ?? const [],
    );

    try {
      if (_isEditing) {
        await _ownerService.updateOwner(owner);
      } else {
        await _ownerService.createOwner(owner);
      }

      if (!mounted) {
        return;
      }
      context.popOrGo<bool>(_fallbackRoute, result: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Owner' : 'New Owner')),
      body: AppPageWidth(
        maxWidth: 720,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null &&
                  widget.ownerId != null &&
                  _currentOwner == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadOwner,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_errorMessage != null) ...[
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_errorMessage!),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _firstNameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                          ),
                          validator: AppValidators.firstName(
                            'First name',
                            minLength: 1,
                            maxLength: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                          ),
                          validator: AppValidators.lastName(
                            'Last name',
                            minLength: 1,
                            maxLength: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                          ),
                          validator: AppValidators.plainText(
                            'Address',
                            minLength: 1,
                            maxLength: 255,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cityController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'City'),
                          validator: AppValidators.plainText(
                            'City',
                            minLength: 1,
                            maxLength: 80,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _telephoneController,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Telephone',
                          ),
                          validator: AppValidators.exactDigits(
                            'Telephone',
                            length: 10,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _isEditing ? 'Save Owner' : 'Add Owner',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
