import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../core/network/api_client.dart';

// ── Quiz State ──
enum QuizStatus { idle, loading, active, submitting, completed, error }

class QuizState {
  final QuizStatus status;
  final GameSessionModel? session;
  final int currentQuestionIndex;
  final Map<int, AnswerResultModel> answers; // questionId -> result
  final GameCompleteModel? result;
  final String? error;

  const QuizState({
    this.status = QuizStatus.idle,
    this.session,
    this.currentQuestionIndex = 0,
    this.answers = const {},
    this.result,
    this.error,
  });

  QuizState copyWith({
    QuizStatus? status,
    GameSessionModel? session,
    int? currentQuestionIndex,
    Map<int, AnswerResultModel>? answers,
    GameCompleteModel? result,
    String? error,
  }) => QuizState(
        status: status ?? this.status,
        session: session ?? this.session,
        currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
        answers: answers ?? this.answers,
        result: result ?? this.result,
        error: error,
      );

  QuizQuestionModel? get currentQuestion {
    if (session == null || currentQuestionIndex >= session!.questions.length) return null;
    return session!.questions[currentQuestionIndex];
  }

  bool get isLastQuestion {
    if (session == null) return false;
    return currentQuestionIndex >= session!.questions.length - 1;
  }

  int get totalQuestions => session?.questions.length ?? 0;
  int get correctCount => answers.values.where((a) => a.correct).length;
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(const QuizState());

  Future<void> startQuiz(int articleId, {bool isDaily = false}) async {
    state = state.copyWith(status: QuizStatus.loading, error: null);
    try {
      final data = await ApiClient.instance.startGame(articleId, isDaily: isDaily);
      state = QuizState(
        status: QuizStatus.active,
        session: GameSessionModel.fromJson(data),
      );
    } catch (e) {
      state = state.copyWith(status: QuizStatus.error, error: e.toString());
    }
  }

  Future<AnswerResultModel?> submitAnswer(String selectedOption, int responseTimeMs) async {
    final question = state.currentQuestion;
    final session = state.session;
    if (question == null || session == null) return null;

    state = state.copyWith(status: QuizStatus.submitting);
    try {
      final data = await ApiClient.instance.submitAnswer(
        session.sessionId,
        question.id,
        selectedOption,
        responseTimeMs,
      );
      final result = AnswerResultModel.fromJson(data);
      final updatedAnswers = Map<int, AnswerResultModel>.from(state.answers)
        ..[question.id] = result;
      state = state.copyWith(
        status: QuizStatus.active,
        answers: updatedAnswers,
      );
      return result;
    } catch (e) {
      state = state.copyWith(status: QuizStatus.active, error: e.toString());
      return null;
    }
  }

  void advanceQuestion() {
    if (!state.isLastQuestion) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
    }
  }

  Future<GameCompleteModel?> completeQuiz() async {
    final session = state.session;
    if (session == null) return null;
    state = state.copyWith(status: QuizStatus.submitting);
    try {
      final data = await ApiClient.instance.completeGame(session.sessionId);
      final result = GameCompleteModel.fromJson(data);
      state = state.copyWith(status: QuizStatus.completed, result: result);
      return result;
    } catch (e) {
      state = state.copyWith(status: QuizStatus.error, error: e.toString());
      return null;
    }
  }

  void reset() => state = const QuizState();
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>(
  (_) => QuizNotifier(),
);
