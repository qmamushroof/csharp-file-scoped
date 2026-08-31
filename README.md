This pearl script
- converts C# block-scoped namespaces (`namespace X { ... }`) to file-scoped (`namespace X;`)
- removes UTF-8 BOM from affected files
- unindents all namespace body content by 4 spaces (one indent level)
- handles `\r\n` (Windows) line endings correctly
- preserves original line ending style throughout conversion
- adds a blank line after the `namespace X;` declaration
- skips files already using file-scoped namespaces (idempotent)
- works recursively on all `.cs` files in given directories
- uses brace-depth tracking to correctly identify the namespace closing `}` (supports multiple types per file)
