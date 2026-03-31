# -----------------------------------------------------------------------------
# MedinovAI Dev Environment Configuration
# -----------------------------------------------------------------------------

environment = "dev"
project     = "medinovai"
region      = "us-east-1"
domain_name = ""

min_nodes = 1
max_nodes = 3

db_instance_class = "db.t3.medium"
redis_node_type   = "cache.t3.micro"

multi_az            = false
create_read_replica = false
backup_retention    = 1

enable_gpu_nodes = false

tags = {
  Environment = "dev"
  ManagedBy   = "terraform"
}
