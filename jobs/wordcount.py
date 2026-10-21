import sys
from pyspark.sql import SparkSession

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: wordcount <input_path> <output_path>")
        sys.exit(-1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    spark = SparkSession.builder \
        .appName("PySpark WordCount Benchmark") \
        .getOrCreate()

    lines = spark.read.text(input_path).rdd.map(lambda r: r[0])
    
    counts = lines.flatMap(lambda line: line.split(" ")) \
                  .filter(lambda word: len(word) > 0) \
                  .map(lambda word: (word, 1)) \
                  .reduceByKey(lambda a, b: a + b)

    counts.saveAsTextFile(output_path)
    spark.stop()
