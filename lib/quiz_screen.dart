import 'package:flutter/material.dart';
import 'package:hsk_vocabulary_trainer/question_model.dart';

class QuizScreen extends StatefulWidget {
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<HskLevel> _selectedHskLevels;
  late List<Question> _questionList;
  late int _currentQuestionIndex, _lives;
  bool _chineseToEnglish = true;
  Answer? _selectedAnswer;

  @override
  void initState() {
    _resetState();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);

    double minWidth = 360;
    double maxWidth = 400;
    double width = media.size.width - 10;
    width = width < minWidth ? minWidth : width;
    width = width > maxWidth ? maxWidth : width;

    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 5, 50, 80),
        body: SingleChildScrollView(
            child: Align(
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                margin: const EdgeInsets.only(left: 5, right: 5),
                width: width,
                child: Column(children: [
                  const SizedBox(height: 30),
                  _title(),
                  const SizedBox(height: 10),
                  _hskLevelSelectionChips(),
                  const SizedBox(height: 30),
                  _content()
                ]),
              )),
        )));
  }

  _title() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Container(
          width: 40,
          margin: const EdgeInsets.only(left: 10, right: 10),
          child: TextButton(
            onPressed: () {
              setState(() {
                _chineseToEnglish = !_chineseToEnglish;
                _resetQuestions();
              });
            },
            child: Column(
              children: [
                Text(_chineseToEnglish ? "🇨🇳" : "🇬🇧"),
                const Icon(
                  Icons.autorenew,
                  color: Colors.white,
                  size: 14,
                ),
                Text(_chineseToEnglish ? "🇬🇧" : "🇨🇳"),
              ],
            ),
          )),
      const Text(
        "HSK Trainer",
        style: TextStyle(
          color: Colors.white,
          fontSize: 36,
        ),
      ),
      const SizedBox(
        width: 60,
      )
    ]);
  }

  _hskLevelSelectionChips() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List<Widget>.generate(
          6,
          (int index) {
            return ChoiceChip(
              selectedColor: Theme.of(context).primaryColor,
              backgroundColor: Theme.of(context).disabledColor,
              labelStyle: const TextStyle(color: Colors.white),
              label: Text('HSK${index + 1}'),
              selected: _selectedHskLevels.contains(HskLevel.values[index]),
              onSelected: (bool selected) async {
                selected
                    ? _selectedHskLevels.add(HskLevel.values[index])
                    : _selectedHskLevels.remove(HskLevel.values[index]);
                _resetQuestions();
              },
            );
          },
        ).toList());
  }

  _content() {
    if (_currentQuestionIndex < 0 ||
        _currentQuestionIndex >= _questionList.length) {
      return const CircularProgressIndicator();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _userStatistics(),
        const SizedBox(height: 20),
        _question(),
        const SizedBox(height: 40),
        _answers(),
      ],
    );
  }

  _userStatistics() {
    return Row(
      children: [
        Text(
          "${_currentQuestionIndex + 1}/${_questionList.length.toString()}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(child: Container()),
        const Icon(
          Icons.favorite,
          color: Colors.pink,
          size: 24.0,
          semanticLabel: 'Text to announce in accessibility modes',
        ),
        const SizedBox(width: 5),
        Text(
          "$_lives",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        )
      ],
    );
  }

  _question() {
    return Container(
      alignment: Alignment.center,
      height: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _questionList[_currentQuestionIndex].questionText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _answers() {
    return Column(
      children: _questionList[_currentQuestionIndex]
          .answers
          .map(
            (answer) => _answerButton(answer),
          )
          .toList(),
    );
  }

  Widget _answerButton(Answer answer) {
    Color buttonColor = Theme.of(context).primaryColor;
    if (_selectedAnswer != null && answer.isCorrect) {
      buttonColor = Colors.green;
    } else if (answer == _selectedAnswer && !answer.isCorrect) {
      buttonColor = Colors.red;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          primary: buttonColor,
        ),
        onPressed: () {
          if (_selectedAnswer != null) {
            return;
          }
          if (!answer.isCorrect) {
            _lives--;
          }
          setState(() {
            _selectedAnswer = answer;
          });
          Future.delayed(const Duration(milliseconds: 500), _nextQuestion);
        },
        child: FittedBox(
            fit: BoxFit.fitWidth,
            child: Text(
              answer.answerTitle,
              style: const TextStyle(fontSize: 20),
            )),
      ),
    );
  }

  _nextQuestion() {
    if (_lives == 0) {
      _showResultDialog(false);
      return;
    }
    bool isLastQuestion = _currentQuestionIndex == _questionList.length - 1;
    if (isLastQuestion) {
      _showResultDialog(true);
    } else {
      setState(() {
        _selectedAnswer = null;
        _currentQuestionIndex++;
      });
    }
  }

  _showResultDialog(bool isPassed) {
    Widget alertDialog = SimpleDialog(
      backgroundColor: Theme.of(context).primaryColor,
      title: Text(
        isPassed ? "Congratulations you have passed!" : "you have Failed!",
        style: const TextStyle(color: Colors.white),
      ),
      children: <Widget>[
        SimpleDialogOption(
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  primary: isPassed ? Colors.green : Colors.red),
              child: const Text("Restart"),
              onPressed: () {
                Navigator.pop(context);
              }),
        ),
      ],
    );
    showDialog(context: context, builder: (_) => alertDialog)
        .then((value) => _resetQuestions());
  }

  Future<void> _resetState() async {
    setState(() {
      _currentQuestionIndex = 0;
      _lives = 5;
      _selectedAnswer = null;
      _questionList = [];
      _selectedHskLevels = [];
    });
  }

  _resetQuestions() async {
    List<HskLevel> selectedHskLevels = _selectedHskLevels;
    _resetState();
    List<Question> questionList =
        await getQuestions(selectedHskLevels, _chineseToEnglish);
    setState(() {
      _selectedHskLevels = selectedHskLevels;
      _questionList = questionList;
    });
  }
}
