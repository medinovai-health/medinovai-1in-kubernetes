#!/usr/bin/env python3
"""
MedinovAI UI Agent Registry
Configurable chatbot system with adaptive learning and 3-step guidance
"""

import os
import yaml
import logging
import asyncio
from typing import Dict, List, Optional, Any
from datetime import datetime
import json
import httpx
import redis
from dataclasses import dataclass
from enum import Enum

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AgentType(Enum):
    PATIENT_PORTAL = "patient_portal"
    DOCTOR_PORTAL = "doctor_portal"
    ADMIN_PORTAL = "admin_portal"
    ANALYTICS = "analytics"
    CLINICAL = "clinical"

@dataclass
class AgentConfig:
    name: str
    model_name: str
    temperature: float
    max_tokens: int
    top_p: float
    specialization: str
    learning_enabled: bool
    performance_threshold: float

@dataclass
class AgentResponse:
    primary_response: str
    next_steps: List[str]
    learning_note: str
    confidence_score: float
    model_used: str
    timestamp: datetime

class UIAgentRegistry:
    """
    Registry for managing UI agents with configurable models and adaptive learning
    """
    
    def __init__(self):
        self.agents: Dict[AgentType, AgentConfig] = {}
        self.learning_data: Dict[AgentType, List[Dict]] = {}
        self.performance_metrics: Dict[AgentType, Dict] = {}
        self.redis_client = redis.Redis(host='redis', port=6379, db=0)
        self.ollama_base_url = os.getenv("OLLAMA_BASE_URL", "http://ollama:11434")
        
        # Load configurations
        self.load_agent_configurations()
        self.initialize_agents()
    
    def load_agent_configurations(self):
        """Load agent configurations from YAML files"""
        try:
            # Load model configurations
            with open('config/models.yaml', 'r') as f:
                model_configs = yaml.safe_load(f)
            
            # Load training configurations
            with open('config/training.yaml', 'r') as f:
                training_configs = yaml.safe_load(f)
            
            # Create agent configurations
            for agent_type, config in model_configs['models'].items():
                agent_enum = AgentType(agent_type)
                self.agents[agent_enum] = AgentConfig(
                    name=config['name'],
                    model_name=config['name'],
                    temperature=config['parameters']['temperature'],
                    max_tokens=config['parameters']['max_tokens'],
                    top_p=config['parameters']['top_p'],
                    specialization=config['specialization'],
                    learning_enabled=training_configs['training']['continuous_learning'],
                    performance_threshold=training_configs['training']['performance_threshold']
                )
            
            logger.info(f"Loaded configurations for {len(self.agents)} agents")
            
        except Exception as e:
            logger.error(f"Error loading configurations: {e}")
            # Fallback to default configurations
            self.create_default_configurations()
    
    def create_default_configurations(self):
        """Create default agent configurations"""
        default_configs = {
            AgentType.PATIENT_PORTAL: AgentConfig(
                name="Patient Portal Agent",
                model_name="qwen2.5:3b",
                temperature=0.7,
                max_tokens=512,
                top_p=0.9,
                specialization="patient_care",
                learning_enabled=True,
                performance_threshold=0.85
            ),
            AgentType.DOCTOR_PORTAL: AgentConfig(
                name="Doctor Portal Agent",
                model_name="meditron:7b",
                temperature=0.5,
                max_tokens=1024,
                top_p=0.8,
                specialization="clinical_decision",
                learning_enabled=True,
                performance_threshold=0.90
            ),
            AgentType.ADMIN_PORTAL: AgentConfig(
                name="Admin Portal Agent",
                model_name="deepseek-coder:7b",
                temperature=0.6,
                max_tokens=768,
                top_p=0.85,
                specialization="administrative",
                learning_enabled=True,
                performance_threshold=0.85
            ),
            AgentType.ANALYTICS: AgentConfig(
                name="Analytics Agent",
                model_name="llama3.1:8b",
                temperature=0.4,
                max_tokens=1024,
                top_p=0.8,
                specialization="data_analysis",
                learning_enabled=True,
                performance_threshold=0.88
            ),
            AgentType.CLINICAL: AgentConfig(
                name="Clinical Agent",
                model_name="medinovai-clinical:latest",
                temperature=0.3,
                max_tokens=1536,
                top_p=0.75,
                specialization="clinical_workflows",
                learning_enabled=True,
                performance_threshold=0.95
            )
        }
        
        self.agents = default_configs
        logger.info("Created default agent configurations")
    
    def initialize_agents(self):
        """Initialize all agents and their learning systems"""
        for agent_type, config in self.agents.items():
            # Initialize learning data storage
            self.learning_data[agent_type] = []
            
            # Initialize performance metrics
            self.performance_metrics[agent_type] = {
                'total_interactions': 0,
                'successful_interactions': 0,
                'average_confidence': 0.0,
                'user_satisfaction': 0.0,
                'learning_progress': 0.0
            }
            
            logger.info(f"Initialized {config.name} with model {config.model_name}")
    
    async def get_agent_response(self, agent_type: AgentType, user_query: str, 
                                context: Optional[Dict] = None) -> AgentResponse:
        """
        Get response from specified agent with 3-step guidance
        """
        try:
            config = self.agents[agent_type]
            
            # Prepare the prompt with context and specialization
            system_prompt = self._create_system_prompt(config, context)
            
            # Call the model
            response_text = await self._call_model(config, system_prompt, user_query)
            
            # Parse response and create structured output
            agent_response = self._parse_response(response_text, config)
            
            # Log interaction for learning
            await self._log_interaction(agent_type, user_query, agent_response, context)
            
            # Update performance metrics
            self._update_performance_metrics(agent_type, agent_response)
            
            return agent_response
            
        except Exception as e:
            logger.error(f"Error getting agent response: {e}")
            return self._create_error_response(agent_type, str(e))
    
    def _create_system_prompt(self, config: AgentConfig, context: Optional[Dict]) -> str:
        """Create system prompt based on agent specialization"""
        base_prompt = f"""You are {config.name}, a specialized AI assistant for {config.specialization}.

Your responses must follow this exact format:
1. PRIMARY RESPONSE: Direct answer to the user's query
2. NEXT 3 STEPS: Provide exactly 3 actionable next steps
3. LEARNING NOTE: What you learned from this interaction

Specialization: {config.specialization}
Model: {config.model_name}
Temperature: {config.temperature}
Max Tokens: {config.max_tokens}

Context: {context or 'No additional context provided'}

Remember to:
- Be helpful and accurate
- Provide actionable next steps
- Learn from each interaction
- Maintain professional tone
- Follow healthcare compliance guidelines"""
        
        return base_prompt
    
    async def _call_model(self, config: AgentConfig, system_prompt: str, user_query: str) -> str:
        """Call the Ollama model with the specified configuration"""
        try:
            async with httpx.AsyncClient() as client:
                payload = {
                    "model": config.model_name,
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_query}
                    ],
                    "options": {
                        "temperature": config.temperature,
                        "num_predict": config.max_tokens,
                        "top_p": config.top_p
                    }
                }
                
                response = await client.post(
                    f"{self.ollama_base_url}/api/chat",
                    json=payload,
                    timeout=30.0
                )
                
                if response.status_code == 200:
                    result = response.json()
                    return result.get("message", {}).get("content", "No response generated")
                else:
                    logger.error(f"Model call failed: {response.status_code}")
                    return "I apologize, but I'm experiencing technical difficulties. Please try again."
                    
        except Exception as e:
            logger.error(f"Error calling model: {e}")
            return "I apologize, but I'm experiencing technical difficulties. Please try again."
    
    def _parse_response(self, response_text: str, config: AgentConfig) -> AgentResponse:
        """Parse model response into structured format"""
        try:
            # Split response into components
            lines = response_text.strip().split('\n')
            
            primary_response = ""
            next_steps = []
            learning_note = ""
            
            current_section = None
            
            for line in lines:
                line = line.strip()
                if not line:
                    continue
                
                if "PRIMARY RESPONSE:" in line.upper():
                    current_section = "primary"
                    primary_response = line.replace("PRIMARY RESPONSE:", "").strip()
                elif "NEXT 3 STEPS:" in line.upper() or "NEXT STEPS:" in line.upper():
                    current_section = "steps"
                elif "LEARNING NOTE:" in line.upper():
                    current_section = "learning"
                    learning_note = line.replace("LEARNING NOTE:", "").strip()
                elif current_section == "primary" and line:
                    primary_response += " " + line
                elif current_section == "steps" and line:
                    # Extract steps (numbered or bulleted)
                    if line.startswith(("1.", "2.", "3.", "-", "*")):
                        step = line.lstrip("123.-* ").strip()
                        if step and len(next_steps) < 3:
                            next_steps.append(step)
                elif current_section == "learning" and line:
                    learning_note += " " + line
            
            # Ensure we have at least 3 steps
            while len(next_steps) < 3:
                next_steps.append("Please provide more specific guidance for this step.")
            
            # Calculate confidence score based on response quality
            confidence_score = self._calculate_confidence_score(primary_response, next_steps)
            
            return AgentResponse(
                primary_response=primary_response or "I understand your query. Let me help you with that.",
                next_steps=next_steps[:3],
                learning_note=learning_note or "No specific learning noted for this interaction.",
                confidence_score=confidence_score,
                model_used=config.model_name,
                timestamp=datetime.utcnow()
            )
            
        except Exception as e:
            logger.error(f"Error parsing response: {e}")
            return self._create_fallback_response(config)
    
    def _calculate_confidence_score(self, primary_response: str, next_steps: List[str]) -> float:
        """Calculate confidence score based on response quality"""
        score = 0.5  # Base score
        
        # Check response length and quality
        if len(primary_response) > 50:
            score += 0.2
        
        # Check if we have 3 steps
        if len(next_steps) == 3:
            score += 0.2
        
        # Check step quality
        for step in next_steps:
            if len(step) > 20:  # Meaningful steps
                score += 0.1
        
        return min(score, 1.0)
    
    def _create_fallback_response(self, config: AgentConfig) -> AgentResponse:
        """Create fallback response when parsing fails"""
        return AgentResponse(
            primary_response="I understand your query. Let me help you with that.",
            next_steps=[
                "Please rephrase your question for better assistance",
                "Contact support if you need immediate help",
                "Try using more specific terms related to your query"
            ],
            learning_note="Response parsing failed, using fallback format",
            confidence_score=0.3,
            model_used=config.model_name,
            timestamp=datetime.utcnow()
        )
    
    def _create_error_response(self, agent_type: AgentType, error_message: str) -> AgentResponse:
        """Create error response"""
        config = self.agents[agent_type]
        return AgentResponse(
            primary_response="I apologize, but I'm experiencing technical difficulties.",
            next_steps=[
                "Please try your request again in a moment",
                "Contact technical support if the issue persists",
                "Check your internet connection and try again"
            ],
            learning_note=f"Error occurred: {error_message}",
            confidence_score=0.0,
            model_used=config.model_name,
            timestamp=datetime.utcnow()
        )
    
    async def _log_interaction(self, agent_type: AgentType, user_query: str, 
                             response: AgentResponse, context: Optional[Dict]):
        """Log interaction for learning purposes"""
        try:
            interaction_data = {
                'timestamp': response.timestamp.isoformat(),
                'user_query': user_query,
                'response': {
                    'primary_response': response.primary_response,
                    'next_steps': response.next_steps,
                    'learning_note': response.learning_note,
                    'confidence_score': response.confidence_score
                },
                'context': context,
                'model_used': response.model_used
            }
            
            # Store in learning data
            self.learning_data[agent_type].append(interaction_data)
            
            # Store in Redis for persistence
            redis_key = f"agent_interactions:{agent_type.value}:{response.timestamp.strftime('%Y%m%d')}"
            await self.redis_client.lpush(redis_key, json.dumps(interaction_data))
            
            # Keep only last 1000 interactions in memory
            if len(self.learning_data[agent_type]) > 1000:
                self.learning_data[agent_type] = self.learning_data[agent_type][-1000:]
            
        except Exception as e:
            logger.error(f"Error logging interaction: {e}")
    
    def _update_performance_metrics(self, agent_type: AgentType, response: AgentResponse):
        """Update performance metrics for the agent"""
        try:
            metrics = self.performance_metrics[agent_type]
            metrics['total_interactions'] += 1
            
            if response.confidence_score > 0.5:
                metrics['successful_interactions'] += 1
            
            # Update average confidence
            total_interactions = metrics['total_interactions']
            current_avg = metrics['average_confidence']
            metrics['average_confidence'] = ((current_avg * (total_interactions - 1)) + response.confidence_score) / total_interactions
            
            # Calculate success rate
            success_rate = metrics['successful_interactions'] / total_interactions
            metrics['learning_progress'] = success_rate
            
        except Exception as e:
            logger.error(f"Error updating performance metrics: {e}")
    
    def get_agent_performance(self, agent_type: AgentType) -> Dict:
        """Get performance metrics for an agent"""
        return self.performance_metrics.get(agent_type, {})
    
    def get_all_agent_performance(self) -> Dict:
        """Get performance metrics for all agents"""
        return {
            agent_type.value: self.get_agent_performance(agent_type)
            for agent_type in AgentType
        }
    
    def update_agent_config(self, agent_type: AgentType, new_config: AgentConfig):
        """Update agent configuration"""
        self.agents[agent_type] = new_config
        logger.info(f"Updated configuration for {agent_type.value}")
    
    def get_available_models(self) -> List[str]:
        """Get list of available models"""
        try:
            # This would typically call Ollama API to get available models
            # For now, return the models we know are available
            return [
                "qwen2.5:3b",
                "meditron:7b", 
                "deepseek-coder:7b",
                "llama3.1:8b",
                "medinovai-clinical:latest"
            ]
        except Exception as e:
            logger.error(f"Error getting available models: {e}")
            return []

