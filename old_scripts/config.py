"""Configuration options for running Spark and Shark performance tests (perf-tests)."""

import time

# Standard Configuration Options
# --------------------------------------------------------------------------------------------------

# Git repos used to clone clean copies of Spark and Shark to path/to/perf-tests/spark and
# path/to/perf-tests/shark, respectively.
SPARK_GIT_REPO = "git://git.apache.org/incubator-spark.git"
SHARK_GIT_REPO = "git://github.com/amplab/shark.git"

# Git repo for a patched, Shark-compatible version of Hive 0.9.
HIVE_GIT_REPO = "git://github.com/amplab/hive.git -b shark-0.9"

# Git commit id to checkout and test. The repository location configured via SPARK_GIT_REPO and/or
# SHARK_GIT_REPO is named "origin". This ID can specify any of the following:
#     1. A git commit hash     e.g. "4af93ff3"
#     2. A branch name         e.g. "origin/branch-0.7"
#     3. A pull request        e.g. "origin/pr/675"
#
# Required for running Spark and Shark tests.
SPARK_COMMIT_ID = ""
# Required for running Shark tests.
SHARK_COMMIT_ID = ""

# Whether to merge this commit into master before testing. If the commit cannot be merged into
# master, the script will exit with a failure.
SPARK_MERGE_COMMIT_INTO_MASTER = False
SHARK_MERGE_COMMIT_INTO_MASTER = False

# File to write results to.
SPARK_OUTPUT_FILENAME = "spark_perf_output_%s_%s" % (
    SPARK_COMMIT_ID.replace("/", "-"), time.strftime("%Y-%m-%d_%H-%M-%S"))
SHARK_OUTPUT_FILENAME = "shark_perf_output_%s_%s" % (
    SHARK_COMMIT_ID.replace("/", "-"), time.strftime("%Y-%m-%d_%H-%M-%S"))

# Existing directories for Spark and Shark.
SPARK_HOME_DIR = "/root/spark"
SHARK_HOME_DIR = "/root/shark"

# Before we start Spark, the files contained in the SPARK_CONF_DIR directory, such as spark-env.sh
# and the slaves file, are copied to the conf directory of the clean Spark copy cloned from
# SPARK_GIT_REPO (i.e path/to/perf-tests/spark).
# To test on your local machine, create a spark-env.sh and a slaves file with a single slave set as
# your local machine.
SPARK_CONF_DIR = SPARK_HOME_DIR + "/conf"

# The same use case as SPARK_CONF_DIR above.
SHARK_CONF_DIR = SHARK_HOME_DIR + "/conf"

# This default setting assumes we are running on the Spark EC2 AMI. Developers will probably want
# to change this to SPARK_CLUSTER_URL = "spark://localhost:7077" for testing.
SPARK_CLUSTER_URL = open("/root/spark-ec2/cluster-url", 'r').readline().strip()

# Command used to launch Scala.
SCALA_CMD = "scala"

# The default values configured below are appropriate for approximately 20 m1.xlarge nodes, in which
# each node has 15 GB of memory.
# Use this variable to scale the values (e.g. number of records in a generated dataset) if you are
# running the tests with more or fewer nodes.
SCALE_FACTOR = 1.0

assert SCALE_FACTOR > 0, "SCALE_FACTOR must be > 0."

# If set, removes the first N trials for each test from all reported statistics. Useful for
# tests which have outlier behavior due to JIT and other system cache warm-ups. If any test
# returns fewer N + 1 results, an exception is thrown.
IGNORED_TRIALS = 2

# Test Configuration
# --------------------------------------------------------------------------------------------------

# Set up OptionSets. Note that giant cross product is done over all JavaOptionsSets + OptionSets
# passed to each test which may be combinations of those set up here.

# Java options.
COMMON_JAVA_OPTS = [
    # Fraction of JVM memory used for caching RDDs.
    JavaOptionSet("spark.storage.memoryFraction", [0.66]),
    JavaOptionSet("spark.serializer", ["org.apache.spark.serializer.JavaSerializer"]),
    JavaOptionSet("spark.executor.memory", ["9g"]),
    # To ensure consistency across runs, we disable delay scheduling
    JavaOptionSet("spark.locality.wait", [str(60 * 1000 * 1000)])
]

# The following options value sets are shared among all tests.
COMMON_OPTS = [
    # How many times to run each experiment - used to warm up system caches.
    # This OptionSet should probably only have a single value (i.e., length 1)
    # since it doesn't make sense to have multiple values here.
    OptionSet("num-trials", [10]),
    # Extra pause added between trials, in seconds. For runs with large amounts
    # of shuffle data, this gives time for buffer cache write-back.
    OptionSet("inter-trial-wait", [3])
]

# The following options value sets are shared among all tests of
# operations on key-value data.
SPARK_KEY_VAL_TEST_OPTS = [
    # The number of input partitions.
    OptionSet("num-partitions", [400], can_scale=True),
    # The number of reduce tasks.
    OptionSet("reduce-tasks", [400], can_scale=True),
    # A random seed to make tests reproducable.
    OptionSet("random-seed", [5]),
    # Input persistence strategy (can be "memory" or "disk").
    OptionSet("persistent-type", ["memory"]),
    # Whether to wait for input in order to exit the JVM.
    FlagSet("wait-for-exit", [False]),
    # Total number of records to create.
    OptionSet("num-records", [200 * 1000 * 1000], True),
    # Number of unique keys to sample from.
    OptionSet("unique-keys",[20 * 1000], True),
    # Length in characters of each key.
    OptionSet("key-length", [10]),
    # Number of unique values to sample from.
    OptionSet("unique-values", [1000 * 1000], True),
    # Length in characters of each value.
    OptionSet("value-length", [10])
]

