from sqlalchemy import (
    Column, Integer, String, DateTime, BigInteger, Boolean, Float, Text, ForeignKey, Enum as SAEnum
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import enum


class DifficultyEnum(str, enum.Enum):
    easy = "easy"
    medium = "medium"
    hard = "hard"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    avatar_url = Column(String(500), nullable=True)
    xp = Column(BigInteger, default=0, nullable=False)
    level = Column(Integer, default=1, nullable=False)
    total_games = Column(Integer, default=0, nullable=False)
    total_score = Column(BigInteger, default=0, nullable=False)
    current_streak = Column(Integer, default=0, nullable=False)
    longest_streak = Column(Integer, default=0, nullable=False)
    last_played_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    game_sessions = relationship("GameSession", back_populates="user", lazy="dynamic")
    article_history = relationship("ArticleHistory", back_populates="user", lazy="dynamic")
    user_answers = relationship("UserAnswer", back_populates="user", lazy="dynamic")
    user_achievements = relationship("UserAchievement", back_populates="user")
    favorites = relationship("Favorite", back_populates="user", lazy="dynamic")
