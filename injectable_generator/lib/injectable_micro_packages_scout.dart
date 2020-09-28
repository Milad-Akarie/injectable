import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:glob/glob.dart';
import 'package:injectable/injectable.dart';
import 'package:source_gen/source_gen.dart';

class InjectableMicroPackagesScout
    extends GeneratorForAnnotation<MicroPackage> {
  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {


    /*AssetId modulesFile = AssetId('','new.json');
    buildStep.writeAsString(modulesFile, "HELLO!!!");*/
    return jsonEncode(MicroPackageModuleModel(element.name,element.location.toString()));
  }


}
/// Model class
/// Represents a register micro module
class MicroPackageModuleModel{
  final String moduleName;
  final String location;
  MicroPackageModuleModel(this.moduleName, this.location);

  MicroPackageModuleModel.fromJson(Map<String,dynamic> json):
      moduleName = json['moduleName'],
  location = json['location'];

  Map<String,dynamic> toJson() => {
    'moduleName': moduleName,
    'location': location
  };

}
