import 'package:flutter/material.dart';

class CustomCircularNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final double? barHeight;
  const CustomCircularNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.barHeight,
  });

  @override
  State<CustomCircularNavBar> createState() => _CustomCircularNavBarState();
}

class _CustomCircularNavBarState extends State<CustomCircularNavBar> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<IconData> icons = [Icons.home, Icons.person];
    List<IconData> outlinedIcons = [Icons.home_outlined, Icons.person_outline];
    const darkBlue = Color.fromARGB(255, 29, 56, 95);
    const white = Color.fromARGB(255, 255, 255, 255);

    return Container(
      width: double.infinity,
      height: widget.barHeight ?? kBottomNavigationBarHeight + 5,
      decoration: const BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
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
          2,
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
