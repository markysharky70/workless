require 'platform-api'

module Delayed
  module Workless
    module Scaler
      class HerokuCedarHobby < Base
        extend Delayed::Workless::Scaler::HerokuClient
        @@mutex = Mutex.new

        def self.up
          workers_needed_now = self.workers_needed
          if workers_needed_now > self.min_workers and self.workers < workers_needed_now
            #p1 = fork { client.post_ps_scale(ENV['APP_NAME'], 'worker', workers_needed_now) }
            #Process.detach(p1)
            sub_commands = []
            (0..workers_needed_now).each do |x|
              process = 'worker'
              case x
                when 0 next
                when 2 then process += 'a'
                when 3 then process += 'b'
                when 4 then process += 'c'
                when 5 then process += 'd'
                when 6 then process += 'e'
                when 7 then process += 'f'
                when 8 then process += 'g'
              end
              sub_commands << {'process' => process,
                               'quantity' => 1}
            end
            command = {'updates' => sub_commands}
            client.formation.batch_update(ENV['APP_NAME'], command) if sub_commands.present?
            if 1 == 0
              # old way replaced with batch....
              client.formation.update(ENV['APP_NAME'], 'worker', {'quantity' => 1}) if workers_needed_now > 0
              client.formation.update(ENV['APP_NAME'], 'workera', {'quantity' => 1}) if workers_needed_now > 1
              client.formation.update(ENV['APP_NAME'], 'workerb', {'quantity' => 1}) if workers_needed_now > 2
              client.formation.update(ENV['APP_NAME'], 'workerc', {'quantity' => 1}) if workers_needed_now > 3
              client.formation.update(ENV['APP_NAME'], 'workerd', {'quantity' => 1}) if workers_needed_now > 4
              client.formation.update(ENV['APP_NAME'], 'workere', {'quantity' => 1}) if workers_needed_now > 5
              client.formation.update(ENV['APP_NAME'], 'workerf', {'quantity' => 1}) if workers_needed_now > 6
              client.formation.update(ENV['APP_NAME'], 'workerg', {'quantity' => 1}) if workers_needed_now > 7
            end
            @@mutex.synchronize do
              @workers = workers_needed_now
            end
            Rails.cache.write("workless-workers", @workers, expires_in: 15.minutes)
          end
        end

        def self.down
          unless self.jobs.count > 0 or self.workers == self.min_workers
            #p1 = fork { client.post_ps_scale(ENV['APP_NAME'], 'worker', self.min_workers) }
            #Process.detach(p1)
            client.formation.update(ENV['APP_NAME'], 'worker', {'quantity' => 0}) if self.min_workers < 1
            client.formation.update(ENV['APP_NAME'], 'workera', {'quantity' => 0}) if self.min_workers < 2
            client.formation.update(ENV['APP_NAME'], 'workerb', {'quantity' => 0}) if self.min_workers < 3
            client.formation.update(ENV['APP_NAME'], 'workerc', {'quantity' => 0}) if self.min_workers < 4
            client.formation.update(ENV['APP_NAME'], 'workerd', {'quantity' => 0}) if self.min_workers < 5
            client.formation.update(ENV['APP_NAME'], 'workere', {'quantity' => 0}) if self.min_workers < 6
            client.formation.update(ENV['APP_NAME'], 'workerf', {'quantity' => 0}) if self.min_workers < 7
            client.formation.update(ENV['APP_NAME'], 'workerg', {'quantity' => 0}) if self.min_workers < 8
            @@mutex.synchronize do
              @workers = self.min_workers
            end
            Rails.cache.write("workless-workers", @workers, expires_in: 15.minutes)
          end
        end

        def self.workers
          @@mutex.synchronize do
            return @workers ||= Rails.cache.fetch("workless-workers", :expires_in => 1.minutes, :race_condition_ttl => 10.seconds) do
              #client.get_ps(ENV['APP_NAME']).body.count { |p| p["process"] =~ /worker[abc]?\.\d?/ }
              client.formation.list(ENV['APP_NAME']).each_with_object([]) { |p,a| a << p if p['type'] =~ /worker[abcdefg]?/ }.map { |p| p['quantity'].to_i }.sum
            end
          end
        end

        # Returns the number of workers needed based on the current number of pending jobs and the settings defined by:
        #
        # ENV['WORKLESS_WORKERS_RATIO']
        # ENV['WORKLESS_MAX_WORKERS']
        # ENV['WORKLESS_MIN_WORKERS']
        #
        def self.workers_needed
          [[(self.jobs.count.to_f / self.workers_ratio).ceil, self.max_workers].min, self.min_workers].max
        end

        def self.workers_ratio
          if ENV['WORKLESS_WORKERS_RATIO'].present? && (ENV['WORKLESS_WORKERS_RATIO'].to_i != 0)
            ENV['WORKLESS_WORKERS_RATIO'].to_i
          else
            100
          end
        end

        def self.max_workers
          ENV['WORKLESS_MAX_WORKERS'].present? ? ENV['WORKLESS_MAX_WORKERS'].to_i : 4
        end

        def self.min_workers
          ENV['PROCESSES'].split(',').each_with_object([]) { |p,a| a << p if p =~ /worker[abcdefg]?$/i }.size
        end
      end
    end
  end
end
