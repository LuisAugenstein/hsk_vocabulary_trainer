import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

enum HskLevel { hsk1, hsk2, hsk3, hsk4, hsk5, hsk6 }

extension HskLevelExtension on HskLevel {
  String get fileName => "${toString().replaceFirst('HskLevel.', '')}.json";
}

class Question {
  final String questionText;
  final List<Answer> answers;

  Question(this.questionText, this.answers);
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

Future<List<Question>> getQuestions(
    List<HskLevel> selectedHskLevels, bool chinesToEnglish) async {
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
  List<Question> questions = chinesToEnglish
      ? createChineseToEnglish(hskVocabularies)
      : createEnglishToChinese(hskVocabularies);
  questions.shuffle();
  return questions;
}

List<Question> createChineseToEnglish(List<HSKVocabulary> hskVocabularies) {
  return hskVocabularies.asMap().entries.map((entry) {
    String correctAnswer = entry.value.definitions[0];
    List<Answer> answers = [Answer(correctAnswer, true)];
    List<int> answerIndices = List<int>.generate(hskVocabularies.length - 1,
        (index) => index == entry.key ? hskVocabularies.length - 1 : index);
    answerIndices.shuffle();
    answers.addAll(answerIndices
        .take(3)
        .map((index) => Answer(hskVocabularies[index].definitions[0], false)));
    answers.shuffle();
    return Question(
        "${entry.value.simplified}\n${entry.value.pinyin}", answers);
  }).toList();
}

List<Question> createEnglishToChinese(List<HSKVocabulary> hskVocabularies) {
  return hskVocabularies.asMap().entries.map((entry) {
    String correctAnswer = "${entry.value.simplified}  ${entry.value.pinyin}";
    List<Answer> answers = [Answer(correctAnswer, true)];
    List<int> answerIndices = List<int>.generate(hskVocabularies.length - 1,
        (index) => index == entry.key ? hskVocabularies.length - 1 : index);
    answerIndices.shuffle();
    answers.addAll(answerIndices.take(3).map((index) => Answer(
        "${hskVocabularies[index].simplified}  ${hskVocabularies[index].pinyin}",
        false)));
    answers.shuffle();
    return Question(entry.value.definitions[0], answers);
  }).toList();
}
