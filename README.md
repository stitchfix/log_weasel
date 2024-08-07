# Log Weasel

Instrument Rails and supported 3rd-party libraries (e.g. Resque, Sidekiq) with shared transaction IDs to trace execution of a unit of work across applications and application instances.

## JavaScript

The `@stitch-fix/log-weasel` javascript package has moved to the frontend-monorepo: https://github.com/stitchfix/web-frontend/blob/main/packages/log-weasel/README.md

## Rails

### Installation

Add log_weasel to your Gemfile:

```rb
gem 'stitchfix-log_weasel'
```

Use bundler to install it:

```
bundle install
```

### Setup

See [this setup guide](https://github.com/stitchfix/eng-wiki/blob/master/technical-topics/log-weasel-configuration.md) for how to configure Log Weasel for Rails applications at Stitch Fix.

For Rails projects, we provide a Railtie that automatically configures and loads Log Weasel.

To see Log Weasel transaction IDs in your Rails logs either use the Logger provided or customize the formatting of your logger to include `LogWeasel::Transaction.id`.

```rb
YourApp::Application.configure do
  config.log_weasel.key = 'YOUR_APP'    # Optional. Defaults to Rails application name.
end
```

### Configure

Load and configure Log Weasel with:

```rb
LogWeasel.configure do |config|
  config.key = "YOUR_APP"
  config.disable_delayed_job_tracing = false
  config.debug = !Rails.env.production?
end
```

`config.key` (default is the Rails `app_name`)
A string that will be included in your transaction IDs and is particularly useful in an environment where a unit of work may span multiple applications.

`config.disable_delayed_job_tracing` (default is `false`)
A boolean that disables Log Weasel appending a `log_weasel_id` parameter in the payloads of delayed Resque jobs. The default is `false`.

`config.debug` (default is `false`)
A boolean that enables some additional debug logging. The default is `false`.

Setting these configuration options are optional, but you must call `LogWeasel.configure`.

### Rack

Log Weasel provides Rack middleware to create and destroy a transaction ID for every HTTP request. You can use it in a any web framework that supports Rack (Rails, Sinatra,...) by using `LogWeasel::Middleware` in your middleware stack.

### Log Weasel ID From Params

The Log Weasel transaction id can also be passed via query string. While this should not be necessary for common Stitch Fix engineering use cases, you can include a `logweasel_id` key in the query string and set `LOG_WEASEL_FROM_PARAMS` environment variable in your application via `fixops`. **Note** this will take precedence over the values passed in the HTTP headers the Log Weasel middleware looks at.

### Resque

When you configure Log Weasel as described above either in Rails or by explicitly calling `LogWeasel.configure`, it modifies Resque to include transaction IDs in all worker logs.

Start your Resque worker with `VERBOSE=1` and you'll see transaction IDs in your Resque logs.

### Airbrake

If you are using <a href="http://airbrake.io/p">Airbrake</a>, Log Weasel will add the parameter `log_weasel_id` to Airbrake errors so that you can track execution through your application stack that resulted in the error. No additional configuration required.

### Example

In this example we have a Rails app pushing jobs to Resque and a Resque worker that run with the Rails environment loaded.

#### HelloController

```rb
class HelloController > ApplicationController

  def index
    Resque.enqueue EchoJob, 'hello from HelloController'
    Rails.logger.info("HelloController#index: pushed EchoJob")
  end

end
```

#### EchoJob

```rb
class EchoJob
  @queue = :default_queue

  def self.perform(args)
    Rails.logger.info("EchoJob.perform: #{args.inspect}")
  end
end
```

Start Resque with:

```
QUEUE=default_queue rake resque:work VERBOSE=1
```

Requesting `http://localhost:3030/hello/index`, our development log shows:

```
[2011-02-14 14:37:42] YOUR_APP-WEB-192587b585fa66b19638 48353 INFO

Started GET "/hello/index" for 127.0.0.1 at 2011-02-14 14:37:42 -0800
[2011-02-14 14:37:42] YOUR_APP-WEB-192587b585fa66b19638 48353 INFO   Processing by HelloController#index as HTML
[2011-02-14 14:37:42] YOUR_APP-WEB-192587b585fa66b19638 48353 INFO HelloController#index: pushed EchoJob
[2011-02-14 14:37:42] YOUR_APP-WEB-192587b585fa66b19638 48353 INFO Rendered hello/index.html.erb within layouts/application (1.8ms)
[2011-02-14 14:37:42] YOUR_APP-WEB-192587b585fa66b19638 48353 INFO Completed 200 OK in 14ms (Views: 6.4ms | ActiveRecord: 0.0ms)
[2011-02-14 14:37:45] YOUR_APP-WEB-192587b585fa66b19638 48461 INFO EchoJob.perform: "hello from HelloController"
```

Fire up a Rails console and push a job directly with:

```
> Resque.enqueue EchoJob, 'hi from Rails console'
```

and our development log shows:

```
[2011-02-14 14:37:10] YOUR_APP-RESQUE-a8e54bfb76718d09f8ed 48453 INFO EchoJob.perform: "hi from Rails console"
```

and our resque log shows:

```
***  got: (Job{default_queue} | EchoJob | ["hello from HelloController"] | {"log_weasel_id"=>"SAMPLE_APP-WEB-a65e45476ff2f5720e23"})
***  Running after_fork hook with [(Job{default_queue} | EchoJob | ["hello from HelloController"] | {"log_weasel_id"=>"SAMPLE_APP-WEB-a65e45476ff2f5720e23"})]
*** SAMPLE_APP-WEB-a65e45476ff2f5720e23 done: (Job{default_queue} | EchoJob | ["hello from HelloController"] | {"log_weasel_id"=>"SAMPLE_APP-WEB-a65e45476ff2f5720e23"})

***  got: (Job{default_queue} | EchoJob | ["hi from Rails console"] | {"log_weasel_id"=>"SAMPLE_APP-RESQUE-00919a012476121cf89c"})
***  Running after_fork hook with [(Job{default_queue} | EchoJob | ["hi from Rails console"] | {"log_weasel_id"=>"SAMPLE_APP-RESQUE-00919a012476121cf89c"})]
*** SAMPLE_APP-RESQUE-00919a012476121cf89c done: (Job{default_queue} | EchoJob | ["hi from Rails console"] | {"log_weasel_id"=>"SAMPLE_APP-RESQUE-00919a012476121cf89c"})
```

Units of work initiated from Resque, for example if using a scheduler like <a href="https://github.com/bvandenbos/resque-scheduler">resque-scheduler</a>, will include 'RESQUE' in the transaction ID to indicate that the work started in Resque.

### Log tagging integration

This gem adds log_weasel_trace_id and trace_origin to logs sent by a `.tagged()`-compatible [Tagged Logger](https://api.rubyonrails.org/classes/ActiveSupport/TaggedLogging.html):

```ruby
logger.warn("oh no!")
{"message":"oh no!","level":"warn","log_weasel_trace_id": "<UUID>","trace_origin":"<UUID>"}
```

## LICENSE

Copyright (c) 2011 Carbon Five. See LICENSE for details.
