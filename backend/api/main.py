import os
from typing import List, Optional
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime

app = FastAPI(title="UniFlow API", description="Server API for UniFlow campus events aggregation")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Reuse PG configuration from the store or define it via ENV
PG_CONFIG = {
    "host": os.getenv("PG_HOST", "127.0.0.1"),
    "port": int(os.getenv("PG_PORT", 5432)),
    "user": os.getenv("PG_USER", "test"),
    "password": os.getenv("PG_PASSWORD", "passwd"),
    "dbname": os.getenv("PG_DBNAME", "uniflow")
}

def get_db_connection():
    try:
        conn = psycopg2.connect(**PG_CONFIG)
        return conn
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection failed: {e}")

# Models for the API response
class EventTimeline(BaseModel):
    time: str
    event: str

class EventSummary(BaseModel):
    uuid: str
    channel: str
    title: str
    genre: str
    importance: int
    source: Optional[str]
    review: Optional[str]
    link: Optional[str]
    keywords: Optional[str]
    timeline: Optional[List[dict]]
    attachment: Optional[List[dict]]
    fetch_time: datetime


class EventDetail(EventSummary):
    link: Optional[str]
    timeline: Optional[List[dict]]
    original_text: Optional[str]

@app.get("/api/events", response_model=dict)
def get_events(
    page: int = Query(1, ge=1),
    limit: int = Query(30, ge=1, le=100),
    genre: Optional[str] = None,
    channel: Optional[str] = None,
    days_ago: Optional[int] = Query(None, description="Filter events within the last N days"),
    sort_by: str = Query("trending", pattern="^(importance|importance_time|trending|timeline_date)$")
):
    """
    Get a paginated list of events.
    Supports filtering by genre and channel.
    """
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        query = "SELECT uuid, channel, title, genre, importance, source, review, link, keywords, timeline, attachment, fetch_time FROM events"
        count_query = "SELECT COUNT(*) FROM events"
        
        conditions = []
        params = []
        
        if genre:
            conditions.append("genre = %s")
            params.append(genre)
            
        if channel:
            conditions.append("channel = %s")
            params.append(channel)
            
        if days_ago is not None:
            conditions.append("fetch_time >= NOW() - CAST(%s AS INTERVAL)")
            params.append(f"{days_ago} days")
            
        if conditions:
            where_clause = " WHERE " + " AND ".join(conditions)
            query += where_clause
            count_query += where_clause
            
        # Define the base calculated time SQL: Extract last timeline date if available, fallback to fetch_time
        # Use a subquery to extract the first value of the last object in the timeline array
        calculated_date_sql = """
            (CASE 
                WHEN jsonb_array_length(timeline) > 0 
                AND timeline->-1 IS NOT NULL
                AND (SELECT value FROM jsonb_each_text(timeline->-1) LIMIT 1) IS NOT NULL
                THEN (SELECT value FROM jsonb_each_text(timeline->-1) LIMIT 1)::timestamp 
                ELSE fetch_time 
            END)
        """

        # Determine sorting
        if sort_by == "importance_time":
            order_clause = f" ORDER BY importance DESC, {calculated_date_sql} DESC"
        elif sort_by == "trending":
            # Time-decay algorithm (Hacker News ranking style): Score = Importance / (Hours_ago + 2)^1.5
            # We use greatest() to avoid negative hours if calculated time is slightly in the future (due to timezone glitches etc)
            order_clause = f" ORDER BY (importance / POWER(GREATEST(EXTRACT(EPOCH FROM (NOW() - {calculated_date_sql}))/3600.0, 0.0) + 2.0, 1.5)) DESC"
        elif sort_by == "timeline_date":
            # Sort by the latest valid timeline date (the last item in the array to represent the latest deadline/time)
            order_clause = f" ORDER BY {calculated_date_sql} DESC, importance DESC"
        else: # importance
            order_clause = f" ORDER BY {sort_by} DESC"
        query += order_clause
        
        # Pagination
        offset = (page - 1) * limit
        query += " LIMIT %s OFFSET %s"
        params.extend([limit, offset])
        
        # Execute Count
        cur.execute(count_query, tuple(params[:-2]) if params[:-2] else None)
        total_items = cur.fetchone()['count']
        
        # Execute query
        cur.execute(query, tuple(params))
        rows = cur.fetchall()
        
        return {
            "success": True,
            "data": {
                "items": rows,
                "total": total_items,
                "page": page,
                "limit": limit,
                "total_pages": (total_items + limit - 1) // limit
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
        conn.close()


@app.get("/api/events/{event_id}", response_model=dict)
def get_event_detail(event_id: str):
    """
    Get the full details of a specific event by UUID.
    """
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        cur.execute("SELECT * FROM events WHERE uuid = %s", (event_id,))
        row = cur.fetchone()
        
        if not row:
            raise HTTPException(status_code=404, detail="Event not found")
            
        return {
            "success": True,
            "data": row
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
        conn.close()
