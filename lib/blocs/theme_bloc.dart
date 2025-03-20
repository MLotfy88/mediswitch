import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();
  
  @override
  List<Object> get props => [];
}

class ThemeChanged extends ThemeEvent {
  final bool isDarkMode;
  
  const ThemeChanged(this.isDarkMode);
  
  @override
  List<Object> get props => [isDarkMode];
}

class LoadTheme extends ThemeEvent {}

// States
abstract class ThemeState extends Equatable {
  const ThemeState();
  
  @override
  List<Object> get props => [];
}

class ThemeInitial extends ThemeState {}

class ThemeLoading extends ThemeState {}

class ThemeLoaded extends ThemeState {
  final bool isDarkMode;
  final ThemeMode themeMode;
  
  const ThemeLoaded(this.isDarkMode, this.themeMode);
  
  @override
  List<Object> get props => [isDarkMode, themeMode];
}

// BLoC
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeInitial()) {
    on<LoadTheme>(_onThemeLoaded);
    on<ThemeChanged>(_onThemeChanged);
  }
  
  Future<void> _onThemeLoaded(LoadTheme event, Emitter<ThemeState> emit) async {
    emit(ThemeLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool('dark_mode') ?? false;
      final themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      emit(ThemeLoaded(isDarkMode, themeMode));
    } catch (e) {
      // Default to light theme if there's an error
      emit(const ThemeLoaded(false, ThemeMode.light));
    }
  }
  
  Future<void> _onThemeChanged(ThemeChanged event, Emitter<ThemeState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', event.isDarkMode);
      final themeMode = event.isDarkMode ? ThemeMode.dark : ThemeMode.light;
      emit(ThemeLoaded(event.isDarkMode, themeMode));
    } catch (e) {
      // Keep current state if there's an error
      if (state is ThemeLoaded) {
        emit(state);
      } else {
        emit(const ThemeLoaded(false, ThemeMode.light));
      }
    }
  }
}