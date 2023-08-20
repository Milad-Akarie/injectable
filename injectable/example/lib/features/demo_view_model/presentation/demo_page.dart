import 'package:example/features/demo_view_model/view_model/view_model.dart';
import 'package:flutter/material.dart';
import 'package:injectable/fmvvm.dart';

class DemoViewPage extends BasePage<DemoViewModel> {
  DemoViewPage({super.key}) : super();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Text Display')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              onChanged: (text) {
                bindingContext.text = text;
              },
              decoration: InputDecoration(labelText: 'Enter your text'),
            ),
            SizedBox(height: 16.0),
            Text(
              'Entered Text:',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              bindingContext.text,
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}
