[![Twitter Follow](https://img.shields.io/twitter/follow/SpeckleSystems?style=social)](https://twitter.com/SpeckleSystems) [![Discourse users](https://img.shields.io/discourse/users?server=https%3A%2F%2Fdiscourse.speckle.works&style=flat-square)](https://discourse.speckle.works)
[![Slack Invite](https://img.shields.io/badge/-slack-grey?style=flat-square&logo=slack)](https://speckle-works.slack.com/join/shared_invite/enQtNjY5Mzk2NTYxNTA4LTU4MWI5ZjdhMjFmMTIxZDIzOTAzMzRmMTZhY2QxMmM1ZjVmNzJmZGMzMDVlZmJjYWQxYWU0MWJkYmY3N2JjNGI) [![website](https://img.shields.io/badge/www-speckle.systems-royalblue?style=flat-square)](https://speckle.systems)

# SQLite3 for SketchUp

## General

SQLite3 is a C-language library that helps to communicate with databases. As you know, SketchUp has been developing with Ruby language, so it's extensions should be written on Ruby. Sometimes extensions might require additional libraries (like SQLite3 on this example) to provide functionalities on SketchUp.

Ruby has [gem](https://rubygems.org/) package manager, just as pip for python, npm for javascript. The packages that installed by gem might not be appropriate to use it on SketchUp because of Runtime issues and version compatibility between SketchUp and gem. For more details please read this [explanation](https://github.com/thomthom/ruby-c-extension-examples#windows-and-runtime-dlls).

When you try to workaround like below by installing gem on SketchUp Runtime, this might cause uncontrollable errors.

```ruby
begin
  require("sqlite3")
rescue LoadError
  Gem.install(File.join(File.dirname(File.expand_path(__FILE__)), "utils/sqlite3-1.4.2.mspgreg-x64-mingw32.gem"))
  require("sqlite3")
end
```

This is also something SketchUp developers does not suggest. Please read rubocop explanation [SketchupRequirements/GemInstall](https://rubocop-sketchup.readthedocs.io/en/latest/cops_requirements/#sketchuprequirementsgeminstall).

## How to include extensions to your extension safely

> <em>The only way to ensure extensions doesn't clash is to namespace everything into extension namespace. This means making a copy of the gem you want to use and wrap it in your own namespace.</em>

SketchUp developers suggest to put every dependency (except builtins) under the same extension namespace. This is the another valid reason that we have this repo, because we will compile SQLite3 C/C++ codes under the `SpeckleConnector` namespace, so they will become native extension classes and methods. 

To be able to convert C/C++ source codes to Ruby functions we should know how to use Ruby C API.

Example to init modules, classes and methods:
```c
// Module decleration
VALUE speckle_connector = rb_define_module("SpeckleConnector");

// Class declerations
VALUE speckle_connector_sqlite3 = rb_define_class_under(speckle_connector, "Sqlite3", rb_cObject);
VALUE speckle_connector_sqlite3_database = rb_define_class_under(speckle_connector_sqlite3, "Database", rb_cObject);

// Method decleration
rb_define_singleton_method(speckle_connector_sqlite3_database, "new", (ruby_method)rbsqlite3_new, 1);

// Method definition
VALUE rbsqlite3_new(VALUE klass, VALUE pathValue)
{
  // Arguments array 
  VALUE argv[1];

  // Convert pathValue to actual path string
  const char* path;
  path = StringValuePtr(pathValue);

  // Init database object with C++ source code
  SQLite::Database* db = new SQLite::Database(path);

  // Wrap class for ruby use
  VALUE obj = Data_Wrap_Struct(klass, NULL, NULL, db);
  
  // Create instance variable for class
  rb_iv_set(obj, "@path", rb_str_new2(path));
  
  // Return wrapped object
  return obj;
}
```
When we compile above C code, so we can initialize class on Ruby as below;
```ruby
database = SpeckleConnector::Sqlite3::Database.new(db_path)
```

This is the single example to see how we can run C/C++ source code behind the Ruby. The 2 things here to know that how to write method definitions by C/C++ and how to wrap them by Ruby C API.

## Motivation

Motivation of this project is to be able to run SQLite3 functions on Runtime for SketchUp Speckle Connector. Currently we provide initialization of database object by given path and it's exec method. We believe that this is a good starting point to add other functionalities to run SQLite3 on SketchUp extensions more extendly. This example also might guide you to create your own extensions with other C/C++ libraries.

## Troubleshooting

Please consider that current version only provides initialization of database and call exec method on it. Other functionalities not there yet.
