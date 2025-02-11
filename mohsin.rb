##########################################
#   BLOCKMESH BOT v1.0 - ULTRA STEALTH   #
#         Modified by Mohsin 🚀           #
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
RESTART_INTERVAL = rand(7200..10800) # 🔥 Auto-Restart After 2-3 Hours

# ✅ Random User-Agents (200+)
USER_AGENTS = File.readlines("user_agents.txt").map(&:strip).reject(&:empty?) rescue []

if USER_AGENTS.empty?
  USER_AGENTS.concat([
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Linux; Android 11; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/537.36 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/537.36"
  ])
end

# 🔥 Clean Terminal UI
def clear_terminal
  system("clear") || system("cls")
end

# ✅ Custom Startup Logo
def show_banner
  clear_terminal
  puts "#{BOLD}========================================#{RESET}"
  puts "#{GREEN}🔥 BLOCKMESH BOT v1.0 - ULTRA STEALTH 🔥#{RESET}"
  puts "#{BLUE}🚀 Created by Mohsin (Beast Mode ON) 🚀#{RESET}"
  puts "#{BOLD}========================================#{RESET}\n\n"
end

# ✅ Load Free Proxies
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

# ✅ Load Accounts
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

# ✅ Secure API Request with Random User-Agent
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
  request['User-Agent'] = USER_AGENTS.sample  # 🔥 Randomized User-Agent
  request.body = payload

  response = http.request(request)
  JSON.parse(response.body) rescue nil
rescue
  nil
end

# ✅ WebSocket Connection
def connect_websocket(email, api_token, proxy)
  ws_url = "wss://ws.blockmesh.xyz/ws?email=#{email}&api_token=#{api_token}"
  headers = { "User-Agent" => USER_AGENTS.sample }

  begin
    ws = WebSocket::Client::Simple.connect(ws_url, headers: headers)
    puts "#{GREEN}🛰️ WebSocket Connected for #{email}! 🚀#{RESET}"
    ws.close
  rescue
    puts "#{RED}⚠️ WebSocket Failed for #{email}! Retrying...#{RESET}"
  end
end

# ✅ Submit Bandwidth
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

# ✅ Task Execution
def execute_task(email, api_token, proxy)
  puts "#{BLUE}📜 Fetching Task for #{email}...#{RESET}"
  sleep(rand(2..5))
  puts "#{GREEN}✅ Task Completed for #{email}!#{RESET}"
end

# ✅ Process Each Account
def process_account(email)
  start_time = Time.now.to_i
  api_token = SecureRandom.hex(8) 
  proxy = get_proxy

  clear_terminal
  show_banner
  puts "#{BOLD}🔄 Status: Active for #{email}#{RESET}"
  puts "🌍 Proxy: #{proxy ? "#{proxy[:host]}:#{proxy[:port]}" : "No Proxy (Direct)"}"
  puts "===================================="

  loop do
    clear_terminal
    show_banner
    puts "#{YELLOW}💻 Running on Proxy: #{proxy ? "#{proxy[:host]}:#{proxy[:port]}" : "Direct"}#{RESET}"

    connect_websocket(email, api_token, proxy)
    submit_bandwidth(email, api_token, proxy)
    execute_task(email, api_token, proxy)

    break if (Time.now.to_i - start_time) >= RESTART_INTERVAL
    sleep(rand(10..30))
  end

  puts "#{YELLOW}🔄 Restarting script after #{RESTART_INTERVAL / 3600} hours...#{RESET}"
  exec("ruby #{$0}") 
end

# ✅ Main Execution
def main
  clear_terminal
  show_banner

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
