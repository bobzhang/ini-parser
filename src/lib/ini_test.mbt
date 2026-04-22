///| Comprehensive tests for the INI parser
test "basic ini parsing" {
  let content =
    #|[database]
    #|host=localhost
    #|port=5432
    #|name=mydb
    #|
    #|[server]
    #|port=8080
    #|debug=true
    #|
  match parse(content) {
    Err(e) => fail("Failed to parse: \{e}")
    Ok(config) => {
      // Test database section
      assert_eq(config.get("database", "host"), Some("localhost"))
      assert_eq(config.get("database", "port"), Some("5432"))
      assert_eq(config.get("database", "name"), Some("mydb"))

      // Test server section
      assert_eq(config.get("server", "port"), Some("8080"))
      assert_eq(config.get("server", "debug"), Some("true"))

      // Show a snapshot of what was parsed
      inspect(config.get("database", "host"), content="Some(\"localhost\")")
      inspect(config.get("server", "debug"), content="Some(\"true\")")
    }
  }
}

///|
test "ini with comments" {
  let content =
    #|# This is a comment
    #|; This is also a comment
    #|[section1]
    #|key1=value1  ; inline comment
    #|# Another comment
    #|key2=value2
    #|
  match parse(content) {
    Err(e) => fail("Failed to parse: \{e}")
    Ok(config) => {
      inspect(
        config.get("section1", "key1"),
        content="Some(\"value1  ; inline comment\")",
      )
      inspect(config.get("section1", "key2"), content="Some(\"value2\")")
    }
  }
}

///|
test "ini with colon separator" {
  let content =
    #|[config]
    #|database_host: localhost
    #|database_port: 5432
    #|api_key=secret123
    #|timeout : 30
    #|
  match parse(content) {
    Err(e) => fail("Failed to parse: \{e}")
    Ok(config) => {
      inspect(
        config.get("config", "database_host"),
        content="Some(\"localhost\")",
      )
      inspect(config.get("config", "database_port"), content="Some(\"5432\")")
      inspect(config.get("config", "api_key"), content="Some(\"secret123\")")
      inspect(config.get("config", "timeout"), content="Some(\"30\")")
    }
  }
}

///|
test "ini without section headers (global)" {
  let content =
    #|global_var=value
    #|another_var=another_value
    #|number=42
    #|
  match parse(content) {
    Err(e) => fail("Failed to parse: \{e}")
    Ok(config) => {
      inspect(config.get("global", "global_var"), content="Some(\"value\")")
      inspect(
        config.get("global", "another_var"),
        content="Some(\"another_value\")",
      )
      inspect(config.get("global", "number"), content="Some(\"42\")")
    }
  }
}

///|
test "mixed global and sectioned config" {
  let content =
    #|global_setting=true
    #|
    #|[database]
    #|host=db.example.com
    #|
    #|[cache]
    #|ttl=3600
    #|
  match parse(content) {
    Err(e) => fail("Failed to parse: \{e}")
    Ok(config) => {
      inspect(config.get("global", "global_setting"), content="Some(\"true\")")
      inspect(
        config.get("database", "host"),
        content="Some(\"db.example.com\")",
      )
      inspect(config.get("cache", "ttl"), content="Some(\"3600\")")
    }
  }
}

///|
test "empty values" {
  let content =
    #|[test]
    #|empty_value=
    #|another_key=not_empty
    #|spaces_only=    
    #|
  match parse(content) {
    Err(e) => fail("Failed to parse: \{e}")
    Ok(config) => {
      inspect(config.get("test", "empty_value"), content="Some(\"\")")
      inspect(config.get("test", "another_key"), content="Some(\"not_empty\")")
      inspect(config.get("test", "spaces_only"), content="Some(\"\")")
    }
  }
}

///|
test "whitespace handling" {
  let content =
    #|  [ section_with_spaces ]  
    #|  key_with_spaces  =  value_with_spaces  
    #|another_key=value_without_spaces
    #|
  match parse(content) {
    Err(e) => fail("Failed to parse: \{e}")
    Ok(config) => {
      inspect(
        config.get("section_with_spaces", "key_with_spaces"),
        content="Some(\"value_with_spaces\")",
      )
      inspect(
        config.get("section_with_spaces", "another_key"),
        content="Some(\"value_without_spaces\")",
      )
    }
  }
}

///|
test "error cases - invalid format" {
  let content =
    #|[valid_section]
    #|valid_key=valid_value
    #|invalid_line_without_separator
    #|
  match parse(content) {
    Ok(_) => fail("Expected parse error but got success")
    Err(InvalidFormat(msg)) =>
      assert_eq(msg, "Invalid key-value pair: invalid_line_without_separator")
    Err(e) => fail("Unexpected error type: \{e}")
  }
}

///|
test "error cases - empty section name" {
  let content =
    #|[]
    #|key=value
    #|
  match parse(content) {
    Ok(_) => fail("Expected parse error but got success")
    Err(InvalidFormat(msg)) => assert_eq(msg, "Empty section name")
    Err(e) => fail("Unexpected error type: \{e}")
  }
}

///|
test "error cases - duplicate key" {
  let content =
    #|[section]
    #|key=value1
    #|key=value2
    #|
  match parse(content) {
    Ok(_) => fail("Expected parse error but got success")
    Err(DuplicateKey(section, key)) => {
      assert_eq(section, "section")
      assert_eq(key, "key")
    }
    Err(e) => fail("Unexpected error type: \{e}")
  }
}

