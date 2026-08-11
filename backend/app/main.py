from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from app.core.config import settings
from app.routers import auth, articles, games, profile, leaderboard, daily

limiter = Limiter(key_func=get_remote_address)

app = FastAPI(
    title="Wiki Roulette API",
    description="Backend for Wiki Roulette — a gamified Wikipedia exploration app",
    version="1.2.0",
    docs_url="/docs" if settings.ENVIRONMENT == "development" else None,
    redoc_url=None,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    """Never expose stack traces to clients."""
    return JSONResponse(
        status_code=500,
        content={"detail": "Something went wrong on our end. Please try again."},
    )


# Include routers
app.include_router(auth.router)
app.include_router(articles.router)
app.include_router(games.router)
app.include_router(profile.router)
app.include_router(leaderboard.router)
app.include_router(daily.router)


@app.get("/health")
async def health():
    return {"status": "ok", "service": "wiki-roulette-api"}
