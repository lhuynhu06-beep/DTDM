"""Sinh dữ liệu benchmark song song bằng Spark (Đỗ Minh Hiển – 24139013).

Usage:
  spark-submit gen_data.py text <output> <num_parts> [mb_per_part=128] [seed=2026]
  spark-submit gen_data.py csv  <output> <num_parts> [mb_per_part=128] [seed=2026]

- text: văn bản tiếng Việt tổng hợp, từ vựng ~6.000 âm tiết, tần suất theo luật Zipf (s=1.1)
        giống phân bố từ trong ngôn ngữ thật → WordCount có cả từ rất phổ biến lẫn đuôi dài.
        (mỗi partition bốc dòng từ 1 kho 50.000 câu sinh theo Zipf – nhanh, vẫn giữ phân bố)
- csv : bảng giao dịch bán hàng (region đứng ĐẦU để aggregation.py group theo cột đầu tiên).
Mỗi partition ghi ra 1 file ~mb_per_part MB; dùng seed cố định → chạy lại cho ra cùng dữ liệu.
1 GB = 8 part × 128 MB; 3 GB = 24 part; 5 GB = 40 part.
"""
import random
import sys
from datetime import date, timedelta

from pyspark.sql import SparkSession

ONSETS = ["", "b", "c", "ch", "d", "đ", "g", "gi", "h", "k", "kh", "l", "m", "n", "ng", "nh",
          "p", "ph", "qu", "r", "s", "t", "th", "tr", "v", "x"]
NUCLEI = ["a", "ă", "â", "e", "ê", "i", "o", "ô", "ơ", "u", "ư", "y", "ai", "ao", "au", "ây",
          "eo", "ia", "iê", "oa", "oi", "ôi", "ơi", "ua", "uô", "ưa", "ươ", "ui", "ưu"]
CODAS = ["", "c", "ch", "m", "n", "ng", "nh", "p", "t", "i", "o", "u"]


def build_vocab(seed, size=6000):
    rng = random.Random(seed)
    words, seen = [], set()
    while len(words) < size:
        w = rng.choice(ONSETS) + rng.choice(NUCLEI) + rng.choice(CODAS)
        if w not in seen:
            seen.add(w)
            words.append(w)
    weights = [1.0 / (rank ** 1.1) for rank in range(1, size + 1)]
    cum, acc = [], 0.0
    for w in weights:
        acc += w
        cum.append(acc)
    return words, cum


def gen_text(seed, target_bytes, pool_lines=50000):
    """Mỗi partition: dựng 1 "kho câu" 50.000 dòng theo Zipf, rồi bốc ngẫu nhiên dòng từ kho
    cho đủ dung lượng. Phân bố từ tổng thể vẫn theo Zipf nhưng nhanh hơn ~20 lần so với
    bốc từng từ (cách cũ chỉ đạt ~2 MB/s/core trên t3.medium)."""
    def _gen(idx, _it):
        words, cum = build_vocab(seed)
        rng = random.Random(seed * 100003 + idx)
        flat = rng.choices(words, cum_weights=cum, k=pool_lines * 12)
        pool, pos = [], 0
        for _ in range(pool_lines):
            n = rng.randint(6, 12)
            pool.append(" ".join(flat[pos:pos + n]))
            pos += n
        sizes = [len(x.encode("utf-8")) + 1 for x in pool]
        written = 0
        while written < target_bytes:
            for i in rng.choices(range(pool_lines), k=10000):
                written += sizes[i]
                yield pool[i]
    return _gen


REGIONS = ["HCM", "HaNoi", "DaNang", "CanTho", "HaiPhong", "Hue", "NhaTrang", "VungTau",
           "BinhDuong", "DongNai", "QuangNinh", "DaLat"]
CATEGORIES = {"Electronics": ["Laptop", "Phone", "Tablet", "Headphone", "Camera"],
              "Fashion": ["Shirt", "Jeans", "Dress", "Shoes", "Bag"],
              "Grocery": ["Rice", "Coffee", "Tea", "Milk", "Noodle"],
              "Home": ["Lamp", "Chair", "Table", "Fan", "Pillow"]}
PRODUCTS = [(c, p) for c, ps in CATEGORIES.items() for p in ps]
HEADER = "region,category,product,quantity,unit_price,order_date,order_id"


def gen_csv(seed, target_bytes):
    def _gen(idx, _it):
        rng = random.Random(seed * 100003 + idx)
        start = date(2025, 1, 1)
        yield HEADER
        written, n = len(HEADER) + 1, 0
        while written < target_bytes:
            cat, prod = rng.choice(PRODUCTS)
            row = (f"{rng.choice(REGIONS)},{cat},{prod},{rng.randint(1, 20)},"
                   f"{rng.randint(10, 5000) * 1000},{start + timedelta(days=rng.randint(0, 364))},"
                   f"{idx:03d}{n:09d}")
            n += 1
            written += len(row) + 1
            yield row
    return _gen


if __name__ == "__main__":
    if len(sys.argv) < 4 or sys.argv[1] not in ("text", "csv"):
        print(__doc__)
        sys.exit(1)
    kind, out, parts = sys.argv[1], sys.argv[2], int(sys.argv[3])
    mb = int(sys.argv[4]) if len(sys.argv) > 4 else 128
    seed = int(sys.argv[5]) if len(sys.argv) > 5 else 2026
    spark = SparkSession.builder.appName(f"gen-{kind}-{parts}x{mb}MB").getOrCreate()
    gen = (gen_text if kind == "text" else gen_csv)(seed, mb * 1024 * 1024)
    (spark.sparkContext.parallelize(range(parts), parts)
          .mapPartitionsWithIndex(gen)
          .saveAsTextFile(out))
    spark.stop()
