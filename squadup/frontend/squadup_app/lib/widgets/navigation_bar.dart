import 'package:flutter/material.dart';

class CustomCircularNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final double? barHeight;
  final List<IconData>? icons;
  final List<IconData>? outlinedIcons;
  final Color? backgroundColor;
  final Color? iconColor;

  const CustomCircularNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.barHeight,
    this.icons,
    this.outlinedIcons,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<CustomCircularNavBar> createState() => _CustomCircularNavBarState();
}

class _CustomCircularNavBarState extends State<CustomCircularNavBar> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final List<IconData> icons = widget.icons ?? [Icons.home, Icons.person];
    final List<IconData> outlinedIcons =
        widget.outlinedIcons ?? [Icons.home_outlined, Icons.person_outline];
    final Color darkBlue =
        widget.backgroundColor ?? const Color.fromARGB(255, 29, 56, 95);
    final Color white =
        widget.iconColor ?? const Color.fromARGB(255, 255, 255, 255);

    return Container(
      width: double.infinity,
      height: widget.barHeight ?? kBottomNavigationBarHeight + 5,
      decoration: BoxDecoration(
        color: darkBlue,
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(40, 0, 0, 0),
            blurRadius: 15,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          icons.length,
          (index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: InkWell(
                onTap: () {
                  widget.onTap(index);
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: EdgeInsets.only(
                        bottom: index == widget.currentIndex ? 4 : 14,
                      ),
                      width: size.width * .025,
                      height:
                          index == widget.currentIndex ? size.width * .014 : 0,
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(10),
                        ),
                      ),
                    ),
                    Icon(
                      index == widget.currentIndex
                          ? icons[index]
                          : outlinedIcons[index],
                      size: size.width * .076,
                      color: white,
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
