import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter_todos/blocs/todos/todos.dart';
import 'package:flutter_todos/models/models.dart';
import 'package:todos_repository_simple/todos_repository_simple.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/models.dart';
import '../blocs.dart';


class TodosBloc extends Bloc<TodosEvent, TodosState> {
  final TodosRepositoryFlutter todosRepository;

  TodosBloc({@required this.todosRepository});

  @override
  TodosState get initialState => TodosLoading();

  @override
  Stream<TodosState> mapEventToState(TodosEvent event) {
    if (event is LoadTodos) {
      return _mapLoadTodosToState();
    } else if (event is AddTodo) {
      return _mapAddTodoToState(event);
    } else if (event is UpdateTodo) {
      return _mapUpdateTodoToState(event);
    } else if (event is DeleteTodo) {
      return _mapDeleteTodoToState(event);
    } else if (event is ToggleAll) {
      return _mapToggleAllToState();
    } else if (event is ClearCompleted) {
      return _mapClearCompletedToState();
    }
  }

  Stream<TodosState> _mapLoadTodosToState() {
    return Stream
        .fromFuture(this.todosRepository.loadTodos())
        .map((todos) => TodosLoaded(todos.map(Todo.fromEntity).toList()))
        .handleError((_) => TodosNotLoaded());
  }

  Stream<TodosState> _mapAddTodoToState(AddTodo event) {
    return Stream.value(state)
        .where((state) => state is TodosLoaded)
        .flatMap((state) {
      final List<Todo> updatedTodos = List.from((state as TodosLoaded).todos)
        ..add(event.todo);

      final savedTodosStream = Stream
          .fromFuture(_saveTodos(updatedTodos))
          .map((_) => TodosLoaded(updatedTodos));

      final resetStream = savedTodosStream.map((_) => TodosInitial());


      return Rx.merge([
        savedTodosStream,
//        resetStream
      ]);
    });
  }

  Stream<TodosState> _mapUpdateTodoToState(UpdateTodo event) {
    return Stream.value(state)
        .where((state) => state is TodosLoaded)
        .flatMap((state) {
      final List<Todo> updatedTodos = (state as TodosLoaded).todos.map((todo) {
        return todo.id == event.updatedTodo.id ? event.updatedTodo : todo;
      }).toList();

      return Stream
          .fromFuture(_saveTodos(updatedTodos))
          .map((_) => TodosLoaded(updatedTodos));
    });
  }

  Stream<TodosState> _mapDeleteTodoToState(DeleteTodo event) {
    return Stream.value(state)
        .where((state) => state is TodosLoaded)
        .flatMap((state) {
      final updatedTodos = (state as TodosLoaded)
          .todos
          .where((todo) => todo.id != event.todo.id)
          .toList();

      return Stream
          .fromFuture(_saveTodos(updatedTodos))
          .map((_) => TodosLoaded(updatedTodos));
    });
  }

  Stream<TodosState> _mapToggleAllToState() {
    return Stream.value(state)
        .where((state) => state is TodosLoaded)
        .flatMap((state) {
      final allComplete =
      (state as TodosLoaded).todos.every((todo) => todo.complete);
      final List<Todo> updatedTodos = (state as TodosLoaded)
          .todos
          .map((todo) => todo.copyWith(complete: !allComplete))
          .toList();

      return Stream
          .fromFuture(_saveTodos(updatedTodos))
          .map((_) => TodosLoaded(updatedTodos));
    });
  }

  Stream<TodosState> _mapClearCompletedToState() {
    return Stream.value(state)
        .where((state) => state is TodosLoaded)
        .flatMap((state) {
      final List<Todo> updatedTodos =
      (state as TodosLoaded).todos.where((todo) => !todo.complete).toList();

      return Stream
          .fromFuture(_saveTodos(updatedTodos))
          .map((_) => TodosLoaded(updatedTodos));
    });
  }

  Future _saveTodos(List<Todo> todos) {
    return todosRepository.saveTodos(
      todos.map((todo) => todo.toEntity()).toList(),
    );
  }
}
