import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/mood_weather.dart';

/// WeatherWidget — عرض الطقس المزاجي.
class WeatherWidget extends StatelessWidget {
  final MoodWeather weather;
  final double size;
  final bool animated;

  const WeatherWidget({
    super.key,
    required this.weather,
    this.size = 80,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: weather.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: weather.gradient.first.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        weather.emoji,
        style: TextStyle(fontSize: size * 0.5),
      ),
    );

    if (animated) {
      content = content
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 2000.ms,
            curve: Curves.easeInOut,
          );
    }

    return content;
  }
}

/// WeatherForecastCard — توقعات 7 أيام.
class WeatherForecastCard extends StatelessWidget {
  final List<MoodWeather> weekWeather;
  final List<String> dayLabels;

  const WeatherForecastCard({
    super.key,
    required this.weekWeather,
    required this.dayLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_outlined, size: 18, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text(
                'Mood Weather · 7 days',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekWeather.asMap().entries.map((e) {
              return Column(
                children: [
                  Text(
                    dayLabels[e.key],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  WeatherWidget(
                    weather: e.value,
                    size: 40,
                    animated: false,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
