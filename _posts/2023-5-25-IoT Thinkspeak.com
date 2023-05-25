---
layout: post
title:IoT Thinkspeak.com
author: [賴建宇]
category: [Lecture]
tags: [jekyll, ai]
---
## Homework Report Format
**IMU-Inertial Measurement Unit**<br>
* **應用與功能說明**<br>
  - 可用於偵測患者心跳與血氧
* **設計考量與所需相關技術**
  - 操作方式:透過Arduino燒錄程式
  - 供電方式:電腦USB
* **系統方塊圖**<br>

![](https://github.com/ouo0725/MCU-project/blob/main/images/share.png?raw=true)

* **實際操作**<br>
![](https://github.com/ouo0725/MCU-project/blob/main/images/IMG_0900.JPG?raw=true)
![](https://github.com/ouo0725/MCU-project/blob/main/images/IMG_0901.JPG?raw=true)
![](https://github.com/ouo0725/MCU-project/blob/main/images/cdv_photo_16850090261.jpg?raw=true)
<iframe width="473" height="840" src="https://www.youtube.com/embed/9KdMP6trdgM" title="" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

<iframe width="473" height="840" src="https://www.youtube.com/embed/SDXN8wvpgIc" title="心跳血氧" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
* **程式碼**<br>

```

---
*This site was last updated {{ site.time | date: "%B %d, %Y" }}.*


