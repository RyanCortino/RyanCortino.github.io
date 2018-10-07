require 'liquid'
require 'uri'

# Capitalize each word of the input
module Titlecase
	def Titlecase(words)
	 return words.split(' ').map(&:capitalize).join(' ')
	end
end

Liquid::Template.register_filter(Titlecase)