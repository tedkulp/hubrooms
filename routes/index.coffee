fs = require('fs')

define ->
  filenames = fs.readdirSync(global.basePath + '/routes').map (file) ->
    if file != 'index.coffee' and file.substr(file.lastIndexOf('.') + 1) == 'coffee'
      return "cs!routes/#{file.substr(0, file.indexOf('.'))}"
  .filter (obj) ->
    return typeof obj != 'undefined'
  requirejs filenames
