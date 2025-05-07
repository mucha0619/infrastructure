openstack aggregate create c6
nova aggregate-set-metadata c6 availability_zone=c6
openstack aggregate add host c6 os-cave006

openstack aggregate create c7
nova aggregate-set-metadata c7 availability_zone=c7
openstack aggregate add host c7 os-cave007

openstack aggregate create c3
nova aggregate-set-metadata c3 availability_zone=c3
openstack aggregate add host c3 os-cave003

openstack aggregate create c4
nova aggregate-set-metadata c4 availability_zone=c4
openstack aggregate add host c4 os-cave004

openstack aggregate create c5
nova aggregate-set-metadata c5 availability_zone=c5
openstack aggregate add host c5 os-cave005

openstack aggregate create c9
nova aggregate-set-metadata c9 availability_zone=c9
openstack aggregate add host c9 os-cave009

openstack aggregate create c10
nova aggregate-set-metadata c10 availability_zone=c10
openstack aggregate add host c10 os-cave010

openstack aggregate create c11
nova aggregate-set-metadata c11 availability_zone=c11
openstack aggregate add host c11 os-cave011

openstack aggregate create c12
nova aggregate-set-metadata c12 availability_zone=c12
openstack aggregate add host c12 os-cave012

openstack aggregate create c13
nova aggregate-set-metadata c13 availability_zone=c13
openstack aggregate add host c13 os-cave013

openstack aggregate create c14
nova aggregate-set-metadata c14 availability_zone=c14
openstack aggregate add host c14 os-cave014


#DATALAKE

nohup rbd -p volumes import data06/DATALAKE06-VDB.img volume-0984bf88-64e2-414a-84d3-5f4140bee3ba &
nohup rbd -p volumes import data06/DATALAKE06-VDA.img volume-6637fa9a-53e7-4d24-abda-f7fc554fcd7c & 

nohup rbd -p volumes import data05/DATALAKE05-VDB.img volume-ceb3815c-7cda-4471-8c65-4bb3d0a2e5f2 &
nohup rbd -p volumes import data05/DATALAKE05-VDA.img volume-3f3402ca-7ae1-4633-9749-e3dc0b61bfc2 &

nohup rbd -p volumes import data04/DATALAKE04-VDB.img volume-6107d891-74bc-4fde-a0c0-4d8ac10f526d &
nohup rbd -p volumes import data04/DATALAKE04-VDA.img volume-9ba90e5c-5e35-442f-8303-04c42a62443e &

nohup rbd -p volumes import data03/DATALAKE03-VDB.img volume-753d93f1-fa88-4309-9dec-56489e518b05 &
nohup rbd -p volumes import data03/DATALAKE03-VDA.img volume-f395de7f-00c5-47ae-8115-9582c1ffc07d &

nohup rbd -p volumes import data02/DATALAKE02-VDB.img volume-b12ee67c-8955-40dc-a7ff-ab9226d5a624 &
nohup rbd -p volumes import data02/DATALAKE02-VDA.img volume-daf5b4c7-8816-4607-8137-580ac12f53bf &

nohup rbd -p volumes import data01/DATALAKE01-VDB.img volume-db2ab9a1-7de4-4772-8a7d-dcfe3d3b4e0c &
nohup rbd -p volumes import data01/DATALAKE01-VDA.img volume-c7765d42-a346-4ed5-9c7d-065d56ee26ec &

nohup rbd -p volumes import data00/DATALAKE00-VDB.img volume-7fc66672-4a70-4f0e-abb1-a55cf8d6904e &
nohup rbd -p volumes import data00/DATALAKE00-VDA.img volume-082a6f25-d93d-47e7-90f4-00f0d47bc1e4 &

nohup rbd -p volumes import gpu05/IAAS-GPU05-VDB.img volume-84342c43-577a-45a9-a762-c621f2a9697d &
nohup rbd -p volumes import gpu05/IAAS-GPU05-VDA.img volume-b7355f6f-e62e-4f73-b729-480ec051b717 &

nohup rbd -p volumes import gpu04/IAAS-GPU04-VDB.img volume-373099fb-0e22-44fd-9629-2f158ae6f7fa &
nohup rbd -p volumes import gpu04/IAAS-GPU04-VDA.img volume-5dd94ec9-5d9b-47ea-9465-ea8c06a0f80f &

nohup rbd -p volumes import gpu03/IAAS-GPU03-VDB.img volume-d6bfce7c-8e9b-4cc9-bfe3-d48c8c9a7005 &
nohup rbd -p volumes import gpu03/IAAS-GPU03-VDA.img volume-1e991746-885f-44d9-8a50-da1f92825c17 &

nohup rbd -p volumes import gpu02/IAAS-GPU02-VDB.img volume-811a4fa7-a2af-4da8-9419-9e0a1504297d &
nohup rbd -p volumes import gpu02/IAAS-GPU02-VDA.img volume-f5c8e61b-2698-4abe-a36b-b5328bfceb46 &

nohup rbd -p volumes import gpu01/IAAS-GPU01-VDB.img volume-86cd1bcb-bcf6-4470-a9c8-e201a7d2cabd &
nohup rbd -p volumes import gpu01/IAAS-GPU01-VDA.img volume-6135ec4b-d3af-44f4-b1cb-b515414f2ae5 &

