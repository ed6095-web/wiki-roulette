from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc
from datetime import datetime, timezone, timedelta
from typing import Optional
from app.core.database import get_db
from app.core.deps import get_optional_user
from app.models.user import User
from app.models.game import GameSession
from app.schemas.user import LeaderboardResponse, LeaderboardEntry

router = APIRouter(prefix="/leaderboard", tags=["leaderboard"])


def _period_start(period: str) -> datetime:
    now = datetime.now(timezone.utc)
    if period == "daily":
        return now.replace(hour=0, minute=0, second=0, microsecond=0)
    elif period == "weekly":
        return (now - timedelta(days=now.weekday())).replace(hour=0, minute=0, second=0, microsecond=0)
    elif period == "monthly":
        return now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    else:  # alltime
        return datetime(2000, 1, 1, tzinfo=timezone.utc)


@router.get("", response_model=LeaderboardResponse)
async def get_leaderboard(
    period: str = Query("weekly", pattern="^(daily|weekly|monthly|alltime)$"),
    limit: int = Query(50, ge=10, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_user),
):
    start = _period_start(period)

    # Aggregate scores per user in the period
    result = await db.execute(
        select(
            GameSession.user_id,
            func.sum(GameSession.score).label("total_score"),
        )
        .where(GameSession.completed == True, GameSession.started_at >= start)
        .group_by(GameSession.user_id)
        .order_by(desc("total_score"))
        .limit(limit)
    )
    rows = result.all()

    entries = []
    current_user_rank = None
    current_user_score = None

    for rank, row in enumerate(rows, start=1):
        user_result = await db.execute(select(User).where(User.id == row.user_id))
        user = user_result.scalar_one_or_none()
        if not user:
            continue
        is_me = current_user is not None and user.id == current_user.id
        if is_me:
            current_user_rank = rank
            current_user_score = row.total_score
        entries.append(LeaderboardEntry(
            rank=rank,
            user_id=user.id,
            username=user.username,
            avatar_url=user.avatar_url,
            score=row.total_score,
            is_current_user=is_me,
        ))

    if current_user and current_user_rank is None:
        my_result = await db.execute(
            select(func.sum(GameSession.score))
            .where(GameSession.user_id == current_user.id, GameSession.completed == True, GameSession.started_at >= start)
        )
        my_score = my_result.scalar() or 0
        current_user_score = my_score

        if my_score > 0:
            rank_result = await db.execute(
                select(func.count()).select_from(
                    select(
                        GameSession.user_id,
                        func.sum(GameSession.score).label("total_score"),
                    )
                    .where(GameSession.completed == True, GameSession.started_at >= start)
                    .group_by(GameSession.user_id)
                    .having(func.sum(GameSession.score) > my_score)
                    .subquery()
                )
            )
            current_user_rank = (rank_result.scalar() or 0) + 1

    return LeaderboardResponse(
        period=period,
        entries=entries,
        current_user_rank=current_user_rank,
        current_user_score=current_user_score,
    )
