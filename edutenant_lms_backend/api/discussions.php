<?php
/**
 * Discussion Forum API
 */
date_default_timezone_set('UTC');

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Request.php';

$db = Database::getInstance()->getConnection();
$method = Request::getMethod();
$path = Request::getPath();
$institutionCode = Request::requireInstitutionCode();

// Route: GET /discussions
if ($method === 'GET' && $path === 'discussions.php') {
    try {
        $params = Request::getQueryParams();
$query = "
SELECT 
  dp.id,
  dp.post_id,
  dp.title,
  dp.content,
  dp.created_date,
  dp.author_id,
  dp.course_id,
  dp.category,
  dp.is_pinned,
  dp.is_locked,

  u.name AS author_name,
  c.title AS course_title,

  COUNT(dr.id) AS replies_count

FROM discussion_posts dp

LEFT JOIN users u 
  ON dp.author_id = u.id 

LEFT JOIN courses c 
  ON dp.course_id = c.id 

LEFT JOIN discussion_replies dr 
  ON dr.post_id = dp.id 
  AND dr.institution_code = dp.institution_code

WHERE dp.institution_code = ?
";
        $params_bind = [$institutionCode];
        
        // Filter by course
        if (isset($params['course_id'])) {
            $query .= " AND dp.course_id = ?";
            $params_bind[] = $params['course_id'];
        }
        
        // Filter by category
        if (isset($params['category'])) {
            $query .= " AND dp.category = ?";
            $params_bind[] = $params['category'];
        }
        
        $query .= " GROUP BY dp.id ";
        // Show pinned first
        $query .= " ORDER BY dp.is_pinned DESC, dp.created_date DESC";
        
        // Pagination
        $limit = isset($params['limit']) ? (int)$params['limit'] : 20;
        $offset = isset($params['offset']) ? (int)$params['offset'] : 0;
        $query .= " LIMIT ? OFFSET ?";
        $params_bind[] = $limit;
        $params_bind[] = $offset;
        
        $stmt = $db->prepare($query);
        $stmt->execute($params_bind);
        $posts = $stmt->fetchAll();
        
        Response::success($posts);
        
    } catch (PDOException $e) {
        Response::error('Failed to fetch discussions: ' . $e->getMessage(), 500);
    }
}

// Route: POST /discussions
if ($method === 'POST' && $path === 'discussions.php') {
    try {
        $data = Request::getBody();
        Request::validateRequired($data, ['title', 'content', 'author_id']);
        
        $postId = 'POST_' . time() . '_' . rand(1000, 9999);
        
        $stmt = $db->prepare("
            INSERT INTO discussion_posts (institution_code, post_id, course_id, author_id, title, content, 
                                         category, tags, is_pinned, is_locked)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $institutionCode,
            $postId,
            $data['course_id'] ?? null,
            $data['author_id'],
            $data['title'],
            $data['content'],
            $data['category'] ?? null,
            $data['tags'] ?? null,
            $data['is_pinned'] ?? false,
            $data['is_locked'] ?? false
        ]);
        
        $newPostId = $db->lastInsertId();
        
        // Get created post
        $stmt = $db->prepare("
           SELECT 
  dp.*,
  DATE_FORMAT(dp.created_date, '%Y-%m-%dT%H:%i:%sZ') AS created_date,
  u.name AS author_name,
  c.title AS course_title

        ");
        $stmt->execute([$newPostId]);
        // $post = $stmt->fetch();
        $post = $stmt->fetch(PDO::FETCH_ASSOC);
        
        Response::success($post, 'Post created successfully', 201);
        
    } catch (PDOException $e) {
        Response::error('Failed to create post: ' . $e->getMessage(), 500);
    }
}

