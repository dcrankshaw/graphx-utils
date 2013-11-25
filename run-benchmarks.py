#!/usr/bin/env python
import urllib2
import os
import re
import subprocess
from subprocess import Popen, PIPE
import time
import traceback
import sys
import threading
# import config


MAX_RETRIES = 3
NUM_SLAVES = 16
GRAPHX_HOME_DIR = '/root/graphx'
GRAPHX_CONF_DIR = '%s/conf/' % GRAPHX_HOME_DIR
RESULTS_DIR = '/root/results'

sbt_cmd = "sbt/sbt"

def countAliveSlaves(master):
  url = 'http://' + master + ':8080'
  response = urllib2.urlopen(url)
  html = response.read()
  aliveCount = len(re.findall('ALIVE', html))
  deadCount = len(re.findall('DEAD', html))
  return (aliveCount, deadCount)

# extracts the internal ip address and process id from a line of the form:
# ec2-184-73-139-226.compute-1.amazonaws.com: org.apache.spark.deploy.worker.Worker running as process 3017. Stop it first.
def extract_ip_and_pid(line):
  words = line.split()
  print words
  base_ip = words[0].split('.')[0].split('-')[1:]
  assert len(base_ip) == 4
  ip_str = '.'.join(base_ip)
  pid_index = 5
  print words[pid_index - 1]
  assert words[pid_index - 1] == 'process'
  pid = int(words[pid_index].replace('.', ''))
  return (ip_str, pid)



# Return a command which copies the supplied directory to the given host.
def make_rsync_cmd(dir_name, host):
    return ('rsync --delete -e "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5" -az "%s/" '
        '"%s:%s"') % (dir_name, host, os.path.abspath(dir_name))

# Return a command running cmd_name on host with proper SSH configs.
def make_ssh_cmd(cmd_name, host):
    return "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 %s '%s'" % (host, cmd_name)

def run_cmd(cmd, exit_on_fail=True):
    if cmd.find(";") != -1:
        print("***************************")
        print("WARNING: the following command contains a semicolon which may cause non-zero return "
            "values to be ignored. This isn't necessarily a problem, but proceed with caution!")
    print(cmd)
    return_code = Popen(cmd, stdout=sys.stderr, shell=True).wait()
    if exit_on_fail:
        if return_code != 0:
            print "The following shell command finished with a non-zero returncode (%s): %s" % (
                return_code, cmd)
            sys.exit(-1)
    return return_code

# Ensures that no executors are running on Spark slaves. Executors can continue to run for some
# time after a shutdown signal is given due to cleaning up temporary files.
def ensure_spark_stopped_on_slaves(slaves):
    stop = False
    while not stop:
        cmd = "ps -ef |grep -v grep |grep ExecutorBackend"
        ret_vals = map(lambda s: run_cmd(make_ssh_cmd(cmd, s), False), slaves)
        if 0 in ret_vals:
            print "GraphX is still running on some slaves ... sleeping for 10 seconds"
            time.sleep(10)
        else:
            stop = True

# Run several commands in parallel, waiting for them all to finish.
# Expects an array of tuples, where each tuple consists of (command_name, exit_on_fail).
def run_cmds_parallel(commands):
    threads = []
    for (cmd_name, exit_on_fail) in commands:
        thread = threading.Thread(target=run_cmd, args=(cmd_name, exit_on_fail))
        thread.start()
        threads = threads + [thread]
    for thread in threads:
        thread.join()

def try_restart_cluster(slaves, recompile=True):
  # If a cluster is already running from the Spark EC2 scripts, try shutting it down.
  run_cmd("%s/bin/stop-all.sh" % GRAPHX_HOME_DIR)
  ensure_spark_stopped_on_slaves(slaves)
  time.sleep(5)
  if recompile:
    print 'Recompiling...'
    os.chdir(GRAPHX_HOME_DIR)
    run_cmd("%s assembly" % sbt_cmd)
  run_cmds_parallel([(make_rsync_cmd(GRAPHX_HOME_DIR, slave), True) for slave in slaves])
  run_cmd("%s/bin/start-all.sh" % GRAPHX_HOME_DIR)


def restart_cluster(master, slaves, recompile=True, allowed_attempts=MAX_RETRIES):
  print 'Restarting Cluster'
  success = False
  retries = 0
  while (not success and retries < allowed_attempts):
    try_restart_cluster(slaves, recompile)
    (aliveCount, deadCount) = countAliveSlaves(master)
    success = (aliveCount == NUM_SLAVES and deadCount == 0)
    retries += 1
  if not success:
    raise Exception('Cluster could not be resurrected')
  else:
    print 'Cluster successfully restarted'
    return retries

def get_master_url():
  # master = ''
  # find URL
  with open('/root/spark-ec2/ec2-variables.sh', 'r') as vars:
    for line in vars:
      if 'MASTERS' in line:
        # master = line.split('=')[1].strip()[1:-1]
        return line.split('=')[1].strip()[1:-1]
        # break
  # return master

