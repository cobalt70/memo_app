import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 사용자 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // Google 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // 웹에서는 Firebase Auth의 GoogleAuthProvider 직접 사용
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        // 웹용 Google 로그인
        final result = await _auth.signInWithPopup(googleProvider);
        print('웹 Google 로그인 성공: ${result.user?.email}');
        return result;
      } else {
        // 모바일용 Google 로그인
        final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

        if (googleUser == null) {
          return null; // 사용자가 로그인을 취소한 경우
        }

        // Google 인증 정보 가져오기
        final GoogleSignInAuthentication googleAuth =
            googleUser.authentication;

        // Firebase 인증 정보 생성 (accessToken은 더 이상 사용할 수 없음)
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        // Firebase에 로그인
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      print('Google 로그인 오류: $e');
      return null;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      print('로그아웃 오류: $e');
    }
  }

  // 사용자 정보 가져오기
  String? get userDisplayName => currentUser?.displayName ?? "사용자";
  String? get userEmail => currentUser?.email ?? "user@example.com";
  String? get userPhotoURL => currentUser?.photoURL;
}
