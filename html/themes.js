window.ThemeHelpers = {
  applyTheme(theme) {
    if (!theme) return;
    document.documentElement.style.setProperty('--accent', theme.accent || '#3b82f6');
    document.documentElement.style.setProperty('--accent-soft', theme.accentSoft || 'rgba(59,130,246,.16)');
    document.documentElement.style.setProperty('--panel', theme.panel || '#10151d');
    document.documentElement.style.setProperty('--panel-2', theme.panel2 || '#151b24');
    document.documentElement.style.setProperty('--text', theme.text || '#f3f4f6');
    document.documentElement.style.setProperty('--muted', theme.muted || '#9ca3af');
  }
};
