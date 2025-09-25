-- MedinovAI Database Schema
-- Initialize the database with required tables

-- Create patients table
CREATE TABLE IF NOT EXISTS patients (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    age INTEGER NOT NULL,
    gender VARCHAR(10) NOT NULL,
    medical_record_number VARCHAR(50) UNIQUE NOT NULL,
    contact_info JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create clinical_records table
CREATE TABLE IF NOT EXISTS clinical_records (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    record_type VARCHAR(100) NOT NULL,
    record_data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create audit_logs table
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(100),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id VARCHAR(100),
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create ai_interactions table
CREATE TABLE IF NOT EXISTS ai_interactions (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(100),
    query TEXT NOT NULL,
    response TEXT,
    model_used VARCHAR(100),
    confidence_score DECIMAL(3,2),
    processing_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_patients_medical_record_number ON patients(medical_record_number);
CREATE INDEX IF NOT EXISTS idx_clinical_records_patient_id ON clinical_records(patient_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_interactions_created_at ON ai_interactions(created_at);

-- Insert sample data
INSERT INTO patients (name, age, gender, medical_record_number, contact_info) VALUES
('John Doe', 45, 'Male', 'MRN001', '{"email": "john.doe@email.com", "phone": "+1-555-0123"}'),
('Jane Smith', 32, 'Female', 'MRN002', '{"email": "jane.smith@email.com", "phone": "+1-555-0124"}'),
('Bob Johnson', 67, 'Male', 'MRN003', '{"email": "bob.johnson@email.com", "phone": "+1-555-0125"}')
ON CONFLICT (medical_record_number) DO NOTHING;

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clinical_records_updated_at BEFORE UPDATE ON clinical_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();








