require 'nokogiri'
require 'yaml'
require "matrix"

def run_command(s)
  puts "running: #{s}"
  return `#{s}`
end

class Hash
  def method_missing(m, *args, &blk)
    fetch(m) { fetch(m.to_s) { super } }
  end
end

class Array
  def blank?
    return self.count == 0
  end
end

def get_size(image)
  return run_command("convert #{image} -format \"%w %h\" info:")
end

def get_width(image)
  return get_size(image).split(" ")[0].to_i
end

def get_height(image)
  return get_size(image).split(" ")[1].to_i
end

def draw_rect(file_name, out_file_name, coordinates)
  #todo draw multiple
  rect_coordinate = coordinates.join(",")
  # return run_command("convert #{file_name} -fill none -stroke black -strokewidth 4 -draw \"rectangle #{rect_coordinate}\"  #{out_file_name}")
end
# files = ARGV

# files.each do |file|
#   run_command("tesseract  hocr") 
# end
def run_ocr(file_name)
  res =  run_command("tesseract #{file_name} #{file_name}")
  return res
end

def crop(file_name, out_file_name, bbox)
  w = bbox[0] - bbox[2]
  h = bbox[1] - bbox[3]
  res = run_command("convert -crop #{w.abs}x#{h.abs}+#{bbox[0]}+#{bbox[1]}  #{file_name} #{out_file_name}")
end

def run_ocr_all_psm(file_name)
  13.times do |i|
    if i == 2
      run_command("tesseract #{file_name} #{file_name} hocr -psm #{i} ")
      # tessedit_char_whitelist=abcdefghijklmnopqrstuvwxyz123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ/
    end
  end
end

def parse_title(title)
  # bbox 0 540 928 600; baseline 0 -8; x_size 72; x_descenders 20; x_ascenders 12
  res = {}
  title = title.split(";")
  title.each do |item|
    item = item.split(" ")
    res[item[0]] = item[1..-1].map{|a| a.to_i}
  end
  return res
end

def run_ocr_with_bb(file_name)
  res =  run_command("tesseract #{file_name} #{file_name} hocr")
  return res
end

def unsharp_mask(file_name, out_file_name)
  return run_command("convert #{file_name} -unsharp 0x7.8+2.69+0 #{out_file_name}")
end

def grayscale(file_name, out_file_name)
  return run_command("convert #{file_name} -set colorspace Gray #{out_file_name}")
end

def resize(file_name, out_file_name)
  return run_command("convert -resize 1000x600  #{file_name} #{out_file_name}")
end

def get_ocr_careas(file_name)
  res = []
  doc = Nokogiri(File.read(file_name))
  doc.css(".ocr_carea").each do |item|
    res << {text: item.text.strip.downcase}.merge(parse_title(item.attr("title")))
  end
  return res
end

def get_ocr_lines(file_name)
  res = []
  doc = Nokogiri(File.read(file_name))
  doc.css(".ocr_line").each do |item|
    words = []
    item.css(".ocrx_word").each do |word|
      confidence =  parse_title(word.attr("title"))["x_wconf"]
      words << {text: word.text.strip.downcase, confidence: confidence}
    end
    res << {text: item.text.strip.downcase, words: words}.merge(parse_title(item.attr("title")))
  end
  return res
end

def draw_carea(file_name)
  ocr_areas = get_ocr_careas("#{file_name}.hocr")
  ocr_areas.each do |item|
    draw_rect(file_name, file_name, item["bbox"]) if item["bbox"]
  end
end

def draw_lines(file_name)
  ocr_areas = get_ocr_lines("#{file_name}.hocr")
  ocr_areas.each do |item|
    draw_rect(file_name, file_name, item["bbox"]) if item["bbox"]
  end
end

def get_json(file_name, document_type)
  ocr_lines = get_ocr_lines("#{file_name}.hocr")
  result = Hash.new([])
  # ocr_lines.each do |line|
  # end
  w = get_width(file_name)
  h = get_height(file_name)
  document_type.fields.each do |field|
    ocr_lines.each do |line|
      ocr_line_noramlised = [line.bbox[0]*100.0/w, line.bbox[1]*100.0/h, line.bbox[2]*100.0/w, line.bbox[3]*100.0/h]
      ocr_line_noramlised = ocr_line_noramlised.map{|a| a.round(2)}
      ocr_line_bbox = Matrix[ocr_line_noramlised]
      field_bbox = Matrix[field.bbox]
      c = field_bbox - ocr_line_bbox
      puts "c: #{c} \nocr_line_noramlised: #{ocr_line_noramlised} \ntext: #{line.text}    field: #{field.name} \n====="
      c = c.to_a.flatten
      if c.all?{|d| d.abs < 4 }
        field_infos = result[field.name]
        field_infos = field_infos + [{value: line.text, words: line.words}]
        result[field.name] = field_infos
      end
    end
  end
  return result
end

def detect_type(file_name)
  lines = get_ocr_lines("#{file_name}.hocr")
  config = get_config
  config.documents.each do |document|
    lines.each do |line|
      common = line.text.split(" ") & document.markers
      if !common.blank?
        return document
      end
    end
  end
  return nil
end

def get_config
  result = YAML.load_file("config.yaml")
  return result
end


def pipeline(file_name)
  process_file_name = file_name[0]+file_name
  resize(file_name, process_file_name)
  grayscale(process_file_name, process_file_name)
  unsharp_mask(process_file_name, process_file_name)
  run_ocr_all_psm(process_file_name)
  result = File.read("#{process_file_name}.hocr")
  draw_lines(process_file_name)
  document_type = detect_type(process_file_name)
  get_json(process_file_name, document_type)
  # get_json(process_file_name)
  # draw_carea(process_file_name)
end