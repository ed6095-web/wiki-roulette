from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timezone, timedelta
from app.core.database import get_db
from app.core.deps import get_optional_user
from app.models.user import User
from app.models.article import Article, ArticleCategory
from app.schemas.article import ArticleSchema, ArticleSearchResult, ArticleListResponse
from app.services.wikipedia_service import wikipedia_service
from app.services.quiz_service import generate_questions_from_extract
from app.models.game import QuizQuestion
from typing import List, Optional

router = APIRouter(prefix="/articles", tags=["articles"])

CACHE_TTL_HOURS = 24


async def _get_or_cache_article(wiki_article, db: AsyncSession) -> Article:
    """Fetches article from DB cache or creates a new record."""
    result = await db.execute(
        select(Article).where(Article.wiki_page_id == wiki_article.wiki_page_id)
    )
    existing = result.scalar_one_or_none()

    if existing:
        cache_age = datetime.now(timezone.utc) - existing.cached_at.replace(tzinfo=timezone.utc)
        if cache_age < timedelta(hours=CACHE_TTL_HOURS):
            return existing
        existing.extract = wiki_article.extract
        existing.thumbnail_url = wiki_article.thumbnail_url
        existing.description = wiki_article.description
        existing.cached_at = datetime.now(timezone.utc)
        await db.commit()
        await db.refresh(existing)
        return existing

    word_count = wiki_article.word_count or 0
    if word_count < 100:
        difficulty = "easy"
    elif word_count < 300:
        difficulty = "medium"
    else:
        difficulty = "hard"

    article = Article(
        wiki_page_id=wiki_article.wiki_page_id,
        title=wiki_article.title,
        slug=wiki_article.slug,
        url=wiki_article.url,
        description=wiki_article.description,
        extract=wiki_article.extract,
        thumbnail_url=wiki_article.thumbnail_url,
        language=wiki_article.language,
        word_count=wiki_article.word_count,
        difficulty=difficulty,
    )
    db.add(article)
    await db.flush()

    if wiki_article.extract:
        questions, quiz_available = generate_questions_from_extract(
            wiki_article.extract, wiki_article.title
        )
        article.quiz_available = quiz_available
        for q in questions:
            qq = QuizQuestion(
                article_id=article.id,
                question=q.question,
                option_a=q.option_a,
                option_b=q.option_b,
                option_c=q.option_c,
                option_d=q.option_d,
                correct_option=q.correct_option,
                explanation=q.explanation,
                difficulty=q.difficulty,
                source=q.source,
            )
            db.add(qq)

    await db.commit()
    await db.refresh(article)
    return article


@router.get("/random", response_model=ArticleSchema)
async def get_random_article(
    db: AsyncSession = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_user),
):
    for attempt in range(10):
        wiki_article = await wikipedia_service.get_random_article()
        if not wiki_article:
            continue

        article = await _get_or_cache_article(wiki_article, db)

        if not article.quiz_available and attempt < 9:
            continue
        return article

    raise HTTPException(status_code=503, detail="Wikipedia service temporarily unavailable. Please try again.")


@router.get("/search", response_model=List[ArticleSearchResult])
async def search_articles(
    q: str = Query(..., min_length=2, max_length=100),
    limit: int = Query(10, ge=1, le=20),
    current_user: Optional[User] = Depends(get_optional_user),
):
    results = await wikipedia_service.search_articles(q, limit)
    return [
        ArticleSearchResult(
            wiki_page_id=0,
            title=r.title,
            description=r.description,
            thumbnail_url=r.thumbnail_url,
            url=r.url,
        )
        for r in results
    ]


@router.get("/{article_id}", response_model=ArticleSchema)
async def get_article(
    article_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_user),
):
    result = await db.execute(select(Article).where(Article.id == article_id))
    article = result.scalar_one_or_none()
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")
    return article
