import 'package:example/lib_service.dart';
import 'package:injectable/injectable.dart';
import 'package:mockito/mockito.dart';

@injectable
class TestService extends Mock implements LibService {}
