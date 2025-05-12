import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:reverie/features/journal/providers/journal_provider.dart';
import 'package:reverie/utils/media_utils.dart';
import 'package:intl/intl.dart';

class JournalCalendar extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final DateTime? selectedDate;
  final DateTime? focusedDate;

  const JournalCalendar({
    super.key,
    required this.onDateSelected,
    this.selectedDate,
    this.focusedDate,
  });

  @override
  State<JournalCalendar> createState() => _JournalCalendarState();
}

class _JournalCalendarState extends State<JournalCalendar> {
  late DateTime _focusedDay;
  late DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDate ?? DateTime.now();
    _selectedDay = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    final journalProvider = context.watch<JournalProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        eventLoader: (day) => journalProvider.getEntriesForDate(day),
        calendarStyle: CalendarStyle(
          markersMaxCount: 3,
          markerDecoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          weekendTextStyle: TextStyle(color: colorScheme.error),
          outsideDaysVisible: false,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          formatButtonTextStyle: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
          titleCentered: true,
          titleTextStyle: theme.textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;

            final mood = journalProvider.getMoodForDate(date);
            if (mood == null) return null;

            return Positioned(
              bottom: 1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: MediaUtils.getMoodColor(mood),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
          dowBuilder: (context, day) {
            final text = DateFormat.E().format(day);
            return Center(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: day.weekday == DateTime.sunday ||
                          day.weekday == DateTime.saturday
                      ? colorScheme.error
                      : colorScheme.onSurface,
                ),
              ),
            );
          },
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          widget.onDateSelected(selectedDay);
        },
      ),
    );
  }
}
