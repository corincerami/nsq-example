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

At this point you can run two separate tasks to pull play messages from the queue. This will either write them to the database, or write them to the cache for more popular videos. The second task will then handle the play messages that are in the cache:

```
  $ rake plays_from_queue
  $ rake plays_from_cache
```

I also tried to implement two workers that can be run with Foreman that run both of these tasks together, but it's not completely reliable yet:

```
  $ gem install foreman
  $ foreman start --concurrency="web=0,worker=2"
```

Stats on the play counts of each video can be found by running the app on your localhost and navigating to "localhost:3000/videos"
