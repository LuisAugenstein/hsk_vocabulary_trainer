import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

enum HskLevel { hsk1, hsk2, hsk3, hsk4, hsk5, hsk6 }

extension HskLevelExtension on HskLevel {
  String get fileName => "${toString().replaceFirst('HskLevel.', '')}.json";
}

class Question {
  final String questionSymbol;
  final String questionPinyin;
  final List<Answer> answers;

  Question(this.questionSymbol, this.questionPinyin, this.answers);
}

class Answer {
  final String answerTitle;
  final bool isCorrect;

  Answer(this.answerTitle, this.isCorrect);
}

class HSKVocabulary {
  final String simplified;
  final String traditional;
  final String pinyin;
  final List<String> definitions;

  HSKVocabulary(
      this.simplified, this.traditional, this.pinyin, this.definitions);

  HSKVocabulary.fromJson(Map<String, dynamic> json)
      : simplified = json['simplified'],
        traditional = json['traditional'],
        pinyin = json['pinyin'],
        definitions = json['definitions'].map<String>((d) {
          return d.toString();
        }).toList();
}

Future<List<Question>> getQuestions(List<HskLevel> selectedHskLevels) async {
  // read json data from local files
  List<String> hskJsonStrings = await Future.wait(selectedHskLevels
      .map((hskLevel) => rootBundle.loadString('assets/${hskLevel.fileName}')));
  // get vocabulary objects from json and merge all vocabularies
  List<HSKVocabulary> hskVocabularies = [];
  for (String hskJsonString in hskJsonStrings) {
    hskVocabularies.addAll(jsonDecode(hskJsonString)
        .map<HSKVocabulary>((json) => HSKVocabulary.fromJson(json)));
  }
  // construct question answers tuples and randomize the questions
  List<Question> questions = hskVocabularies.asMap().entries.map((entry) {
    String correctAnswer = entry.value.definitions[0];
    List<Answer> answers = [Answer(correctAnswer, true)];
    List<int> answerIndices = List<int>.generate(hskVocabularies.length - 1,
        (index) => index == entry.key ? hskVocabularies.length - 1 : index);
    answerIndices.shuffle();
    answers.addAll(answerIndices
        .take(3)
        .map((index) => Answer(hskVocabularies[index].definitions[0], false)));
    answers.shuffle();
    return Question(entry.value.simplified, entry.value.pinyin, answers);
  }).toList();
  questions.shuffle();
  return questions;
}
