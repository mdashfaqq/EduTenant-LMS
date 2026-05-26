import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database Helper for EduTenant LMS
/// Manages SQLite database with multi-tenant support using Institution Code
/// All tables include institution_code for data isolation
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('edutenant_lms.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Institution Table
    await db.execute('''
      CREATE TABLE institutions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        logo TEXT,
        address TEXT,
        contact_email TEXT,
        contact_phone TEXT,
        subscription_status TEXT DEFAULT 'active',
        subscription_expiry TEXT,
        user_count INTEGER DEFAULT 0,
        user_limit INTEGER DEFAULT 1000,
        academic_year TEXT,
        primary_color TEXT,
        modules_courses INTEGER DEFAULT 1,
        modules_assignments INTEGER DEFAULT 1,
        modules_grades INTEGER DEFAULT 1,
        modules_attendance INTEGER DEFAULT 1,
        modules_fees INTEGER DEFAULT 1,
        modules_discussions INTEGER DEFAULT 1,
        modules_exams INTEGER DEFAULT 1,
        created_date TEXT,
        last_modified TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT
      )
    ''');

    // Users Table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT NOT NULL,
        department TEXT,
        status TEXT DEFAULT 'active',
        avatar TEXT,
        phone TEXT,
        date_of_birth TEXT,
        address TEXT,
        last_activity TEXT,
        join_date TEXT,
        courses_teaching INTEGER DEFAULT 0,
        students_managed INTEGER DEFAULT 0,
        courses_enrolled INTEGER DEFAULT 0,
        gpa REAL,
        parent_id INTEGER,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        UNIQUE(institution_code, user_id)
      )
    ''');

    // Courses Table
    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        course_id TEXT NOT NULL,
        title TEXT NOT NULL,
        code TEXT NOT NULL,
        description TEXT,
        instructor_id INTEGER,
        instructor_name TEXT,
        category TEXT,
        level TEXT,
        credits INTEGER,
        duration TEXT,
        start_date TEXT,
        end_date TEXT,
        schedule TEXT,
        room TEXT,
        capacity INTEGER,
        enrolled_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'active',
        thumbnail TEXT,
        syllabus_url TEXT,
        created_date TEXT,
        last_modified TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (instructor_id) REFERENCES users(id),
        UNIQUE(institution_code, course_id)
      )
    ''');

    // Course Enrollments Table
    await db.execute('''
      CREATE TABLE course_enrollments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        course_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        enrollment_date TEXT,
        status TEXT DEFAULT 'active',
        progress REAL DEFAULT 0.0,
        grade TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (course_id) REFERENCES courses(id),
        FOREIGN KEY (student_id) REFERENCES users(id),
        UNIQUE(institution_code, course_id, student_id)
      )
    ''');

    // Classes/Sessions Table
    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        class_id TEXT NOT NULL,
        course_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        class_date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        room TEXT,
        type TEXT,
        status TEXT DEFAULT 'scheduled',
        instructor_id INTEGER,
        created_date TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (course_id) REFERENCES courses(id),
        FOREIGN KEY (instructor_id) REFERENCES users(id),
        UNIQUE(institution_code, class_id)
      )
    ''');

    // Attendance Table
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        class_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        marked_at TEXT,
        marked_by INTEGER,
        notes TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (class_id) REFERENCES classes(id),
        FOREIGN KEY (student_id) REFERENCES users(id),
        FOREIGN KEY (marked_by) REFERENCES users(id),
        UNIQUE(institution_code, class_id, student_id)
      )
    ''');

    // Assignments Table
    await db.execute('''
      CREATE TABLE assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        assignment_id TEXT NOT NULL,
        course_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT,
        total_points INTEGER,
        due_date TEXT,
        submission_type TEXT,
        status TEXT DEFAULT 'active',
        created_by INTEGER,
        created_date TEXT,
        last_modified TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (course_id) REFERENCES courses(id),
        FOREIGN KEY (created_by) REFERENCES users(id),
        UNIQUE(institution_code, assignment_id)
      )
    ''');

    // Assignment Submissions Table
    await db.execute('''
      CREATE TABLE assignment_submissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        assignment_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        submission_text TEXT,
        file_url TEXT,
        submitted_at TEXT,
        status TEXT DEFAULT 'pending',
        grade REAL,
        feedback TEXT,
        graded_by INTEGER,
        graded_at TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (assignment_id) REFERENCES assignments(id),
        FOREIGN KEY (student_id) REFERENCES users(id),
        FOREIGN KEY (graded_by) REFERENCES users(id),
        UNIQUE(institution_code, assignment_id, student_id)
      )
    ''');

    // Exams Table
    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        exam_id TEXT NOT NULL,
        course_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        exam_date TEXT,
        start_time TEXT,
        end_time TEXT,
        duration INTEGER,
        total_marks INTEGER,
        passing_marks INTEGER,
        exam_type TEXT,
        room TEXT,
        status TEXT DEFAULT 'scheduled',
        created_by INTEGER,
        created_date TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (course_id) REFERENCES courses(id),
        FOREIGN KEY (created_by) REFERENCES users(id),
        UNIQUE(institution_code, exam_id)
      )
    ''');

    // Exam Results Table
    await db.execute('''
      CREATE TABLE exam_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        exam_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        marks_obtained REAL,
        grade TEXT,
        percentage REAL,
        status TEXT DEFAULT 'absent',
        remarks TEXT,
        entered_by INTEGER,
        entered_at TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (exam_id) REFERENCES exams(id),
        FOREIGN KEY (student_id) REFERENCES users(id),
        FOREIGN KEY (entered_by) REFERENCES users(id),
        UNIQUE(institution_code, exam_id, student_id)
      )
    ''');

    // Fees Structure Table
    await db.execute('''
      CREATE TABLE fees_structure (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        fee_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        fee_type TEXT,
        frequency TEXT,
        applicable_to TEXT,
        due_date TEXT,
        academic_year TEXT,
        status TEXT DEFAULT 'active',
        created_date TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        UNIQUE(institution_code, fee_id)
      )
    ''');

    // Student Fees Table
    await db.execute('''
      CREATE TABLE student_fees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        student_id INTEGER NOT NULL,
        fee_id INTEGER NOT NULL,
        amount_due REAL NOT NULL,
        amount_paid REAL DEFAULT 0.0,
        amount_pending REAL,
        due_date TEXT,
        status TEXT DEFAULT 'pending',
        last_payment_date TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (student_id) REFERENCES users(id),
        FOREIGN KEY (fee_id) REFERENCES fees_structure(id),
        UNIQUE(institution_code, student_id, fee_id)
      )
    ''');

    // Fee Payments Table
    await db.execute('''
      CREATE TABLE fee_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        payment_id TEXT NOT NULL,
        student_id INTEGER NOT NULL,
        student_fee_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT,
        transaction_id TEXT,
        payment_date TEXT,
        status TEXT DEFAULT 'completed',
        receipt_url TEXT,
        processed_by INTEGER,
        notes TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (student_id) REFERENCES users(id),
        FOREIGN KEY (student_fee_id) REFERENCES student_fees(id),
        FOREIGN KEY (processed_by) REFERENCES users(id),
        UNIQUE(institution_code, payment_id)
      )
    ''');

    // Learning Content Table
    await db.execute('''
      CREATE TABLE learning_content (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        content_id TEXT NOT NULL,
        course_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        content_type TEXT,
        content_url TEXT,
        file_size INTEGER,
        duration INTEGER,
        order_index INTEGER,
        is_mandatory INTEGER DEFAULT 1,
        created_by INTEGER,
        created_date TEXT,
        last_modified TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (course_id) REFERENCES courses(id),
        FOREIGN KEY (created_by) REFERENCES users(id),
        UNIQUE(institution_code, content_id)
      )
    ''');

    // Content Progress Table
    await db.execute('''
      CREATE TABLE content_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        content_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        progress REAL DEFAULT 0.0,
        status TEXT DEFAULT 'not_started',
        started_at TEXT,
        completed_at TEXT,
        last_accessed TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (content_id) REFERENCES learning_content(id),
        FOREIGN KEY (student_id) REFERENCES users(id),
        UNIQUE(institution_code, content_id, student_id)
      )
    ''');

    // Discussion Forum Posts Table
    await db.execute('''
      CREATE TABLE discussion_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        post_id TEXT NOT NULL,
        course_id INTEGER,
        author_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT,
        tags TEXT,
        is_pinned INTEGER DEFAULT 0,
        is_locked INTEGER DEFAULT 0,
        views_count INTEGER DEFAULT 0,
        likes_count INTEGER DEFAULT 0,
        replies_count INTEGER DEFAULT 0,
        created_date TEXT,
        last_modified TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (course_id) REFERENCES courses(id),
        FOREIGN KEY (author_id) REFERENCES users(id),
        UNIQUE(institution_code, post_id)
      )
    ''');

    // Discussion Replies Table
    await db.execute('''
      CREATE TABLE discussion_replies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        reply_id TEXT NOT NULL,
        post_id INTEGER NOT NULL,
        author_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        parent_reply_id INTEGER,
        likes_count INTEGER DEFAULT 0,
        is_solution INTEGER DEFAULT 0,
        created_date TEXT,
        last_modified TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (post_id) REFERENCES discussion_posts(id),
        FOREIGN KEY (author_id) REFERENCES users(id),
        FOREIGN KEY (parent_reply_id) REFERENCES discussion_replies(id),
        UNIQUE(institution_code, reply_id)
      )
    ''');

    // Notifications Table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        notification_id TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT,
        reference_id TEXT,
        reference_type TEXT,
        is_read INTEGER DEFAULT 0,
        created_date TEXT,
        read_at TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (user_id) REFERENCES users(id),
        UNIQUE(institution_code, notification_id)
      )
    ''');

    // Announcements Table
    await db.execute('''
      CREATE TABLE announcements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        announcement_id TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        target_audience TEXT,
        priority TEXT DEFAULT 'normal',
        is_active INTEGER DEFAULT 1,
        created_by INTEGER,
        created_date TEXT,
        expiry_date TEXT,
        sync_status INTEGER DEFAULT 0,
        last_sync TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        FOREIGN KEY (created_by) REFERENCES users(id),
        UNIQUE(institution_code, announcement_id)
      )
    ''');

    // Reports/Analytics Cache Table
    await db.execute('''
      CREATE TABLE analytics_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        institution_code TEXT NOT NULL,
        report_type TEXT NOT NULL,
        report_data TEXT NOT NULL,
        generated_at TEXT,
        valid_until TEXT,
        FOREIGN KEY (institution_code) REFERENCES institutions(institution_code),
        UNIQUE(institution_code, report_type)
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
      'CREATE INDEX idx_users_institution ON users(institution_code)',
    );
    await db.execute(
      'CREATE INDEX idx_courses_institution ON courses(institution_code)',
    );
    await db.execute(
      'CREATE INDEX idx_attendance_institution ON attendance(institution_code)',
    );
    await db.execute(
      'CREATE INDEX idx_assignments_institution ON assignments(institution_code)',
    );
    await db.execute(
      'CREATE INDEX idx_exams_institution ON exams(institution_code)',
    );
    await db.execute(
      'CREATE INDEX idx_fees_institution ON student_fees(institution_code)',
    );
    await db.execute(
      'CREATE INDEX idx_discussions_institution ON discussion_posts(institution_code)',
    );
  }

  /// Close database connection
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }

  /// Clear all data for a specific institution (for testing/logout)
  Future<void> clearInstitutionData(String institutionCode) async {
    final db = await instance.database;
    final tables = [
      'users',
      'courses',
      'course_enrollments',
      'classes',
      'attendance',
      'assignments',
      'assignment_submissions',
      'exams',
      'exam_results',
      'fees_structure',
      'student_fees',
      'fee_payments',
      'learning_content',
      'content_progress',
      'discussion_posts',
      'discussion_replies',
      'notifications',
      'announcements',
      'analytics_cache',
    ];

    for (String table in tables) {
      await db.delete(
        table,
        where: 'institution_code = ?',
        whereArgs: [institutionCode],
      );
    }
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats(String institutionCode) async {
    final db = await instance.database;
    final stats = <String, int>{};

    final tables = [
      'users',
      'courses',
      'attendance',
      'assignments',
      'exams',
      'discussion_posts',
    ];

    for (String table in tables) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $table WHERE institution_code = ?',
        [institutionCode],
      );
      stats[table] = Sqflite.firstIntValue(result) ?? 0;
    }

    return stats;
  }
}
