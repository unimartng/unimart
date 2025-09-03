import 'package:flutter/material.dart';

class LocationToggleWidget extends StatelessWidget {
  final bool isLocationEnabled;
  final ValueChanged<bool?> onToggle;
  final EdgeInsetsGeometry? padding;

  const LocationToggleWidget({
    super.key,
    required this.isLocationEnabled,
    required this.onToggle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(left: 13, right: 15, top: 10),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          // Text label - takes up remaining space
          Expanded(
            child: Text(
              'Enable Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),

          // Switch with accessibility
          Semantics(
            label: 'Location toggle switch',
            hint: isLocationEnabled
                ? 'Double tap to disable location'
                : 'Double tap to enable location',
            child: Switch(
              value: isLocationEnabled,
              onChanged: onToggle,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// Alternative version with InkWell for better UX
class LocationToggleWithTap extends StatelessWidget {
  final bool isLocationEnabled;
  final ValueChanged<bool?> onToggle;
  final EdgeInsetsGeometry? padding;
  final String? subtitle;

  const LocationToggleWithTap({
    super.key,
    required this.isLocationEnabled,
    required this.onToggle,
    this.padding,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(left: 13, right: 15, top: 10),
      child: InkWell(
        onTap: () => onToggle(!isLocationEnabled),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // Text content - takes up remaining space
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Switch
              Switch(
                value: isLocationEnabled,
                onChanged: onToggle,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Usage example widget
