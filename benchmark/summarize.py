#!/usr/bin/env python3
"""Tổng hợp benchmark/results-self-managed.csv → summary-self-managed.md + biểu đồ PNG.
Chạy: python3 benchmark/summarize.py   (cần matplotlib nếu muốn vẽ biểu đồ)
"""
import csv
import statistics as st
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
rows = [r for r in csv.DictReader(open(HERE / "results-self-managed.csv", encoding="utf-8"))]
ok = [r for r in rows if r["exit_code"] == "0"]
g = defaultdict(list)
for r in ok:
    g[(r["config"], r["job"], int(r["size_gb"]))].append(float(r["seconds"]))

lines = ["# Kết quả benchmark – cụm tự dựng (1 master + 2 worker t3.medium)", "",
         f"Tổng số lần chạy: {len(rows)} (thành công {len(ok)}). Thời gian = wall-clock của "
         "`spark-submit --deploy-mode cluster` (gồm cả xin container YARN), đọc/ghi trực tiếp S3 qua S3A.", "",
         "| Cấu hình | Job | Dữ liệu (GB) | Số lần | Trung bình (s) | Độ lệch chuẩn (s) | Min | Max | Thông lượng (MB/s) |",
         "|---|---|---:|---:|---:|---:|---:|---:|---:|"]
for (cfg, job, gb), v in sorted(g.items()):
    mean = st.mean(v)
    lines.append(f"| {cfg} | {job} | {gb} | {len(v)} | {mean:.1f} | {st.pstdev(v):.1f} | {min(v):.1f} | "
                 f"{max(v):.1f} | {gb * 1024 / mean:.1f} |")

base = {(j, s): st.mean(v) for (c, j, s), v in g.items() if c == "baseline"}
tuned = {(c, j, s): st.mean(v) for (c, j, s), v in g.items() if c != "baseline"}
if tuned:
    lines += ["", "## Trước / sau tối ưu Spark", "",
              "| Cấu hình | Job | GB | Baseline (s) | Sau tối ưu (s) | Thay đổi |", "|---|---|---:|---:|---:|---:|"]
    for (c, j, s), t in sorted(tuned.items()):
        b = base.get((j, s))
        if b:
            lines.append(f"| {c} | {j} | {s} | {b:.1f} | {t:.1f} | {100 * (t - b) / b:+.1f}% |")
(HERE / "summary-self-managed.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print("\n".join(lines))

try:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(7, 4.2), dpi=150)
    colors = {"wordcount": "#2a6fdb", "aggregation": "#e07b39"}
    for job in ("wordcount", "aggregation"):
        pts = sorted((s, st.mean(v), st.pstdev(v)) for (c, j, s), v in g.items() if c == "baseline" and j == job)
        if pts:
            xs, ys, es = zip(*pts)
            ax.errorbar(xs, ys, yerr=es, marker="o", capsize=4, label=job, color=colors[job])
            for x, y in zip(xs, ys):
                ax.annotate(f"{y:.0f}s", (x, y), textcoords="offset points", xytext=(6, -12), fontsize=8)
    ax.set_xlabel("Kích thước dữ liệu (GB)")
    ax.set_ylabel("Thời gian chạy trung bình (s), n=3")
    ax.set_title("Cụm tự dựng (3 × t3.medium) – thời gian chạy theo kích thước dữ liệu")
    ax.set_xticks([1, 3, 5])
    ax.set_ylim(bottom=0)
    ax.grid(alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(HERE / "runtime-self-managed.png")
    print("Đã vẽ benchmark/runtime-self-managed.png")
except ImportError:
    print("(không có matplotlib – bỏ qua biểu đồ)")
