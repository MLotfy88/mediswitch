import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  
  @override
  List<Object> get props => [];
}

class NotificationStatusChanged extends NotificationEvent {
  final bool isEnabled;
  
  const NotificationStatusChanged(this.isEnabled);
  
  @override
  List<Object> get props => [isEnabled];
}

class NotificationStatusLoaded extends NotificationEvent {}

// States
abstract class NotificationState extends Equatable {
  const NotificationState();
  
  @override
  List<Object> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final bool isEnabled;
  
  const NotificationLoaded(this.isEnabled);
  
  @override
  List<Object> get props => [isEnabled];
}

// BLoC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(NotificationInitial()) {
    on<NotificationStatusLoaded>(_onNotificationStatusLoaded);
    on<NotificationStatusChanged>(_onNotificationStatusChanged);
  }
  
  Future<void> _onNotificationStatusLoaded(NotificationStatusLoaded event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('notifications_enabled') ?? true;
      emit(NotificationLoaded(isEnabled));
    } catch (e) {
      // Default to enabled if there's an error
      emit(const NotificationLoaded(true));
    }
  }
  
  Future<void> _onNotificationStatusChanged(NotificationStatusChanged event, Emitter<NotificationState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', event.isEnabled);
      emit(NotificationLoaded(event.isEnabled));
    } catch (e) {
      // Keep current state if there's an error
      if (state is NotificationLoaded) {
        emit(state);
      } else {
        emit(const NotificationLoaded(true));
      }
    }
  }
}