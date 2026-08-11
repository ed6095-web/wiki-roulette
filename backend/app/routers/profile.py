from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc
from datetime import datetime, timezone, timedelta
from typing import List, Optional
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.game import GameSession, ArticleHistory, UserAnswer
from app.models.article import Article
from app.models.achievement import Achievement, UserAchievement
from app.schemas.user import (
    UserStatsResponse, HistoryResponse, HistoryEntry, AchievementSchema, LeaderboardResponse, LeaderboardEntry
)
from app.services.xp_service import xp_progress

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("/stats", response_model=UserStatsResponse)
async def get_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    uid = current_user.id

    # Quizzes completed
    quizzes_result = await db.execute(
        select(func.count()).select_from(GameSession)
        .where(GameSession.user_id == uid, GameSession.completed == True)
    )
    quizzes_completed = quizzes_result.scalar() or 0

    # Articles discovered
    articles_result = await db.execute(
        select(func.count()).select_from(ArticleHistory)
        .where(ArticleHistory.user_id == uid)
    )
    articles_discovered = articles_result.scalar() or 0

    # Perfect quizzes (all answers correct in a session)
    sessions_result = await db.execute(
        select(GameSession).where(GameSession.user_id == uid, GameSession.completed == True)
    )
    sessions = sessions_result.scalars().all()
    perfect_count = 0
    all_corrects = []
    all_times = []
    for s in sessions:
        answers_r = await db.execute(
            select(UserAnswer).where(UserAnswer.game_session_id == s.id)
        )
        answers = answers_r.scalars().all()
        if answers:
            if all(a.correct for a in answers):
                perfect_count += 1
            all_corrects.extend([a.correct for a in answers])
            all_times.extend([a.response_time_ms for a in answers if a.response_time_ms])

    total_answers = len(all_corrects)
    correct_answers = sum(1 for c in all_corrects if c)
    avg_accuracy = (correct_answers / total_answers * 100) if total_answers > 0 else 0.0
    avg_response = (sum(all_times) / len(all_times)) if all_times else 0.0

    best_score_result = await db.execute(
        select(func.max(GameSession.score))
        .where(GameSession.user_id == uid)
    )
    best_score = best_score_result.scalar() or 0

    return UserStatsResponse(
        articles_discovered=articles_discovered,
        quizzes_completed=quizzes_completed,
        perfect_quizzes=perfect_count,
        average_score=current_user.total_score / max(1, quizzes_completed),
        average_accuracy=round(avg_accuracy, 1),
        average_response_time_ms=round(avg_response, 0),
        best_score=best_score,
        current_streak=current_user.current_streak,
        longest_streak=current_user.longest_streak,
        total_xp=current_user.xp,
        favorite_category=None,  # TODO: calculate from article_category_map joins
    )


@router.get("/history", response_model=HistoryResponse)
async def get_history(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    offset = (page - 1) * per_page

    total_result = await db.execute(
        select(func.count()).select_from(ArticleHistory)
        .where(ArticleHistory.user_id == current_user.id)
    )
    total = total_result.scalar() or 0

    history_result = await db.execute(
        select(ArticleHistory)
        .where(ArticleHistory.user_id == current_user.id)
        .order_by(desc(ArticleHistory.visited_at))
        .offset(offset).limit(per_page)
    )
    entries = history_result.scalars().all()

    result_entries = []
    for h in entries:
        article = None
        if h.article_id:
            a_result = await db.execute(select(Article).where(Article.id == h.article_id))
            article = a_result.scalar_one_or_none()

        result_entries.append(HistoryEntry(
            id=h.id,
            article_id=h.article_id,
            article_title=article.title if article else None,
            article_thumbnail=article.thumbnail_url if article else None,
            source=h.source,
            completed=h.completed,
            visited_at=h.visited_at,
        ))

    return HistoryResponse(entries=result_entries, total=total, page=page, per_page=per_page)


@router.get("/achievements", response_model=List[AchievementSchema])
async def get_achievements(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    all_result = await db.execute(select(Achievement))
    all_achievements = all_result.scalars().all()

    unlocked_result = await db.execute(
        select(UserAchievement)
        .where(UserAchievement.user_id == current_user.id)
    )
    unlocked = {ua.achievement_id: ua.unlocked_at for ua in unlocked_result.scalars().all()}

    return [
        AchievementSchema(
            id=a.id, name=a.name, description=a.description,
            icon=a.icon, xp_reward=a.xp_reward,
            condition_type=a.condition_type, condition_value=a.condition_value,
            unlocked=a.id in unlocked,
            unlocked_at=unlocked.get(a.id),
        )
        for a in all_achievements
    ]
