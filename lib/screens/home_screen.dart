import "package:flutter/material.dart";
import "../models/memo.dart";
import "../services/memo_service.dart";
import "../services/auth_service.dart";
import "memo_edit_screen.dart";

class HomeScreen extends StatefulWidget {
  final VoidCallback? onLogout; // 웹용 로그아웃 콜백

  const HomeScreen({super.key, this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _memoService = MemoService();
  final _authService = AuthService();
  List<Memo> _memos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  Future<void> _loadMemos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final memos = await _memoService.getMemos();
      setState(() {
        _memos = memos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("메모를 불러오는 중 오류가 발생했습니다: $e")));
      }
    }
  }

  Future<void> _addNewMemo() async {
    final result = await Navigator.push<Memo>(
      context,
      MaterialPageRoute(builder: (context) => const MemoEditScreen()),
    );

    if (result != null) {
      await _loadMemos();
    }
  }

  Future<void> _editMemo(Memo memo) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (context) => MemoEditScreen(memo: memo)),
    );

    if (result != null) {
      if (result == "deleted") {
        await _loadMemos();
      } else if (result is Memo) {
        await _loadMemos();
      }
    }
  }

  Future<void> _deleteMemo(Memo memo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("메모 삭제"),
        content: const Text("이 메모를 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("삭제"),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _memoService.deleteMemo(memo.id);
        await _loadMemos();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("메모가 삭제되었습니다")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("메모 삭제 중 오류가 발생했습니다: $e")));
        }
      }
    }
  }

  Future<void> _deleteAllMemos() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("모든 메모 삭제"),
        content: const Text("모든 메모를 삭제하시겠습니까?이 작업은 되돌릴 수 없습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text("모두 삭제"),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _memoService.deleteAllMemos();
        await _loadMemos();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("모든 메모가 삭제되었습니다")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("메모 삭제 중 오류가 발생했습니다: $e")));
        }
      }
    }
  }

  Future<void> _signOut() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("로그아웃"),
        content: const Text("로그아웃하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("로그아웃"),
          ),
        ],
      ),
    );

    if (result == true) {
      if (widget.onLogout != null) {
        // 웹용 로그아웃 콜백 호출
        widget.onLogout!();
      } else {
        // 모바일용 Firebase 로그아웃
        await _authService.signOut();
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final memoDate = DateTime(date.year, date.month, date.day);

    if (memoDate == today) {
      return "오늘 ${date.hour.toString().padLeft(2, "0")}:${date.minute.toString().padLeft(2, "0")}";
    } else if (memoDate == today.subtract(const Duration(days: 1))) {
      return "어제 ${date.hour.toString().padLeft(2, "0")}:${date.minute.toString().padLeft(2, "0")}";
    } else {
      return "${date.month}/${date.day} ${date.hour.toString().padLeft(2, "0")}:${date.minute.toString().padLeft(2, "0")}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "메모 앱",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          // 사용자 정보 표시
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (user.photoURL != null)
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(user.photoURL!),
                    )
                  else
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      child: Text(
                        (user.displayName?.substring(0, 1).toUpperCase() ??
                            'U'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    user.displayName ?? user.email ?? '사용자',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (_memos.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == "delete_all") {
                  _deleteAllMemos();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: "delete_all",
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red),
                      SizedBox(width: 8),
                      Text("모든 메모 삭제"),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _memos.isEmpty
          ? _buildEmptyState()
          : _buildMemoList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewMemo,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "메모가 없습니다",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "새 메모를 작성해보세요!",
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _memos.length,
      itemBuilder: (context, index) {
        final memo = _memos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              memo.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  memo.content,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(memo.updatedAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == "edit") {
                  _editMemo(memo);
                } else if (value == "delete") {
                  _deleteMemo(memo);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: "edit",
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text("수정"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "delete",
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text("삭제"),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _editMemo(memo),
          ),
        );
      },
    );
  }
}
