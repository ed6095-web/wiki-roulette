from sqlalchemy import (
    Column, Integer, String, DateTime, Boolean, BigInteger, Float, ForeignKey, Text
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class GameSession(Base):
    __tablename__ = "game_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    article_id = Column(Integer, ForeignKey("articles.id", ondelete="SET NULL"), nullable=True)
    game_type = Column(String(20), nullable=False, default="roulette")  # roulette|quiz|speedrun|daily|rabbit_hole
    score = Column(Integer, default=0, nullable=False)
    xp_earned = Column(Integer, default=0, nullable=False)
    started_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    time_taken = Column(Integer, nullable=True)  # seconds
    completed = Column(Boolean, default=False, nullable=False)
    is_daily = Column(Boolean, default=False, nullable=False)

    # Relationships
    user = relationship("User", back_populates="game_sessions")
    article = relationship("Article", back_populates="game_sessions")
    user_answers = relationship("UserAnswer", back_populates="game_session", cascade="all, delete-orphan")


class QuizQuestion(Base):
    __tablename__ = "quiz_questions"

    id = Column(Integer, primary_key=True, index=True)
    article_id = Column(Integer, ForeignKey("articles.id", ondelete="CASCADE"), nullable=False, index=True)
    question = Column(Text, nullable=False)
    option_a = Column(String(500), nullable=False)
    option_b = Column(String(500), nullable=False)
    option_c = Column(String(500), nullable=False)
    option_d = Column(String(500), nullable=False)
    correct_option = Column(String(1), nullable=False)  # "a"|"b"|"c"|"d"
    explanation = Column(Text, nullable=True)
    difficulty = Column(String(10), default="medium", nullable=False)
    source = Column(String(20), default="generated", nullable=False)  # "handcrafted"|"generated"|"cached"
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    article = relationship("Article", back_populates="quiz_questions")
    user_answers = relationship("UserAnswer", back_populates="question")


class UserAnswer(Base):
    __tablename__ = "user_answers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    game_session_id = Column(Integer, ForeignKey("game_sessions.id", ondelete="CASCADE"), nullable=False)
    question_id = Column(Integer, ForeignKey("quiz_questions.id", ondelete="SET NULL"), nullable=True)
    selected_option = Column(String(1), nullable=True)
    correct = Column(Boolean, nullable=False)
    response_time_ms = Column(Integer, nullable=True)
    answered_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="user_answers")
    game_session = relationship("GameSession", back_populates="user_answers")
    question = relationship("QuizQuestion", back_populates="user_answers")


class ArticleHistory(Base):
    __tablename__ = "article_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    article_id = Column(Integer, ForeignKey("articles.id", ondelete="SET NULL"), nullable=True)
    source = Column(String(20), default="roulette", nullable=False)  # roulette|quiz|search|daily|rabbit_hole
    time_spent_seconds = Column(Integer, nullable=True)
    completed = Column(Boolean, default=False, nullable=False)
    visited_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    # Relationships
    user = relationship("User", back_populates="article_history")
    article = relationship("Article", back_populates="article_history")


class DailyChallenge(Base):
    __tablename__ = "daily_challenges"

    id = Column(Integer, primary_key=True, index=True)
    challenge_date = Column(DateTime(timezone=True), unique=True, nullable=False, index=True)
    article_id = Column(Integer, ForeignKey("articles.id", ondelete="SET NULL"), nullable=True)
    challenge_type = Column(String(20), default="quiz", nullable=False)

    article = relationship("Article")


class Favorite(Base):
    __tablename__ = "favorites"

    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    article_id = Column(Integer, ForeignKey("articles.id", ondelete="CASCADE"), primary_key=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="favorites")
    article = relationship("Article", back_populates="favorites")
