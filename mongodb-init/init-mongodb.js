// MongoDB Initialization Script for MedinovAI
// Creates databases, users, and collections with proper indexes

print('=== MedinovAI MongoDB Initialization ===');

// Switch to medinovai database
db = db.getSiblingDB('medinovai');

// Create application user with read/write privileges
db.createUser({
  user: 'medinovai_app',
  pwd: process.env.MONGODB_APP_PASSWORD || 'medinovai_app_secure_2025',
  roles: [
    {
      role: 'readWrite',
      db: 'medinovai'
    }
  ]
});

print('✅ Created medinovai_app user');

// Create core collections
db.createCollection('patients');
db.createCollection('medical_records');
db.createCollection('sessions');
db.createCollection('logs');
db.createCollection('audit_trail');

print('✅ Created core collections');

// Create indexes for performance
db.patients.createIndex({ "patient_id": 1 }, { unique: true });
db.patients.createIndex({ "email": 1 });
db.patients.createIndex({ "created_at": -1 });

db.medical_records.createIndex({ "patient_id": 1 });
db.medical_records.createIndex({ "record_type": 1 });
db.medical_records.createIndex({ "created_at": -1 });

db.sessions.createIndex({ "session_id": 1 }, { unique: true });
db.sessions.createIndex({ "user_id": 1 });
db.sessions.createIndex({ "expires_at": 1 }, { expireAfterSeconds: 0 });

db.logs.createIndex({ "timestamp": -1 });
db.logs.createIndex({ "level": 1 });
db.logs.createIndex({ "service": 1 });

db.audit_trail.createIndex({ "timestamp": -1 });
db.audit_trail.createIndex({ "user_id": 1 });
db.audit_trail.createIndex({ "action": 1 });

print('✅ Created indexes');

// Create capped collections for logs (auto-cleanup)
db.createCollection('system_logs', { capped: true, size: 1073741824, max: 1000000 }); // 1GB, 1M docs

print('✅ Created capped collections');

print('=== MongoDB Initialization Complete ===');

