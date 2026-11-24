enum AppThemes(final String key, final String displayName) {
  catppuccinMocha('catppuccin_mocha', 'Catppuccin Mocha'),
  solarizedDark('solarized_dark', 'Solarized Dark'),
  tokyoNight('tokyo_night', 'Tokyo Night'),
  instagram('instagram', 'Instagram'),
  whatsapp('whatsapp', 'WhatsApp'),
  oneDark('one_dark', 'One Dark'),
  gruvbox('gruvbox', 'Gruvbox'),
  dracula('dracula', 'Dracula'),
  crimson('crimson', 'Crimson'),
  github('github', 'GitHub'),
  nord('nord', 'Nord');

  static const defaultTheme = nord;

  static AppThemes? fromKey(String key) {
    if (key.isEmpty) return null;

    for (final theme in AppThemes.values) {
      if (theme.key == key) return theme;
    }

    return null;
  }
}
