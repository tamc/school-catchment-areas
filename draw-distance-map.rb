require 'OSM'
require 'OSM/StreamParser'
require 'OSM/Database'
require 'OSM/objects'

db = OSM::Database.new
parser = OSM::StreamParser.new(:filename => 'stanford-infants-map.osm.xml', :db => db)
parser.parse

class OSM::Way
  def to_svg
    "<path id='way#{id}' class='#{svg_class_names}' #{svg_data_name} d='#{svg_path}'/>"
  end

  def svg_class_names
    tags.map do |k,v| 
      unless %w{created_by name}.include?(k)
        "#{k}_#{v.gsub(/[^a-zA-Z0-9]+/,'')}" 
      end
    end.join(" ")
  end

  def svg_data_name 
    "data-name='#{name}'" if name
  end

  def svg_path
    points = node_objects.map { |n| [svg_x(n.lat.to_f), svg_y(n.lon.to_f)] }
    path = ["M"]
    path << points.shift.join(",")
    path << " L"
    path << points.map { |p| p.join(",") }.join(" L")
    path << "Z" if is_closed?
    path.join("")
  end

  def svg_x(lat)
    (lat - 50.80729675292969) * (4000/0.16015052795410156)
  end

  def svg_y(lon)
    4000 - ((lon - -0.24716582894325256) * (4000/0.16015052795410156))
  end
end

puts "<html><link href='style.css' media='screen' rel='stylesheet' type='text/css'/><body>"
puts '<svg xmlns="http://www.w3.org/2000/svg" id="map" width="100%" height="100%">'
db.ways.each do |id,way|
  puts way.to_svg
end
puts "</svg>"
puts "</body></html>"
