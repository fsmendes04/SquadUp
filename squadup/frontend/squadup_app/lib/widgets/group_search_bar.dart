import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupSearchBar extends StatefulWidget {
  final void Function(String)? onChanged;
  final void Function(bool)? onSearchingChanged;

  const GroupSearchBar({super.key, this.onChanged, this.onSearchingChanged});

  @override
  State<GroupSearchBar> createState() => _GroupSearchBarState();
}

class _GroupSearchBarState extends State<GroupSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _controller.text;
    });
    if (widget.onChanged != null) {
      widget.onChanged!(_searchQuery);
    }
  }

  void _onTap() {
    setState(() {
      _isSearching = true;
    });
    if (widget.onSearchingChanged != null) {
      widget.onSearchingChanged!(true);
    }
  }

  void _onClose() {
    if (_searchQuery.isNotEmpty) {
      _controller.clear();
    } else {
      setState(() {
        _isSearching = false;
      });
      _focusNode.unfocus();
      if (widget.onSearchingChanged != null) {
        widget.onSearchingChanged!(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 50,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onTap: _onTap,
        style: GoogleFonts.poppins(fontSize: 14, color: darkBlue),
        decoration: InputDecoration(
          hintText: 'Search groups...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 17,
            color: darkBlue,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(Icons.search, color: darkBlue, size: 30),
          suffixIcon:
              _searchQuery.isNotEmpty || _isSearching
                  ? IconButton(
                    icon: Icon(
                      _searchQuery.isNotEmpty ? Icons.clear : Icons.close,
                      color: darkBlue,
                      size: 28,
                    ),
                    onPressed: _onClose,
                  )
                  : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
