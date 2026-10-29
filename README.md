# course-catalog-db

PostgreSQL schema for the course catalog (Lab 6, "Advanced Web Technologies").

## How to run

PostgreSQL 16 or newer is required. Once, as the `postgres` superuser:

```sql
CREATE ROLE catalog_app LOGIN PASSWORD 'change-me';
CREATE DATABASE course_catalog OWNER catalog_app;
```

Then, from the project folder (it stops at the first error):

```bash
psql -h localhost -U catalog_app -d course_catalog -v ON_ERROR_STOP=1 -f schema.sql
psql -h localhost -U catalog_app -d course_catalog -v ON_ERROR_STOP=1 -f seed.sql
psql -h localhost -U catalog_app -d course_catalog -v ON_ERROR_STOP=1 -f queries.sql
```

The password `change-me` is for teaching; real projects keep passwords out of git.

## Constraint violation log

Commands were run with `\set VERBOSITY verbose`.

| # | What we violate | SQLSTATE | Constraint | API response |
|---|-----------------|----------|------------|--------------|
| 1 | NULL in courses.title | 23502 | `title` (COLUMN NAME, NOT NULL has no constraint name) | 422 Unprocessable Entity (500 if Pydantic let it through due to a bug) |
| 2 | courses.credits = 0 | 23514 | `courses_credits_check` | 422 Unprocessable Entity |
| 3 | courses.likes = -1 | 23514 | `courses_likes_check` | 500 Internal Server Error (only server code increments likes via `likes + 1`; negative value indicates application bug) |
| 4 | a one-letter student name | 23514 | `students_name_check` | 422 Unprocessable Entity |
| 5 | a duplicate student email | 23505 | `students_email_key` | 409 Conflict |
| 6 | a duplicate course id | 23505 | `courses_pkey` | 409 Conflict |
| 7 | a repeated enrollment in a course | 23505 | `enrollments_course_id_student_id_key` | 409 Conflict |
| 8 | enrolling in a nonexistent course | 23503 | `enrollments_course_id_fkey` | 404 Not Found (course not found) |
| 9 | enrolling a nonexistent student | 23503 | `enrollments_student_id_fkey` | 404 Not Found (student not found) |
| 10 | deleting a course that has enrollments | 23503 | `enrollments_course_id_fkey` | 409 Conflict: a course with enrollments can't be deleted |
| 11 | deleting a student (cascade delete) | — (no error) | `enrollments_student_id_fkey` (ON DELETE CASCADE) | 204 No Content / 200 OK: student deleted; enrollments deleted by cascade, 6 → 3, 6 after ROLLBACK |

### Why check in the database if there is already a check in Pydantic?

Pydantic performs input validation at the FastAPI boundary, rejecting invalid payloads early with friendly client messages. However, the database is the single source of truth and final line of defense. The API is rarely the only client touching the database: direct SQL scripts, data migrations (Alembic), administrative consoles, and background workers can all write to PostgreSQL directly. Enforcing constraints at the database level guarantees data integrity regardless of how or by whom data is inserted.
