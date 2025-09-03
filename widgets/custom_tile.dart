import 'package:flutter/material.dart';

class CustomTile extends StatelessWidget {
  final String title;
  final IconData? leadingIcon;
  final void Function() onTap;

  const CustomTile({
    super.key,
    required this.title,
    required this.onTap,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          if (leadingIcon != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Icon(
                leadingIcon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(title, style: TextStyle(fontSize: 18)),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
