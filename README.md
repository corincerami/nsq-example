# NSQ Example

This app serves as an example of how to use NSQ to queue data, which is then dealt with based on priority. In this example, videos with low view counts (less than 100) have their play_count incremented immediately, where as more popular videos have their views batched and handled in groups.

In order to set up the database and create videos with unique UUIDs:

```
  $ rake db:setup
```

NSQ will need to be running locally, and startup instructions can be found [here](http://nsq.io/overview/quick_start.html). To create the mock views that will be handled by NSQ and write them to the queue:

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

# Post Mortem

First, I'll say that most of the topics dealt with in this challenge were pretty new to me. I was familiar the basic idea of queueing jobs to be run in the background, but it wasn't something I had any experience with. That being said, I really enjoyed this challenge a lot. I feel like I learned so much by being giving a task that was outside of my comfort zone and that's something I love doing.

Over the last couple of days I feel like there were a few rough patches, but in general I really liked doing the necessary research and planning out how to build this system. When I first read the gist with the details of the challenge, I was nervous about whether or not I would be able to complete it, given how unfamiliar I was with NSQ specifically and concepts like queueing and batching in general. After a few hours though I felt relatively comfortable working on this, and spent a lot of time after that tweaking and tuning things the way I needed them.

I found it really interesting to learn more about how these sorts of background tasks are handled. For example, I knew that writing to the database can be costly on the server, but I had never really thought about how to optimize an app to reduce the number of calls to the database in this way.

I'm also not sure what the best way is to handle data like this during the interim, when it's been pulled from the queue but hasn't yet been saved to the database. I decided to use the Rails cache in order to store them temporarily, and then once they reach a certain threshold, writing them all at once.

I also haven't done a lot of work using custom rake tasks, so that was another interesting aspect to this. I tried to utilize Foreman to create some workers that would run those tasks continuously so I was always pulling messages from the queue, and checking the cache for new views, but it didn't always run smoothly. While at times it would run continuously and write all 100,000 views, other times it would get interrupted after 5-10k messages without an error message. I'm wondering if it's an issue with how I set up the workers, since I'm able to run the two tasks at the same time in two separate terminals without issue.

There were a lot of interesting things about this challenge and I'm really excited to keep learning and improving on these skills. If you guys have any thoughts or input on my solution, I would love to hear what you have to say.

EDITED Monday, March 16, 2015

After returning to this challenge in order to correct the way I was batching updates, I have some more insight on what I think about it and what I've learned. One of the biggest improvement I made to the code was to reduce the number of writes to the database by an even greater degree. Previously when pulling from the cache, I was waiting until each individual video had either 100 new views to add, or hadn't been updated in at least a minute. At that point I was increasing it's playcount in the database. I didn't realize that what I should be doing was to update 100 videos all at the same time once per minute.

This made a lot of sense once I realized it, because you can reduce the number of times you write to the database from O(n) operations, where n represents the number of videos that need to be updated, to just 1 update. In order to do this I built a raw SQL statement using ruby to iterate through each video's ID and it's updated playcount.

Unfortunately, I'm still finding the biggest bottleneck in terms of speed to be when working through the queue in order to decide how to deal with each message. I would like to try to find a way to speed this process up further, so I'd like to try to figure out exactly where it's getting slowed down. I suspect it may relate to connecting to NSQ, but I'm not sure yet.

350/sec
