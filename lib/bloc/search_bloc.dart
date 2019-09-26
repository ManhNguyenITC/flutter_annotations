import 'package:avatar_letter/avatar_letter.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_annotations/bloc/theme_bloc.dart';
import 'package:flutter_annotations/core/data/preferences.dart';
import 'package:flutter_annotations/core/model/domain/anotation.dart';
import 'package:flutter_annotations/utils/constants.dart';

import 'bloc_base.dart';
import 'object_event.dart';
import 'object_state.dart';
import 'package:rxdart/rxdart.dart';

//enum StateWidget { Idle, Busy, Refresh, Empty }

class SearchBloc extends AnnotationBase {

//  List<Annotation> annotations = [];
  String _valueQuery = null;

  @override
  get initialState => ObjectUninitialized();

  void updateQueryValue(String valueQuery) {
    this._valueQuery = valueQuery;
    dispatch(Run());
  }

  Future<List<Annotation>> _search() async {
    var searchs = List<Annotation>();

    var query =
        'select * from $DB_ANOTATION_TABLE_NAME where title like ${"'%$_valueQuery%'"}';
    print('query = ${query}');
    List<Map> jsons = await this.database.rawQuery(query);
    for (Map json in jsons) {
      var anotation = Annotation.fromJsonMap(json);
      searchs.add(anotation);
    }

    return searchs;
  }

  Stream<ObjectState> transformEvents(Stream<ObjectEvent> events,
      Stream<ObjectState> Function(ObjectEvent event) next) {
    return super.transformEvents(
        (events as Observable<ObjectEvent>)
            .debounceTime(Duration(milliseconds: 500)),
        next);
  }

  @override
  Stream<ObjectState> mapEventToState(ObjectEvent event) async* {
    print('mapEventToState: ${event}');
    print('mapEventToState:currentState =>  ${currentState}');
    if (event is Run) {
      try {
        if (currentState is ObjectUninitialized) {
          var annotations = await _search();
          yield ObjectLoaded(objects: annotations, hasReachedMax: false);
          return;
        }
        if (currentState is ObjectLoaded) {
          var annotations = await _search();
          yield annotations.isEmpty
              ? (currentState as ObjectLoaded).copyWith(hasReachedMax: true)
              : ObjectLoaded(
                  objects: annotations,
                  hasReachedMax: false);
        }
      } catch (_) {
        yield ObjectError();
      }
    }
  }

  SearchBloc() : super();
}
