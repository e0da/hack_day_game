require 'rack'

use Rack::Static, root: '.', index: 'index.html'

run Rack::Directory.new ''

# web: ruby -rrack -e "include Rack;Handler::Thin.run Builder.new{run Directory.new''}"