nohup rbd -p volumes import gpu00/IAAS-GPU00-VDC.img volume-e7c382a0-a6f1-4bce-9d97-0c6030f10d95 &
nohup rbd -p volumes import gpu00/IAAS-GPU00-VDB.img volume-04e55180-86f9-4dee-9a43-14c1e6f2197b &
nohup rbd -p volumes import gpu00/IAAS-GPU00-VDA.img volume-cff51714-309b-47da-828b-f760dc2588ef &

nohup rbd -p volumes import IAAS-MASTER-VDC.img volume-f5fa94b1-49c0-4ee2-8788-0b464ce3c9fc &
nohup rbd -p volumes import IAAS-MASTER-VDB.img volume-1a05eb7b-1d84-407e-9080-03a5b0d456d2 &
nohup rbd -p volumes import IAAS-MASTER-VDA.img volume-085d1e65-22a3-401a-a815-91d2a64a4dad &


막세 떡작 -> 중 단일
4.45%
12.9
2.89
방어구 15강 (0단계) -> 16강(0단계)
0.86%
27.5
31.95
방어구 19강 (40단계)-> 20강(40단계)
1.06%
103.5
97.6
6작-> 7작 (전체 사이클 감소)
2.55%
8
3.13
7겁-> 8겁 (딜 지분 20%)
0.74%
24.5
33.10
무기 22강 (40단계)-> 23강(40단계)
1.29%
130.1
100.85
7작-> 8작 (전체 사이클 감소)
2.64%
24.5
9.28
악세 중 -> 상 단일
2.85%
121:3
42.56
방어구 20강 (40단계)-> 21강(40단계)
1.07%
110
102.8
6겁-> 7겁 (딜 지분 20%)
0.72%
8.0
11.11
결대 & 슈차 유각 (20장)
2.63%
120.0
45.62
8겁-> 9겁 (딜 지분 20%)
0.74%
ㄲ7.1
104.18
무기 14강 (0단계)-> 15강(0단계)
1.08%
17.1
15.83
방어구 16강 (10단계)-> 17강(10단계)
0.90%
42
46.66
77돌-> 97돌
2.3%
250
108.69
무기 15강 (0단계)-> 16강(0단계)
1.09%
19.1
17.52
방어구 16강 (0단계)-> 16강(10단계)
1.77%
85.5
48.30
아드 유각 (20장)
4.52%
680.0
128.31
전설 아바타 (4부위)
1.42%
25
17.60
방어구 17강 (10단계)-> 18강(10단계)
0.92%
45
48.91
예둔 & 저 & 돌대 유각 (20장)
2.63%
3600
136.88
무기 16강 (0단계)-> 16강(10단계)
2.24%
39.6
17.67
9작-> 10작 (전체 사이클 감소)
2.77%
139.7
50.43
96돌 -> 97돌
1.7%
250
147.05
6겁-> 7겁 (딜 지분 10%)
0.42%
8.0
19.04
방어구 19강 (20단계)-> 19강(30단계)
2.57%
131
50.97
방어구 21강 (40단계)-> 22강(40단계)
1.09%
171.5
157.3
악세 중 -) 중하
1.85%
36.3
19.62
방어구 18강 (10단계)-> 19강(10단계)
0.93%
48
51.61
방어구 22강 (40단계) -> 23강(40단계)
1.10%
182
165.45
무기 19강 (20단계) -> 19강(30단계)
3.13%
65.1
20.79
방어구 19강 (30단계)-> 19강(40단계)
2.96%
155
52.36
악세 상 -> 상상
739%
1.242
168.06
무기 19강 (30단계)-> 19강(40단계)
3.56%
76.8
21.57
7겁-> 8겹 (딜 지분 10%)
0.45%
24.5
54.44
8겁-> 9겁 (딜 지분 10%)
0.45%
ㄲ7.1
171.33
무기 16강 (10단계)-> 17강(10단계)
1.13%
28.2
24.95
무기 19강 (40단계)-> 20강(40단계)
1.26%
69.8
55.39
원한 유각 (20장)
2.54%
470.0
185.04
8작-> 9작 (전체 사이클 감소)
2.70%
69.3
25.66
무기 20강 (40단계)-> 21강(40단계)
1.27%
74.9
58.97
무기 23강 (40단계)-> 24강(40단계)
1.30%
274.9
211.46
무기 17강 (10단계)-> 18강(10단계)
1.15%
30.8
26.78
방어구 19강 (10단계)-> 19강(20단계)
1.92%
133
69.25
무기 24강 (40단계)-> 25강(40단계)
1.31%
283.7
216.56
무기 19강 (10단계)-> 19강(20단계)
2.37%
65.9
27.80
악세 상 -> 상중
4.41%
3620
82.08
9겁-> 10겹 (딜 지분 20%)
0.73%
253.1
346:71
악세 중 -) 중중
4.36%
122.0
27.98
질증& 기습&타대 유각 (20장)
2.63%
220.0
83.65
방어구 23강 (40단계)-> 24강(40단계)
1.12%
401.1
358.0
무기 18강 (10단계)-> 19강(10단계)
1.16%
33.4
28.79
악세 상 -> 상하
1.92%
166.0
86.45
방어구 24강 (40단계)-> 25강(40단계)
1.13%
414.5
366.8
방어구 14강 (0단계) -> 15강(0단계)
0.84%
25.5
30.35
무기 21강 (40단계)-> 22강(40단계)
1.28%
121.6
95.00
9겁-> 10겁 (딜 지분 10%
0.44%
253.1