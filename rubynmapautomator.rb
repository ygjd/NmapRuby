#!/usr/bin/ruby

require 'pty'
require 'fileutils'
require 'progress_bar'

FileUtils.mkdir_p 'nmap'
cmd = "nmap -sV -sC -oA nmap/initial #{ARGV[0]}"

$syn_bar = ProgressBar.new
$srv_bar = ProgressBar.new
$nse_bar = ProgressBar.new

$syn_progress = 0
$srv_progress = 0
$nse_progress = 0

$step = "init"

def increment_bar(stdout)
  new_status = stdout.match(/[[:digit:]]{1,2}\.[[:digit:]]{2}/)
  new_status ? new_status = new_status[0].to_i : return

  if stdout.include? "SYN Stealth Scan"
    if $step != "syn"
      puts "Step 1/3 [SYN Stealth Scan]"
      $step = "syn"
    end

    inc_amount = new_status - $syn_progress
    $syn_progress = new_status
    $syn_bar.increment! inc_amount
  elsif stdout.include? "Service"
    if $step != "srv"
      puts "Step 2/3 [Service Scan]"
      $step = "srv"
    end

    inc_amount = new_status - $srv_progress
    $srv_progress = new_status
    $srv_bar.increment! inc_amount
  elsif stdout.include? "NSE Timing"
    if $step != "nse" && $step != 'init'
      # NSE Timing shows up before it actually begins
      puts "Step 3/3 [NSE]"
      $step = "nse"
    end

    inc_amount = new_status - $nse_progress
    $nse_progress = new_status
    $nse_bar.increment! inc_amount
  end
end

PTY.spawn( cmd ) do |stdout, stdin, pid|
  loop do
    stdin.puts ' '
    response = stdout.gets.chomp

    increment_bar(response)

    running = %x[ ps -p #{pid} -o comm= ]
    if running.include? "defunct"
      break
    end

    sleep 0.1
  end
end
