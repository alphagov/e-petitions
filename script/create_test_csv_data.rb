puts %{"email","name","title","description"}

NAMES = IO.readlines("words.txt")

def random_word
  random_words(1)
end

def random_words(count)
  Array.new(count) { NAMES.choice.strip }.join(' ')
end

ARGV[0].to_i.times do |x|
  puts ([%{"#{random_word}@example.com"}] + [2,5,30].map{|x| %{"#{random_words(x)}"} }).join(',')
end

