/// INI Parser for MoonBit
/// 
/// This module provides functionality to parse INI configuration files.
/// 
/// INI files have the following format:
/// - Comments start with ';' or '#'
/// - Sections are enclosed in square brackets [section]
/// - Key-value pairs are separated by '=' or ':'
/// - Whitespace around keys and values is trimmed

///| Represents a parsed INI configuration
pub struct IniConfig {
  sections : Map[String, Map[String, String]]
}

///| Error types that can occur during INI parsing
pub enum ParseError {
  InvalidFormat(String)
  DuplicateKey(String, String) // section, key
} derive(Show, Eq)

///| Helper function to trim whitespace from a string
fn trim_string(s : String) -> String {
  let mut start = 0
  let mut end = s.length()

  // Trim leading whitespace
  while start < end && (s[start] == ' ' || s[start] == '\t' || s[start] == '\r') {
    start = start + 1
  }

  // Trim trailing whitespace
  while end > start &&
        (s[end - 1] == ' ' || s[end - 1] == '\t' || s[end - 1] == '\r') {
    end = end - 1
  }
  if start == 0 && end == s.length() {
    s
  } else {
    s.substring(start~, end~)
  }
}

///| Helper function to check if string starts with given prefix
fn starts_with(s : String, prefix : String) -> Bool {
  if s.length() < prefix.length() {
    return false
  }
  s.substring(start=0, end=prefix.length()) == prefix
}

///| Helper function to check if string ends with given suffix
fn ends_with(s : String, suffix : String) -> Bool {
  if s.length() < suffix.length() {
    return false
  }
  s.substring(start=s.length() - suffix.length(), end=s.length()) == suffix
}

///| Create a new empty INI configuration
pub fn IniConfig::new() -> IniConfig {
  { sections: Map::new() }
}

///| Parse an INI string and return the configuration
pub fn parse(content : String) -> Result[IniConfig, ParseError] {
  let config = IniConfig::new()
  let mut current_section = ""
  let lines = content.split("\n")
  for line_view in lines {
    let line = line_view.to_string()
    let trimmed = trim_string(line)

    // Skip empty lines and comments
    if trimmed.is_empty() ||
      starts_with(trimmed, ";") ||
      starts_with(trimmed, "#") {
      continue
    }

    // Check for section header
    if starts_with(trimmed, "[") && ends_with(trimmed, "]") {
      let section_name = trim_string(
        trimmed.substring(start=1, end=trimmed.length() - 1),
      )
      if section_name.is_empty() {
        return Err(InvalidFormat("Empty section name"))
      }
      current_section = section_name
      if config.sections.contains(current_section) == false {
        config.sections[current_section] = Map::new()
      }
      continue
    }

    // Parse key-value pairs
    let separator_pos = find_separator(trimmed)
    match separator_pos {
      None => return Err(InvalidFormat("Invalid key-value pair: \{trimmed}"))
      Some(pos) => {
        let key = trim_string(trimmed.substring(start=0, end=pos))
        let value = trim_string(
          trimmed.substring(start=pos + 1, end=trimmed.length()),
        )
        if key.is_empty() {
          return Err(InvalidFormat("Empty key in line: \{trimmed}"))
        }

        // Ensure we have a section (default to global if none specified)
        if current_section.is_empty() {
          current_section = "global"
          if config.sections.contains(current_section) == false {
            config.sections[current_section] = Map::new()
          }
        }

        // Check for duplicate keys in the same section
        if config.sections.contains(current_section) == false {
          config.sections[current_section] = Map::new()
        }
        match config.sections.get(current_section) {
          None => {
            // This shouldn't happen since we just ensured it exists
            let new_map = Map::new()
            new_map.set(key, value)
            config.sections[current_section] = new_map
          }
          Some(section_map) => {
            if section_map.contains(key) {
              return Err(DuplicateKey(current_section, key))
            }
            section_map.set(key, value)
          }
        }
      }
    }
  }
  Ok(config)
}

///| Find the position of the first separator ('=' or ':') in a string
fn find_separator(line : String) -> Int? {
  let mut i = 0
  while i < line.length() {
    let char = line[i]
    if char == '=' || char == ':' {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///| Get a value from a specific section and key
pub fn IniConfig::get(
  self : IniConfig,
  section : String,
  key : String,
) -> String? {
  match self.sections.get(section) {
    None => None
    Some(section_map) => section_map.get(key)
  }
}

///| Get a value with a default fallback
pub fn IniConfig::get_or_default(
  self : IniConfig,
  section : String,
  key : String,
  default : String,
) -> String {
  match self.get(section, key) {
    None => default
    Some(value) => value
  }
}

///| Check if a section exists
pub fn IniConfig::has_section(self : IniConfig, section : String) -> Bool {
  self.sections.contains(section)
}

///| Check if a key exists in a section
pub fn IniConfig::has_key(
  self : IniConfig,
  section : String,
  key : String,
) -> Bool {
  match self.sections.get(section) {
    None => false
    Some(section_map) => section_map.contains(key)
  }
}

///| Get all section names
pub fn IniConfig::sections(self : IniConfig) -> Array[String] {
  let result = []
  for entry in self.sections {
    result.push(entry.0)
  }
  result
}

///| Get all keys in a section
pub fn IniConfig::keys(self : IniConfig, section : String) -> Array[String] {
  match self.sections.get(section) {
    None => []
    Some(section_map) => {
      let result = []
      for entry in section_map {
        result.push(entry.0)
      }
      result
    }
  }
}

///| Set a value in the configuration
pub fn IniConfig::set(
  self : IniConfig,
  section : String,
  key : String,
  value : String,
) -> Unit {
  if self.sections.contains(section) == false {
    self.sections[section] = Map::new()
  }
  match self.sections.get(section) {
    None => () // This shouldn't happen
    Some(section_map) => section_map.set(key, value)
  }
}

///| Convert the configuration back to INI format string
pub fn IniConfig::to_string(self : IniConfig) -> String {
  let mut result = ""
  for section_entry in self.sections {
    let section_name = section_entry.0
    let section_map = section_entry.1
    if section_name != "global" {
      result = result + "[\{section_name}]\n"
    }
    for key_entry in section_map {
      let key = key_entry.0
      let value = key_entry.1
      result = result + "\{key}=\{value}\n"
    }
    result = result + "\n"
  }
  trim_string(result)
}
