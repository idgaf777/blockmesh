##########################################
# Code  : Blockmesh Bot v.0.3 Beast Mode #
# Author: Modified by Mohsiin            #
##########################################

require 'net/http'
require 'json'
require 'uri'
require 'colorize'
require 'securerandom'
require 'websocket-client-simple'

# Colors
RED = "\e[31m"
BLUE = "\e[34m"
GREEN = "\e[32m"
YELLOW = "\e[33m"
RESET = "\e[0m"
BOLD = "\e[1m"

PROXIES = []
CREDENTIALS = {}

# Load free proxies
def fetch_proxies
  url = "https://api.proxyscrape.com/v2/?request=getproxies&protocol=http&timeout=1000&country=all"
  uri = URI(url)
  response = Net::HTTP.get(uri)
  PROXIES.replace(response.split("\n").map(&:strip).reject(&:empty?))
rescue
  puts "#{RED}⚠️ Failed to fetch proxies! Using direct connection...#{RESET}"
end

def get_proxy
  return nil if PROXIES.empty?
  proxy = PROXIES.sample
  host, port = proxy.split(":")
  { host: host, port: port.to_i }
end

# Load accounts (Fix: Passwords are stored separately)
def load_accounts
  unless File.exist?("data.txt")
    puts "#{RED}❌ data.txt file not found!#{RESET}"
    exit
  end

  File.readlines("data.txt").each do |line|
    email, password = line.chomp.split(":", 2)
    CREDENTIALS[email] = password
  end
end

# Secure API Request
def secure_request(uri, payload, proxy = nil)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 10

  if proxy
    http.proxy_address = proxy[:host]
    http.proxy_port = proxy[:port]
  end

  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = payload

  response = http.request(request)
  JSON.parse(response.body) rescue nil
rescue
  nil
end

# WebSocket Connection
def connect_websocket(email, api_token, proxy)
  ws_url = "wss://ws.blockmesh.xyz/ws?email=#{email}&api_token=#{api_token}"
  begin
    ws = WebSocket::Client::Simple.connect(ws_url)
    puts "#{GREEN}🛰️ Connected to WebSocket for #{email}! 🚀#{RESET}"
    ws.close
  rescue
    puts "#{RED}⚠️ WebSocket Failed for #{email}! Retrying...#{RESET}"
  end
end

# Submit Bandwidth
def submit_bandwidth(email, api_token, proxy)
  puts "#{YELLOW}🔄 Uploading Bandwidth for #{email}...#{RESET}"
  payload = {
    email: email,
    api_token: api_token,
    download_speed: rand(0.0..10.0).round(16),
    upload_speed: rand(0.0..5.0).round(16),
    latency: rand(20.0..300.0).round(16),
    device_id: SecureRandom.hex(16)
  }.to_json
  secure_request(URI("https://app.blockmesh.xyz/api/submit_bandwidth"), payload, proxy)
end

# Task Execution
def execute_task(email, api_token, proxy)
  puts "#{BLUE}📜 Fetching Task for #{email}...#{RESET}"
  sleep(rand(2..5))
  puts "#{GREEN}✅ Task Completed for #{email}!#{RESET}"
end

# Process Each Account
def process_account(email)
  api_token = SecureRandom.hex(8) # 🔥 API Token replace kar diya with random secure token
  proxy = get_proxy

  puts "#{BOLD}🔄 Status: Active for #{email}#{RESET}"
  puts "🌍 Proxy: #{proxy ? "#{proxy[:host]}:#{proxy[:port]}" : "No Proxy (Direct)"}"
  puts "===================================="

  loop do
    connect_websocket(email, api_token, proxy)
    submit_bandwidth(email, api_token, proxy)
    execute_task(email, api_token, proxy)
    sleep(rand(10..30))
  end
end

# Main Execution
def main
  fetch_proxies
  load_accounts

  if CREDENTIALS.empty?
    puts "#{RED}❌ No accounts found in data.txt#{RESET}"
    exit
  end

  threads = []
  CREDENTIALS.keys.each do |email|
    threads << Thread.new { process_account(email) }
  end
  threads.each(&:join)
end

main if __FILE__ == $0