def run_algo(master,
             slaves,
             algo='pagerank',
             epart=128,
             data='soc-LiveJournal1.txt',
             iters=5,
             strategy='RandomVertexCut',
             dynamic=False):

  cls = 'org.apache.spark.graph.Analytics'
  command = None
  if dynamic:
    command = ['/root/graphx/run-example',
               cls,
               'spark://' + master + ':7077',
               algo,
               'hdfs://' + master + ':9000/' + data,
               '--dynamic=true',
               '--numEPart=' + str(epart),
               '--partStrategy=' + strategy]
  else:
    command = ['/root/graphx/run-example',
               cls,
               'spark://' + master + ':7077',
               algo,
               'hdfs://' + master + ':9000/' + data,
               '--numIter=' + str(iters),
               '--numEPart=' + str(epart),
               '--partStrategy=' + strategy]
    

  num_restarts = 0
  command_string = ' '.join(command)
  # Restart cluster if slaves have died. If it fails restart_cluster throws an exception
  # which will propagate through
  (alive, dead) = countAliveSlaves(master)
  if alive != NUM_SLAVES:
    print alive, NUM_SLAVES
    # num_restarts = restart_cluster(master, recompile='no', allowed_attempts=3)
    num_restarts = restart_cluster(master, slaves, recompile=False, allowed_attempts=3)

  start = time.time()
  proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  # TODO poll to see if dead slaves
  out, err = proc.communicate()
  end = time.time()
  full_runtime = (end - start)
  rc = proc.returncode
  gx_runtime = -1
  for line in err.splitlines():
    if 'Runtime' in line:
      words = line.split()
      for word in words:
        try:
          gx_runtime = float(word)
          break
        except ValueError, e:
          pass
      break

  (alive, dead) = countAliveSlaves(master)
  if alive != NUM_SLAVES:
    print str(dead) + 'slaves died during run. Rerun algorithm...'
    raise Exception(str(dead) + ' slaves died.')
  if gx_runtime == -1:
    # TODO do something more intelligent
    print err
    raise Exception('Run Failure', err)
  return (command_string, gx_runtime, full_runtime, num_restarts)


def run_test(master, slaves, strat, algorithm, data, dynamic=False, num_iters=20, restart=True):
  timing = ''
  errors = ''
  for i in range(5):
    if restart:
      restart_cluster(master, slaves, recompile=False, allowed_attempts=3)
    retries = 0
    success = False
    while (not success and retries < MAX_RETRIES):
      try:
        results = run_algo(master, slaves, algo=algorithm, iters=num_iters, data=data, strategy=strat, dynamic=dynamic)
        gx_runtime = results[1]
        full_runtime = results[2]
        print strat, i, gx_runtime, full_runtime
        success = True
      except Exception as e:
        errors += '\n' + str(e) +'\n'
        retries += 1
        print strat, i
        traceback.print_exc()
    if success:
      timing += '\n' + str(results) + '\n'
      
    else:
      errors += 'BENCHMARK FAILED ON TRIAL: ' + str(i)
      break
  return (timing, errors)
      

def run_strats_benchmark(master, slaves):
  strategies = ['EdgePartition2D', 'RandomVertexCut', 'EdgePartition1D']
  restart_cluster(master, slaves, recompile=True, allowed_attempts=3)
  format_str = '%Y-%m-%d-%H-%M-%S'
  now = time.strftime(format_str, time.localtime())
  for strat in strategies:
    (timing, error_output) = run_test(master, slaves, strat, 'pagerank', 'soc-LiveJournal1.txt', num_iters=20, restart=False)
    bm_str = 'part_strats_benchmark'
    with open('%s/%s_timing-%s' % (RESULTS_DIR, bm_str, now), 'a') as t:
      t.write(timing)
    with open('%s/%s_error-%s' % (RESULTS_DIR, bm_str, now), 'a') as e:
      e.write(error_output)
    # restart cluster after each strategy
    restart_cluster(master, slaves, recompile=False, allowed_attempts=3)

def run_dynamic_algos_benchmark(master, slaves):
  restart_cluster(master, slaves, recompile=True, allowed_attempts=3)
  format_str = '%Y-%m-%d-%H-%M-%S'
  now = time.strftime(format_str, time.localtime())
  strat = 'EdgePartition2D'
  algorithms = ['triangles', 'pagerank', 'cc']
  for algo in algorithms:
    (timing, error_output) = run_test(master, slaves, strat, algo, 'soc-LiveJournal1.txt', dynamic=True)
    bm_str = 'dynamic_algos_benchmark'
    with open('%s/%s_timing-%s' % (RESULTS_DIR, bm_str, now), 'a') as t:
      t.write(timing)
    with open('%s/%s_error-%s' % (RESULTS_DIR, bm_str, now), 'a') as e:
      e.write(error_output)

def main():
  master = get_master_url()
  # Get a list of slaves by parsing the slaves file in SPARK_CONF_DIR.
  slaves_file_raw = open("%s/slaves" % GRAPHX_CONF_DIR, 'r').read().split("\n")
  slaves_list = filter(lambda x: not x.startswith("#") and not x is "", slaves_file_raw)

  run_dynamic_algos_benchmark(master, slaves_list)
  run_strats_benchmark(master, slaves_list)


if __name__ == '__main__':
  main()




