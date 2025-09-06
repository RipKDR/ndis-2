class EventModel {
  final String id;
  final String ownerUid;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? location;
  final String? notes;
  final String? providerId; // optional link to provider
  final bool allDay;

  EventModel({
    required this.id,
    required this.ownerUid,
    required this.title,
    required this.start,
    required this.end,
    this.location,
    this.notes,
    this.providerId,
    this.allDay = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerUid': ownerUid,
        'title': title,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'location': location,
        'notes': notes,
        'providerId': providerId,
        'allDay': allDay,
      };

  factory EventModel.fromMap(Map<String, dynamic> map) => EventModel(
        id: map['id'] as String,
        ownerUid: map['ownerUid'] as String,
        title: map['title'] as String,
        start: DateTime.parse(map['start'] as String),
        end: DateTime.parse(map['end'] as String),
        location: map['location'] as String?,
        notes: map['notes'] as String?,
        providerId: map['providerId'] as String?,
        allDay: (map['allDay'] as bool?) ?? false,
      );
}

