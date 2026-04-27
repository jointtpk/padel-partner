import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/controllers/app_controller.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/avatar_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _store = AppController.to;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _handleCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _cityCtrl;

  String? _photoPath;

  @override
  void initState() {
    super.initState();
    final u = _store.currentUser.value;
    _nameCtrl   = TextEditingController(text: u.name);
    _handleCtrl = TextEditingController(text: u.handle.startsWith('@') ? u.handle.substring(1) : u.handle);
    _emailCtrl  = TextEditingController(text: u.email ?? '');
    _bioCtrl    = TextEditingController(text: u.bio ?? '');
    _cityCtrl   = TextEditingController(text: u.city);
    _photoPath  = u.photoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _handleCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile != null) setState(() => _photoPath = xfile.path);
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      Get.snackbar('Name required', 'Please enter your name',
          backgroundColor: AppColors.hot, colorText: Colors.white,
          margin: const EdgeInsets.all(16), borderRadius: 12);
      return;
    }
    final h = _handleCtrl.text.trim();
    _store.updateCurrentUser(
      name: _nameCtrl.text.trim(),
      handle: h.isEmpty ? null : '@$h',
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      photoPath: _photoPath,
    );
    Get.back();
    Get.snackbar('Profile updated', 'Your changes were saved',
        backgroundColor: AppColors.ball, colorText: AppColors.ink,
        margin: const EdgeInsets.all(16), borderRadius: 12,
        duration: const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue900,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('Edit profile',
                      style: AppFonts.display(22, color: Colors.white, letterSpacing: -0.4)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.ball,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('Save',
                          style: AppFonts.display(13, color: AppColors.ink, letterSpacing: 0.3)),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    Center(
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Stack(
                          children: [
                            Container(
                              width: 96, height: 96,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: Colors.white.withOpacity(0.20)),
                              ),
                              child: _photoPath != null && _photoPath!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(28),
                                      child: Image.network(
                                        _photoPath!,
                                        fit: BoxFit.cover,
                                        width: 96, height: 96,
                                        errorBuilder: (_, __, ___) => _avatarFallback(),
                                      ),
                                    )
                                  : _avatarFallback(),
                            ),
                            Positioned(
                              right: -2, bottom: -2,
                              child: Container(
                                width: 32, height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.ball,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_outlined, color: AppColors.ink, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text('Tap photo to change',
                          style: AppFonts.mono(10, color: Colors.white.withOpacity(0.45), letterSpacing: 0.2)),
                    ),
                    const SizedBox(height: 28),

                    _Label('FULL NAME'),
                    _Field(controller: _nameCtrl, hint: 'Your name'),
                    const SizedBox(height: 16),

                    _Label('USERNAME'),
                    _Field(
                      controller: _handleCtrl,
                      hint: 'username',
                      prefix: '@',
                      formatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_.]')),
                        LengthLimitingTextInputFormatter(18),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _Label('EMAIL'),
                    _Field(controller: _emailCtrl, hint: 'you@email.com', keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),

                    _Label('CITY'),
                    _Field(controller: _cityCtrl, hint: 'e.g. DHA Phase 6'),
                    const SizedBox(height: 16),

                    _Label('BIO'),
                    _Field(
                      controller: _bioCtrl,
                      hint: '3.0 level · weekend hitter · big forehand.',
                      maxLines: 3,
                      maxLength: 100,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return Center(
      child: AvatarWidget(player: _store.currentUser.value, size: 80, ring: false),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: AppFonts.mono(10, color: Colors.white.withOpacity(0.55), letterSpacing: 0.2)),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.prefix,
    this.formatters,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? prefix;
  final List<TextInputFormatter>? formatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prefix != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 0, 14),
              child: Text(prefix!,
                  style: AppFonts.mono(14, color: Colors.white.withOpacity(0.50))),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              maxLength: maxLength,
              inputFormatters: formatters,
              style: AppFonts.body(15, color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppFonts.body(15, color: Colors.white.withOpacity(0.40)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(prefix != null ? 8 : 16, 14, 16, 14),
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
