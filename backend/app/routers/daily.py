from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import datetime, timezone, date
from pydantic import BaseModel
from typing import Optional
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.game import DailyChallenge
from app.models.article import Article
from app.schemas.article import ArticleSchema

router = APIRouter(prefix="/daily", tags=["daily"])


class DailyChallengeResponse(BaseModel):
    challenge_date: datetime
    challenge_type: str
    article: ArticleSchema


@router.get("", response_model=DailyChallengeResponse)
async def get_daily_challenge(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    today = datetime.now(timezone.utc).date()
    today_start = datetime(today.year, today.month, today.day, tzinfo=timezone.utc)

    result = await db.execute(
        select(DailyChallenge).where(
            func.date(DailyChallenge.challenge_date) == today
        )
    )
    challenge = result.scalar_one_or_none()

    if not challenge:
        raise HTTPException(
            status_code=404,
            detail="No daily challenge set for today. Check back later!"
        )

    article_result = await db.execute(
        select(Article).where(Article.id == challenge.article_id)
    )
    article = article_result.scalar_one_or_none()
    if not article:
        raise HTTPException(status_code=404, detail="Daily challenge article not found")

    return DailyChallengeResponse(
        challenge_date=challenge.challenge_date,
        challenge_type=challenge.challenge_type,
        article=ArticleSchema.model_validate(article),
    )
