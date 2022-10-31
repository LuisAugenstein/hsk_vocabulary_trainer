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
  Answer? _selectedAnswer;

  @override
  void initState() {
    _resetState();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 5, 50, 80),
        body: SingleChildScrollView(
            child: Align(
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                width: 400,
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
    return const Text(
      "HSK Trainer",
      style: TextStyle(
        color: Colors.white,
        fontSize: 36,
      ),
    );
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
                _setHskLevel(_selectedHskLevels);
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
        "${_questionList[_currentQuestionIndex].questionSymbol}\n${_questionList[_currentQuestionIndex].questionPinyin}",
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
    bool isSelected = answer == _selectedAnswer;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          primary: isSelected
              ? (answer.isCorrect ? Colors.green : Colors.red)
              : Theme.of(context).primaryColor,
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
        .then((value) => _setHskLevel(_selectedHskLevels));
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

  _setHskLevel(List<HskLevel> hskLevels) async {
    _resetState();
    List<Question> questionList = await getQuestions(hskLevels);
    setState(() {
      _questionList = questionList;
      _selectedHskLevels = hskLevels;
    });
  }
}
