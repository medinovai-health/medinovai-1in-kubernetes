# Apple Liquid Glass UI — medinovai-1in-kubernetes
# Build: 20260413.2200.001 | © 2026 DescartesBio / MedinovAI Health.

GLASS_TOKENS = {
    "--glass-blur": "20px",
    "--glass-opacity": "0.15",
    "--glass-border": "rgba(255,255,255,0.2)",
    "--glass-shadow": "0 8px 32px rgba(0,0,0,0.37)",
    "--glass-bg": "rgba(255,255,255,0.08)",
}

SUPPORTED_LANGUAGES = ["en", "es", "fr", "de", "zh", "ar"]

OMNOBOX_CONFIG = {
    "placeholder": "Search or command...",
    "shortcuts": ["Cmd+K", "Ctrl+K"],
    "module": "medinovai-1in-kubernetes",
}

DASHBOARD_COMPONENTS = [
    "DashboardPage",
    "OmnoBox",
    "BentoGrid",
    "NarrationPanel",
    "GlassCard",
    "MetricsWidget",
]
