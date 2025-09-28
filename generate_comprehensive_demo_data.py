#!/usr/bin/env python3
"""
Comprehensive Demo Data Generator for MedinovAI Platform RA1
Generates realistic demo data for all modules with 5 workflows each
"""

import json
import random
import uuid
from datetime import datetime, timedelta
from typing import Dict, List, Any
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MedinovAIDemoDataGenerator:
    def __init__(self):
        self.demo_data = {}
        self.start_date = datetime.now() - timedelta(days=365)
        self.end_date = datetime.now()
        
    def generate_users_and_roles(self, count: int = 1000) -> List[Dict[str, Any]]:
        """Generate diverse user base with realistic roles"""
        
        roles = [
            {"role": "admin", "percentage": 0.05},
            {"role": "doctor", "percentage": 0.15},
            {"role": "nurse", "percentage": 0.25},
            {"role": "patient", "percentage": 0.40},
            {"role": "staff", "percentage": 0.10},
            {"role": "manager", "percentage": 0.05}
        ]
        
        users = []
        
        for i in range(count):
            # Select role based on distribution
            role_rand = random.random()
            cumulative = 0
            selected_role = "patient"
            
            for role_info in roles:
                cumulative += role_info["percentage"]
                if role_rand <= cumulative:
                    selected_role = role_info["role"]
                    break
            
            user = {
                "user_id": str(uuid.uuid4()),
                "username": f"user_{i:04d}",
                "email": f"user{i}@medinovai-demo.com",
                "first_name": self.generate_first_name(),
                "last_name": self.generate_last_name(),
                "role": selected_role,
                "created_at": self.random_date(),
                "active": random.choice([True, True, True, False]),  # 75% active
                "last_login": self.random_recent_date(),
                "profile": self.generate_user_profile(selected_role)
            }
            
            users.append(user)
        
        self.demo_data["users"] = users
        logger.info(f"✅ Generated {len(users)} users with diverse roles")
        return users

    def generate_ats_demo_data(self) -> Dict[str, Any]:
        """Generate comprehensive ATS demo data with 5 complete workflows"""
        
        logger.info("🏢 Generating ATS demo data...")
        
        # Generate candidates
        candidates = []
        for i in range(1000):
            candidate = {
                "candidate_id": str(uuid.uuid4()),
                "first_name": self.generate_first_name(),
                "last_name": self.generate_last_name(),
                "email": f"candidate{i}@demo-email.com",
                "phone": self.generate_phone(),
                "location": self.generate_location(),
                "experience_years": random.randint(0, 30),
                "skills": self.generate_skills(),
                "education": self.generate_education(),
                "salary_expectation": random.randint(40000, 500000),
                "availability": self.generate_availability(),
                "resume_url": f"https://demo-resumes.medinovai.com/resume_{i}.pdf",
                "status": random.choice(["new", "screening", "interview", "offer", "hired", "rejected"]),
                "created_at": self.random_date(),
                "source": random.choice(["direct", "linkedin", "indeed", "referral", "website"])
            }
            candidates.append(candidate)
        
        # Generate jobs
        jobs = []
        job_titles = [
            "Software Engineer", "Data Scientist", "Product Manager", "UX Designer",
            "DevOps Engineer", "Marketing Manager", "Sales Representative", "Nurse",
            "Doctor", "Medical Assistant", "Healthcare Administrator", "Clinical Researcher"
        ]
        
        for i in range(50):
            job = {
                "job_id": str(uuid.uuid4()),
                "title": random.choice(job_titles),
                "department": self.generate_department(),
                "location": self.generate_location(),
                "job_type": random.choice(["full_time", "part_time", "contract", "remote"]),
                "salary_min": random.randint(40000, 200000),
                "salary_max": random.randint(200000, 500000),
                "required_skills": self.generate_skills(),
                "experience_required": random.randint(0, 15),
                "education_required": random.choice(["high_school", "bachelor", "master", "phd"]),
                "description": f"Exciting opportunity for {random.choice(job_titles)} in our growing team.",
                "status": random.choice(["open", "closed", "on_hold", "filled"]),
                "posted_date": self.random_date(),
                "hiring_manager": f"manager_{random.randint(1, 20)}"
            }
            jobs.append(job)
        
        # Generate applications
        applications = []
        for i in range(2000):
            application = {
                "application_id": str(uuid.uuid4()),
                "candidate_id": random.choice(candidates)["candidate_id"],
                "job_id": random.choice(jobs)["job_id"],
                "applied_date": self.random_date(),
                "status": random.choice(["applied", "screening", "phone_interview", "technical_interview", 
                                      "final_interview", "offer_extended", "offer_accepted", "hired", "rejected"]),
                "cover_letter": f"Demo cover letter for application {i}",
                "interview_notes": self.generate_interview_notes(),
                "rating": random.randint(1, 10) if random.random() > 0.3 else None
            }
            applications.append(application)
        
        # Generate 5 complete workflow scenarios
        workflows = self.generate_ats_workflows(candidates, jobs, applications)
        
        ats_data = {
            "candidates": candidates,
            "jobs": jobs,
            "applications": applications,
            "workflows": workflows,
            "summary": {
                "total_candidates": len(candidates),
                "total_jobs": len(jobs),
                "total_applications": len(applications),
                "workflow_scenarios": len(workflows)
            }
        }
        
        self.demo_data["ats"] = ats_data
        logger.info(f"✅ Generated ATS demo data: {len(candidates)} candidates, {len(jobs)} jobs, {len(applications)} applications")
        return ats_data

    def generate_healthcare_demo_data(self) -> Dict[str, Any]:
        """Generate HIPAA-compliant synthetic healthcare demo data"""
        
        logger.info("🏥 Generating healthcare demo data...")
        
        # Generate patients (HIPAA-compliant synthetic data)
        patients = []
        for i in range(500):
            patient = {
                "patient_id": str(uuid.uuid4()),
                "mrn": f"MRN{i:06d}",  # Medical Record Number
                "first_name": self.generate_first_name(),
                "last_name": self.generate_last_name(),
                "date_of_birth": self.generate_birth_date(),
                "gender": random.choice(["male", "female", "other"]),
                "address": self.generate_address(),
                "phone": self.generate_phone(),
                "email": f"patient{i}@demo-health.com",
                "emergency_contact": self.generate_emergency_contact(),
                "insurance": self.generate_insurance_info(),
                "allergies": self.generate_allergies(),
                "medical_conditions": self.generate_medical_conditions(),
                "medications": self.generate_medications(),
                "created_at": self.random_date(),
                "last_visit": self.random_recent_date()
            }
            patients.append(patient)
        
        # Generate healthcare providers
        providers = []
        specialties = ["Family Medicine", "Cardiology", "Neurology", "Oncology", "Pediatrics", 
                      "Emergency Medicine", "Surgery", "Psychiatry", "Radiology", "Pathology"]
        
        for i in range(100):
            provider = {
                "provider_id": str(uuid.uuid4()),
                "npi": f"NPI{i:010d}",  # National Provider Identifier
                "first_name": self.generate_first_name(),
                "last_name": self.generate_last_name(),
                "specialty": random.choice(specialties),
                "credentials": self.generate_credentials(),
                "license_number": f"LIC{i:08d}",
                "experience_years": random.randint(1, 40),
                "availability": self.generate_provider_availability(),
                "contact_info": self.generate_provider_contact(),
                "created_at": self.random_date()
            }
            providers.append(provider)
        
        # Generate clinical encounters
        encounters = []
        for i in range(1000):
            encounter = {
                "encounter_id": str(uuid.uuid4()),
                "patient_id": random.choice(patients)["patient_id"],
                "provider_id": random.choice(providers)["provider_id"],
                "encounter_type": random.choice(["routine", "urgent", "emergency", "follow_up"]),
                "chief_complaint": self.generate_chief_complaint(),
                "diagnosis": self.generate_diagnosis(),
                "treatment_plan": self.generate_treatment_plan(),
                "medications_prescribed": self.generate_prescribed_medications(),
                "follow_up_required": random.choice([True, False]),
                "encounter_date": self.random_date(),
                "duration_minutes": random.randint(15, 120),
                "notes": f"Clinical notes for encounter {i}",
                "billing_codes": self.generate_billing_codes()
            }
            encounters.append(encounter)
        
        # Generate 5 healthcare workflow scenarios
        healthcare_workflows = self.generate_healthcare_workflows(patients, providers, encounters)
        
        healthcare_data = {
            "patients": patients,
            "providers": providers,
            "encounters": encounters,
            "workflows": healthcare_workflows,
            "summary": {
                "total_patients": len(patients),
                "total_providers": len(providers),
                "total_encounters": len(encounters),
                "workflow_scenarios": len(healthcare_workflows)
            }
        }
        
        self.demo_data["healthcare"] = healthcare_data
        logger.info(f"✅ Generated healthcare demo data: {len(patients)} patients, {len(providers)} providers, {len(encounters)} encounters")
        return healthcare_data

    def generate_business_demo_data(self) -> Dict[str, Any]:
        """Generate comprehensive business demo data for all business modules"""
        
        logger.info("💼 Generating business demo data...")
        
        # Generate clients/customers
        clients = []
        for i in range(200):
            client = {
                "client_id": str(uuid.uuid4()),
                "company_name": f"Demo Company {i}",
                "industry": random.choice(["Healthcare", "Technology", "Finance", "Retail", "Manufacturing"]),
                "size": random.choice(["startup", "small", "medium", "large", "enterprise"]),
                "contact_person": f"{self.generate_first_name()} {self.generate_last_name()}",
                "email": f"contact{i}@demo-company{i}.com",
                "phone": self.generate_phone(),
                "address": self.generate_address(),
                "annual_revenue": random.randint(100000, 100000000),
                "employee_count": random.randint(10, 10000),
                "created_at": self.random_date(),
                "status": random.choice(["active", "inactive", "prospect", "churned"])
            }
            clients.append(client)
        
        # Generate projects for bidding
        projects = []
        project_types = ["Software Development", "Healthcare IT", "Marketing Campaign", 
                        "Data Analytics", "Mobile App", "Web Platform", "AI/ML Implementation"]
        
        for i in range(1000):
            project = {
                "project_id": str(uuid.uuid4()),
                "title": f"{random.choice(project_types)} Project {i}",
                "client_id": random.choice(clients)["client_id"],
                "project_type": random.choice(project_types),
                "budget_min": random.randint(10000, 500000),
                "budget_max": random.randint(500000, 5000000),
                "duration_weeks": random.randint(4, 52),
                "requirements": self.generate_project_requirements(),
                "status": random.choice(["open", "in_progress", "completed", "cancelled"]),
                "posted_date": self.random_date(),
                "deadline": self.random_future_date(),
                "complexity": random.choice(["low", "medium", "high", "very_high"])
            }
            projects.append(project)
        
        # Generate bids
        bids = []
        for i in range(5000):
            bid = {
                "bid_id": str(uuid.uuid4()),
                "project_id": random.choice(projects)["project_id"],
                "bid_amount": random.randint(50000, 2000000),
                "proposal_text": f"Comprehensive proposal for project {i}",
                "estimated_duration": random.randint(4, 48),
                "submitted_at": self.random_date(),
                "status": random.choice(["submitted", "under_review", "shortlisted", "won", "lost", "withdrawn"]),
                "confidence_score": random.uniform(0.1, 0.95),
                "auto_generated": random.choice([True, False])
            }
            bids.append(bid)
        
        # Generate business workflows
        business_workflows = self.generate_business_workflows(clients, projects, bids)
        
        business_data = {
            "clients": clients,
            "projects": projects,
            "bids": bids,
            "workflows": business_workflows,
            "summary": {
                "total_clients": len(clients),
                "total_projects": len(projects),
                "total_bids": len(bids),
                "workflow_scenarios": len(business_workflows)
            }
        }
        
        self.demo_data["business"] = business_data
        logger.info(f"✅ Generated business demo data: {len(clients)} clients, {len(projects)} projects, {len(bids)} bids")
        return business_data

    def generate_ats_workflows(self, candidates: List, jobs: List, applications: List) -> List[Dict[str, Any]]:
        """Generate 5 complete ATS workflow scenarios"""
        
        workflows = [
            {
                "workflow_id": "ats_workflow_1",
                "name": "Tech Startup Software Engineer Hiring",
                "description": "Complete hiring process for senior software engineer at tech startup",
                "steps": [
                    {"step": 1, "action": "job_posting", "duration_hours": 2},
                    {"step": 2, "action": "application_collection", "duration_days": 14},
                    {"step": 3, "action": "resume_screening", "duration_days": 3},
                    {"step": 4, "action": "phone_interviews", "duration_days": 5},
                    {"step": 5, "action": "technical_assessment", "duration_days": 2},
                    {"step": 6, "action": "final_interviews", "duration_days": 3},
                    {"step": 7, "action": "offer_negotiation", "duration_days": 2},
                    {"step": 8, "action": "onboarding", "duration_days": 5}
                ],
                "demo_data": {
                    "job_id": jobs[0]["job_id"] if jobs else None,
                    "candidate_count": 50,
                    "applications_received": 75,
                    "interviews_conducted": 15,
                    "offers_extended": 3,
                    "hires_completed": 1
                },
                "success_metrics": {
                    "time_to_hire": "21 days",
                    "cost_per_hire": "$5,000",
                    "candidate_satisfaction": "4.2/5",
                    "hiring_manager_satisfaction": "4.5/5"
                }
            },
            {
                "workflow_id": "ats_workflow_2", 
                "name": "Healthcare Facility Nurse Recruitment",
                "description": "Bulk recruitment of registered nurses for hospital expansion",
                "steps": [
                    {"step": 1, "action": "workforce_planning", "duration_hours": 4},
                    {"step": 2, "action": "job_posting_multiple_platforms", "duration_hours": 3},
                    {"step": 3, "action": "bulk_application_processing", "duration_days": 7},
                    {"step": 4, "action": "credential_verification", "duration_days": 5},
                    {"step": 5, "action": "group_interviews", "duration_days": 3},
                    {"step": 6, "action": "background_checks", "duration_days": 7},
                    {"step": 7, "action": "bulk_offers", "duration_days": 1},
                    {"step": 8, "action": "orientation_scheduling", "duration_days": 2}
                ],
                "demo_data": {
                    "positions_open": 20,
                    "applications_received": 200,
                    "qualified_candidates": 60,
                    "interviews_conducted": 40,
                    "offers_extended": 25,
                    "hires_completed": 18
                }
            },
            {
                "workflow_id": "ats_workflow_3",
                "name": "Executive Search C-Level Position", 
                "description": "Executive search for Chief Medical Officer position",
                "steps": [
                    {"step": 1, "action": "executive_search_planning", "duration_days": 2},
                    {"step": 2, "action": "headhunter_engagement", "duration_days": 1},
                    {"step": 3, "action": "candidate_identification", "duration_days": 14},
                    {"step": 4, "action": "initial_screening", "duration_days": 7},
                    {"step": 5, "action": "board_presentation", "duration_days": 3},
                    {"step": 6, "action": "executive_interviews", "duration_days": 5},
                    {"step": 7, "action": "reference_checks", "duration_days": 3},
                    {"step": 8, "action": "compensation_negotiation", "duration_days": 7}
                ],
                "demo_data": {
                    "target_candidates": 10,
                    "candidates_identified": 8,
                    "initial_interviews": 5,
                    "board_presentations": 3,
                    "final_candidates": 2,
                    "offers_extended": 1
                }
            },
            {
                "workflow_id": "ats_workflow_4",
                "name": "Seasonal Retail Staff Hiring",
                "description": "High-volume seasonal hiring for holiday retail period",
                "steps": [
                    {"step": 1, "action": "seasonal_planning", "duration_days": 3},
                    {"step": 2, "action": "mass_job_posting", "duration_hours": 4},
                    {"step": 3, "action": "automated_screening", "duration_days": 2},
                    {"step": 4, "action": "group_interviews", "duration_days": 5},
                    {"step": 5, "action": "rapid_background_checks", "duration_days": 3},
                    {"step": 6, "action": "bulk_onboarding", "duration_days": 2},
                    {"step": 7, "action": "training_coordination", "duration_days": 3}
                ],
                "demo_data": {
                    "positions_needed": 100,
                    "applications_received": 500,
                    "automated_screening_passed": 300,
                    "interviews_conducted": 150,
                    "hires_completed": 85
                }
            },
            {
                "workflow_id": "ats_workflow_5",
                "name": "Remote Digital Marketing Position",
                "description": "Remote hiring process for digital marketing specialist",
                "steps": [
                    {"step": 1, "action": "remote_job_design", "duration_hours": 3},
                    {"step": 2, "action": "global_job_posting", "duration_hours": 2},
                    {"step": 3, "action": "timezone_coordination", "duration_days": 1},
                    {"step": 4, "action": "video_interviews", "duration_days": 7},
                    {"step": 5, "action": "portfolio_review", "duration_days": 3},
                    {"step": 6, "action": "skills_assessment", "duration_days": 2},
                    {"step": 7, "action": "remote_onboarding", "duration_days": 3}
                ],
                "demo_data": {
                    "global_applications": 150,
                    "timezone_coverage": "24/7",
                    "video_interviews": 25,
                    "portfolio_reviews": 15,
                    "skills_assessments": 10,
                    "remote_hires": 3
                }
            }
        ]
        
        return workflows

    def generate_healthcare_workflows(self, patients: List, providers: List, encounters: List) -> List[Dict[str, Any]]:
        """Generate 5 complete healthcare workflow scenarios"""
        
        workflows = [
            {
                "workflow_id": "healthcare_workflow_1",
                "name": "AI-Assisted Emergency Diagnosis",
                "description": "Emergency department patient with chest pain - AI-assisted diagnosis workflow",
                "steps": [
                    {"step": 1, "action": "patient_triage", "duration_minutes": 5},
                    {"step": 2, "action": "vital_signs_collection", "duration_minutes": 10},
                    {"step": 3, "action": "ai_symptom_analysis", "duration_minutes": 2},
                    {"step": 4, "action": "diagnostic_recommendations", "duration_minutes": 3},
                    {"step": 5, "action": "physician_review", "duration_minutes": 15},
                    {"step": 6, "action": "treatment_initiation", "duration_minutes": 30},
                    {"step": 7, "action": "monitoring_setup", "duration_minutes": 10},
                    {"step": 8, "action": "discharge_planning", "duration_minutes": 20}
                ],
                "demo_data": {
                    "patient_id": patients[0]["patient_id"] if patients else None,
                    "chief_complaint": "Chest pain and shortness of breath",
                    "ai_diagnosis_confidence": 0.87,
                    "physician_concurrence": True,
                    "treatment_outcome": "Stable, discharged home"
                }
            },
            {
                "workflow_id": "healthcare_workflow_2",
                "name": "Chronic Disease Management",
                "description": "Diabetes patient ongoing care management with AI monitoring",
                "steps": [
                    {"step": 1, "action": "baseline_assessment", "duration_days": 1},
                    {"step": 2, "action": "care_plan_development", "duration_days": 2},
                    {"step": 3, "action": "patient_education", "duration_hours": 2},
                    {"step": 4, "action": "monitoring_device_setup", "duration_minutes": 30},
                    {"step": 5, "action": "ai_trend_analysis", "continuous": True},
                    {"step": 6, "action": "medication_adjustments", "duration_days": 1},
                    {"step": 7, "action": "lifestyle_recommendations", "duration_minutes": 30},
                    {"step": 8, "action": "follow_up_scheduling", "duration_minutes": 15}
                ],
                "demo_data": {
                    "condition": "Type 2 Diabetes",
                    "baseline_hba1c": 8.5,
                    "target_hba1c": 7.0,
                    "monitoring_frequency": "Daily glucose, weekly weight",
                    "ai_alerts_generated": 15,
                    "medication_adjustments": 3
                }
            },
            {
                "workflow_id": "healthcare_workflow_3",
                "name": "Surgical Procedure Planning",
                "description": "Complete surgical workflow from consultation to recovery",
                "steps": [
                    {"step": 1, "action": "surgical_consultation", "duration_minutes": 45},
                    {"step": 2, "action": "pre_operative_assessment", "duration_days": 7},
                    {"step": 3, "action": "surgical_scheduling", "duration_days": 14},
                    {"step": 4, "action": "pre_op_preparation", "duration_hours": 4},
                    {"step": 5, "action": "surgical_procedure", "duration_hours": 3},
                    {"step": 6, "action": "post_op_monitoring", "duration_days": 2},
                    {"step": 7, "action": "discharge_planning", "duration_hours": 2},
                    {"step": 8, "action": "follow_up_care", "duration_days": 30}
                ],
                "demo_data": {
                    "procedure": "Laparoscopic Cholecystectomy",
                    "surgeon": "Dr. Smith, General Surgery",
                    "anesthesia_type": "General",
                    "estimated_duration": "2-3 hours",
                    "complications": "None",
                    "recovery_time": "2-4 weeks"
                }
            },
            {
                "workflow_id": "healthcare_workflow_4",
                "name": "Telemedicine Consultation",
                "description": "Remote patient consultation with AI-assisted diagnosis",
                "steps": [
                    {"step": 1, "action": "appointment_booking", "duration_minutes": 5},
                    {"step": 2, "action": "pre_visit_questionnaire", "duration_minutes": 10},
                    {"step": 3, "action": "technology_setup", "duration_minutes": 5},
                    {"step": 4, "action": "video_consultation", "duration_minutes": 30},
                    {"step": 5, "action": "ai_documentation_assist", "duration_minutes": 5},
                    {"step": 6, "action": "prescription_management", "duration_minutes": 10},
                    {"step": 7, "action": "follow_up_scheduling", "duration_minutes": 5},
                    {"step": 8, "action": "care_summary_delivery", "duration_minutes": 2}
                ],
                "demo_data": {
                    "consultation_type": "Follow-up for hypertension",
                    "video_quality": "HD 1080p",
                    "connection_stability": "Excellent",
                    "ai_assistance_used": True,
                    "prescription_sent": "Electronic to pharmacy",
                    "patient_satisfaction": "5/5"
                }
            },
            {
                "workflow_id": "healthcare_workflow_5",
                "name": "Clinical Research Enrollment",
                "description": "Patient enrollment in clinical trial with AI matching",
                "steps": [
                    {"step": 1, "action": "trial_eligibility_screening", "duration_days": 1},
                    {"step": 2, "action": "ai_patient_matching", "duration_minutes": 30},
                    {"step": 3, "action": "informed_consent", "duration_hours": 2},
                    {"step": 4, "action": "baseline_data_collection", "duration_days": 2},
                    {"step": 5, "action": "randomization", "duration_minutes": 5},
                    {"step": 6, "action": "treatment_initiation", "duration_days": 1},
                    {"step": 7, "action": "monitoring_setup", "duration_hours": 1},
                    {"step": 8, "action": "data_reporting", "continuous": True}
                ],
                "demo_data": {
                    "trial_name": "Novel Diabetes Treatment Study",
                    "eligibility_criteria": "Type 2 diabetes, HbA1c > 7.5%",
                    "ai_matching_score": 0.92,
                    "enrollment_success": True,
                    "compliance_rate": "98%"
                }
            }
        ]
        
        return workflows

    def generate_business_workflows(self, clients: List, projects: List, bids: List) -> List[Dict[str, Any]]:
        """Generate 5 complete business workflow scenarios"""
        
        workflows = [
            {
                "workflow_id": "business_workflow_1",
                "name": "Enterprise Software Development Bid",
                "description": "Complete bidding process for large enterprise software project",
                "steps": [
                    {"step": 1, "action": "rfp_analysis", "duration_hours": 4},
                    {"step": 2, "action": "technical_assessment", "duration_days": 2},
                    {"step": 3, "action": "team_allocation", "duration_days": 1},
                    {"step": 4, "action": "cost_estimation", "duration_hours": 6},
                    {"step": 5, "action": "proposal_writing", "duration_days": 3},
                    {"step": 6, "action": "proposal_submission", "duration_hours": 1},
                    {"step": 7, "action": "client_presentation", "duration_hours": 2},
                    {"step": 8, "action": "contract_negotiation", "duration_days": 5}
                ],
                "demo_data": {
                    "project_value": "$2,500,000",
                    "duration": "18 months",
                    "team_size": "12 developers",
                    "win_probability": "75%",
                    "competition": "3 other bidders"
                }
            },
            {
                "workflow_id": "business_workflow_2",
                "name": "Marketing Campaign Automation",
                "description": "Automated marketing campaign for healthcare SaaS product launch",
                "steps": [
                    {"step": 1, "action": "market_research", "duration_days": 3},
                    {"step": 2, "action": "target_audience_definition", "duration_days": 1},
                    {"step": 3, "action": "campaign_strategy", "duration_days": 2},
                    {"step": 4, "action": "content_creation", "duration_days": 5},
                    {"step": 5, "action": "automation_setup", "duration_days": 2},
                    {"step": 6, "action": "campaign_launch", "duration_hours": 2},
                    {"step": 7, "action": "performance_monitoring", "continuous": True},
                    {"step": 8, "action": "optimization_cycles", "duration_days": 30}
                ],
                "demo_data": {
                    "target_audience": "Healthcare IT Directors",
                    "campaign_budget": "$50,000",
                    "channels": "LinkedIn, Email, Google Ads",
                    "expected_leads": "500",
                    "conversion_rate": "15%"
                }
            },
            {
                "workflow_id": "business_workflow_3",
                "name": "Sales Pipeline Optimization",
                "description": "AI-driven sales pipeline optimization and lead scoring",
                "steps": [
                    {"step": 1, "action": "lead_data_analysis", "duration_days": 1},
                    {"step": 2, "action": "ai_lead_scoring", "duration_hours": 2},
                    {"step": 3, "action": "pipeline_segmentation", "duration_hours": 4},
                    {"step": 4, "action": "automated_nurturing", "duration_days": 14},
                    {"step": 5, "action": "sales_team_assignment", "duration_hours": 2},
                    {"step": 6, "action": "personalized_outreach", "duration_days": 7},
                    {"step": 7, "action": "conversion_tracking", "continuous": True},
                    {"step": 8, "action": "pipeline_optimization", "duration_days": 30}
                ],
                "demo_data": {
                    "total_leads": "2,000",
                    "qualified_leads": "600",
                    "sales_qualified": "200",
                    "opportunities": "75",
                    "closed_won": "25"
                }
            },
            {
                "workflow_id": "business_workflow_4",
                "name": "Customer Onboarding Automation",
                "description": "Automated customer onboarding for healthcare software platform",
                "steps": [
                    {"step": 1, "action": "welcome_sequence", "duration_hours": 1},
                    {"step": 2, "action": "account_setup", "duration_hours": 2},
                    {"step": 3, "action": "data_migration", "duration_days": 3},
                    {"step": 4, "action": "training_delivery", "duration_days": 5},
                    {"step": 5, "action": "integration_testing", "duration_days": 2},
                    {"step": 6, "action": "go_live_support", "duration_days": 1},
                    {"step": 7, "action": "success_metrics_tracking", "duration_days": 30},
                    {"step": 8, "action": "optimization_recommendations", "duration_days": 7}
                ],
                "demo_data": {
                    "customer_type": "Mid-size hospital",
                    "users_onboarded": "150",
                    "integrations_completed": "5",
                    "training_hours": "40",
                    "time_to_value": "14 days"
                }
            },
            {
                "workflow_id": "business_workflow_5",
                "name": "Subscription Management Lifecycle",
                "description": "Complete subscription lifecycle from trial to renewal",
                "steps": [
                    {"step": 1, "action": "trial_signup", "duration_minutes": 10},
                    {"step": 2, "action": "trial_onboarding", "duration_days": 1},
                    {"step": 3, "action": "usage_monitoring", "duration_days": 14},
                    {"step": 4, "action": "conversion_outreach", "duration_days": 3},
                    {"step": 5, "action": "subscription_activation", "duration_hours": 1},
                    {"step": 6, "action": "ongoing_support", "continuous": True},
                    {"step": 7, "action": "renewal_management", "duration_days": 30},
                    {"step": 8, "action": "expansion_opportunities", "continuous": True}
                ],
                "demo_data": {
                    "trial_conversion_rate": "25%",
                    "average_trial_duration": "14 days",
                    "subscription_tiers": "Basic, Pro, Enterprise",
                    "renewal_rate": "85%",
                    "expansion_revenue": "40%"
                }
            }
        ]
        
        return workflows

    # Helper methods for generating realistic data
    def generate_first_name(self) -> str:
        names = ["John", "Jane", "Michael", "Sarah", "David", "Emily", "Robert", "Jessica", 
                "William", "Ashley", "James", "Amanda", "Christopher", "Jennifer", "Daniel"]
        return random.choice(names)

    def generate_last_name(self) -> str:
        names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", 
                "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez"]
        return random.choice(names)

    def generate_phone(self) -> str:
        return f"({random.randint(200, 999)}) {random.randint(200, 999)}-{random.randint(1000, 9999)}"

    def generate_location(self) -> str:
        cities = ["New York, NY", "Los Angeles, CA", "Chicago, IL", "Houston, TX", 
                 "Phoenix, AZ", "Philadelphia, PA", "San Antonio, TX", "San Diego, CA"]
        return random.choice(cities)

    def generate_skills(self) -> List[str]:
        skills = ["Python", "JavaScript", "React", "Node.js", "Docker", "Kubernetes", 
                 "AWS", "Machine Learning", "Data Analysis", "Project Management",
                 "Healthcare IT", "HIPAA Compliance", "Clinical Workflows"]
        return random.sample(skills, random.randint(3, 8))

    def random_date(self) -> str:
        """Generate random date within the last year"""
        time_between = self.end_date - self.start_date
        days_between = time_between.days
        random_days = random.randrange(days_between)
        random_date = self.start_date + timedelta(days=random_days)
        return random_date.isoformat()

    def random_recent_date(self) -> str:
        """Generate random date within the last 30 days"""
        recent_start = self.end_date - timedelta(days=30)
        time_between = self.end_date - recent_start
        days_between = time_between.days
        random_days = random.randrange(days_between)
        random_date = recent_start + timedelta(days=random_days)
        return random_date.isoformat()

    def save_all_demo_data(self):
        """Save all generated demo data to files"""
        
        logger.info("💾 Saving comprehensive demo data...")
        
        # Create demo data directory
        import os
        os.makedirs("demo_data", exist_ok=True)
        
        # Save complete demo data
        with open("demo_data/comprehensive_demo_data.json", "w") as f:
            json.dump(self.demo_data, f, indent=2)
        
        # Save individual module data
        for module_name, module_data in self.demo_data.items():
            with open(f"demo_data/{module_name}_demo_data.json", "w") as f:
                json.dump(module_data, f, indent=2)
        
        logger.info("✅ Demo data saved successfully")

    def generate_complete_demo_ecosystem(self):
        """Generate complete demo data ecosystem for all modules"""
        
        logger.info("🚀 Generating comprehensive MedinovAI demo data ecosystem...")
        
        # Generate core data
        self.generate_users_and_roles(1000)
        
        # Generate business module data
        self.generate_ats_demo_data()
        self.generate_business_demo_data()
        
        # Generate healthcare module data
        self.generate_healthcare_demo_data()
        
        # Save all data
        self.save_all_demo_data()
        
        # Generate summary report
        summary = {
            "generation_timestamp": datetime.now().isoformat(),
            "total_modules": len(self.demo_data),
            "total_workflows": sum(len(data.get("workflows", [])) for data in self.demo_data.values()),
            "data_summary": {
                module: {
                    "records": len(data) if isinstance(data, list) else len(data.get("summary", {})),
                    "workflows": len(data.get("workflows", [])) if isinstance(data, dict) else 0
                }
                for module, data in self.demo_data.items()
            }
        }
        
        with open("demo_data/generation_summary.json", "w") as f:
            json.dump(summary, f, indent=2)
        
        logger.info("🎉 Complete demo data ecosystem generated successfully!")
        return summary

if __name__ == "__main__":
    generator = MedinovAIDemoDataGenerator()
    summary = generator.generate_complete_demo_ecosystem()
    
    print(f"\n🎯 DEMO DATA GENERATION SUMMARY:")
    print(f"Total Modules: {summary['total_modules']}")
    print(f"Total Workflows: {summary['total_workflows']}")
    print(f"Generation Time: {summary['generation_timestamp']}")
    print(f"\n📄 Complete data saved to: demo_data/ directory")
