#  -*- coding: utf-8 -*-
#  bot_admin.rb
#  Author: William Woodruff
#  ------------------------
#  A Cinch plugin for administrating yossarian-bot.
#  ------------------------
#  This code is licensed by William Woodruff under the MIT License.
#  http://opensource.org/licenses/MIT

require_relative 'yossarian_plugin'

class BotAdmin < YossarianPlugin
	include Cinch::Plugin
	use_blacklist

	def usage
		'!admin <commands> - Control bot operation with <commands>. See !help for a link to admin commands.'
	end

	def match?(cmd)
		cmd =~ /^(!)?admin$/
	end

	def authenticate?(m)
		if @bot.admins.include?(m.user.nick) && User(m.user.nick).authed?
			return true
		end

		m.reply "You do not have permission to do that.", true
		return false
	end

	hook :pre, :for => [:match], :method => :authenticate?

	match /admin plugin list/, method: :plugin_list

	def plugin_list(m)
		all_plugin_names = $BOT_PLUGINS.map { |p| p.name }
		active_plugin_names = @bot.plugins.map { |p2| p2.class.name }

		plugins = all_plugin_names.map do |apn|
			Format(active_plugin_names.include?(apn) ? :green : :red, apn)
		end.join(', ')

		# temporarily allow up to three messages due to long plugin lists
		@bot.config.max_messages = 3
		m.reply "Available plugins: #{plugins}", true
		@bot.config.max_messages = 1
	end


	match /admin enable (\w+)/, method: :plugin_enable

	def plugin_enable(m, name)
		$BOT_PLUGINS.each do |plugin|
			if plugin.name == name && !@bot.plugins.include?(plugin)
				@bot.plugins.register_plugin(plugin)
				m.reply "#{m.user.nick}: #{name} has been enabled."
				return
			end
		end

		m.reply "#{name} is already enabled or does not exist.", true
	end

	match /admin disable (\w+)/, method: :plugin_disable

	def plugin_disable(m, name)
		@bot.plugins.each do |plugin|
			if plugin.class.name == name
				@bot.plugins.unregister_plugin(plugin)
				m.reply "#{name} has been disabled.", true
				return
			end
		end

		m.reply "#{name} is already disabled or does not exist.", true
	end

	match /admin quit/, method: :bot_quit

	def bot_quit(m)
		m.reply 'Goodbye!'
		@bot.quit
	end

	match /admin auth (\S+)/, method: :bot_add_admin

	def bot_add_admin(m, nick)
		unless @bot.admins.include?(nick)
			@bot.admins << nick
			m.reply "Added #{nick} as an admin.", true
		else
			m.reply "#{nick} is already an admin.", true
		end
	end

	match /admin deauth (\S+)/, method: :bot_remove_admin

	def bot_remove_admin(m, nick)
		if @bot.admins.include?(nick)
			@bot.admins.delete(nick)
			m.reply "#{nick} is no longer an admin.", true
		else
			m.reply "No admin \'#{nick}\' to remove.", true
		end
	end

	match /admin join (\S+)/, method: :bot_join_channel

	def bot_join_channel(m, chan)
		if !@bot.channels.include?(chan)
			@bot.join(chan)
			m.reply "I\'ve joined #{chan}.", true
		else
			m.reply "I\'m already in #{chan}!", true
		end
	end

	match /admin leave (\S+)/, method: :bot_leave_channel

	def bot_leave_channel(m, chan)
		if @bot.channels.include?(chan)
			m.reply "I\'m leaving #{chan}.", true
			@bot.part(chan)
		else
			m.reply "I\'m not in that channel.", true
		end
	end

	match /admin ignore nick (\S+)/, method: :bot_ignore_nick

	def bot_ignore_nick(m, nick)
		host = User(nick).host

		@bot.blacklist << nick

		if !host.empty?
			@bot.blacklist << host
			m.reply "Ignoring everything from #{host} (#{nick}).", true
		else
			m.reply "Ignoring everything from #{nick}.", true
		end
	end

	match /admin ignore host (\S+)/, method: :bot_ignore_host

	def bot_ignore_host(m, host)
		@bot.blacklist << host 

		m.reply "Ignoring everything from #{host}.", true
	end

	match /admin unignore nick (\S+)/, method: :bot_unignore_nick

	def bot_unignore_nick(m, nick)
		host = User(nick).host

		@bot.blacklist.delete(nick)

		if !host.empty?
			@bot.blacklist.delete(host)
		end

		m.reply "Removed any records associated with #{nick} from the blacklist.", true
	end

	match /admin unignore host (\S+)/, method: :bot_unignore_host

	def bot_unignore_host(m, host)
		@bot.blacklist.delete(host)

		m.reply "Removed #{host} from the blacklist.", true
	end

	match /admin nick (\S+)/, method: :bot_nick

	def bot_nick(m, nick)
		m.reply "Changing my nickname to #{nick}.", true
		@bot.nick = nick
	end

	match /admin say (#\S+) (.+)/, method: :bot_say

	def bot_say(m, chan, msg)
		Channel(chan).send msg
	end

	match /admin act (#\S+) (.+)/, method: :bot_act

	def bot_act(m, chan, msg)
		Channel(chan).action msg
	end
end
