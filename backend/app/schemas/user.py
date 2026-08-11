from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


class LeaderboardEntry(BaseModel):
    rank: int
    user_id: int
    username: str
    avatar_url: Optional[str]
    score: int
    is_current_user: bool = False


class LeaderboardResponse(BaseModel):
    period: str  # daily|weekly|monthly|alltime
    entries: List[LeaderboardEntry]
    current_user_rank: Optional[int]
    current_user_score: Optional[int]


class UserStatsResponse(BaseModel):
    articles_discovered: int
    quizzes_completed: int
    perfect_quizzes: int
    average_score: float
    average_accuracy: float
    average_response_time_ms: float
    best_score: int
    current_streak: int
    longest_streak: int
    total_xp: int
    favorite_category: Optional[str]


class HistoryEntry(BaseModel):
    id: int
    article_id: Optional[int]
    article_title: Optional[str]
    article_thumbnail: Optional[str]
    source: str
    completed: bool
    visited_at: datetime


class HistoryResponse(BaseModel):
    entries: List[HistoryEntry]
    total: int
    page: int
    per_page: int


class AchievementSchema(BaseModel):
    id: int
    name: str
    description: str
    icon: str
    xp_reward: int
    condition_type: str
    condition_value: int
    unlocked: bool = False
    unlocked_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
