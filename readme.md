Start process:
```
bundle exec sidekiq -r ./sidekiq.rb -L ./logs/sidekiq.log -d
```

To disabled process create a empty file config/disabled.txt