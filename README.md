# NSQ Example

This app serves as an example of how to use NSQ to queue data, which is then dealt with based on priority. In this example, videos with low view counts (less than 100) have their play_count incremented immediately, where as more popular videos have their views batched and handled in groups.

In order to set up the database and create videos with unique UUIDs:

```
  $ rake db:setup
```

To create the mock views that will be handled by NSQ and write them to the queue:

```
  $ rake queue_plays
```

At this point you can use Foreman to run the worker process that will work through the queue.

```
  $ gem install foreman
  $ foreman start --concurrency="web=0,worker=2"
```
