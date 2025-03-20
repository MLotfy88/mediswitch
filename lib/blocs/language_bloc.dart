import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class LanguageEvent extends Equatable {
  const LanguageEvent();
  
  @override
  List<Object> get props => [];
}

class LanguageChanged extends LanguageEvent {
  final String languageCode;
  
  const LanguageChanged(this.languageCode);
  
  @override
  List<Object> get props => [languageCode];
}

class LoadLanguage extends LanguageEvent {}

// States
abstract class LanguageState extends Equatable {
  const LanguageState();
  
  @override
  List<Object> get props => [];
}

class LanguageInitial extends LanguageState {}

class LanguageLoading extends LanguageState {}

class LanguageLoaded extends LanguageState {
  final String languageCode;
  final Locale locale;
  
  const LanguageLoaded(this.languageCode, this.locale);
  
  @override
  List<Object> get props => [languageCode, locale];
}

// BLoC
class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  LanguageBloc() : super(LanguageInitial()) {
    on<LoadLanguage>(_onLanguageLoaded);
    on<LanguageChanged>(_onLanguageChanged);
  }
  
  Future<void> _onLanguageLoaded(LoadLanguage event, Emitter<LanguageState> emit) async {
    emit(LanguageLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language') ?? 'ar';
      final locale = Locale(languageCode);
      emit(LanguageLoaded(languageCode, locale));
    } catch (e) {
      // Default to Arabic if there's an error
      emit(const LanguageLoaded('ar', Locale('ar')));
    }
  }
  
  Future<void> _onLanguageChanged(LanguageChanged event, Emitter<LanguageState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', event.languageCode);
      final locale = Locale(event.languageCode);
      emit(LanguageLoaded(event.languageCode, locale));
    } catch (e) {
      // Keep current state if there's an error
      if (state is LanguageLoaded) {
        emit(state);
      } else {
        emit(const LanguageLoaded('ar', Locale('ar')));
      }
    }
  }
}