///|
test "error cases - empty key" {
  let content =
    #|[section]
    #|=value_without_key
    #|
  match parse(content) {
    Ok(_) => fail("Expected parse error but got success")
    Err(InvalidFormat(msg)) =>
      assert_eq(msg, "Empty key in line: =value_without_key")
    Err(e) => fail("Unexpected error type: \{e}")
  }
}

///|
test "config access methods" {
  let content =
    #|[database]
    #|host=localhost
    #|port=5432
    #|
    #|[server] 
    #|port=8080
    #|
  match parse(content) {
    Err(_) => fail("Failed to parse valid INI")
    Ok(config) => {
      // Test get method
      inspect(config.get("database", "host"), content="Some(\"localhost\")")
      inspect(config.get("database", "nonexistent"), content="None")
      inspect(config.get("nonexistent", "key"), content="None")

      // Test get_or_default method
      inspect(
        config.get_or_default("database", "host", "default"),
        content="localhost",
      )
      inspect(
        config.get_or_default("database", "nonexistent", "default"),
        content="default",
      )

      // Test has_section method
      inspect(config.has_section("database"), content="true")
      inspect(config.has_section("nonexistent"), content="false")

      // Test has_key method
      inspect(config.has_key("database", "host"), content="true")
      inspect(config.has_key("database", "nonexistent"), content="false")
      inspect(config.has_key("nonexistent", "key"), content="false")

      // Test sections method
      let sections = config.sections()
      sections.sort()
      inspect(
        sections,
        content=(
          #|["server", "database"]
        ),
      )

      // Test keys method
      let db_keys = config.keys("database")
      db_keys.sort()
      inspect(db_keys, content="[\"host\", \"port\"]")
      inspect(config.keys("nonexistent"), content="[]")
    }
  }
}

///|
test "config modification methods" {
  let config = IniConfig::new()

  // Test set method
  config.set("section1", "key1", "value1")
  config.set("section1", "key2", "value2")
  config.set("section2", "key1", "value3")
  inspect(config.get("section1", "key1"), content="Some(\"value1\")")
  inspect(config.get("section1", "key2"), content="Some(\"value2\")")
  inspect(config.get("section2", "key1"), content="Some(\"value3\")")
  let sections = config.sections()
  sections.sort()
  inspect(sections, content="[\"section1\", \"section2\"]")
}

///|
test "to_string conversion" {
  let config = IniConfig::new()
  config.set("database", "host", "localhost")
  config.set("database", "port", "5432")
  config.set("server", "port", "8080")
  config.set("global", "debug", "true")
  let ini_string = config.to_string()
  inspect(
    ini_string,
    content=(
      #|[database]
      #|host=localhost
      #|port=5432
      #|
      #|[server]
      #|port=8080
      #|
      #|debug=true
      #|
      #|
    ),
  )
}

///|
test "real world example - application config" {
  let content =
    #|# Application Configuration
    #|
    #|# Global settings
    #|app_name=MyApplication
    #|version=1.2.3
    #|
    #|[database]
    #|# Database connection settings
    #|driver=postgresql
    #|host=db.example.com
    #|port=5432
    #|database=app_production
    #|username=app_user
    #|password=secret123
    #|pool_size=10
    #|
    #|[logging]
    #|level=INFO
    #|file=/var/log/app.log
    #|max_size=100MB
    #|
    #|[cache]
    #|type=redis
    #|host=cache.example.com:6379
    #|ttl=3600
    #|
    #|[api]
    #|rate_limit=1000
    #|timeout=30
    #|cors_enabled=true
    #|
  match parse(content) {
    Err(e) => fail("Failed to parse real world config: \{e}")
    Ok(config) => {
      // Verify global settings
      inspect(
        config.get("global", "app_name"),
        content="Some(\"MyApplication\")",
      )
      inspect(config.get("global", "version"), content="Some(\"1.2.3\")")

      // Verify database config
      inspect(config.get("database", "driver"), content="Some(\"postgresql\")")
      inspect(
        config.get("database", "host"),
        content="Some(\"db.example.com\")",
      )
      inspect(config.get("database", "port"), content="Some(\"5432\")")

      // Verify other sections exist
      inspect(config.has_section("logging"), content="true")
      inspect(config.has_section("cache"), content="true")
      inspect(config.has_section("api"), content="true")

      // Test getting boolean-like values
      inspect(
        config.get_or_default("api", "cors_enabled", "false"),
        content="true",
      )
      inspect(
        config.get_or_default("api", "nonexistent", "false"),
        content="false",
      )
    }
  }
}

///| Regression test for the starts_with / ends_with rewrite.
///
/// MoonBit slice syntax validates UTF-16 surrogate boundaries, so the
/// previous s[0:prefix.length()].to_string() rewrite would abort on input
/// whose first or last character was outside the BMP (e.g. an emoji).
/// Using String::has_prefix / has_suffix delegates to a safe comparison.
test "parse keys with non-BMP (emoji) characters at line boundaries" {
  let content =
    #|[section]
    #|🔑=value with emoji key
    #|key=value ending with 🎯
    #|
  match parse(content) {
    Ok(cfg) => {
      inspect(cfg.get("section", "🔑"), content="Some(\"value with emoji key\")")
      inspect(
        cfg.get("section", "key"),
        content="Some(\"value ending with 🎯\")",
      )
    }
    Err(_) => fail("expected parse to succeed on non-BMP input")
  }
}
