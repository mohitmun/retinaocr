require 'nokogiri'
require 'yaml'

def run_command(s)
  puts "running: #{s}"
  return `#{s}`
end

def draw_rect(file_name, out_file_name, coordinates)
  #todo draw multiple
  rect_coordinate = coordinates.join(",")
  return run_command("convert #{file_name} -fill none -stroke black -strokewidth 4 -draw \"rectangle #{rect_coordinate}\"  #{out_file_name}")
end
# files = ARGV

# files.each do |file|
#   run_command("tesseract  hocr") 
# end
def run_ocr(file_name)
  res =  run_command("tesseract #{file_name} #{file_name}")
  return res
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
    res[item[0]] = item[1..-1]
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
    res << {text: item.text.strip}.merge(parse_title(item.attr("title")))
  end
  return res
end

def get_ocr_lines(file_name)
  res = []
  doc = Nokogiri(File.read(file_name))
  doc.css(".ocr_line").each do |item|
    res << {text: item.text.strip}.merge(parse_title(item.attr("title")))
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

def get_json(file_name)
  ocr_line = get_ocr_lines("#{file_name}.hocr")

end

def detect_type(file_name)
  
end

def get_config
  
end


def pipeline(file_name)
  process_file_name = file_name[0]+file_name
  resize(file_name, process_file_name)
  grayscale(process_file_name, process_file_name)
  unsharp_mask(process_file_name, process_file_name)
  run_ocr_all_psm(process_file_name)
  result = File.read("#{process_file_name}.hocr")
  draw_lines(process_file_name)
  get_json(process_file_name)
  # draw_carea(process_file_name)
end