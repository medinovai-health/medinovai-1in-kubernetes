# -----------------------------------------------------------------------------
# MedinovAI Production Environment Configuration
# -----------------------------------------------------------------------------

environment = "production"
project     = "medinovai"
region      = "us-east-1"
domain_name = ""

min_nodes = 3
max_nodes = 20

db_instance_class = "db.r6g.xlarge"
redis_node_type   = "cache.r6g.xlarge"

multi_az            = true
create_read_replica = true
backup_retention    = 30

enable_gpu_nodes = true

tags = {
  Environment = "production"
  ManagedBy   = "terraform"
}
