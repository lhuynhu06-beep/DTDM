#!/usr/bin/env python3
"""Sinh sơ đồ kiến trúc cụm tự dựng ở 2 định dạng từ CÙNG một mô tả:
   - self-managed-architecture.drawio  (mở/sửa bằng draw.io / diagrams.net)
   - self-managed-architecture.svg     (nhúng vào báo cáo; PNG xuất từ SVG)
Chạy:  python3 docs/diagrams/make_self_managed_diagram.py
"""
from pathlib import Path
from xml.sax.saxutils import escape

OUT = Path(__file__).resolve().parent
W, H = 1400, 740

# ---- màu (gần bảng màu AWS) ---------------------------------------------------
C = dict(cloud="#232F3E", vpc="#8C4FFF", subnet="#7AA116", sg="#DD344C",
         ec2="#ED7100", s3="#7AA116", iam="#DD344C", cw="#E7157B",
         ink="#16191F", muted="#545B64", edge="#545B64")

# ---- khối: id, x, y, w, h, nhãn (dòng đầu đậm), kiểu ---------------------------
# kind: group (khung chứa), node (máy EC2), svc (dịch vụ AWS), ext (ngoài AWS)
BOXES = [
    ("cloud", 230, 30, 1150, 690, "AWS Cloud · Learner Lab account · Region us-east-1", "group", C["cloud"], False),
    ("vpc", 255, 75, 830, 625, "Default VPC 172.31.0.0/16", "group", C["vpc"], False),
    ("subnet", 395, 115, 670, 565, "Public subnet · us-east-1a", "group", C["subnet"], False),
    ("sg", 415, 155, 630, 505,
     "Security Group: hadoop-selfmanaged-sg\nInbound: TCP 22 ← IP nhóm/32  ·  All traffic ← chính SG  ·  Outbound: all",
     "group", C["sg"], True),

    ("master", 540, 225, 420, 170,
     "hadoop-master  (t3.medium · 2 vCPU · 4 GiB · gp3 30 GB)\n"
     "HDFS NameNode — RPC :9000 · UI :9870 · dfs.replication = 2\n"
     "HDFS SecondaryNameNode\n"
     "YARN ResourceManager — :8032 · UI :8088\n"
     "Spark client (spark-submit) · History Server :18080\n"
     "Không chạy DataNode/NodeManager (giống EMR primary)",
     "node", C["ec2"], False),
    ("w1", 435, 470, 280, 155,
     "hadoop-worker1  (t3.medium · gp3 30 GB)\n"
     "HDFS DataNode — :9866 · UI :9864\n"
     "YARN NodeManager — UI :8042\n"
     "  3072 MB · 2 vcores cho container\n"
     "Spark executors (YARN containers)",
     "node", C["ec2"], False),
    ("w2", 745, 470, 280, 155,
     "hadoop-worker2  (t3.medium · gp3 30 GB)\n"
     "HDFS DataNode — :9866 · UI :9864\n"
     "YARN NodeManager — UI :8042\n"
     "  3072 MB · 2 vcores cho container\n"
     "Spark executors (YARN containers)",
     "node", C["ec2"], False),

    ("igw", 270, 355, 110, 60, "Internet\nGateway", "svc", C["vpc"], False),
    ("pc", 25, 330, 175, 110,
     "Máy sinh viên\nSSH key vockey (labsuser.pem)\nSSH tunnel -L 9870/8088/18080",
     "ext", C["muted"], False),

    ("s3", 1110, 170, 250, 150,
     "Amazon S3\ns3://hadoop-spark-lab-24139035\n  data/  ·  jobs/  ·  results/self-managed/\n← cả 3 node đọc/ghi qua S3A\n   (s3a://, hadoop-aws 3.3.6)",
     "svc", C["s3"], False),
    ("iam", 1110, 355, 250, 120,
     "IAM: LabInstanceProfile → LabRole\nGắn vào cả 3 node; S3A lấy\ncredentials tạm qua IMDSv2\n(không lưu access key trên máy)",
     "svc", C["iam"], False),
    ("cw", 1110, 510, 250, 120,
     "Amazon CloudWatch  (Tuần 3)\nAgent trên 3 node: CPU · RAM · Disk\nDashboard + 1 alarm",
     "svc", C["cw"], True),
]

# ---- cạnh: nguồn, (fx,fy) điểm ra, đích, (fx,fy) điểm vào, nhãn, nét đứt ---------
EDGES = [
    ("pc", (1, .5), "igw", (0, .5), "SSH :22", False),
    ("igw", (1, .5), "master", (0, .5), "SSH / tunnel UI", False),
    ("master", (.3, 1), "w1", (.5, 0), "HDFS + YARN RPC\nSSH (start-dfs/yarn)", False),
    ("master", (.7, 1), "w2", (.5, 0), "HDFS + YARN RPC", False),
    ("w1", (1, .5), "w2", (0, .5), "", False),
    ("sg", (1, .19), "s3", (0, .5), "", False),
    ("iam", (0, .5), "sg", (1, .51), "", True),
    ("sg", (1, .8), "cw", (0, .5), "", True),
]

BOX = {b[0]: b for b in BOXES}


def pt(box_id, f):
    _, x, y, w, h, *_ = BOX[box_id]
    return x + f[0] * w, y + f[1] * h


