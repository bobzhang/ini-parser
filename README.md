# INI Parser for MoonBit

A comprehensive INI configuration file parser written in MoonBit with extensive test coverage.

## Features

- **Complete INI parsing**: Supports sections, key-value pairs, and comments
- **Flexible separators**: Handles both `=` and `:` as key-value separators
- **Comment support**: Skips lines starting with `#` or `;`
- **Whitespace handling**: Automatically trims whitespace around sections, keys, and values
- **Global values**: Keys without sections are stored in a "global" section
- **Error handling**: Comprehensive error reporting for malformed files
- **Round-trip support**: Convert parsed config back to INI format
- **High test coverage**: 92% line coverage with snapshot tests

## Usage

```moonbit
// Parse INI content
let ini_content = #|[database]
                   #|host=localhost
                   #|port=5432
                   #|
                   #|[server]
                   #|debug=true
                   #|

match @lib.parse(ini_content) {
  Err(e) => println("Parse error: \{e}")
  Ok(config) => {
    // Access values
    let host = config.get("database", "host") // Some("localhost")
    let port = config.get_or_default("database", "port", "3306")
    
    // Check existence 
    let has_db = config.has_section("database") // true
    let has_ssl = config.has_key("database", "ssl") // false
    
    // Modify configuration
    config.set("cache", "ttl", "3600")
    
    // Convert back to string
    let ini_string = config.to_string()
  }
}
```

## Supported INI Format

```ini
# Comments start with # or ;
global_setting=value

[section_name]
key1=value1
key2 : value2   # Both = and : separators supported
empty_value=
spaces = are trimmed automatically

; Another comment type
[another_section]
number=42
boolean=true
```

## API Reference

### Types

- `IniConfig` - Main configuration container
- `ParseError` - Error type for parsing failures
  - `InvalidFormat(String)` - Malformed INI content
  - `DuplicateKey(String, String)` - Duplicate key in same section

### Functions

- `parse(content: String) -> Result[IniConfig, ParseError]` - Parse INI string
- `IniConfig::new() -> IniConfig` - Create empty configuration
- `get(section: String, key: String) -> Option[String]` - Get value
- `get_or_default(section: String, key: String, default: String) -> String` - Get with fallback
- `has_section(section: String) -> Bool` - Check section existence
- `has_key(section: String, key: String) -> Bool` - Check key existence
- `sections() -> Array[String]` - List all section names
- `keys(section: String) -> Array[String]` - List keys in section
- `set(section: String, key: String, value: String) -> Unit` - Set value
- `to_string() -> String` - Convert to INI format

## Tests

The parser includes 15 comprehensive test cases covering:

- Basic parsing with sections and key-value pairs
- Comment handling (both `#` and `;`)
- Mixed separators (`=` and `:`)
- Global values (keys without sections)
- Empty values and whitespace handling
- Error conditions (malformed syntax, duplicate keys, etc.)
- Configuration access and modification methods
- Real-world configuration examples

Run tests with:
```bash
moon test
```

## Test Coverage

Current test coverage: **92%** (93/101 lines)

Check coverage with:
```bash
moon test --coverage
```