# Global registry instance
agent_registry = UIAgentRegistry()

# Convenience functions for easy access
async def get_patient_agent_response(query: str, context: Optional[Dict] = None) -> AgentResponse:
    """Get response from patient portal agent"""
    return await agent_registry.get_agent_response(AgentType.PATIENT_PORTAL, query, context)

async def get_doctor_agent_response(query: str, context: Optional[Dict] = None) -> AgentResponse:
    """Get response from doctor portal agent"""
    return await agent_registry.get_agent_response(AgentType.DOCTOR_PORTAL, query, context)

async def get_admin_agent_response(query: str, context: Optional[Dict] = None) -> AgentResponse:
    """Get response from admin portal agent"""
    return await agent_registry.get_agent_response(AgentType.ADMIN_PORTAL, query, context)

async def get_analytics_agent_response(query: str, context: Optional[Dict] = None) -> AgentResponse:
    """Get response from analytics agent"""
    return await agent_registry.get_agent_response(AgentType.ANALYTICS, query, context)

async def get_clinical_agent_response(query: str, context: Optional[Dict] = None) -> AgentResponse:
    """Get response from clinical agent"""
    return await agent_registry.get_agent_response(AgentType.CLINICAL, query, context)

if __name__ == "__main__":
    # Test the registry
    async def test_registry():
        print("Testing UI Agent Registry...")
        
        # Test patient portal agent
        response = await get_patient_agent_response("I need to schedule an appointment")
        print(f"Patient Agent Response: {response.primary_response}")
        print(f"Next Steps: {response.next_steps}")
        print(f"Learning Note: {response.learning_note}")
        
        # Test doctor portal agent
        response = await get_doctor_agent_response("What are the latest treatment guidelines for diabetes?")
        print(f"Doctor Agent Response: {response.primary_response}")
        print(f"Next Steps: {response.next_steps}")
        print(f"Learning Note: {response.learning_note}")
        
        # Get performance metrics
        performance = agent_registry.get_all_agent_performance()
        print(f"Performance Metrics: {performance}")
    
    asyncio.run(test_registry())







