import 'package:example/injector/injector.config.dart';
import 'package:example/services/abstract_service.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

GetIt getIt = GetIt.instance;

void main() async {
  await getIt.init(environment: Environment.dev);

  // Example 1: Basic service without parameters
  print('=== Basic Service ===');
  print(getIt<IService>());

  // Example 2: Service with factory parameters - Using standard syntax
  print('\n=== Service with Factory Parameters (Standard Syntax) ===');
  final service1 = getIt.get<ConfigurableService>(
    param1: 'sk-12345',
    param2: 'https://api.example.com',
  );
  print(service1);

  // Example 3: Service with factory parameters - Using accessor methods
  print('\n=== Service with Factory Parameters (Accessor Methods) ===');
  final service2 = getIt.configurableService(
    apiKey: 'sk-67890',
    baseUrl: 'https://api.example.org',
  );
  print(service2);

  // Example 4: Service with single parameter
  print('\n=== Service with Single Parameter ===');
  final logger = getIt.loggerService(name: 'MyApp');
  logger.log('Application started');
}

