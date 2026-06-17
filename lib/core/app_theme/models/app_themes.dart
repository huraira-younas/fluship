enum AppThemes {
  catppuccinMocha('catppuccin_mocha'),
  solarizedDark('solarized_dark'),
  tokyoNight('tokyo_night'),
  oneDark('one_dark'),
  gruvbox('gruvbox'),
  dracula('dracula'),
  nord('nord');

  const AppThemes(this.key);

  final String key;

  static const defaultTheme = nord;
}
