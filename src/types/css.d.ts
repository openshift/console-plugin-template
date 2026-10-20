// CSS Modules are imported with a default export of the local class names.
// Plain CSS files are intentionally not declared: plugins should use CSS
// Modules (*.module.css) so that class names are scoped automatically.
declare module '*.module.css' {
  const classes: Readonly<Record<string, string>>;
  export default classes;
}
