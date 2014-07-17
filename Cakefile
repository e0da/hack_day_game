{print} = require 'util'
{spawn, _} = require 'child_process'

build = (watch=false) ->
  options = ['-w', '-c', '-o', 'lib', 'src']
  options.shift '-w' unless watch
  coffee = spawn 'coffee', options
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()

task 'build', 'build all CoffeeScript in src to JavaScript in lib', ->
  build()

task 'watch', 'watch for changes to CoffeeScript in src and build to JavaScript in lib', ->
  build true
