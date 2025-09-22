import 'package:analyzer/dart/element/element.dart'
    show MethodElement, FormalParameterElement;
import 'package:floor_generator/misc/extension/dart_type_extension.dart';
import 'package:floor_generator/processor/error/query_processor_error.dart';
import 'package:floor_generator/processor/processor.dart';
import 'package:floor_generator/value_object/query.dart';

class QueryProcessor extends Processor<Query> {
  final QueryProcessorError _processorError;

  final String _query;

  final List<FormalParameterElement> _parameters;

  QueryProcessor(MethodElement methodElement, this._query)
      : _parameters = methodElement.formalParameters,
        _processorError = QueryProcessorError(methodElement);

  @override
  Query process() {
    _assertNoNullableParameters();

    final indices = <String, int>{};
    final fixedParameters = <String>{};
    // map parameters to index (1-based) or 0 (if it's a list)
    int currentIndex = 1;
    for (final parameter in _parameters) {
      final name = parameter.displayName;
      if (parameter.type.isDartCoreList) {
        indices[':$name'] = 0;
      } else {
        fixedParameters.add(name);
        indices[':$name'] = currentIndex++;
      }
    }

    // get list of query variables
    final variables = findVariables(_query);
    _assertAllParametersAreUsed(variables);

    final newQuery = StringBuffer();
    final listParameters = <ListParameter>[];
    // iterate over all found variables, replace them with assigned indices
    // (?1, ?2, ...) or with a placeholder if the variable is a list
    int currentLast = 0;
    for (final varToken in variables) {
      newQuery.write(
        _query.substring(currentLast, varToken.startPosition).replaceAll('\n', ' '),
      );
      final varIndexInMethod = indices[varToken.name];
      if (varIndexInMethod == null) {
        throw _processorError.unknownQueryVariable(varToken.name);
      } else if (varIndexInMethod > 0) {
        // normal variable/parameter
        if (varToken.isListVar) {
          throw _processorError
              .queryMethodParameterIsNormalButVariableIsList(varToken.name);
        }
        newQuery.write('?');
        newQuery.write(varIndexInMethod);
      } else {
        // list variable/parameter
        if (!varToken.isListVar) {
          throw _processorError
              .queryMethodParameterIsListButVariableIsNot(varToken.name);
        }
        listParameters
            .add(ListParameter(newQuery.length, varToken.name.substring(1)));
        newQuery.write(varlistPlaceholder);
      }
      currentLast = varToken.endPosition;
    }
    newQuery.write(_query.substring(currentLast).replaceAll('\n', ' '));

    return Query(
      newQuery.toString(),
      listParameters,
    );
  }

  void _assertNoNullableParameters() {
    for (final parameter in _parameters) {
      if (parameter.type.isNullable) {
        throw _processorError.queryMethodParameterIsNullable(parameter);
      }
    }
  }

  void _assertAllParametersAreUsed(List<VariableToken> variables) {
    final queryVariables = variables.map((e) => e.name.substring(1)).toSet();
    for (final param in _parameters) {
      if (!queryVariables.contains(param.displayName)) {
        throw _processorError.unusedQueryMethodParameter(param);
      }
    }
  }
}

/// Treats the incoming String as an Sqlite query and tries to find all used
/// sqlite variables. Also try to identify List variables by looking at their
/// context.
List<VariableToken> findVariables(final String query) {
  final output = <VariableToken>[];
  for (final match
      in RegExp(r':[\w]+| [iI][nN]\s*\((:[\w]+)\)').allMatches(query)) {
    final content = match.group(0)!;
    final expectsList = content.toLowerCase().startsWith(' in');
    if (expectsList) {
      final varname = match.group(1)!;
      output.add(
        VariableToken(varname, query.indexOf(varname, match.start), true),
      );
    } else {
      output.add(VariableToken(content, match.start, false));
    }
  }
  return output;
}

/// Represents a variable within an sqlite query.
class VariableToken {
  /// the variable name including `:` (e.g. `:foo`)
  final String name;

  /// the offset within the query, where the variable name starts
  final int startPosition;

  /// the offset within the query, where the variable name ends
  int get endPosition => startPosition + name.length;

  /// denotes if the variable was determined to contain a list
  final bool isListVar;

  VariableToken(this.name, this.startPosition, this.isListVar);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariableToken &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          startPosition == other.startPosition &&
          isListVar == other.isListVar;

  @override
  int get hashCode =>
      name.hashCode ^ startPosition.hashCode ^ isListVar.hashCode;
}
