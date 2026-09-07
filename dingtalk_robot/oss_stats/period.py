"""Resolve calendar-month and custom reporting periods."""

from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import date, datetime, time, timezone
from typing import Optional
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


MONTH_PATTERN = re.compile(r"^(\d{4})-(0[1-9]|1[0-2])$")


@dataclass(frozen=True)
class ReportingPeriod:
    start: datetime
    end: datetime
    timezone_name: str
    label: str


def _next_month(value: datetime) -> datetime:
    if value.month == 12:
        return value.replace(year=value.year + 1, month=1)
    return value.replace(month=value.month + 1)


def _previous_month(value: datetime) -> datetime:
    if value.month == 1:
        return value.replace(year=value.year - 1, month=12)
    return value.replace(month=value.month - 1)


def _parse_datetime(value: str, zone: ZoneInfo) -> datetime:
    try:
        if "T" not in value and " " not in value:
            parsed = datetime.combine(date.fromisoformat(value), time.min)
        else:
            parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ValueError(f"Invalid ISO date or datetime: {value}") from exc
    return parsed.replace(tzinfo=zone) if parsed.tzinfo is None else parsed


def resolve_period(
    timezone_name: str,
    month: Optional[str] = None,
    start: Optional[str] = None,
    end: Optional[str] = None,
    now: Optional[datetime] = None,
) -> ReportingPeriod:
    try:
        zone = ZoneInfo(timezone_name)
    except ZoneInfoNotFoundError as exc:
        raise ValueError(f"Unknown timezone: {timezone_name}") from exc

    if month and (start or end):
        raise ValueError("--month cannot be combined with --start or --end")
    if bool(start) != bool(end):
        raise ValueError("--start and --end must be specified together")

    if month:
        match = MONTH_PATTERN.fullmatch(month)
        if not match:
            raise ValueError("--month must use YYYY-MM format")
        local_start = datetime(int(match.group(1)), int(match.group(2)), 1, tzinfo=zone)
        local_end = _next_month(local_start)
        label = month
    elif start and end:
        local_start = _parse_datetime(start, zone).astimezone(zone)
        local_end = _parse_datetime(end, zone).astimezone(zone)
        label = f"{local_start:%Y%m%dT%H%M}-{local_end:%Y%m%dT%H%M}"
    else:
        current = (now or datetime.now(timezone.utc)).astimezone(zone)
        local_end = current.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        local_start = _previous_month(local_end)
        label = f"{local_start:%Y-%m}"

    if local_start >= local_end:
        raise ValueError("Reporting period start must be before end")
    return ReportingPeriod(
        start=local_start.astimezone(timezone.utc),
        end=local_end.astimezone(timezone.utc),
        timezone_name=timezone_name,
        label=label,
    )
