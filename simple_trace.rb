# This module is intended for local use only
# Do not use it in production
# Example usage:
#
# SimpleTrace.begin(:foo)
# SimpleTrace.mark(:a)
# do_something
# SimpleTrace.mark(:b)
# do_something_else
# x = SimpleTrace.trace(:my_block_name) { do_something }
# render json: x
# SimpleTrace.end
#
# The above will create a file in log/simple_traces/foo.log
# It will contain timestamps for when :a and :b occurred, and will contain an
# open and close timestamp for when :my_block_name was executed
#
# Timestamps are relative to the begin call.
module SimpleTrace
  def self.dev_or_local_test?
    return true if Rails.env.development?
    return true if Rails.env.test? && !ENV["CI"]

    false
  end

  def self.begin(name)
    raise 'not for use outside local development' unless dev_or_local_test?

    Thread.current[:simple_trace_events_name] = name
    Thread.current[:simple_trace_events] = []
    Thread.current[:simple_trace_events] << [Time.now, :open, name]
  end

  def self.end
    name = Thread.current[:simple_trace_events_name]
    Thread.current[:simple_trace_events] << [Time.now, :close, name]
    output = Thread.current[:simple_trace_events].sort_by { |ts, *rest| ts }
    first_ts = output[0][0]
    human_output = output.map { |ts, *rest| [((ts - first_ts)* 1000).to_i, *rest] }
    indent = 0
    human_output = human_output.map do |ts, op, *rest|
      indent -= 4 if op == :close
      x = indent
      indent += 4 if op == :open
      [ts, x, op, *rest]
    end

    human_output = human_output.map { |ts, indent, op, *rest| "#{ts}\t#{' ' * indent}#{op} #{rest.inspect}"}.join("\n")
    File.write("log/simple_traces/#{name}.log", human_output)

    op_mapping = {
      open: { ph: 'B' },
      close: { ph: 'E' },
      mark: { ph: 'i', s: 'g' },
    }
    tef_output = output.map do |ts, op, name, rest|
      {
        name: name || 'missing_name',
        cat: 'PERF',
        ts: (ts.to_f * 1_000_000).to_i,
        pid: 1,
        tid: 1,
        args: rest,
        **op_mapping[op],
      }
    end
    File.write("log/simple_traces/#{name}.json", tef_output.to_json)
  end

  def self.mark(name, *args, **kwargs)
    Thread.current[:simple_trace_events] << [Time.now, :mark, name, [*args, kwargs]]
  end

  def save_to_file(name, &block)
    SimpleTrace.begin(name)
    trace(name, &block)
  ensure
    SimpleTrace.end
  end

  def self.trace(name, *args, &block)
    Thread.current[:simple_trace_events] ||= []
    Thread.current[:simple_trace_events] << [Time.now, :open, name, args]
    yield
  ensure
    Thread.current[:simple_trace_events] << [Time.now, :close, name]
  end

  def self.hook
    ActiveSupport::Notifications.subscribe do |name, start, finish, id, payload|
      payload = {} unless payload.is_a? Hash
      Thread.current[:simple_trace_events] ||= []
      Thread.current[:simple_trace_events] << [Time.now, :open, name, payload.without(:datadog_span, :connection, :binds)]
      Thread.current[:simple_trace_events] << [Time.now, :close, name]
    end
  end
  hook
end
