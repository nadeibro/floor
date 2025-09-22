import 'package:analyzer/dart/element/element.dart'
    show MethodElement, FormalParameterElement;
import 'package:analyzer/dart/element/type.dart';

class TransactionMethod {
  final MethodElement methodElement;
  final String name; // pass methodElement.displayName when constructing
  final DartType returnType;
  final List<FormalParameterElement> parameterElements;
  final String daoFieldName;
  final String databaseName;

  TransactionMethod(
    this.methodElement,
    this.name,
    this.returnType,
    this.parameterElements,
    this.daoFieldName,
    this.databaseName,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionMethod &&
          runtimeType == other.runtimeType &&
          methodElement == other.methodElement &&
          name == other.name &&
          returnType == other.returnType &&
          parameterElements == other.parameterElements &&
          daoFieldName == other.daoFieldName &&
          databaseName == other.databaseName;

  @override
  int get hashCode =>
      methodElement.hashCode ^
      name.hashCode ^
      returnType.hashCode ^
      parameterElements.hashCode ^
      daoFieldName.hashCode ^
      databaseName.hashCode;

  @override
  String toString() {
    return 'NewTransactionMethod{methodElement: $methodElement, name: $name, returnType: $returnType, parameterElements: $parameterElements, daoFieldName: $daoFieldName, databaseName: $databaseName}';
  }
}
