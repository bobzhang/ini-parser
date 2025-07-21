///|
fn main {
  // Example usage of the INI parser
  let sample_ini =
    #|# Sample configuration file
    #|app_name=INI Parser Demo  
    #|debug=true
    #|
    #|[database]
    #|host=localhost
    #|port=5432
    #|name=demo_db
    #|
    #|[server]
    #|port=8080
    #|threads=4
    #|
  println("=== INI Parser Demo ===")
  println("Parsing the following INI content:")
  println(sample_ini)
  println("")
  match @lib.parse(sample_ini) {
    Err(e) => println("Parse error: \{e}")
    Ok(config) => {
      println("Parsed successfully!")
      println("")

      // Demonstrate accessing values
      println("Global settings:")
      println(
        "  app_name: " + config.get_or_default("global", "app_name", "N/A"),
      )
      println("  debug: " + config.get_or_default("global", "debug", "false"))
      println("")
      println("Database configuration:")
      println("  host: " + config.get_or_default("database", "host", "N/A"))
      println("  port: " + config.get_or_default("database", "port", "N/A"))
      println("  name: " + config.get_or_default("database", "name", "N/A"))
      println("")
      println("Server configuration:")
      println("  port: " + config.get_or_default("server", "port", "N/A"))
      println("  threads: " + config.get_or_default("server", "threads", "N/A"))
      println("")
      println("Available sections:")
      let sections = config.sections()
      for section in sections {
        println("  - " + section)
      }
      println("")
      println("Keys in 'database' section:")
      let db_keys = config.keys("database")
      for key in db_keys {
        println("  - " + key)
      }
    }
  }
}
