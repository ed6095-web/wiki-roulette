from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timezone
from typing import Optional
from app.core.database import get_db
from app.core.deps import get_optional_user
from app.models.user import User
from app.models.article import Article
from app.models.game import DailyChallenge, GameSession
from app.schemas.article import DailyChallengeResponse, ArticleSchema

router = APIRouter(prefix="/daily", tags=["daily"])


@router.get("", response_model=DailyChallengeResponse)
async def get_daily_challenge(
    db: AsyncSession = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_user),
):
    today = datetime.now(timezone.utc).date()
    start_of_day = datetime(today.year, today.month, today.day, tzinfo=timezone.utc)

    result = await db.execute(
        select(DailyChallenge).where(DailyChallenge.challenge_date >= start_of_day)
    )
    challenge = result.scalar_one_or_none()

    if not challenge:
        # Fallback to latest available daily challenge or any quiz-capable article
        art_result = await db.execute(
            select(Article).where(Article.quiz_available == True).limit(1)
        )
        fallback_art = art_result.scalar_one_or_none()
        if not fallback_art:
            raise HTTPException(status_code=404, detail="No daily challenge available")
        return DailyChallengeResponse(
            date=start_of_day,
            article=ArticleSchema.model_validate(fallback_art),
            completed=False,
        )

    art_result = await db.execute(select(Article).where(Article.id == challenge.article_id))
    article = art_result.scalar_one_or_none()
    if not article:
        raise HTTPException(status_code=404, detail="Challenge article not found")

    completed = False
    if current_user:
        session_result = await db.execute(
            select(GameSession).where(
                GameSession.user_id == current_user.id,
                GameSession.article_id == article.id,
                GameSession.is_daily == True,
                GameSession.completed == True,
                GameSession.started_at >= start_of_day,
            )
        )
        completed = session_result.scalar_one_or_none() is not None

    return DailyChallengeResponse(
        date=challenge.challenge_date,
        article=ArticleSchema.model_validate(article),
        completed=completed,
    )
