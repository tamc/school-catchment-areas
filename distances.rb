require 'OSM'
require 'OSM/StreamParser'
require 'OSM/Database'
require 'OSM/objects'

class OSM::Node
  def ways
    @ways || []
  end

  def add_way(way)
    @ways ||= []
    @ways << way
    @ways.uniq!
  end

  def distance_from(node)
    Math.sqrt(((lat.to_f-node.lat.to_f)**2) + ((lon.to_f-node.lon.to_f)**2))
  end

  def neighbours
    @neighbours || []
  end

  def add_neighbour(way, neighbour)
    @neighbours ||= []
    @neighbours << [way, neighbour]
  end

  def get_distance
    tags['Distance from Stanford Infants'] || Float::INFINITY
  end

  def set_distance(new_distance)
    tags['Distance from Stanford Infants'] = new_distance
  end

  attr_accessor :visited

  def update_distance_from(node)
    tentative_distance = node.get_distance + distance_from(node)
    set_distance(tentative_distance) if tentative_distance < get_distance
  end

end


db = OSM::Database.new
parser = OSM::StreamParser.new(:filename => 'stanford-infants-map.osm.xml', :db => db)
parser.parse

db.ways.each do |id,way|
  nodes = way.node_objects
  nodes.each_with_index do |n,i|
    n.add_way(way)
    next unless nodes.length > 1
    n.add_neighbour(way, nodes[i-1]) if i > 0
    n.add_neighbour(way, nodes[i+1]) if i < (nodes.length - 1) && nodes[i+1]
  end
end

school = db.nodes.values.find { |n| n.name == "Stanford Infants" }
road = db.ways.values.find { |w| w.name == "Highcroft Villas" }
entrance = db.nodes.values.sort_by { |n| n.distance_from(school) }.find { |n| n.ways.include?(road) }

unvisited_nodes = db.nodes.values
entrance.set_distance(0)

while true
  break if unvisited_nodes.empty?
  unvisited_nodes = unvisited_nodes.sort_by { |n| n.get_distance }
  break if unvisited_nodes.first.get_distance == Float::INFINITY
  next_node = unvisited_nodes.shift
  next_node.visited = true
  next_node.neighbours.each do |way, neighbour|
    next unless way.highway
    next if neighbour.visited
    neighbour.update_distance_from(next_node)
  end
end

p db.nodes.values.sort_by(&:get_distance).map(&:get_distance)
  
# require 'builder'
# doc = Builder::XmlMarkup.new(:indent => 2, :target => STDOUT)
# doc.instruct!
# db.to_xml(doc')
