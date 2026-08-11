from sqlalchemy import (
    Column, Integer, String, DateTime, Boolean, Text, ForeignKey, Table, Float
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


# Many-to-many: articles <-> categories
article_category_map = Table(
    "article_category_map",
    Base.metadata,
    Column("article_id", Integer, ForeignKey("articles.id", ondelete="CASCADE"), primary_key=True),
    Column("category_id", Integer, ForeignKey("article_categories.id", ondelete="CASCADE"), primary_key=True),
)


class ArticleCategory(Base):
    __tablename__ = "article_categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)
    description = Column(String(255), nullable=True)
    icon = Column(String(10), nullable=True)  # Emoji

    articles = relationship("Article", secondary=article_category_map, back_populates="categories")


class Article(Base):
    __tablename__ = "articles"

    id = Column(Integer, primary_key=True, index=True)
    wiki_page_id = Column(Integer, unique=True, nullable=False, index=True)
    title = Column(String(500), nullable=False, index=True)
    slug = Column(String(500), nullable=False)
    url = Column(String(1000), nullable=False)
    description = Column(String(500), nullable=True)
    extract = Column(Text, nullable=True)
    thumbnail_url = Column(String(1000), nullable=True)
    language = Column(String(10), default="en", nullable=False)
    word_count = Column(Integer, nullable=True)
    difficulty = Column(String(10), default="medium", nullable=False)
    quiz_available = Column(Boolean, default=True, nullable=False)
    cached_at = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    categories = relationship("ArticleCategory", secondary=article_category_map, back_populates="articles")
    game_sessions = relationship("GameSession", back_populates="article")
    article_history = relationship("ArticleHistory", back_populates="article")
    quiz_questions = relationship("QuizQuestion", back_populates="article")
    favorites = relationship("Favorite", back_populates="article")
