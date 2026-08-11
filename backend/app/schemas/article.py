from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


class CategorySchema(BaseModel):
    id: int
    name: str
    icon: Optional[str]

    model_config = {"from_attributes": True}


class ArticleSchema(BaseModel):
    id: int
    wiki_page_id: int
    title: str
    slug: str
    url: str
    description: Optional[str]
    extract: Optional[str]
    thumbnail_url: Optional[str]
    language: str
    word_count: Optional[int]
    difficulty: str
    quiz_available: bool
    categories: List[CategorySchema] = []

    model_config = {"from_attributes": True}


class ArticleSearchResult(BaseModel):
    wiki_page_id: int
    title: str
    description: Optional[str]
    thumbnail_url: Optional[str]
    url: str


class ArticleListResponse(BaseModel):
    articles: List[ArticleSchema]
    total: int


class DailyChallengeResponse(BaseModel):
    date: datetime
    article: ArticleSchema
    completed: bool = False

    model_config = {"from_attributes": True}
