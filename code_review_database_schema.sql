-- MedinovAI Code Review Database Schema
-- Stores all test cases, issues, and analysis results for future use

CREATE DATABASE IF NOT EXISTS medinovai_code_review;
USE medinovai_code_review;

-- Table to store code review sessions
CREATE TABLE IF NOT EXISTS review_sessions (
    session_id VARCHAR(36) PRIMARY KEY,
    session_name VARCHAR(255) NOT NULL,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP NULL,
    status ENUM('running', 'completed', 'failed') DEFAULT 'running',
    total_files INT DEFAULT 0,
    total_issues INT DEFAULT 0,
    total_tests INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Table to store analyzed files
CREATE TABLE IF NOT EXISTS analyzed_files (
    file_id VARCHAR(36) PRIMARY KEY,
    session_id VARCHAR(36),
    file_path VARCHAR(500) NOT NULL,
    file_type VARCHAR(50),
    file_size INT,
    checksum VARCHAR(64),
    analysis_status ENUM('pending', 'analyzing', 'completed', 'failed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES review_sessions(session_id) ON DELETE CASCADE,
    INDEX idx_session_file (session_id, file_path)
);

-- Table to store issues found during analysis
CREATE TABLE IF NOT EXISTS code_issues (
    issue_id VARCHAR(36) PRIMARY KEY,
    session_id VARCHAR(36),
    file_id VARCHAR(36),
    model_name VARCHAR(100) NOT NULL,
    iteration_number INT NOT NULL,
    category VARCHAR(100) NOT NULL,
    severity ENUM('CRITICAL', 'HIGH', 'MEDIUM', 'LOW') NOT NULL,
    line_number INT,
    column_number INT,
    issue_type VARCHAR(100),
    title VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    code_snippet TEXT,
    suggested_fix TEXT,
    status ENUM('open', 'in_progress', 'fixed', 'wont_fix', 'duplicate') DEFAULT 'open',
    assigned_to VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES review_sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (file_id) REFERENCES analyzed_files(file_id) ON DELETE CASCADE,
    INDEX idx_session_issue (session_id, severity),
    INDEX idx_file_issue (file_id, severity),
    INDEX idx_model_issue (model_name, iteration_number)
);

-- Table to store detailed comments generated
CREATE TABLE IF NOT EXISTS code_comments (
    comment_id VARCHAR(36) PRIMARY KEY,
    session_id VARCHAR(36),
    file_id VARCHAR(36),
    model_name VARCHAR(100) NOT NULL,
    iteration_number INT NOT NULL,
    line_number INT,
    comment_type ENUM('inline', 'function', 'class', 'module', 'documentation') NOT NULL,
    original_code TEXT,
    commented_code TEXT,
    explanation TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES review_sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (file_id) REFERENCES analyzed_files(file_id) ON DELETE CASCADE,
    INDEX idx_file_comment (file_id, line_number),
    INDEX idx_model_comment (model_name, iteration_number)
);

-- Table to store generated test cases
CREATE TABLE IF NOT EXISTS test_cases (
    test_id VARCHAR(36) PRIMARY KEY,
    session_id VARCHAR(36),
    file_id VARCHAR(36),
    model_name VARCHAR(100) NOT NULL,
    iteration_number INT NOT NULL,
    test_type ENUM('unit', 'integration', 'e2e', 'performance', 'security', 'accessibility') NOT NULL,
    test_category VARCHAR(100),
    test_name VARCHAR(500) NOT NULL,
    test_description TEXT,
    test_code TEXT NOT NULL,
    test_file_path VARCHAR(500),
    expected_result TEXT,
    test_data JSON,
    prerequisites TEXT,
    cleanup_steps TEXT,
    status ENUM('generated', 'validated', 'failed', 'passed') DEFAULT 'generated',
    execution_time_ms INT,
    last_run TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES review_sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (file_id) REFERENCES analyzed_files(file_id) ON DELETE CASCADE,
    INDEX idx_file_test (file_id, test_type),
    INDEX idx_model_test (model_name, iteration_number),
    INDEX idx_test_status (status, test_type)
);

-- Table to store test execution results
CREATE TABLE IF NOT EXISTS test_executions (
    execution_id VARCHAR(36) PRIMARY KEY,
    test_id VARCHAR(36),
    session_id VARCHAR(36),
    execution_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('passed', 'failed', 'skipped', 'error') NOT NULL,
    duration_ms INT,
    error_message TEXT,
    output_log TEXT,
    screenshots JSON,
    performance_metrics JSON,
    FOREIGN KEY (test_id) REFERENCES test_cases(test_id) ON DELETE CASCADE,
    FOREIGN KEY (session_id) REFERENCES review_sessions(session_id) ON DELETE CASCADE,
    INDEX idx_test_execution (test_id, execution_time),
    INDEX idx_session_execution (session_id, execution_time)
);

-- Table to store model analysis metadata
CREATE TABLE IF NOT EXISTS model_analysis (
    analysis_id VARCHAR(36) PRIMARY KEY,
    session_id VARCHAR(36),
    model_name VARCHAR(100) NOT NULL,
    model_version VARCHAR(50),
    analysis_type VARCHAR(100) NOT NULL,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP NULL,
    duration_ms INT,
    files_analyzed INT DEFAULT 0,
    issues_found INT DEFAULT 0,
    comments_generated INT DEFAULT 0,
    tests_generated INT DEFAULT 0,
    status ENUM('running', 'completed', 'failed', 'timeout') DEFAULT 'running',
    error_message TEXT,
    FOREIGN KEY (session_id) REFERENCES review_sessions(session_id) ON DELETE CASCADE,
    INDEX idx_session_model (session_id, model_name),
    INDEX idx_model_analysis (model_name, analysis_type)
);

-- Table to store deployment test results
CREATE TABLE IF NOT EXISTS deployment_tests (
    deployment_id VARCHAR(36) PRIMARY KEY,
    session_id VARCHAR(36),
    deployment_name VARCHAR(255) NOT NULL,
    deployment_version VARCHAR(100),
    test_suite_name VARCHAR(255),
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP NULL,
    total_tests INT DEFAULT 0,
    passed_tests INT DEFAULT 0,
    failed_tests INT DEFAULT 0,
    skipped_tests INT DEFAULT 0,
    success_rate DECIMAL(5,2),
    status ENUM('running', 'completed', 'failed', 'partial') DEFAULT 'running',
    error_summary TEXT,
    performance_metrics JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES review_sessions(session_id) ON DELETE CASCADE,
    INDEX idx_session_deployment (session_id, deployment_name),
    INDEX idx_deployment_status (status, start_time)
);

-- Table to store quality metrics
CREATE TABLE IF NOT EXISTS quality_metrics (
    metric_id VARCHAR(36) PRIMARY KEY,
    session_id VARCHAR(36),
    file_id VARCHAR(36),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(10,4) NOT NULL,
    metric_unit VARCHAR(50),
    threshold_value DECIMAL(10,4),
    status ENUM('pass', 'fail', 'warning') NOT NULL,
    measured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES review_sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (file_id) REFERENCES analyzed_files(file_id) ON DELETE CASCADE,
    INDEX idx_session_metric (session_id, metric_name),
    INDEX idx_file_metric (file_id, metric_name)
);

-- Table to store fix implementations
CREATE TABLE IF NOT EXISTS issue_fixes (
    fix_id VARCHAR(36) PRIMARY KEY,
    issue_id VARCHAR(36),
    session_id VARCHAR(36),
    fix_type ENUM('code_change', 'configuration', 'documentation', 'test_addition') NOT NULL,
    original_code TEXT,
    fixed_code TEXT,
    fix_description TEXT,
    implementation_notes TEXT,
    validation_status ENUM('pending', 'validated', 'failed') DEFAULT 'pending',
    implemented_by VARCHAR(100),
    implemented_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (issue_id) REFERENCES code_issues(issue_id) ON DELETE CASCADE,
    FOREIGN KEY (session_id) REFERENCES review_sessions(session_id) ON DELETE CASCADE,
    INDEX idx_issue_fix (issue_id),
    INDEX idx_session_fix (session_id, fix_type)
);

-- Views for common queries
CREATE VIEW IF NOT EXISTS session_summary AS
SELECT 
    s.session_id,
    s.session_name,
    s.start_time,
    s.end_time,
    s.status,
    COUNT(DISTINCT af.file_id) as files_analyzed,
    COUNT(DISTINCT ci.issue_id) as total_issues,
    COUNT(DISTINCT tc.test_id) as total_tests,
    COUNT(DISTINCT CASE WHEN ci.severity = 'CRITICAL' THEN ci.issue_id END) as critical_issues,
    COUNT(DISTINCT CASE WHEN ci.severity = 'HIGH' THEN ci.issue_id END) as high_issues,
    COUNT(DISTINCT CASE WHEN ci.severity = 'MEDIUM' THEN ci.issue_id END) as medium_issues,
    COUNT(DISTINCT CASE WHEN ci.severity = 'LOW' THEN ci.issue_id END) as low_issues,
    COUNT(DISTINCT CASE WHEN ci.status = 'fixed' THEN ci.issue_id END) as fixed_issues
FROM review_sessions s
LEFT JOIN analyzed_files af ON s.session_id = af.session_id
LEFT JOIN code_issues ci ON s.session_id = ci.session_id
LEFT JOIN test_cases tc ON s.session_id = tc.session_id
GROUP BY s.session_id;

CREATE VIEW IF NOT EXISTS file_quality_summary AS
SELECT 
    af.file_id,
    af.file_path,
    af.file_type,
    s.session_name,
    COUNT(DISTINCT ci.issue_id) as total_issues,
    COUNT(DISTINCT CASE WHEN ci.severity = 'CRITICAL' THEN ci.issue_id END) as critical_issues,
    COUNT(DISTINCT CASE WHEN ci.severity = 'HIGH' THEN ci.issue_id END) as high_issues,
    COUNT(DISTINCT tc.test_id) as total_tests,
    COUNT(DISTINCT CASE WHEN tc.status = 'passed' THEN tc.test_id END) as passed_tests,
    AVG(qm.metric_value) as avg_quality_score
FROM analyzed_files af
JOIN review_sessions s ON af.session_id = s.session_id
LEFT JOIN code_issues ci ON af.file_id = ci.file_id
LEFT JOIN test_cases tc ON af.file_id = tc.file_id
LEFT JOIN quality_metrics qm ON af.file_id = qm.file_id
GROUP BY af.file_id;

-- Stored procedures for common operations
DELIMITER //

CREATE PROCEDURE IF NOT EXISTS StartReviewSession(
    IN p_session_name VARCHAR(255),
    OUT p_session_id VARCHAR(36)
)
BEGIN
    SET p_session_id = UUID();
    INSERT INTO review_sessions (session_id, session_name) 
    VALUES (p_session_id, p_session_name);
END //

CREATE PROCEDURE IF NOT EXISTS GetCriticalIssues(
    IN p_session_id VARCHAR(36)
)
BEGIN
    SELECT 
        ci.issue_id,
        af.file_path,
        ci.line_number,
        ci.title,
        ci.description,
        ci.severity,
        ci.model_name,
        ci.iteration_number
    FROM code_issues ci
    JOIN analyzed_files af ON ci.file_id = af.file_id
    WHERE ci.session_id = p_session_id 
    AND ci.severity IN ('CRITICAL', 'HIGH')
    ORDER BY ci.severity DESC, ci.line_number;
END //

CREATE PROCEDURE IF NOT EXISTS GetTestCoverage(
    IN p_session_id VARCHAR(36)
)
BEGIN
    SELECT 
        af.file_path,
        COUNT(DISTINCT tc.test_id) as total_tests,
        COUNT(DISTINCT CASE WHEN tc.test_type = 'unit' THEN tc.test_id END) as unit_tests,
        COUNT(DISTINCT CASE WHEN tc.test_type = 'integration' THEN tc.test_id END) as integration_tests,
        COUNT(DISTINCT CASE WHEN tc.test_type = 'e2e' THEN tc.test_id END) as e2e_tests,
        COUNT(DISTINCT CASE WHEN tc.status = 'passed' THEN tc.test_id END) as passed_tests
    FROM analyzed_files af
    LEFT JOIN test_cases tc ON af.file_id = tc.file_id
    WHERE af.session_id = p_session_id
    GROUP BY af.file_id, af.file_path
    ORDER BY total_tests DESC;
END //

DELIMITER ;

-- Insert initial data
INSERT INTO review_sessions (session_id, session_name, status) 
VALUES (UUID(), 'Initial Comprehensive Review', 'running')
ON DUPLICATE KEY UPDATE session_name = session_name;

-- Create indexes for performance
CREATE INDEX idx_issues_severity ON code_issues(severity, status);
CREATE INDEX idx_tests_type_status ON test_cases(test_type, status);
CREATE INDEX idx_executions_time ON test_executions(execution_time);
CREATE INDEX idx_metrics_name_value ON quality_metrics(metric_name, metric_value);

-- Grant permissions (adjust as needed for your environment)
-- GRANT ALL PRIVILEGES ON medinovai_code_review.* TO 'medinovai_user'@'%';
-- FLUSH PRIVILEGES;
