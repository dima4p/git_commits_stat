#!/usr/bin/env ruby
# encoding: utf-8
require 'optparse'
require 'open3'
require 'ostruct'
require 'active_support/core_ext/date/acts_like'
require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/integer/time'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/string/conversions'
require 'active_support/core_ext/string/filters'
require 'active_support/core_ext/big_decimal/conversions'

def get_date(date)
  match = date.match(/^((?:\d\d)?\d\d).?(\d\d).?(\d\d)\b/) or return nil
  match = match.to_a[1..3]
  match[0] = '20' + match[0] if match[0].to_i < 100
  res = match.join('-').to_date
rescue => e
  puts "Wrong date #{date}"
  # puts "Wrong date #{date} #{match.inspect}\n#{e.backtrace.join("\n")}"
  return nil
end

def process_directory(dir, new_lines, options)
  return unless File.directory? dir
  return unless File.directory? "#{dir}/.git"
  File.open("#{dir}/.git/config").each_line.detect do |line|
    line.match /url *= *([^ ]+)/
  end
  project = $1.split('/').last.split('.').first
  process_project project, dir, new_lines, options
end

def process_project(project, dir, new_lines, options)
  pwd = Dir.getwd
  Dir.chdir dir
  if options.fetch
    puts project if options.verbose
    data, err, res = Open3.capture3 'git fetch'
  end
  data, err, res = Open3.capture3 "git log --since=#{options.from} --until=#{options.to} origin/#{options.branch} | grep -EA2 '^commit '"
  data.split("\n--\n").each do |bunch|
    bunch = bunch.split("\n")
    commit = bunch[0].split(' ')[1]
    author = bunch.detect{|line| line.include? 'Author:'}.split(/: */)[1]
    email = get_email author, options
    process_commit project, new_lines, commit, email, options
  end
ensure
  Dir.chdir pwd
end

def get_email(author, options)
  if author.match /(.*) <(.*)>/
    options.authors[$2] ||= $1
    options.authors[$2] = $1 if $1.length > options.authors[$2].length
    $2
  else
    options.authors[author] ||= author
  end
end

def get_email(author, options)
  if m = author.match(/(.*) <(.*)>/)
    email = options.aliases[m[2]] || m[2]
    name = m[1]
    options.authors[email] ||= name
    options.authors[email] = name if name.length > options.authors[email].length
    email
  else
    options.authors[author] ||= author
  end
end

def process_commit(project, new_lines, commit, email, options)
  return if options.exclude.detect do |c|
    commit[0...c.length] == c
  end
  data, err, res = Open3.capture3 "git diff -b -w #{commit}^ #{commit}"
  data = data.split(/\n/) rescue data.force_encoding('ASCII-8BIT').split(/\n/)
  data.select! do |line|
    line[0] == '+'
  end
  data.reject! do |line|
    line = line[1..-1].squish
    line[0..1] == '++' or
        line.blank? or
        line[0] == '#'
  end
  count_commit new_lines, project, email, data.size, commit, options
end

def count_commit(new_lines, project, email, count, commit, options)
  return if count > options.limit
  new_lines[:total] ||= 0
  new_lines[email] ||= {total: 0}
  new_lines[email][project] ||= {total: 0, commits: []}
  new_lines[:total] += count
  new_lines[email][:total] += count
  new_lines[email][project][:total] += count
  new_lines[email][project][:commits] << [count, commit]
end

def print_result(new_lines, options)
  ws1 = ' ' * (options.abbreviate ?  5 :  3)
  ws2 = ' ' * (options.abbreviate ? 23 : 21)
  grand_total = new_lines.delete :total
  new_lines.sort_by{|email, projects| projects[:total]}.reverse.each do |email, projects|
    total = projects.delete :total
    next unless total > 0
    print abbreviate_name email, options
    puts " =>#{sprintf '%6d', total} - #{sprintf '%5.2f%%', 100.0 * total / grand_total}"
    if options.projects
      projects.sort_by{|project, details| details[:total]}.reverse.each do |project, details|
        puts "#{ws1}#{sprintf '%6d', details[:total]} - #{sprintf '%5.2f%%', 100.0 * details[:total] / total} - #{project}" if details[:total] > 0
        if options.commits
          details[:commits].sort_by(&:first).reverse.each do |count, commit|
            puts "#{ws2}#{sprintf '%4d', count} #{commit[0..8]}"
          end
        end
      end
    end
  end
  puts "TOTAL: #{grand_total}"
end

def abbreviate_name(email, options)
  name = options.authors[email]
  return "#{name} <#{email}>\n" unless options.abbreviate
  names = name.split(/ +/)
  if names.length < 2
    names = name.split('.')
    if names.length < 2
      names = email.split('@').first.split(/[-_.+]/)
      if names.length < 2
        names = name[0..1].split ''
      end
    end
  end
  "#{names.first[0]}#{names.last[0]}".upcase
end

options = OpenStruct.new(
  root: './',
  month: 0,
  limit: 1000,
  exclude: [],
  aliases: {},
  branch: "master"
)

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} options"
  opts.separator ""
  opts.on('-f', '--from date', "Date to start from. Default is beginning of the current month.") do |val|
    options.from = get_date val
  end
  opts.on('-t', '--to date', "Date to finish after. Default is end of the current month.") do |val|
    options.to = get_date val
  end
  opts.on('-m', '--month n', "Show n-th month ago. Default is 0") do |val|
    options.month = val.to_i
  end
  opts.on('-b', '--brunch name', "Branch to be analysed. Default is #{options[:branch]}") do |val|
    options.branch= val.to_s
  end
  opts.on('-r', '--root dir', "Look up the projects in the dir. Default is #{options.root}") do |val|
    options.root = val
    options.root << '/' unless options.root[-1] == '/'
  end
  opts.on('-l', '--limit max_new_lines', "Ignores commits larger than max_new_lines. Default is #{options.limit}") do |val|
    options.limit = val.to_i.abs
    options.limit = BigDecimal.new('Infinity') if options.limit == 0
  end
  opts.on('-F', 'Fetch projects to have them actual') do
    options.fetch = true
  end
  opts.on('-v', 'Prints the project name before fetch if requested') do
    options.verbose = true
  end
  opts.on('-p', 'Show projects statistics') do
    options.projects = true
  end
  opts.on('-c', 'Include commit data to projects statistics') do
    options.commits = true
  end
  opts.on('-x', '--exclude list', 'Comma separated list of the commits to be skipped in calculation') do |val|
    options.exclude = val.split(/,/)
  end
  opts.on('-A', 'Abbreviate names') do
    options.abbreviate = true
  end
  opts.on('-a', '--aliases LIST', 'Aliases of the contributors: comma-separated list of colon-separated emails') do |val|
    options.aliases = {}
    val.split(/,|;/).each do |contributor|
      emails = contributor.split ':'
      main_email = emails.shift
      emails.each do |email|
        options.aliases[email] = main_email
      end
    end
  end
end.parse!

options.from ||= Date.current.beginning_of_month
options.to ||= Date.current.end_of_month
options.from -= options.month.months
options.to = options.to + 1. day - options.month.months - 1.day
options.authors = {}

new_lines = {}

limit = " with the limit of #{options.limit} new lines per commit" if options.limit < BigDecimal.new('Infinity')
puts "From #{options.from} to #{options.to} in #{options.root}#{limit}"
if File.directory? "#{options.root}/.git"
  process_directory options.root, new_lines, options
else
  Dir["#{options.root}*"].each do |dir|
    process_directory dir, new_lines, options
  end
end

print_result new_lines, options
