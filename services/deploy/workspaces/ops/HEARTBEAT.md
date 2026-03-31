# Ops Agent Heartbeat

## Schedule
Every 30 minutes (configurable in deploy.json5)

## Heartbeat Checklist
- [ ] Review last 30 min of events in my domain
- [ ] Check for unresolved items from previous heartbeat
- [ ] Scan for anomalies or threshold breaches
- [ ] Update state/telemetry/ with current metrics
- [ ] Route any waiting tasks to appropriate skill

## Output
Heartbeat summary posted to: `state/telemetry/heartbeat-$(date +%Y%m%d-%H%M).json`
