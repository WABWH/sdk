// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

abstract class ClassWithCall {
  ClassWithCall call();
  int method();
}

class Class {
  ClassWithCall classWithCall;

  int method() =>
      /*cfe.invoke: ClassWithCall*/
      /*cfe:nnbd.invoke: ClassWithCall!*/
      classWithCall()
          . /*cfe.invoke: int*/
          /*cfe:nnbd.invoke: int!*/
          method();
}

abstract class GenericClassWithCall<T> {
  T call();
  T method();
}

class GenericClass<S, T extends GenericClassWithCall<S>> {
  GenericClassWithCall<T> classWithCall;

  S method() =>
      /*cfe.invoke: T*/ /*cfe:nnbd.invoke: T!*/ classWithCall()
          . /*cfe.invoke: S*/ /*cfe:nnbd.invoke: S%*/ method();
}

main() {
  new /*cfe.GenericClass<String,GenericClassWithCall<String>>*/
      /*cfe:nnbd.GenericClass<String!,GenericClassWithCall<String!>!>!*/
      GenericClass<String, GenericClassWithCall<String>>
          /*cfe.<String,GenericClassWithCall<String>>*/
          /*cfe:nnbd.<String!,GenericClassWithCall<String!>!>*/ ()
      . /*cfe.invoke: GenericClassWithCall<String>*/
      /*cfe:nnbd.invoke: GenericClassWithCall<String!>!*/
      classWithCall()
      . /*cfe.invoke: String*/ /*cfe:nnbd.invoke: String!*/ method();
}
