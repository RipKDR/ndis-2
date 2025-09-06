import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/notifications_service.dart';
import '../services/reminders_service.dart';
import '../services/remote_config_service.dart';
import '../viewmodels/calendar_viewmodel.dart';
import '../widgets/calendar_grid.dart';

class CalendarScreen extends StatelessWidget {
  static const route = '/calendar';
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarViewModel(EventService(), FirebaseAuth.instance),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatelessWidget {
  const _CalendarView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.calendar),
        actions: [
          IconButton(
            onPressed: vm.loading ? null : () => vm.refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: s.retry,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventForm(context),
        icon: const Icon(Icons.add),
        label: Text(s.newEvent),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          final prev = DateTime(vm.currentMonth.year, vm.currentMonth.month - 1);
                          vm.goToMonth(prev);
                        },
                      ),
                      Text(
                        '${vm.currentMonth.year}-${vm.currentMonth.month.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          final next = DateTime(vm.currentMonth.year, vm.currentMonth.month + 1);
                          vm.goToMonth(next);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CalendarGrid(
                    month: vm.currentMonth,
                    events: vm.events,
                    onDayTap: (day) => _showDayEvents(context, day),
                  ),
                ],
              ),
            ),
    );
  }

  void _showDayEvents(BuildContext context, DateTime day) {
    final vm = context.read<CalendarViewModel>();
    final todaysEvents =
        vm.events.where((e) => _isSameDay(e.start, day) || _spansDay(e, day)).toList();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Events on ${day.toLocal().toString().split(' ').first}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...todaysEvents.map((e) => ListTile(
                title: Text(e.title),
                subtitle: Text(
                    '${e.start.hour.toString().padLeft(2, '0')}:${e.start.minute.toString().padLeft(2, '0')} - '
                    '${e.end.hour.toString().padLeft(2, '0')}:${e.end.minute.toString().padLeft(2, '0')}'),
                onTap: () => _showEventForm(context, existing: e),
              )),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEventForm(context, initialDay: day);
            },
            icon: const Icon(Icons.add),
            label: const Text('New event'),
          )
        ],
      ),
    );
  }

  Future<void> _showEventForm(BuildContext context,
      {EventModel? existing, DateTime? initialDay}) async {
    final s = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    DateTime start =
        existing?.start ?? (initialDay ?? DateTime.now()).add(const Duration(hours: 1));
    DateTime end = existing?.end ?? start.add(const Duration(hours: 1));
    bool allDay = existing?.allDay ?? false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? s.newEvent : s.editEvent,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: s.title),
                ),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(labelText: s.locationOptional),
                ),
                TextField(
                  controller: notesCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: s.notesOptional),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _DateTimeField(
                          label: s.start, initial: start, onChanged: (v) => start = v),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DateTimeField(label: s.end, initial: end, onChanged: (v) => end = v),
                    ),
                  ],
                ),
                CheckboxListTile(
                  value: allDay,
                  onChanged: (v) => allDay = v ?? false,
                  title: Text(s.allDay),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (existing != null)
                      OutlinedButton.icon(
                        onPressed: () async {
                          await context.read<CalendarViewModel>().deleteEvent(existing.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete),
                        label: Text(s.delete),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () async {
                        final uid = FirebaseAuth.instance.currentUser!.uid;
                        final e = EventModel(
                          id: existing?.id ?? '',
                          ownerUid: uid,
                          title: titleCtrl.text.trim(),
                          start: start,
                          end: end,
                          location:
                              locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                          allDay: allDay,
                        );
                        EventModel saved;
                        if (existing == null) {
                          saved = await context.read<CalendarViewModel>().addEvent(e);
                        } else {
                          await context.read<CalendarViewModel>().updateEvent(e);
                          saved = e;
                        }
                        // Schedule reminder via Cloud Function if configured
                        final rc = context.read<RemoteConfigService>();
                        final url = rc.remindersFunctionUrl;
                        if (url.isNotEmpty && start.isAfter(DateTime.now())) {
                          final token = await context.read<NotificationsService>().getFCMToken();
                          if (token != null) {
                            final svc = RemindersService(Uri.parse(url));
                            await svc.scheduleReminder(
                              eventId: saved.id,
                              uid: uid,
                              title: saved.title,
                              timestampMs: saved.start.millisecondsSinceEpoch,
                              token: token,
                            );
                          }
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.save),
                      label: Text(s.save),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  bool _spansDay(EventModel e, DateTime day) => e.start.isBefore(day) && e.end.isAfter(day);
}

class _DateTimeField extends StatefulWidget {
  final String label;
  final DateTime initial;
  final ValueChanged<DateTime> onChanged;
  const _DateTimeField({required this.label, required this.initial, required this.onChanged});

  @override
  State<_DateTimeField> createState() => _DateTimeFieldState();
}

class _DateTimeFieldState extends State<_DateTimeField> {
  late DateTime _value;
  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (d == null) return;
        final t =
            await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_value));
        if (t == null) return;
        final next = DateTime(d.year, d.month, d.day, t.hour, t.minute);
        setState(() => _value = next);
        widget.onChanged(next);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text('${widget.label}: ${_value.toLocal()}'),
      ),
    );
  }
}
