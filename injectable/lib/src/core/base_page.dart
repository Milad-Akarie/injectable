import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/src/core/navigable_view_model.dart';
import 'package:provider/provider.dart';

final _ioc = GetIt.instance;

class BasePage<T extends ANavigableViewModel> extends StatefulWidget {
  final T bindingContext = _ioc<T>();
  BasePage({Key? key}) : super(key: key);

  @override
  BasePageState createState() => BasePageState<BasePage<T>, T>();

  void initState() {}

  Widget build(BuildContext context) {
    return Container();
  }
}

class BasePageState<P extends BasePage, T extends ANavigableViewModel>
    extends State<P> {
  @override
  void initState() {
    super.initState();
    widget.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>.value(
      value: _ioc<T>(),
      child: Consumer<T>(builder: (context, viewModel, _) {
        return widget.build(context);
      }),
    );
  }
}
