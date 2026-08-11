"""
Achievement checking service.
Evaluated after each game completion.
"""

from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.models.achievement import Achievement, UserAchievement
from app.models.game import GameSession, ArticleHistory, UserAnswer
from app.models.user import User


ACHIEVEMENT_CHECKERS = {}


def achievement_checker(condition_type: str):
    def decorator(fn):
        ACHIEVEMENT_CHECKERS[condition_type] = fn
        return fn
    return decorator


@achievement_checker("articles_read")
async def check_articles_read(user: User, db: AsyncSession, condition_value: int) -> bool:
    result = await db.execute(
        select(func.count()).select_from(ArticleHistory)
        .where(ArticleHistory.user_id == user.id)
    )
    count = result.scalar() or 0
    return count >= condition_value


@achievement_checker("quizzes_completed")
async def check_quizzes_completed(user: User, db: AsyncSession, condition_value: int) -> bool:
    result = await db.execute(
        select(func.count()).select_from(GameSession)
        .where(GameSession.user_id == user.id, GameSession.completed == True)
    )
    count = result.scalar() or 0
    return count >= condition_value


@achievement_checker("perfect_quiz")
async def check_perfect_quiz(user: User, db: AsyncSession, condition_value: int) -> bool:
    """condition_value = minimum number of perfect quizzes."""
    result = await db.execute(
        select(GameSession)
        .where(GameSession.user_id == user.id, GameSession.completed == True)
    )
    sessions = result.scalars().all()
    perfect_count = 0
    for session in sessions:
        answers = await db.execute(
            select(UserAnswer).where(UserAnswer.game_session_id == session.id)
        )
        all_answers = answers.scalars().all()
        if all_answers and all(a.correct for a in all_answers):
            perfect_count += 1
    return perfect_count >= condition_value


@achievement_checker("streak")
async def check_streak(user: User, db: AsyncSession, condition_value: int) -> bool:
    return user.longest_streak >= condition_value


@achievement_checker("total_score")
async def check_total_score(user: User, db: AsyncSession, condition_value: int) -> bool:
    return user.total_score >= condition_value


@achievement_checker("first_game")
async def check_first_game(user: User, db: AsyncSession, condition_value: int) -> bool:
    return user.total_games >= 1


async def check_and_award_achievements(user: User, db: AsyncSession) -> List[str]:
    """
    Checks all achievements against current user state.
    Awards any newly earned achievements.
    Returns list of newly unlocked achievement names.
    """
    # Get already unlocked achievement IDs
    result = await db.execute(
        select(UserAchievement.achievement_id)
        .where(UserAchievement.user_id == user.id)
    )
    unlocked_ids = set(result.scalars().all())

    # Get all achievements
    all_achievements = await db.execute(select(Achievement))
    achievements = all_achievements.scalars().all()

    newly_unlocked = []
    for ach in achievements:
        if ach.id in unlocked_ids:
            continue
        checker = ACHIEVEMENT_CHECKERS.get(ach.condition_type)
        if checker and await checker(user, db, ach.condition_value):
            user_ach = UserAchievement(user_id=user.id, achievement_id=ach.id)
            db.add(user_ach)
            # Award XP
            user.xp += ach.xp_reward
            newly_unlocked.append(ach.name)

    if newly_unlocked:
        await db.flush()

    return newly_unlocked