# The following options apply to generation of table data shared by all Shark tests.
SHARK_TABLE_GEN_OPTS = [
    OptionSet("num-rows", [200 * 1000 * 1000], can_scale=True),
    OptionSet("num-columns", [10]),
    OptionSet("unique_rows", [20 * 1000], can_scale=True)
]

# TODO(harvey): Selectivity factor could measure the performance of stitching rows back together
#               when scanning columnar stores.
# The following option applies to scans over tables generated using SHARK_TABLE_GEN_OPTs.
SHARK_TABLE_SCAN_OPTS = [
   OptionSet("selectivity-factor", [0.5])
]

# The following option controls storage formats for cached tables. Currently, the only in-memory
# storage format for cached tables in Shark is columnar.
SHARK_TABLE_STORAGE_OPTS = [
    # Supported compression types: "rle", "dictionary", "rle-variant", and "default".
    # Tables are uncompressed by default.
    OptionSet("column-compression-type", ["default"])
]

# Test setup
# --------------------------------------------------------------------------------------------------
# Set up the actual tests. Each test is represtented by a tuple: (short_name, test_cmd,
# scale_factor, list<JavaOptionSet>, list<OptionSet>).

# Set up Spark tests
SPARK_KV_OPTS = COMMON_OPTS + SPARK_KEY_VAL_TEST_OPTS

SPARK_TESTS = []

SPARK_TESTS += [("scheduling-throughput", "spark.perf.TestRunner scheduling-throughput",
    SCALE_FACTOR, COMMON_JAVA_OPTS, [OptionSet("num-tasks", [10 * 1000])] + COMMON_OPTS)]

SPARK_TESTS += [("scala-agg-by-key", "spark.perf.TestRunner aggregate-by-key", SCALE_FACTOR,
    COMMON_JAVA_OPTS, SPARK_KV_OPTS)]

# Scale the input for this test by 2x since ints are smaller.
SPARK_TESTS += [("scala-agg-by-key-int", "spark.perf.TestRunner aggregate-by-key-int",
    SCALE_FACTOR * 2, COMMON_JAVA_OPTS, SPARK_KV_OPTS)]

# Scale the input for this test by 0.10.
SPARK_TESTS += [("scala-sort-by-key", "spark.perf.TestRunner sort-by-key", SCALE_FACTOR * 0.1,
    COMMON_JAVA_OPTS, SPARK_KV_OPTS)]

SPARK_TESTS += [("scala-sort-by-key-int", "spark.perf.TestRunner sort-by-key-int",
    SCALE_FACTOR * 0.2, COMMON_JAVA_OPTS, SPARK_KV_OPTS)]

SPARK_TESTS += [("scala-count", "spark.perf.TestRunner count", SCALE_FACTOR, COMMON_JAVA_OPTS,
    SPARK_KV_OPTS)]

SPARK_TESTS += [("scala-count-w-fltr", "spark.perf.TestRunner count-with-filter", SCALE_FACTOR,
    COMMON_JAVA_OPTS, SPARK_KV_OPTS)]

# Set up Shark tests
SHARK_TABLE_OPTS = COMMON_OPTS + SHARK_TABLE_GEN_OPTS + SHARK_TABLE_STORAGE_OPTS

SHARK_TESTS = []

SHARK_TABLE_SCAN_OPTS = SHARK_TABLE_OPTS + SHARK_TABLE_SCAN_OPTS
SHARK_TESTS += [("table-scan-query", "shark.perf.TestRunner table-scan-query", SCALE_FACTOR,
    COMMON_JAVA_OPTS, SHARK_TABLE_OPTS)]

'''
TODO(harvey): Uncomment once these tests are supported.

SHARK_TESTS += [("sort-query", "shark.perf.TestRunner sort-query", SCALE_FACTOR, COMMON_JAVA_OPTS,
    SHARK_TABLE_OPTS)]

SHARK_TESTS += [("aggregate-query", "shark.perf.TestRunner aggregate-query", SCALE_FACTOR,
    COMMON_JAVA_OPTS, SHARK_TABLE_OPTS)]

SHARK_TESTS += [("join-query", "shark.perf.TestRunner join-query", SCALE_FACTOR, COMMON_JAVA_OPTS,
    SHARK_TABLE_OPTS)]

SHARK_TESTS += [("UDF-query", "shark.perf.TestRunner udf-query", SCALE_FACTOR, COMMON_JAVA_OPTS,
    SHARK_TABLE_OPTS)]
'''

# Advanced Configuration Options
# --------------------------------------------------------------------------------------------------

# Skip downloading and building Spark, Hive and/or Shark components. Requires project to be already
# built in its respective directory.
SPARK_SKIP_PREP = False
SHARK_SKIP_PREP = False
HIVE_SKIP_PREP = False

# Skip building and packaging project tests (requires respective perf tests to already be packaged
# in the project's target directory).
SPARK_SKIP_TEST_PREP = False
SHARK_SKIP_TEST_PREP = False

# Skip warming up local disks.
SKIP_DISK_WARMUP = False

# Total number of bytes used to warm up each local directory.
DISK_WARMUP_BYTES = 200 * 1024 * 1024

# Number of files to create when warming up each local directory. Bytes will be evenly divided
# across files.
DISK_WARMUP_FILES = 200

# Prompt for confirmation when deleting temporary files.
PROMPT_FOR_DELETES = True
