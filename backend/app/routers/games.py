from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import datetime, timezone
from typing import List, Optional
from app.core.database import get_db
from app.core.deps import get_optional_user
from app.core.security import hash_password
from app.models.user import User
from app.models.game import GameSession, QuizQuestion, UserAnswer, ArticleHistory
from app.models.article import Article
from app.schemas.game import (
    StartGameRequest, StartGameResponse, SubmitAnswerRequest, SubmitAnswerResponse,
    CompleteGameRequest, CompleteGameResponse, ScoreBreakdown, QuizQuestionSchema,
)
from app.services.xp_service import calculate_score, level_for_xp, xp_progress
from app.services.achievement_service import check_and_award_achievements
import random

router = APIRouter(prefix="/games", tags=["games"])


async def _get_or_create_default_user(db: AsyncSession, user: Optional[User]) -> User:
    if user:
        return user
    # Check for existing guest user
    result = await db.execute(select(User).where(User.username == "Explorer"))
    guest = result.scalar_one_or_none()
    if not guest:
        guest = User(
            username="Explorer",
            email="explorer@wikiroulette.app",
            hashed_password=hash_password("GuestPass123!"),
            xp=0,
            level=1,
        )
        db.add(guest)
        await db.commit()
        await db.refresh(guest)
    return guest


@router.post("/start", response_model=StartGameResponse)
async def start_game(
    payload: StartGameRequest,
    db: AsyncSession = Depends(get_db),
    user_opt: Optional[User] = Depends(get_optional_user),
):
    current_user = await _get_or_create_default_user(db, user_opt)

    result = await db.execute(select(Article).where(Article.id == payload.article_id))
    article = result.scalar_one_or_none()
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")
    if not article.quiz_available:
        raise HTTPException(status_code=422, detail="This article does not have enough quiz questions")

    q_result = await db.execute(
        select(QuizQuestion).where(QuizQuestion.article_id == article.id)
    )
    all_questions = q_result.scalars().all()
    if not all_questions:
        raise HTTPException(status_code=422, detail="No quiz questions available for this article")

    selected = random.sample(all_questions, min(5, len(all_questions)))

    session = GameSession(
        user_id=current_user.id,
        article_id=article.id,
        game_type=payload.game_type,
        is_daily=payload.is_daily,
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)

    history = ArticleHistory(
        user_id=current_user.id,
        article_id=article.id,
        source=payload.game_type,
    )
    db.add(history)
    await db.commit()

    return StartGameResponse(
        session_id=session.id,
        article_id=article.id,
        game_type=payload.game_type,
        questions=[QuizQuestionSchema.model_validate(q) for q in selected],
        started_at=session.started_at,
    )


@router.post("/{session_id}/answer", response_model=SubmitAnswerResponse)
async def submit_answer(
    session_id: int,
    payload: SubmitAnswerRequest,
    db: AsyncSession = Depends(get_db),
    user_opt: Optional[User] = Depends(get_optional_user),
):
    current_user = await _get_or_create_default_user(db, user_opt)

    result = await db.execute(
        select(GameSession).where(
            GameSession.id == session_id,
            GameSession.completed == False,
        )
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Active game session not found")

    q_result = await db.execute(
        select(QuizQuestion).where(QuizQuestion.id == payload.question_id)
    )
    question = q_result.scalar_one_or_none()
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    correct = payload.selected_option.lower() == question.correct_option.lower()

    answer = UserAnswer(
        user_id=current_user.id,
        game_session_id=session_id,
        question_id=payload.question_id,
        selected_option=payload.selected_option.lower(),
        correct=correct,
        response_time_ms=payload.response_time_ms,
    )
    db.add(answer)
    await db.commit()

    score_delta = 100 if correct else 0
    if correct:
        t = payload.response_time_ms
        if t < 3000:
            score_delta += 50
        elif t < 5000:
            score_delta += 30
        elif t < 10000:
            score_delta += 10

    return SubmitAnswerResponse(
        correct=correct,
        correct_option=question.correct_option,
        explanation=question.explanation,
        score_delta=score_delta,
        xp_delta=score_delta // 10 if correct else 0,
    )


@router.post("/{session_id}/complete", response_model=CompleteGameResponse)
async def complete_game(
    session_id: int,
    db: AsyncSession = Depends(get_db),
    user_opt: Optional[User] = Depends(get_optional_user),
):
    current_user = await _get_or_create_default_user(db, user_opt)

    result = await db.execute(
        select(GameSession).where(
            GameSession.id == session_id,
            GameSession.completed == False,
        )
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Active game session not found")

    answers_result = await db.execute(
        select(UserAnswer).where(UserAnswer.game_session_id == session_id)
    )
    answers = answers_result.scalars().all()

    correct_count = sum(1 for a in answers if a.correct)
    total_count = len(answers)
    response_times = [a.response_time_ms for a in answers if a.response_time_ms is not None]

    score_data = calculate_score(
        correct_answers=correct_count,
        total_questions=total_count,
        response_times_ms=response_times,
        is_daily=session.is_daily,
    )

    level_before = current_user.level
    current_user.xp += score_data["xp_earned"]
    current_user.total_score += score_data["final_score"]
    current_user.total_games += 1
    current_user.level = level_for_xp(current_user.xp)

    now = datetime.now(timezone.utc)
    if current_user.last_played_at:
        days_diff = (now.date() - current_user.last_played_at.date()).days
        if days_diff == 1:
            current_user.current_streak += 1
        elif days_diff > 1:
            current_user.current_streak = 1
    else:
        current_user.current_streak = 1

    current_user.longest_streak = max(current_user.longest_streak, current_user.current_streak)
    current_user.last_played_at = now

    session.completed = True
    session.completed_at = now
    session.score = score_data["final_score"]
    session.xp_earned = score_data["xp_earned"]
    if session.started_at:
        session.time_taken = int((now - session.started_at.replace(tzinfo=timezone.utc)).total_seconds())

    history_result = await db.execute(
        select(ArticleHistory).where(
            ArticleHistory.user_id == current_user.id,
            ArticleHistory.article_id == session.article_id,
        ).order_by(ArticleHistory.visited_at.desc()).limit(1)
    )
    history = history_result.scalar_one_or_none()
    if history:
        history.completed = True
        history.time_spent_seconds = session.time_taken

    await db.flush()
    new_achievements = await check_and_award_achievements(current_user, db)
    await db.commit()

    leveled_up = current_user.level > level_before

    return CompleteGameResponse(
        session_id=session_id,
        score_breakdown=ScoreBreakdown(
            correct_answers=correct_count,
            total_questions=total_count,
            base_score=score_data["base_score"],
            speed_bonus=score_data["speed_bonus"],
            perfect_bonus=score_data["perfect_bonus"],
            daily_multiplier=score_data["daily_multiplier"],
            final_score=score_data["final_score"],
            xp_earned=score_data["xp_earned"],
            level_before=level_before,
            level_after=current_user.level,
            leveled_up=leveled_up,
            new_achievements=new_achievements,
        ),
        new_streak=current_user.current_streak,
    )
