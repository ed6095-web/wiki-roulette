from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


class QuizQuestionSchema(BaseModel):
    id: int
    question: str
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    difficulty: str
    # correct_option intentionally excluded from client responses

    model_config = {"from_attributes": True}


class QuizQuestionWithAnswer(QuizQuestionSchema):
    correct_option: str
    explanation: Optional[str]


class StartGameRequest(BaseModel):
    article_id: int
    game_type: str = "roulette"
    is_daily: bool = False


class StartGameResponse(BaseModel):
    session_id: int
    article_id: int
    game_type: str
    questions: List[QuizQuestionSchema]
    started_at: datetime


class SubmitAnswerRequest(BaseModel):
    question_id: int
    selected_option: str  # "a"|"b"|"c"|"d"
    response_time_ms: int


class SubmitAnswerResponse(BaseModel):
    correct: bool
    correct_option: str
    explanation: Optional[str]
    score_delta: int
    xp_delta: int


class CompleteGameRequest(BaseModel):
    pass  # server calculates final score from stored answers


class ScoreBreakdown(BaseModel):
    correct_answers: int
    total_questions: int
    base_score: int
    speed_bonus: int
    perfect_bonus: int
    daily_multiplier: float
    final_score: int
    xp_earned: int
    level_before: int
    level_after: int
    leveled_up: bool
    new_achievements: List[str] = []


class CompleteGameResponse(BaseModel):
    session_id: int
    score_breakdown: ScoreBreakdown
    new_streak: int
