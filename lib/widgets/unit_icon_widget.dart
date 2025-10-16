import 'package:flutter/material.dart';

class UnitIconWidget extends StatelessWidget {
  final String unit;
  final double size;
  final Color? color;

  const UnitIconWidget({
    Key? key,
    required this.unit,
    this.size = 16,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData iconData;

    // Usar ícones do Material Design ao invés de emojis
    switch (unit.toLowerCase()) {
      case 'kwh':
      case 'energia':
        iconData = Icons.flash_on;
        break;
      case '°c':
      case 'celsius':
      case 'temperatura':
        iconData = Icons.thermostat;
        break;
      case '%':
      case 'umidade':
      case 'humidity':
        iconData = Icons.water_drop;
        break;
      case 'watts':
      case 'w':
        iconData = Icons.lightbulb;
        break;
      default:
        iconData = Icons.analytics;
    }

    return Icon(
      iconData,
      size: size,
      color: color ?? Theme.of(context).primaryColor,
    );
  }
}