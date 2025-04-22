import 'package:equatable/equatable.dart';

sealed class FavToggleState extends Equatable {
  const FavToggleState();

  @override
  List<Object> get props => [];
}

final class FavDoctors extends FavToggleState {}

final class FavArticles extends FavToggleState {}
