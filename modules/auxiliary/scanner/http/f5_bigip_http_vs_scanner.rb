##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary
  include Msf::Exploit::Remote::HttpClient
  include Msf::Auxiliary::Scanner

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'F5 BigIP HTTP Virtual Server Scanner',
      'Description' => %q{
        This module scans for BigIP HTTP virtual servers using banner grabbing. BigIP system uses
        different HTTP profiles for managing HTTP traffic and these profiles allow to customize
        the string used as Server HTTP header. The default values are "BigIP" or "BIG-IP" depending
        on the BigIP system version.
      },
      'Author'      =>
        [
          'Oleg Broslavsky <ovbroslavsky[at]gmail.com>',
          'Nikita Oleksov <neoleksov[at]gmail.com>',
          'Denis Kolegov <dnkolegov[at]gmail.com>',
        ],
      'License'     => MSF_LICENSE,
      'References'     =>
        [
          [ 'URL', 'https://www.owasp.org/index.php/SCG_D_BIGIP'],
        ]
    ))

    register_options(
    [
      OptString.new('PORTS', [true, 'Ports to scan (e.g. 80-81,443,8080-8090)', '80,443']),
      OptInt.new('TIMEOUT', [true, 'The socket connect/read timeout in seconds', 1]),
    ], self.class)

    deregister_options('RPORT')
  end

  def bigip_http?(ip, port, ssl)
    begin
      res = send_request_raw(
        'method' => 'GET',
        'uri' => '/',
        'rport' => port,
        'SSL' => ssl,
        'timeout' => datastore['TIMEOUT']
      )
      return false unless res
      server = res.headers['Server']
      return true if server =~ /BIG\-IP/ || server =~ /BigIP/
    rescue ::Rex::ConnectionRefused
      vprint_error("#{ip}:#{port} - Connection refused")
    rescue ::Rex::ConnectionError
      vprint_error("#{ip}:#{port} - Connection error")
    rescue ::OpenSSL::SSL::SSLError
      vprint_error("#{ip}:#{port} - SSL/TLS connection error")
    end

    false
  end

  def run_host(ip)
    ports = Rex::Socket.portspec_crack(datastore['PORTS'])

    if ports.empty?
      print_error('PORTS options is invalid')
      return
    end

    ports.each do |port|
      if bigip_http?(ip, port, false)
        print_good("#{ip}:#{port} - BigIP HTTP virtual server found")
        next
      end

      if bigip_http?(ip, port, true)
        print_good("#{ip}:#{port} - BigIP HTTPS virtual server found")
      end
    end
  end
end
