part of 'monthly_series_cubit.dart';

class MonthlySeriesState extends Equatable {
  const MonthlySeriesState({
    this.enabled = false,
    this.isLoading = false,
    this.preview,
    this.error,
    this.choices = const {},
  });

  final bool enabled;
  final bool isLoading;
  final SeriesPreview? preview;
  final String? error;

  /// The moves the manager has made, keyed by the position each one replaces.
  ///
  /// Held here rather than read back off the preview: once the server has
  /// applied a move it returns that row badged as a replacement, with no
  /// record of which local choice produced it. Deriving the payload from the
  /// response would therefore send an empty list on the second round trip and
  /// book the series with the clash still in it.
  final Map<String, ReplacementSlot> choices;

  /// How many appointments still need the manager's attention.
  int get unresolvedCount => preview?.unresolved.length ?? 0;

  /// Whether the recurring booking may be confirmed.
  ///
  /// Deliberately false while loading: the plan on screen during a reload is
  /// the previous one, and confirming against it would book dates the manager
  /// has already moved away from.
  bool get canConfirm =>
      enabled && !isLoading && error == null && (preview?.isReadyToConfirm ?? false);

  /// The moves to send with the booking, in the shape the server expects.
  ///
  /// `original_date` is what makes each one a MOVE of an existing position
  /// rather than an additional appointment.
  List<Map<String, dynamic>> get replacementPayload => choices.entries
      .map((e) => {
            'original_date': e.key,
            'date': e.value.date,
            'start_time': e.value.startTime,
            'end_time': e.value.endTime,
          })
      .toList();

  MonthlySeriesState copyWith({
    bool? enabled,
    bool? isLoading,
    SeriesPreview? preview,
    String? error,
    Map<String, ReplacementSlot>? choices,
    bool clearError = false,
  }) {
    return MonthlySeriesState(
      enabled: enabled ?? this.enabled,
      isLoading: isLoading ?? this.isLoading,
      preview: preview ?? this.preview,
      error: clearError ? null : (error ?? this.error),
      choices: choices ?? this.choices,
    );
  }

  @override
  List<Object?> get props => [
        enabled,
        isLoading,
        error,
        preview?.planSignature,
        choices.entries.map((e) => '${e.key}>${e.value.startTime}').join(','),
        preview?.dates.map((d) => '${d.date}|${d.startTime}|${d.available}').join(','),
      ];
}
