require 'cinch'
require 'open-uri'
require_relative '../classes/Util.rb'
require_relative '../classes/Markov.rb'
class Markovian
	include Cinch::Plugin
	include Hooks::ACLHook
	include Util::PluginHelper
	set :prefix, /^:/
	@clist = %w{markov}
	@@commands["markov"] = ":markov <length> - markov chainsaw of <length>"
	match /markov (\d+)?/, method: :markov
	match /markov/, method: :markov
	listen_to :channel
	
	def listen(m)
		text = m.message
		return if m.message.match /^:/
		user = m.user.nick
		#puts "Markovian\n\t#{user}: #{text}"
		mkv = Markovin8or.new(2)
		db = Util::Util.instance.getCollection("markov","ngrams") 		
		chains = mkv.chain(text)		
		chains.each { |chain|
			hash = chain.asHash()	
			next if hash["head"] == nil
			hash["head"].downcase!
			hash["tail"].map! { |x| x.downcase if x != nil }
			hash["user"] = user
			hash["server"] = Util::Util.instance.hton(m.bot.config.server)
			#p hash

			val = db.insert_one(hash)
			#p val
			if(val)
				#puts "success :: #{hash}"
			else
				#puts "failure :: #{hash}"
			end
		}
	end

	def markov(m,length=nil)
		
		out = start(length == nil ? length : length.to_i)
		m.reply(out)
		
	end
	def getRandomRow(seed = nil)
		db = Util::Util.instance.getCollection("markov","ngrams") 
		ret = []
		if(seed == nil)
			res = db.find()
			tmp = res.to_a
			ret = tmp[rand(tmp.count)]
		else
			ret = getRow(seed)
		end
		return ret
	end
		
	def start(words=nil, seed=nil)
		db = Util::Util.instance.getCollection("markov","ngrams") 
		res = ""
		words = (4+rand(24).to_i) if words == nil
		#puts "begin markov chainsaw"
		#puts "start.count: #{words}, start.seed: #{seed}"
		row = getRandomRow(seed)
		out = ""
		i = 0
		while i < words
			#puts i
			head = row[:head]
			tail = row[:tail]
			n = tail.shift
			#next if n == nil
			#puts "\t#{head} -> #{n}"
			out += "#{head} "
			if(n == nil)
				row = getRandomRow()
				next
			end
			row = getRow(n)
			#puts "\trow: "
			p row
			#puts "out: #{out}"
			i+=1
		end
		#puts "end markov chainsaw"
		out.gsub! /\r?\n/, ""
		return out
	end
	def getRow(head)
		db = Util::Util.instance.getCollection("markov","ngrams") 
		res = db.find({'head' => head}).to_a[0]
		return res
	end
end
