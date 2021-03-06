// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/services/search/element_visitors.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/**
 * Returns direct children of [parent].
 */
List<Element> getChildren(Element parent, [String name]) {
  List<Element> children = <Element>[];
  visitChildren(parent, (Element element) {
    if (name == null || element.displayName == name) {
      children.add(element);
    }
    return false;
  });
  return children;
}

/**
 * Returns direct non-synthetic children of the given [ClassElement].
 *
 * Includes: fields, accessors and methods.
 * Excludes: constructors and synthetic elements.
 */
List<Element> getClassMembers(ClassElement clazz, [String name]) {
  List<Element> members = <Element>[];
  visitChildren(clazz, (Element element) {
    if (element.isSynthetic) {
      return false;
    }
    if (element is ConstructorElement) {
      return false;
    }
    if (name != null && element.displayName != name) {
      return false;
    }
    if (element is ExecutableElement) {
      members.add(element);
    }
    if (element is FieldElement) {
      members.add(element);
    }
    return false;
  });
  return members;
}

/**
 * Returns a [Set] with direct subclasses of [seed].
 */
Future<Set<ClassElement>> getDirectSubClasses(
    SearchEngine searchEngine, ClassElement seed) async {
  // TODO(brianwilkerson) Determine whether this await is necessary.
  await null;
  List<SearchMatch> matches = await searchEngine.searchSubtypes(seed);
  return matches.map((match) => match.element).cast<ClassElement>().toSet();
}

/// Return the non-synthetic children of the given [extension]. This includes
/// fields, accessors and methods, but excludes synthetic elements.
List<Element> getExtensionMembers(ExtensionElement extension, [String name]) {
  List<Element> members = <Element>[];
  visitChildren(extension, (Element element) {
    if (element.isSynthetic) {
      return false;
    }
    if (name != null && element.displayName != name) {
      return false;
    }
    if (element is ExecutableElement) {
      members.add(element);
    }
    if (element is FieldElement) {
      members.add(element);
    }
    return false;
  });
  return members;
}

/**
 * @return all implementations of the given {@link ClassMemberElement} is its superclasses and
 *         their subclasses.
 */
Future<Set<ClassMemberElement>> getHierarchyMembers(
    SearchEngine searchEngine, ClassMemberElement member) async {
  // TODO(brianwilkerson) Determine whether this await is necessary.
  await null;
  Set<ClassMemberElement> result = HashSet<ClassMemberElement>();
  // extension member
  if (member.enclosingElement is ExtensionElement) {
    result.add(member);
    return Future.value(result);
  }
  // static elements
  if (member.isStatic || member is ConstructorElement) {
    result.add(member);
    return Future.value(result);
  }
  // method, field, etc
  String name = member.displayName;
  ClassElement memberClass = member.enclosingElement;
  Set<ClassElement> searchClasses = getSuperClasses(memberClass);
  searchClasses.add(memberClass);
  for (ClassElement superClass in searchClasses) {
    // ignore if super- class does not declare member
    if (getClassMembers(superClass, name).isEmpty) {
      continue;
    }
    // check all sub- classes
    Set<ClassElement> subClasses =
        await searchEngine.searchAllSubtypes(superClass);
    subClasses.add(superClass);
    for (ClassElement subClass in subClasses) {
      List<Element> subClassMembers = getChildren(subClass, name);
      for (Element member in subClassMembers) {
        if (member is ClassMemberElement) {
          result.add(member);
        }
      }
    }
  }
  return result;
}

/**
 * If the [element] is a named parameter in a [MethodElement], return all
 * corresponding named parameters in the method hierarchy.
 */
Future<List<ParameterElement>> getHierarchyNamedParameters(
    SearchEngine searchEngine, ParameterElement element) async {
  // TODO(brianwilkerson) Determine whether this await is necessary.
  await null;
  if (element.isNamed) {
    Element method = element.enclosingElement;
    if (method is MethodElement) {
      var hierarchyParameters = <ParameterElement>[];
      var hierarchyMembers = await getHierarchyMembers(searchEngine, method);
      for (ClassMemberElement hierarchyMethod in hierarchyMembers) {
        if (hierarchyMethod is MethodElement) {
          for (var hierarchyParameter in hierarchyMethod.parameters) {
            if (hierarchyParameter.isNamed &&
                hierarchyParameter.name == element.name) {
              hierarchyParameters.add(hierarchyParameter);
              break;
            }
          }
        }
      }
      return hierarchyParameters;
    }
  }
  return [element];
}

/**
 * Returns non-synthetic members of the given [ClassElement] and its super
 * classes.
 *
 * Includes: fields, accessors and methods.
 * Excludes: constructors and synthetic elements.
 */
List<Element> getMembers(ClassElement clazz) {
  List<Element> members = <Element>[];
  members.addAll(getClassMembers(clazz));
  Set<ClassElement> superClasses = getSuperClasses(clazz);
  for (ClassElement superClass in superClasses) {
    members.addAll(getClassMembers(superClass));
  }
  return members;
}

/**
 * Returns a [Set] with all direct and indirect superclasses of [seed].
 */
Set<ClassElement> getSuperClasses(ClassElement seed) {
  Set<ClassElement> result = HashSet<ClassElement>();
  // prepare queue
  List<ClassElement> queue = <ClassElement>[];
  queue.add(seed);
  // process queue
  while (queue.isNotEmpty) {
    ClassElement current = queue.removeLast();
    // add if not checked already
    if (!result.add(current)) {
      continue;
    }
    // append supertype
    {
      InterfaceType superType = current.supertype;
      if (superType != null) {
        queue.add(superType.element);
      }
    }
    // append superclass constraints
    for (InterfaceType interface in current.superclassConstraints) {
      queue.add(interface.element);
    }
    // append interfaces
    for (InterfaceType interface in current.interfaces) {
      queue.add(interface.element);
    }
  }
  // we don't need "seed" itself
  result.remove(seed);
  return result;
}

/**
 * If the given [element] is a synthetic [PropertyAccessorElement] returns
 * its variable, otherwise returns [element].
 */
Element getSyntheticAccessorVariable(Element element) {
  if (element is PropertyAccessorElement) {
    if (element.isSynthetic) {
      return element.variable;
    }
  }
  return element;
}
