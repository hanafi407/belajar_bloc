import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => PersonBloc(),
        child: const MyHomePage(),
      ),
    );
  }
}

@immutable
abstract class LoadAction {
  const LoadAction();
}

@immutable
class LoadPersonAction implements LoadAction {
  final Personsurl url;

  const LoadPersonAction({required this.url}) : super();
}

@immutable
class Person {
  final String name;
  final int age;

  const Person({required this.name, required this.age});

  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        age = json['age'] as int;
}

enum Personsurl {
  persons1,
  persons2,
}

extension UrlString on Personsurl {
  String get urlString {
    switch (this) {
      case Personsurl.persons1:
        return 'http://127.0.0.1:5500/api/person1.json';
      case Personsurl.persons2:
        return 'http://127.0.0.1:5500/api/person2.json';
    }
  }
}

Future<Iterable<Person>> getPersons(String url) => HttpClient()
    .getUrl(Uri.parse(url))
    .then((req) => req.close())
    .then((res) => res.transform(utf8.decoder).join())
    .then((str) => json.decode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));

@immutable
class FetchResult {
  final Iterable<Person> persons;
  final bool isRetrieveFromChace;

  const FetchResult({required this.persons, required this.isRetrieveFromChace});

  @override
  String toString() {
    return 'FetchResult(isRetrieveFromChace = $isRetrieveFromChace,persons = $persons)';
  }
}

class PersonBloc extends Bloc<LoadAction, FetchResult?> {
  final Map<Personsurl, Iterable<Person>> _chace = {};
  PersonBloc() : super(null) {
    on<LoadPersonAction>((event, emit) async {
      final url = event.url;
      if (_chace.containsKey(url)) {
        final chacedPerson = _chace[url]!;

        final result = FetchResult(
          persons: chacedPerson,
          isRetrieveFromChace: true,
        );
        emit(result);
      } else {
        final persons = await getPersons(url.urlString);
        _chace[url] = persons;
        final result = FetchResult(
          isRetrieveFromChace: false,
          persons: persons,
        );
        emit(result);
      }
    });
  }
}

extension Subcript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Column(children: [
        Row(
          children: [
            TextButton(
              onPressed: () {
                context.read<PersonBloc>().add(
                      const LoadPersonAction(url: Personsurl.persons1),
                    );
              },
              child: const Text('Load Json #1'),
            ),
            TextButton(
              onPressed: () {
                context.read<PersonBloc>().add(
                      const LoadPersonAction(url: Personsurl.persons2),
                    );
              },
              child: const Text('Load Json #2'),
            ),
          ],
        ),
        BlocBuilder<PersonBloc, FetchResult?>(
          buildWhen: (previousResult, currentResult) {
            return previousResult?.persons != currentResult?.persons;
          },
          builder: ((context, FetchResult) {
            final persons = FetchResult?.persons;
            if (persons == null) {
              return const SizedBox();
            }

            return Expanded(
              child: ListView.builder(
                  itemCount: persons.length,
                  itemBuilder: (context, index) {
                    final person = persons[index]!;
                    return ListTile(
                      title: Text(person.name),
                    );
                  }),
            );
          }),
        )
      ]),
    );
  }
}
