# A dedicated store keeps protection active when the general cache is NullStore.
# FileStore shares counters between workers on ONE filesystem, not across instances.
# Production must verify its topology and supply a shared store / edge protection
# before claiming deployment-wide protection. See docs/security/security_audit_128.md.
Rails.application.config.x.authentication_rate_limit_store =
  if Rails.env.test?
    ActiveSupport::Cache::MemoryStore.new
  else
    ActiveSupport::Cache::FileStore.new(Rails.root.join("tmp/authentication_rate_limits"))
  end
