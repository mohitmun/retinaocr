require 'nokogiri'
def run_command(s)
  puts "running: #{s}"
  return `#{s}`
end

def draw_rect(file_name, coordinates)
  #todo draw multiple
  rect_coordinate = coordinates.join(",")
  return run_command("convert #{file_name} -fill none -stroke black -strokewidth 4 -draw \"rectangle #{rect_coordinate}\" bb#{file_name}")
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
    run_command("tesseract #{file_name} #{i}#{file_name} -psm #{i}")
  end
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


def pipeline(file_name)
  process_file_name = file_name[0]+file_name
  resize(file_name, process_file_name)
  grayscale(process_file_name, process_file_name)
  unsharp_mask(process_file_name, process_file_name)
  run_ocr_all_psm(process_file_name)
  puts File.read("#{process_file_name}.txt")
end