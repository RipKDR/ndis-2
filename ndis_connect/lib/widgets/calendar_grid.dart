import 'package:flutter/material.dart';
import '../models/event.dart';

/// Calendar widget for displaying events
class Calendar extends StatelessWidget {
  final DateTime month;
  final List<EventModel> events;
  final void Function(DateTime day) onDayTap;
  
  const Calendar({
    super.key,
    required this.month,
    required this.events,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return CalendarGrid(
      month: month,
      events: events,
      onDayTap: onDayTap,
    );
  }
}

class CalendarGrid extends StatelessWidget {
  final DateTime month;
  final List<EventModel> events;
  final void Function(DateTime day) onDayTap;
  const CalendarGrid({super.key, required this.month, required this.events, required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDay.weekday % 7; // make Sunday=0
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7.0).ceil();
    final cells = rows * 7;

    List<Widget> dayCells = [];
    for (int i = 0; i < cells; i++) {
      final dayNum = i - firstWeekday + 1;
      if (dayNum < 1 || dayNum > daysInMonth) {
        dayCells.add(const SizedBox.shrink());
        continue;
      }
      final day = DateTime(month.year, month.month, dayNum);
      final todaysEvents = events.where((e) => _isSameDay(e.start, day) || _spansDay(e, day)).toList();
      dayCells.add(_DayCell(day: day, events: todaysEvents, onTap: () => onDayTap(day)));
    }

    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Wk('S'), _Wk('M'), _Wk('T'), _Wk('W'), _Wk('T'), _Wk('F'), _Wk('S'),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: dayCells,
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool _spansDay(EventModel e, DateTime day) => e.start.isBefore(day) && e.end.isAfter(day);
}

class _Wk extends StatelessWidget {
  final String t;
  const _Wk(this.t);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(t, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium),
        ),
      );
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final List<EventModel> events;
  final VoidCallback onTap;
  const _DayCell({required this.day, required this.events, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasEvents = events.isNotEmpty;
    return Semantics(
      label: 'Day ${day.day}${hasEvents ? ', ${events.length} events' : ''}',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${day.day}', style: Theme.of(context).textTheme.labelLarge),
              if (hasEvents)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: List.generate(
                      events.length.clamp(0, 3),
                      (i) => Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.indigo)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

