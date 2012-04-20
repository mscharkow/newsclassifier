# Author::    Lucas Carlson  (mailto:lucas@rufy.com)
# Copyright:: Copyright (c) 2005 Lucas Carlson
# License::   LGPL

# These are extensions to the String class to provide convenience 
# methods for the RubyClassifier package.
class String
  
  # Removes common punctuation symbols, returning a new string. 
  # E.g.,
  #   "Hello (greeting's), with {braces} < >...?".without_punctuation
  #   => "Hello  greetings   with  braces         "
  def without_punctuation
    tr( ',?.!;:"@#$%^&*()_=+[]{}\|<>/`~', " " ) .tr( "'\-", "")
  end
  
  # Return a Hash of strings => ints. Each word in the string is stemmed,
  # interned, and indexes to its frequency in the document.  
	def word_hash
		word_hash_for_words(gsub(/[^\w\s]/,"").split + gsub(/[\w]/," ").split)
	end

	# Return a word hash without extra punctuation or short symbols, just stemmed words
	def clean_word_hash
		word_hash_for_words gsub(/[^\w\s]/,"").split
	end
	
	private
	
	def word_hash_for_words(words)
		d = Hash.new
		words.each do |word|
			word.downcase! if word =~ /[\w]+/
			key = word
			if word =~ /[^\w]/ && word.length > 2
				d[key] ||= 0
				d[key] += 1
			end
		end
		return d
	end
end