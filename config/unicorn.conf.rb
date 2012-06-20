listen "/home/warehouse/warehouse/tmp/sockets/unicorn.sock", :backlog => 64
worker_processes 2
pid "/home/warehouse/warehouse/tmp/pids/unicorn.pid"
stderr_path "/home/warehouse/warehouse/log/unicorn.log"
stdout_path "/home/warehouse/warehouse/log/unicorn.log"
