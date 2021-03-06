require 'cinch'
require 'open-uri'
require_relative '../classes/Util.rb'
class DynPlug
	include Cinch::Plugin
	include Hooks::ACLHook
	include Util::PluginHelper
	set :prefix, /^:/
	@clist = %w{dynload reload unload load}
	@@commands["dynload"] = ":dynload <plugname> <url> - dynamically load a plugin from <url> using <plugname> as plugin name"
	@@commands["reload"] = ":reload <plugname> - reload plugin source"
	@@commands["unload"] = ":unload <plugname> - unload plugin source"
	@@commands["load"] = ":load <plugname> - load plugin source"
	@@levelRequired = 10
	match /dynload ([a-zA-Z][a-zA-Z0-9]+) (.+)/, method: :dynload;
	match /reload ([a-zA-Z][a-zA-Z0-9]+)/, method: :reload;
	match /unload ([a-zA-Z][a-zA-Z0-9]+)/, method: :unload;
	match /load ([a-zA-Z][a-zA-Z0-9]+)/, method: :mload;
	
	
	def dynload(m, modname, url) 
		aclcheck(m)
		if(!aclcheck(m)) 
			m.reply("#{m.user.nick}: your access level is not high enough for this command.")
			return
		end
		begin
			if(File.exist?("./plugins/#{modname}.rb")) 
				m.reply("plugin with name #{modname} already exists")
				return false;
			end
			content = ""
			begin 
				open(url) do |f|
					content = f.read
					content.gsub!(%r{</?[^>]+?>}, '')
					open("./plugins/#{modname}.rb", "w") do |plugin|
						plugin.write content
					end
				end
			rescue Exception => error
				m.user.send("Error downloading #{modname}: #{error}")
			end
			load "./plugins/#{modname}.rb";
			ibot = Util::BotFamily.instance.get(Util::Util.instance.hton(m.bot.config.server)).bot
			ibot.plugins.register_plugin(Object.const_get(modname))
			m.reply("#{modname} added successfully")
		rescue Exception => error
			m.user.send "Error loading #{modname}: #{error}"
			m.reply "Error loading, deleting downloaded module. Check privmsg for details"
			m.user.send "#{modname}.rb deleted" if File.unlink "./plugins/#{modname}.rb"
		end
	end

	def reload(m, modname) 
		aclcheck(m)
		if(!aclcheck(m)) 
			m.reply("#{m.user.nick}: your access level is not high enough for this command.")
			return
		end
			unload(m, modname)
			mload(m, modname)
	end
	def unload(m, modname) 
		aclcheck(m)
		if(!aclcheck(m)) 
			m.reply("#{m.user.nick}: your access level is not high enough for this command.")
			return
		end
		if(File.exist?("./plugins/#{modname}.rb")) 
				
			ibot = Util::BotFamily.instance.get(Util::Util.instance.hton(m.bot.config.server)).bot
			i = ibot.plugins.find_index { |x| x.class == Kernel.const_get(modname) }
			if(i == nil) 
				m.reply("#{modname} not loaded currently")
			else 
				ibot.plugins.unregister_plugin(ibot.bot.plugins[i])
				m.reply("#{modname} unloaded successfully")
			end
		else 
			m.reply("#{modname} not found...")
		end
	end

	def mload(m, modname) 
		aclcheck(m)
		if(!aclcheck(m)) 
			m.reply("#{m.user.nick}: your access level is not high enough for this command.")
			return
		end
		if(File.exist?("./plugins/#{modname}.rb")) 	
			ibot = Util::BotFamily.instance.get(Util::Util.instance.hton(m.bot.config.server)).bot
			i = ibot.plugins.find_index { |x| x.class == modname }
			if(i != nil) 
				m.reply("#{modname} already loaded; try :reload instead")
			else 
				begin
					load "./plugins/#{modname}.rb"
				rescue Exception => error
					m.reply "Error loading #{modname}. check privmsg for details"
					m.user.send "Error loading #{modname}: #{error}"
					return
				end
				ibot.plugins.register_plugin(Object.const_get(modname))
				m.reply("#{modname} loaded successfully")
			end	
		else 
			m.reply("#{modname} not found...")
		end
	end


end

		
	
