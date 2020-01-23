abstract class InjectableTypes {
  static const none = -1;
  static const factory = 0;
  static const singleton = 1;
  static const lazySingleton = 2;
}

class Inject {
  final Type type;
  final int _injectableType;

  // const Inject(this.type);

  const Inject.singleton(this.type)
      : _injectableType = InjectableTypes.singleton;
  const Inject.lazySingleton(this.type)
      : _injectableType = InjectableTypes.lazySingleton;
  const Inject.factory(this.type) : _injectableType = InjectableTypes.factory;
}

class Injectable {
  final int _injectableType;
  final String instanceName;
  final Type bindTo;
  final Type _type;
  final bool signalsReady;

  const Injectable._(this._injectableType, [this.instanceName, this.bindTo])
      : _type = null,
        signalsReady = null;

  const Injectable.factory(this._type, {this.bindTo, this.instanceName})
      : _injectableType = InjectableTypes.factory,
        signalsReady = null;

  const Injectable.singleton(this._type,
      {this.bindTo, this.instanceName, this.signalsReady})
      : _injectableType = InjectableTypes.singleton;

  const Injectable.lazySingleton(this._type,
      {this.bindTo, this.instanceName, this.signalsReady})
      : _injectableType = InjectableTypes.lazySingleton;
}

const injectable = const Injectable._(InjectableTypes.none);

class Factory extends Injectable {
  final Map<Type, String> resolovers;

  const Factory({String instanceName, Type bindTo, this.resolovers})
      : super._(InjectableTypes.factory, instanceName, bindTo);
}

class Singleton extends Injectable {
  final bool signalsReady;

  const Singleton({String instanceName, this.signalsReady, Type bindto})
      : super._(
          InjectableTypes.singleton,
          instanceName,
          bindto,
        );
  const Singleton.lazy({String instanceName, this.signalsReady, Type bindTo})
      : super._(
          InjectableTypes.lazySingleton,
          instanceName,
          bindTo,
        );
}

class InjectorConfig {
  const InjectorConfig();
}

const injectorConfig = const InjectorConfig();
