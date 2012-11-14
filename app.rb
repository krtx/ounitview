# coding: utf-8

require 'sinatra'
require 'sinatra/reloader' if development?
require 'pp'

@@test_bin = "path/to/oUnit/test/binary/file"
@@result = {"ok" => :success, "FAIL" => :failure, "ERROR" => :error, "SKIP" => :skip, "TODO" => :todo}
@@tests = []

set :haml, :format => :html5

# run test
get '/' do
  @title = "test no list"
  @@tests = params.keys
  @result = run_test(@@tests)
  @list = test_list

  haml :result
end

private

def exec(arg)
  open("| #{@@test_bin} #{arg}") do |out|
    return out.read
  end
end

class TestNode
  attr_accessor :name, :children

  def initialize(name="")
    @name = name
    @children = []
  end

  def leaf?
    @children.length == 0
  end
end

helpers do
  def node_tag(node, str)
    capture_haml do 
      name = node.name == "" ? "(no name)" : node.name
      val = (str + (node.name == "" ? "" : ":#{node.name}")).gsub(/^:/, '')

      haml_tag "li" do
        haml_tag(:span, {:class => node.leaf? ? "node-path-leaf" : "node-path"}) do
          haml_concat name
        end
        haml_tag("input.checkbox", {:type => "checkbox", :name => val, :checked => @@tests.include?(val)})
      end

      return if node.leaf?
      
      haml_tag("ul.path-list", {:style => @@tests.select{|x| x =~ /^#{val}.+/}.length > 0 ? "" : "display:none;"}) do
      #haml_tag("ul.path-list") do
        node.children.each_with_index do |node, idx|
          haml_concat node_tag(node, val + ":#{idx}")
        end
      end
    end
  end
  
  def list_tag(root)
    capture_haml do
      haml_tag :ul, {:id => "list-tree"} do
        haml_concat(node_tag(root, ""))
      end
    end
  end
end

def path_of_string(node, path)
  return node if path.length == 0

  hd = path[0]
  tl = path[1..-1]
  if hd =~ /^\d+$/
    idx = hd.to_i
    if node.children.length <= idx
      node.children.push(path_of_string(TestNode.new, tl))
      return node
    else
      return path_of_string(node.children[idx], tl)
    end
  else
    node.name = hd
    return path_of_string(node, tl)
  end
end

def test_list
  list = exec("-list-test").split(/\n/)
  root = TestNode.new
  list.each do |path|
    path_of_string(root, path.split(':'))
  end
  return root
end

def run_test(paths=[])
  arg = "-verbose"
  paths.each do |path|
    arg += " -only-test '#{path}'"
  end
  ret = exec(arg).split(/([=]+\n)|([-]+\n)/)

  all_result = []
  errors = []
  status = []
  if ret.length == 1
    ret = ret[0].split(/\n/)
    all_result = ret[0..-3]
    errors = []
    status = [ret[-2].strip, ret[-1].strip].join('<br />')
  else
    all_result = ret[0].split(/\n/)
    errors = ret[1..-2].map{|v| v.strip}.reject{|v| v == "" or v =~ /(^[=]+$)|(^[-]+$)/}
    status = ret[-1].strip.gsub(/\n/, '<br />')
  end

  tests = {}

  all_result.length.times do |idx|
    next if idx.odd?
    tests[all_result[idx][0..-5]] = [@@result[all_result[idx + 1]]]
  end

  errors.each do |v|
    m = v.split(/\n/)

    path = m[0].match(/[^:]+: (.*)/).to_a[1]
    message = m[2..-1].join('<br />')

    tests[path].push(message)
  end

  return {:test => tests, :status => status}
end

