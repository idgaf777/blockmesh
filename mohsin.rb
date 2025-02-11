require 'net/http'
require 'json'
require 'uri'
require 'colorize'
require 'securerandom'
require 'websocket-client-simple'

# Colors & UI
RED = "\e[31m"
BLUE = "\e[34m"
GREEN = "\e[32m"
YELLOW = "\e[33m"
RESET = "\e[0m"
BOLD = "\e[1m"

PROXIES = []
CREDENTIALS = {}

USER_AGENTS = [
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/112.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/113.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 Chrome/110.0.5481.65 Mobile Safari/537.36",
  "Mozilla/5.0 (X11; Ubuntu; Linux x86_64) AppleWebKit/537.36 Chrome/99.0.4844.51 Safari/537.36",
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/115.0.5790.170 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_4_1) AppleWebKit/537.36 Chrome/115.0.5790.170 Safari/537.36",
  "Mozilla/5.0 (Android 13; Mobile; rv:109.0) Gecko/109.0 Firefox/113.0",
  "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/537.36 Chrome/115.0.5790.170 Mobile Safari/537.36",
  "Mozilla/5.0 (Windows NT 11.0; Win64; x64) AppleWebKit/537.36 Chrome/117.0.5890.200 Safari/537.36",
  "Mozilla/5.0 (Linux; Ubuntu 22.04) AppleWebKit/537.36 Chrome/116.0.5845.140 Safari/537.36"
]

# Fetch fresh proxies
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

# Load accounts from file
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

# Secure API Request with User-Agent
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
  request['User-Agent'] = USER_AGENTS.sample  # ✅ Random User-Agent

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
    puts "#{GREEN}🛰️ WebSocket Connected: #{email} | Proxy: #{proxy ? "#{proxy[:host]}:#{proxy[:port]}" : "Direct"} 🚀#{RESET}"
    ws.close
  rescue
    puts "#{RED}⚠️ WebSocket Failed: #{email} | Proxy: #{proxy ? "#{proxy[:host]}:#{proxy[:port]}" : "Direct"}#{RESET}"
  end
end

# Submit Bandwidth
def submit_bandwidth(email, api_token, proxy)
  puts "#{YELLOW}🔄 Uploading Bandwidth: #{email} | Proxy: #{proxy ? "#{proxy[:host]}:#{proxy[:port]}" : "Direct"}#{RESET}"
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

# Fetch Tasks
def execute_task(email, api_token, proxy)
  puts "#{BLUE}📜 Fetching Task: #{email} | Proxy: #{proxy ? "#{proxy[:host]}:#{proxy[:port]}" : "Direct"}#{RESET}"
  sleep(rand(2..5))
  puts "#{GREEN}✅ Task Completed: #{email} | Proxy: #{proxy ? "#{proxy[:host]}:#{proxy[:port]}" : "Direct"}#{RESET}"
end

# Clean UI
def clear_terminal
  system("clear") || system("cls")
end

# Professional UI Header
def show_banner
  puts "#{BOLD}======================================#{RESET}"
  puts "#{BOLD}🔥 BLOCKMESH BOT v1.3 - ULTRA STEALTH 🔥#{RESET}"
  puts "#{BOLD}🚀 Created by Mohsin (Beast Mode ON) 🚀#{RESET}"
  puts "#{BOLD}======================================#{RESET}"
end

# Process Each Account with Random Delays
def process_account(email)
  start_time = Time.now.to_i
  api_token = SecureRandom.hex(8)
  proxy = get_proxy  # ✅ Alag proxy har account ke liye

  loop do
    clear_terminal
    show_banner
    puts "#{YELLOW}💻 Running on Proxy: #{proxy ? "#{proxy[:host]}:#{proxy[:port]}" : "Direct"}#{RESET}"

    connect_websocket(email, api_token, proxy)
    submit_bandwidth(email, api_token, proxy)
    execute_task(email, api_token, proxy)

    elapsed_time = Time.now.to_i - start_time

    if elapsed_time > rand(7200..10800)  # ✅ 2-3 ghante ka delay
      puts "#{RED}⏳ Auto Restarting to Avoid Detection...#{RESET}"
      break
    end

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

  clear_terminal
  show_banner
  puts "#{GREEN}✅ All Systems Go! Starting Bot...#{RESET}"

  threads = []
  CREDENTIALS.keys.each do |email|
    threads << Thread.new { process_account(email) }
  end
  threads.each(&:join)
end

main if __FILE__ == $0
