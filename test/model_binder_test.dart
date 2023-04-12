import 'package:model_binder/model_binder.dart';
import 'package:test/test.dart';

void main() {
  group('ModelBinder', () {
    late int callsCount;
    late ModelBinderTestModel model;

    setUp(() {
      callsCount = 0;
      model = ModelBinderTestModel();
    });

    void fn1(Object? value) => callsCount++;
    void fn2(Object? value) => callsCount++;
    void fn3(Object? value) => callsCount++;

    test('should notify all three functions if name property is changed', () {
      model.bind('name', fn1);
      model.bind('name', fn2);
      model.bind('name', fn3);

      model.name = 'random_name';

      expect(model.name, 'random_name');
      expect(callsCount, 3);
    });

    test('should notify all three functions if name property is changed after the commit', () {
      model.bind('name', fn1);
      model.bind('name', fn2);
      model.bind('name', fn3);

      model.startTransaction();
      model.name = 'random_name';
      expect(model.name, 'random_name');
      expect(callsCount, isZero);
      model.commit();

      expect(model.name, 'random_name');
      expect(callsCount, 3);
    });

    test('should notify just fn1 after remove the others', () {
      model.bind('name', fn1);
      model.bind('name', fn2);
      model.bind('name', fn3);

      model.name = 'random_name';

      expect(model.name, 'random_name');
      expect(callsCount, 3);

      callsCount = 0;
      model.removeBind('name', fn2);
      model.removeBind('name', fn3);

      model.name = 'random_name1';

      expect(model.name, 'random_name1');
      expect(callsCount, 1);
    });
  });
}

class ModelBinderTestModel with ModelBinder {
  ModelBinderTestModel();

  String _name = '';
  String get name => _name;
  set name(String name) {
    _name = name;
    notify('name', _name);
  }
}