// Route: GET /discussions/{id}/replies
if ($method === 'GET' && preg_match('/^discussions.php\/(\d+)\/replies$/', $path, $matches)) {
    try {
        $postId = $matches[1];
        $stmt = $db->prepare("
            SELECT dr.*, u.name as author_name 
            FROM discussion_replies dr 
            LEFT JOIN users u ON dr.author_id = u.id 
            WHERE dr.post_id = ? AND dr.institution_code = ?
            ORDER BY dr.created_date ASC
        ");
        $stmt->execute([$postId, $institutionCode]);
        $replies = $stmt->fetchAll();
        
        Response::success($replies);
        
    } catch (PDOException $e) {
        Response::error('Failed to fetch replies: ' . $e->getMessage(), 500);
    }
}

// Route: POST /discussions/{id}/replies
if ($method === 'POST' && preg_match('/^discussions.php\/(\d+)\/replies$/', $path, $matches)) {
    try {
        $postId = $matches[1];
        $data = Request::getBody();
        Request::validateRequired($data, ['content', 'author_id']);
        
        $replyId = 'REPLY_' . time() . '_' . rand(1000, 9999);
        
        $db->beginTransaction();
        
        // Insert reply
        $stmt = $db->prepare("
            INSERT INTO discussion_replies (institution_code, reply_id, post_id, author_id, content, parent_reply_id)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $institutionCode,
            $replyId,
            $postId,
            $data['author_id'],
            $data['content'],
            $data['parent_reply_id'] ?? null
        ]);
        
        // Update replies count
        // $stmt = $db->prepare("
        //     UPDATE discussion_posts 
        //     SET replies_count = replies_count + 1 
        //     WHERE id = ? AND institution_code = ?
        // ");
        // $stmt->execute([$postId, $institutionCode]);
        
        $db->commit();
        
        // Get created reply
        $stmt = $db->prepare("
            SELECT dr.*, u.name as author_name 
            FROM discussion_replies dr 
            LEFT JOIN users u ON dr.author_id = u.id 
            WHERE dr.reply_id = ?
        ");
        $stmt->execute([$replyId]);
        $reply = $stmt->fetch();
        
        Response::success($reply, 'Reply created successfully', 201);
        
    } catch (PDOException $e) {
        $db->rollBack();
        Response::error('Failed to create reply: ' . $e->getMessage(), 500);
    }
}

// Route: PUT /discussions/{id}
if ($method === 'PUT' && preg_match('/^discussions.php\/(\d+)$/', $path, $matches)) {
    try {
        $postId = $matches[1];
        $data = Request::getBody();

        Request::validateRequired($data, ['title', 'content']);

        $stmt = $db->prepare("
            UPDATE discussion_posts 
            SET title = ?, content = ?, category = ?, last_modified = NOW()
            WHERE id = ? AND institution_code = ?
        ");

        $stmt->execute([
            $data['title'],
            $data['content'],
            $data['category'] ?? null,
            $postId,
            $institutionCode
        ]);

        // Return updated post
        $stmt = $db->prepare("
            SELECT dp.*, u.name as author_name
            FROM discussion_posts dp
            LEFT JOIN users u ON dp.author_id = u.id
            WHERE dp.id = ?
        ");

        $stmt->execute([$postId]);
        $post = $stmt->fetch();

        Response::success($post, 'Post updated successfully');

    } catch (PDOException $e) {
        Response::error('Failed to update post: ' . $e->getMessage(), 500);
    }
}

// Route: DELETE /discussions/{id}
if ($method === 'DELETE' && preg_match('/^discussions.php\/(\d+)$/', $path, $matches)) {
    try {
        $postId = $matches[1];

        $stmt = $db->prepare("
            DELETE FROM discussion_posts
            WHERE id = ? AND institution_code = ?
        ");

        $stmt->execute([$postId, $institutionCode]);

        Response::success(null, 'Post deleted successfully');

    } catch (PDOException $e) {
        Response::error('Failed to delete post: ' . $e->getMessage(), 500);
    }
}

Response::notFound('Endpoint not found');

