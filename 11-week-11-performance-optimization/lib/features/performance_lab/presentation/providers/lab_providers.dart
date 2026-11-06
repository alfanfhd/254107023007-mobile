import 'package:flutter_riverpod/flutter_riverpod.dart';

class LabCounterState {
  const LabCounterState({this.counter = 0, this.label = 'Label awal'});

  final int counter;
  final String label;

  LabCounterState copyWith({int? counter, String? label}) {
    return LabCounterState(
      counter: counter ?? this.counter,
      label: label ?? this.label,
    );
  }
}

/// State kecil untuk mendemonstrasikan `ref.watch` vs `ref.watch(...select)`.
class LabCounterNotifier extends Notifier<LabCounterState> {
  @override
  LabCounterState build() => const LabCounterState();

  void incrementCounter() {
    state = state.copyWith(counter: state.counter + 1);
  }

  void changeLabel() {
    final next = state.label == 'Label awal' ? 'Label berubah' : 'Label awal';
    state = state.copyWith(label: next);
  }
}

final labCounterProvider =
    NotifierProvider<LabCounterNotifier, LabCounterState>(
      LabCounterNotifier.new,
    );
