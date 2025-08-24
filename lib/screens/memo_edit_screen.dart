import "package:flutter/material.dart";
import "package:uuid/uuid.dart";
import "../models/memo.dart";
import "../services/memo_service.dart";

class MemoEditScreen extends StatefulWidget {
  final Memo? memo; // null for new memo, not null for editing
  
  const MemoEditScreen({super.key, this.memo});
  
  @override
  State<MemoEditScreen> createState() => _MemoEditScreenState();
}

class _MemoEditScreenState extends State<MemoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _memoService = MemoService();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // 웹에서 텍스트 입력 오류를 방지하기 위해 안전하게 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.memo != null) {
        _titleController.text = widget.memo!.title;
        _contentController.text = widget.memo!.content;
      }
    });
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  Future<void> _saveMemo() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final now = DateTime.now();
      final memo = Memo(
        id: widget.memo?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: widget.memo?.createdAt ?? now,
        updatedAt: now,
      );
      
      await _memoService.saveMemo(memo);
      
      if (mounted) {
        Navigator.pop(context, memo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("메모 저장 중 오류가 발생했습니다: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.memo != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "메모 수정" : "새 메모"),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "제목",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "제목을 입력해주세요";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: "내용",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "내용을 입력해주세요";
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMemo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditing ? "수정" : "저장"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _showDeleteDialog() async {
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
      await _deleteMemo();
    }
  }
  
  Future<void> _deleteMemo() async {
    if (widget.memo == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _memoService.deleteMemo(widget.memo!.id);
      
      if (mounted) {
        Navigator.pop(context, "deleted");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("메모 삭제 중 오류가 발생했습니다: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
