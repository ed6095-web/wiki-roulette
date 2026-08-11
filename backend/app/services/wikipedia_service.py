"""
WikipediaService — All communication with Wikimedia APIs.

Uses two official APIs:
1. MediaWiki Action API (random articles, namespace=0)
2. Wikipedia REST Summary API (article details, thumbnail, extract)

Never exposes raw Wikipedia responses to Flutter — normalises everything.
"""

import httpx
from dataclasses import dataclass
from typing import Optional, List
from app.core.config import settings


@dataclass
class WikiArticle:
    wiki_page_id: int
    title: str
    slug: str
    url: str
    description: Optional[str]
    extract: Optional[str]
    thumbnail_url: Optional[str]
    language: str = "en"
    word_count: Optional[int] = None


@dataclass
class WikiSearchResult:
    title: str
    description: Optional[str]
    thumbnail_url: Optional[str]
    url: str


class WikipediaService:
    def __init__(self):
        self.headers = {
            "User-Agent": settings.WIKIPEDIA_USER_AGENT,
            "Accept": "application/json",
        }
        self.mediawiki_url = settings.MEDIAWIKI_API_URL
        self.rest_url = settings.WIKIPEDIA_REST_URL

    async def get_random_article(self, max_attempts: int = 5) -> Optional[WikiArticle]:
        """
        Fetches a random main-namespace Wikipedia article.
        Retries up to max_attempts times to get a valid article with an extract.
        Uses rnnamespace=0 to restrict to main articles only.
        """
        async with httpx.AsyncClient(timeout=15.0) as client:
            for _ in range(max_attempts):
                # Step 1: Get random article title from MediaWiki API (namespace 0 = main articles)
                params = {
                    "action": "query",
                    "list": "random",
                    "rnnamespace": "0",
                    "rnlimit": "1",
                    "format": "json",
                }
                try:
                    resp = await client.get(
                        self.mediawiki_url, params=params, headers=self.headers
                    )
                    resp.raise_for_status()
                    data = resp.json()
                    random_pages = data.get("query", {}).get("random", [])
                    if not random_pages:
                        continue
                    title = random_pages[0]["title"]
                except Exception:
                    continue

                # Step 2: Fetch article summary via REST API
                article = await self._fetch_summary(client, title)
                if article and article.extract:
                    return article

        return None

    async def get_article_by_title(self, title: str) -> Optional[WikiArticle]:
        async with httpx.AsyncClient(timeout=15.0) as client:
            return await self._fetch_summary(client, title)

    async def search_articles(self, query: str, limit: int = 10) -> List[WikiSearchResult]:
        """
        Uses Wikipedia OpenSearch API for autocomplete-style search.
        Returns namespace=0 results only.
        """
        params = {
            "action": "opensearch",
            "search": query,
            "limit": str(limit),
            "namespace": "0",
            "format": "json",
        }
        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                resp = await client.get(
                    self.mediawiki_url, params=params, headers=self.headers
                )
                resp.raise_for_status()
                data = resp.json()
                # OpenSearch returns [query, [titles], [descriptions], [urls]]
                titles = data[1] if len(data) > 1 else []
                descriptions = data[2] if len(data) > 2 else []
                urls = data[3] if len(data) > 3 else []

                results = []
                for i, title in enumerate(titles):
                    results.append(WikiSearchResult(
                        title=title,
                        description=descriptions[i] if i < len(descriptions) else None,
                        thumbnail_url=None,  # OpenSearch doesn't return thumbnails
                        url=urls[i] if i < len(urls) else f"https://en.wikipedia.org/wiki/{title.replace(' ', '_')}",
                    ))
                return results
            except Exception:
                return []

    async def get_related_articles(self, title: str, limit: int = 5) -> List[WikiSearchResult]:
        """
        Fetches articles linked from the given article (first {limit} main-namespace links).
        """
        params = {
            "action": "query",
            "titles": title,
            "prop": "links",
            "pllimit": str(limit * 3),  # over-fetch; filter to main ns
            "plnamespace": "0",
            "format": "json",
        }
        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                resp = await client.get(
                    self.mediawiki_url, params=params, headers=self.headers
                )
                resp.raise_for_status()
                data = resp.json()
                pages = data.get("query", {}).get("pages", {})
                links = []
                for page in pages.values():
                    for link in page.get("links", [])[:limit]:
                        links.append(WikiSearchResult(
                            title=link["title"],
                            description=None,
                            thumbnail_url=None,
                            url=f"https://en.wikipedia.org/wiki/{link['title'].replace(' ', '_')}",
                        ))
                return links[:limit]
            except Exception:
                return []

    async def _fetch_summary(self, client: httpx.AsyncClient, title: str) -> Optional[WikiArticle]:
        """
        Fetches article summary from Wikipedia REST API.
        Returns None if the article has no extract or is a redirect/disambiguation.
        """
        encoded_title = title.replace(" ", "_")
        url = f"{self.rest_url}/page/summary/{encoded_title}"
        try:
            resp = await client.get(url, headers=self.headers)
            if resp.status_code == 404:
                return None
            resp.raise_for_status()
            data = resp.json()

            # Skip redirects and disambiguation pages
            page_type = data.get("type", "")
            if page_type in ("disambiguation", "no-extract"):
                return None

            extract = data.get("extract", "").strip()
            if not extract or len(extract) < 100:
                return None

            thumbnail = data.get("thumbnail", {})
            thumbnail_url = thumbnail.get("source") if thumbnail else None

            content_urls = data.get("content_urls", {})
            page_url = content_urls.get("desktop", {}).get("page", f"https://en.wikipedia.org/wiki/{encoded_title}")

            word_count = len(extract.split()) if extract else None

            return WikiArticle(
                wiki_page_id=data.get("pageid", 0),
                title=data.get("title", title),
                slug=encoded_title,
                url=page_url,
                description=data.get("description"),
                extract=extract,
                thumbnail_url=thumbnail_url,
                language=data.get("lang", "en"),
                word_count=word_count,
            )
        except Exception:
            return None


# Singleton instance
wikipedia_service = WikipediaService()
