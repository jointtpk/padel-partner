import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../routes.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final _auth = FirebaseAuth.instance;
  final user = Rx<User?>(null);
  final verificationId = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    user.bindStream(_auth.authStateChanges());
  }

  Future<void> sendOTP({required String phoneNumber}) async {
    isLoading.value = true;
    errorMessage.value = '';

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        isLoading.value = false;
      },
      verificationFailed: (e) {
        isLoading.value = false;
        errorMessage.value = e.message ?? 'Verification failed. Check your number.';
      },
      codeSent: (vid, _) {
        verificationId.value = vid;
        isLoading.value = false;
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<bool> verifyOTP(String otp) async {
    try {
      isLoading.value = true;
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      isLoading.value = false;
      return true;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Invalid code. Try again.';
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    Get.offAllNamed(Routes.signUp);
  }
}
