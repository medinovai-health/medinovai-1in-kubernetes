# -----------------------------------------------------------------------------
# MedinovAI Staging Environment Configuration
# -----------------------------------------------------------------------------

environment = "staging"
project     = "medinovai"
region      = "us-east-1"
domain_name = ""

min_nodes = 2
max_nodes = 5

db_instance_class = "db.r6g.large"
redis_node_type   = "cache.r6g.large"

multi_az            = false
create_read_replica = false
backup_retention    = 7

enable_gpu_nodes = true

tags = {
  Environment = "staging"
  ManagedBy   = "terraform"
}
