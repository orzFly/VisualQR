#!/usr/bin/env ruby
require 'rqrcode'
require 'chunky_png'
require 'color'

module VisualQR
	DB = ChunkyPNG::Color(0, 0, 0, (255 * 0.25).to_i)
	DF = ChunkyPNG::Color(0, 0, 0, (255 * 0.75).to_i)
	LB = ChunkyPNG::Color(255, 255, 255, (255 * 0.25).to_i)
	LF = ChunkyPNG::Color(255, 255, 255, (255 * 0.75).to_i) 
	def self.size(s)
		case s
		when 4
			35
		when 3
			31
		when 2
			27
		when 1
			23
		end
	end
	def self.is_important?(s, x, y)
		case s
		when 4, 3, 2, 1
			# return true if (x == 7 || y == 7)
			return false
		end
	end
	def self.is_fixed?(s, x, y)
		case s
		when 4, 3, 2, 1
			return true if (x < 9 && y < 9)
			return true if (x > (size(s) - 2) - 8 && y < 9)
			return true if (x < 9 && y > (size(s) - 2) - 8)
			return true if s != 1 && (x > (size(s) - 2) - 9 && x < (size(s) - 2) - 3 && y > (size(s) - 2) - 9 && y < (size(s) - 2) - 3)
			return false
		end
	end
	def self.is_padding?(s, x, y)
		case s
		when 4, 3, 2, 1
			return true if (x == 0 || y == 0 || x == (size(s) - 1) || y == (size(s) - 1))
			return false
		end
	end
	def self.create(string, bgimg, options = {})
		options[:size] ||= 4
		options[:level] ||= :h
		options[:modified] ||= (options[:level] == :h ? 0.03 : 0)
		options[:bgcolor] ||= ChunkyPNG::Color(255, 255, 255)
		options[:dotpadding] ||= 0.25
		size = size(options[:size])
		qr = RQRCode::QRCode.new( string, :size => options[:size], :level => options[:level] )
		bw = (1.0 * bgimg.width / size).ceil
		bh = (1.0 * bgimg.height / size).ceil
		qrcode = ChunkyPNG::Image.new(bw * size, bh * size, ChunkyPNG::Color::TRANSPARENT)
		bb = bgimg.resample_bilinear(qrcode.width, qrcode.height)
		data = size.times.map { size.times.map { false } }
		qr.modules.each_index do |x|
			qr.modules.each_index do |y|
				data[y + 1][x + 1] = true if qr.dark?(x, y)
			end
		end
		
		lum = {}
		data.each_index do |x|
			data.each_index do |y|
				if is_important?(options[:size], x, y)
				elsif is_fixed?(options[:size], x, y)
				elsif is_padding?(options[:size], x, y)
				else
					rect = [(x + 0) * bw, (y + 0) * bh, bw - 1, bh - 1].map(&:to_i)
					color = ChunkyPNG::Color.compose_precise(bb.crop(*rect).resample_bilinear(1,1)[0, 0], options[:bgcolor])
					l = Color::RGB.new(ChunkyPNG::Color.r(color), ChunkyPNG::Color.g(color), ChunkyPNG::Color.b(color)).to_hsl.l
					f = data[x][y] ? 0.0 : 1.0
					r = (l - f).abs
					lum[[x, y]] = r
				end
			end
		end
		r = lum.sort_by{|_key, value| value}.reverse
		fix = r[0...((size - 2) ** 2 * options[:modified])].map{|i|i[0]}
		fix.each do |i|
			data[i[0]][i[1]] = !data[i[0]][i[1]]
			lum[i] = 1.0 - lum[i]
		end
		
		data.each_index do |x|
			data.each_index do |y|
				b = data[x][y] ? DB : LB
				f = data[x][y] ? DF : LF
				rect = [(x + 0) * bw, (y + 0) * bh, (x + 1) * bw - 1, (y + 1) * bh - 1].map(&:to_i)
				
				if is_fixed?(options[:size], x, y)
					qrcode.rect(*rect, ChunkyPNG::Color::TRANSPARENT, f)
				elsif is_padding?(options[:size], x, y)
					qrcode.rect(*rect, ChunkyPNG::Color::TRANSPARENT, b)
				else

					qrcode.rect(*rect, ChunkyPNG::Color::TRANSPARENT, b)
					lll = lum[[x, y]]
					if lll && lll < 0.3
					else
						qrcode.rect(*[(x + options[:dotpadding]) * bw, (y + options[:dotpadding]) * bh, (x + 1 - options[:dotpadding]) * bw - 1, (y + 1 - options[:dotpadding]) * bh - 1].map(&:to_i), ChunkyPNG::Color::TRANSPARENT, f)
					end
				end
			end
		end
		
		composited = ChunkyPNG::Image.new(qrcode.width, qrcode.height, options[:bgcolor])
		composited.compose!(bb)
		composited.compose!(qrcode)
		composited
	end
end

if $0 == __FILE__
	def report_error(code = 1)
		STDERR.puts <<ERROR
#{File.basename($0)}: #$!
Usage: #{File.basename($0)} [options] data bg out

Try `#{File.basename($0)} --help` for more options.
ERROR
		exit code
	end
	require 'optparse'
	options = {}
	OptionParser.new do |opts|
		opts.banner = <<TEXT
Usage: #{File.basename($0)} [options] data bg out
Create QR Code with background image.

    data                             data to be embedded.
    bg                               file name of background image. must be PNG
    out                              file name of output image. will be PNG

Options: 
TEXT
		
		opts.on_tail("-h", "--help", "show this message") do
			puts opts
			exit
		end
		
		opts.on_tail("--version", "show version") do
			puts "#{File.basename($0)}: git current"
			exit
		end
		
		opts.on("-s", "--size N", Integer, <<EXPLAIN) do |n|
size of the qrcode, 1~4 (default 4)
               1                        21 * 21,  72 code length
               2                        25 * 25, 128 code length
               3                        29 * 29, 208 code length
               4                        33 * 33, 288 code length
EXPLAIN
			raise "size out of range 1..4" unless (1..4) === n
			options[:size] = n
		end
		
		opts.on("-l", "--level N", Integer, <<EXPLAIN) do |n|
error correction level, 1~4 (default 4)
                1 (:l in rqrcode)     7% of code can be restored
                2 (:m in rqrcode)    15% of code can be restored
                3 (:q in rqrcode)    25% of code can be restored
                4 (:h in rqrcode)    30% of code can be restored
EXPLAIN
			raise "level out of range 1..4" unless (1..4) === n
			options[:level] = [:l, :m, :q, :h][n - 1]
		end
		
		opts.on("-m", "--modified N", Float, "modified coefficient to make dots more naturual, 0~0.1 (default 0.03 when level is 4, otherwise 0)") do |n|
			raise "modified out of range 0..0.1" unless (0..0.1) === n
			options[:modified] = n
		end
		
		opts.on("-d", "--dotpadding N", Float, "padding of dots for background (default 0.25)") do |n|
			raise "dotpadding out of range 0.0..1.0" unless (0.0..1.0) === n
			options[:dotpadding] = n
		end
	end.parse! rescue proc do
		report_error
	end.call
	
	if ARGV.count == 3
		begin
			qr = VisualQR.create(ARGV[0], ChunkyPNG::Image.from_file(ARGV[1]), options)
			qr.save(ARGV[2])
		rescue
			report_error
		end
	else
		begin
			case ARGV.count
			when 0, 1, 2
				raise "missing operand"
			else
				raise "too many operands"
			end
		rescue
			report_error
		end
	end
end
