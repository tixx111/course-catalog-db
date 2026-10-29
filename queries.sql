-- queries.sql: queries for the API routes (values are filled in as examples)
-- Queries that change data are wrapped in a transaction that rolls back,
-- so the file can be run as many times as you like.

-- 1. GET /courses?is_elective=false&sort=popular&page=1&page_size=3
-- TODO 1: id, title, credits, likes; non-elective courses only;
-- most popular first (ties on likes — by id);
-- LIMIT and OFFSET for page 1
SELECT id, title, credits, likes
FROM courses
WHERE is_elective = false
ORDER BY likes DESC, id
LIMIT 3 OFFSET 0;

-- 1b. the same, page 2: OFFSET = (2 - 1) * 3
-- TODO 2: the same query for page 2
SELECT id, title, credits, likes
FROM courses
WHERE is_elective = false
ORDER BY likes DESC, id
LIMIT 3 OFFSET 3;

-- 2. GET /courses/{course_id}
-- TODO 3: id, title, credits, is_elective, likes of the course 'api-design'
SELECT id, title, credits, is_elective, likes
FROM courses
WHERE id = 'api-design';

-- 2b. no such course: 0 rows, the API answers 404
-- TODO 4: the same query for 'no-such-course'
SELECT id, title, credits, is_elective, likes
FROM courses
WHERE id = 'no-such-course';

-- 3. POST /courses/{course_id}/like
BEGIN;
-- TODO 5: increase likes by 1 for 'api-design' with a single UPDATE
-- and return the id and the new value (RETURNING)
UPDATE courses
SET likes = likes + 1
WHERE id = 'api-design'
RETURNING id, likes;

-- 3b. no such course: UPDATE 0, the API answers 404
-- TODO 6: the same for 'no-such-course'
UPDATE courses
SET likes = likes + 1
WHERE id = 'no-such-course'
RETURNING id, likes;
ROLLBACK;

-- 4. POST /enrollments
BEGIN;
-- TODO 7: enroll the student with number 3 in the course 'web-security';
-- return id, course_id, and student_id (RETURNING)
INSERT INTO enrollments (course_id, student_id)
VALUES ('web-security', 3)
RETURNING id, course_id, student_id;
ROLLBACK;

-- 5. GET /enrollments
-- TODO 8: the enrollment number (id), the student's name (AS student), and
-- the course title (AS course); join the tables with JOIN;
-- order by the enrollment number
SELECT e.id, s.name AS student, c.title AS course
FROM enrollments e
JOIN students s ON s.id = e.student_id
JOIN courses c ON c.id = e.course_id
ORDER BY e.id;

-- 6. statistics: enrollments per course, including courses with none
-- TODO 9: LEFT JOIN enrollments to courses; GROUP BY the course;
-- the number of enrollments — count(e.id) AS enrolled;
-- courses with the most enrollments first (ties — by id)
SELECT c.id, count(e.id) AS enrolled
FROM courses c
LEFT JOIN enrollments e ON e.course_id = c.id
GROUP BY c.id
ORDER BY enrolled DESC, c.id;

-- 7. courses without enrollments (Bonus Task 4)
-- ids of the courses nobody is enrolled in, in alphabetical order
SELECT c.id
FROM courses c
LEFT JOIN enrollments e ON e.course_id = c.id
WHERE e.id IS NULL
ORDER BY c.id;

-- 8. students with more than one course (Bonus Task 4)
-- a student's name and the number of their courses (AS courses),
-- for students enrolled in more than one course; those with more courses first
SELECT s.name, count(*) AS courses
FROM students s
JOIN enrollments e ON e.student_id = s.id
GROUP BY s.id, s.name
HAVING count(*) > 1
ORDER BY courses DESC, s.name;