# ============================ SVG =============================================
def svg():
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" '
         f'font-family="Helvetica, Arial, sans-serif">',
         '<defs><marker id="arr" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" '
         f'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{C["edge"]}"/></marker></defs>',
         f'<rect width="{W}" height="{H}" fill="#ffffff"/>']
    for bid, x, y, w, h, label, kind, col, dashed in BOXES:
        lines = label.split("\n")
        dash = ' stroke-dasharray="7 5"' if dashed else ""
        if kind == "group":
            o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="none" stroke="{col}" stroke-width="2"{dash}/>')
            for i, ln in enumerate(lines):
                fw = "bold" if i == 0 else "normal"
                o.append(f'<text x="{x+10}" y="{y+20+i*17}" font-size="{14 if i == 0 else 12}" font-weight="{fw}" fill="{col}">{escape(ln)}</text>')
        else:
            fill = {"node": "#FFF4E8", "svc": "#ffffff", "ext": "#F2F3F3"}[kind]
            o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="{fill}" stroke="{col}" stroke-width="2"{dash}/>')
            centered = kind in ("svc", "ext") and bid in ("igw", "pc")
            for i, ln in enumerate(lines):
                fw = "bold" if i == 0 else "normal"
                fs = 13 if i == 0 else 12
                ty = y + 24 + i * 19
                if centered:
                    ty = y + h / 2 - (len(lines) - 1) * 9.5 + i * 19 + 4
                    o.append(f'<text x="{x+w/2}" y="{ty}" text-anchor="middle" font-size="{fs}" font-weight="{fw}" fill="{C["ink"]}">{escape(ln)}</text>')
                else:
                    o.append(f'<text x="{x+12}" y="{ty}" font-size="{fs}" font-weight="{fw}" fill="{C["ink"] if i == 0 else C["muted"]}" xml:space="preserve">{escape(ln)}</text>')
    for s, fs_, d, fd, label, dashed in EDGES:
        x1, y1 = pt(s, fs_)
        x2, y2 = pt(d, fd)
        dash = ' stroke-dasharray="6 4"' if dashed else ""
        o.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{C["edge"]}" stroke-width="1.6" marker-end="url(#arr)"{dash}/>')
        if not label:
            continue
        mx, my = (x1 + x2) / 2, (y1 + y2) / 2
        lines = label.split("\n")
        bw = max(len(ln) for ln in lines) * 6.4 + 10
        bh = len(lines) * 15 + 4
        o.append(f'<rect x="{mx-bw/2}" y="{my-bh/2}" width="{bw}" height="{bh}" fill="#ffffff" opacity="0.92"/>')
        for i, ln in enumerate(lines):
            o.append(f'<text x="{mx}" y="{my-bh/2+13+i*15}" text-anchor="middle" font-size="11" fill="{C["ink"]}">{escape(ln)}</text>')
    o.append("</svg>")
    return "\n".join(o)


# ============================ draw.io =========================================
def drawio():
    cells = ['<mxCell id="0"/>', '<mxCell id="1" parent="0"/>']
    for bid, x, y, w, h, label, kind, col, dashed in BOXES:
        val = escape(label).replace("\n", "&#xa;")
        d = "dashed=1;" if dashed else ""
        if kind == "group":
            st = (f"rounded=0;whiteSpace=wrap;html=0;fillColor=none;strokeColor={col};strokeWidth=2;{d}"
                  f"verticalAlign=top;align=left;spacingLeft=8;fontColor={col};fontStyle=1;fontSize=13;")
        else:
            fill = {"node": "#FFF4E8", "svc": "#ffffff", "ext": "#F2F3F3"}[kind]
            al = "center" if bid in ("igw", "pc") else "left"
            va = "middle" if bid in ("igw", "pc") else "top"
            st = (f"rounded=1;arcSize=4;whiteSpace=wrap;html=0;fillColor={fill};strokeColor={col};strokeWidth=2;{d}"
                  f"align={al};verticalAlign={va};spacingLeft=10;spacingTop=4;fontSize=12;fontColor={C['ink']};")
        cells.append(f'<mxCell id="{bid}" value="{val}" style="{st}" vertex="1" parent="1">'
                     f'<mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" as="geometry"/></mxCell>')
    for i, (s, fs_, d, fd, label, dashed) in enumerate(EDGES):
        val = escape(label).replace("\n", "&#xa;")
        st = (f"endArrow=block;endFill=1;html=0;strokeColor={C['edge']};fontSize=11;labelBackgroundColor=#ffffff;"
              f"exitX={fs_[0]};exitY={fs_[1]};exitDx=0;exitDy=0;entryX={fd[0]};entryY={fd[1]};entryDx=0;entryDy=0;"
              + ("dashed=1;" if dashed else ""))
        cells.append(f'<mxCell id="e{i}" value="{val}" style="{st}" edge="1" parent="1" source="{s}" target="{d}">'
                     '<mxGeometry relative="1" as="geometry"/></mxCell>')
    return ('<mxfile host="generator" agent="make_self_managed_diagram.py">'
            '<diagram id="self-managed" name="Self-managed cluster">'
            f'<mxGraphModel dx="{W}" dy="{H}" grid="1" gridSize="10" guides="1" page="1" pageWidth="{W}" pageHeight="{H}">'
            f'<root>{"".join(cells)}</root></mxGraphModel></diagram></mxfile>')


if __name__ == "__main__":
    (OUT / "self-managed-architecture.svg").write_text(svg(), encoding="utf-8")
    (OUT / "self-managed-architecture.drawio").write_text(drawio(), encoding="utf-8")
    print("wrote", OUT / "self-managed-architecture.svg", "and .drawio")
