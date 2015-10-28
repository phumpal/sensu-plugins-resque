#! /usr/bin/env ruby
#
#   resque-metrics
#
# DESCRIPTION:
#   Pull resque metrics
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: socket
#   gem: resque
#
# USAGE:
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   Copyright 2012 Pete Shima <me@peteshima.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'socket'
require 'resque'
require 'resque/failure/redis'

class ResqueMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :hostname,
         short: '-h HOSTNAME',
         long: '--host HOSTNAME',
         description: 'Redis hostname',
         required: true

  option :port,
         short: '-P PORT',
         long: '--port PORT',
         description: 'Redis port',
         default: '6379'

  option :db,
         short: '-d DB',
         long: '--db DB',
         description: 'Redis DB',
         default: '0'

  option :namespace,
         description: 'Resque namespace',
         short: '-n NAMESPACE',
         long: '--namespace NAMESPACE',
         default: 'resque'

  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.resque"

  def run
    redis = Redis.new(host: config[:hostname], port: config[:port], db: config[:db])
    Resque.redis = redis
    Resque.redis.namespace = config[:namespace]
    count = Resque::Failure::Redis.count
    info = Resque.info

    Resque.queues.each do |v|
      sz = Resque.size(v)
      qn = v.gsub(/[^\w-]/, '_').downcase
      output "#{config[:scheme]}.queue.#{qn}", sz
    end

    output "#{config[:scheme]}.queues", info[:queues]
    output "#{config[:scheme]}.workers", info[:workers]
    output "#{config[:scheme]}.working", info[:working]
    output "#{config[:scheme]}.failed", count
    output "#{config[:scheme]}.pending", info[:pending]
    output "#{config[:scheme]}.processed", info[:processed]

    ok
  end
end
