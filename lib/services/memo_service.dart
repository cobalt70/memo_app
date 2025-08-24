import "dart:convert";
import "package:shared_preferences/shared_preferences.dart";
import "../models/memo.dart";

class MemoService {
  static const String _memoKey = "memos";
  
  // Get all memos
  Future<List<Memo>> getMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? memosJson = prefs.getString(_memoKey);
    
    if (memosJson == null) return [];
    
    final List<dynamic> memosList = jsonDecode(memosJson);
    return memosList.map((json) => Memo.fromJson(json)).toList();
  }
  
  // Save memo
  Future<void> saveMemo(Memo memo) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Memo> memos = await getMemos();
    
    // Check if memo already exists (for update)
    final existingIndex = memos.indexWhere((m) => m.id == memo.id);
    if (existingIndex != -1) {
      memos[existingIndex] = memo;
    } else {
      memos.add(memo);
    }
    
    final String memosJson = jsonEncode(memos.map((m) => m.toJson()).toList());
    await prefs.setString(_memoKey, memosJson);
  }
  
  // Delete memo
  Future<void> deleteMemo(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Memo> memos = await getMemos();
    
    memos.removeWhere((memo) => memo.id == id);
    
    final String memosJson = jsonEncode(memos.map((m) => m.toJson()).toList());
    await prefs.setString(_memoKey, memosJson);
  }
  
  // Delete all memos
  Future<void> deleteAllMemos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_memoKey);
  }
}
