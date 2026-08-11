"""Tests for XP calculation and scoring logic."""
import pytest
from app.services.xp_service import xp_for_level, level_for_xp, xp_progress, calculate_score


class TestXpLeveling:
    def test_level_1_requires_zero_xp(self):
        assert xp_for_level(1) == 0

    def test_level_2_requires_more_than_level_1(self):
        assert xp_for_level(2) > xp_for_level(1)

    def test_xp_is_monotonically_increasing(self):
        for lvl in range(1, 20):
            assert xp_for_level(lvl + 1) > xp_for_level(lvl)

    def test_zero_xp_is_level_1(self):
        assert level_for_xp(0) == 1

    def test_large_xp_gives_high_level(self):
        assert level_for_xp(100_000) > 10

    def test_roundtrip_level_xp(self):
        """Level computed from XP should match level for which that XP threshold was set."""
        for lvl in range(2, 15):
            threshold_xp = xp_for_level(lvl)
            assert level_for_xp(threshold_xp) == lvl

    def test_xp_progress_structure(self):
        progress = xp_progress(1000)
        assert "level" in progress
        assert "xp_in_level" in progress
        assert "progress_pct" in progress
        assert 0.0 <= progress["progress_pct"] <= 1.0


class TestScoring:
    def test_all_correct_full_quiz(self):
        result = calculate_score(5, 5, [2000, 4000, 6000, 8000, 2500])
        assert result["final_score"] > 0
        assert result["correct_answers"] == 5
        assert result["perfect_bonus"] == 200

    def test_zero_correct(self):
        result = calculate_score(0, 5, [5000, 5000, 5000, 5000, 5000])
        assert result["final_score"] == 0
        assert result["base_score"] == 0
        assert result["xp_earned"] == 0

    def test_speed_bonus_under_3s(self):
        result = calculate_score(1, 5, [2000])
        assert result["speed_bonus"] == 50

    def test_speed_bonus_under_5s(self):
        result = calculate_score(1, 5, [4000])
        assert result["speed_bonus"] == 30

    def test_speed_bonus_under_10s(self):
        result = calculate_score(1, 5, [8000])
        assert result["speed_bonus"] == 10

    def test_no_speed_bonus_over_10s(self):
        result = calculate_score(1, 5, [12000])
        assert result["speed_bonus"] == 0

    def test_daily_multiplier_applied(self):
        normal = calculate_score(3, 5, [5000, 5000, 5000])
        daily = calculate_score(3, 5, [5000, 5000, 5000], is_daily=True)
        assert daily["final_score"] == int(normal["final_score"] * 1.5)

    def test_no_perfect_bonus_for_partial(self):
        result = calculate_score(4, 5, [5000] * 4)
        assert result["perfect_bonus"] == 0
