---
layout: post
title: IoT Thinkspeak.com
author: [賴建宇]
category: [Lecture]
tags: [jekyll, ai]
---
## Homework Report Format
**IMU-Inertial Measurement Unit**<br>
* **應用與功能說明**<br>
  - 將空氣中的數據透過開發版傳送到Thingspeak物聯網網站
* **設計考量與所需相關技術**
  - 操作方式:透過Arduino燒錄程式
  - 供電方式:電腦USB
  - 連線方式:WiFi或行動熱點
* **系統方塊圖**<br>

![](https://github.com/ouo0725/MCU-project/blob/main/images/1A360CA9-1AD6-4FC2-830E-BFF9AF8E75AE.jpg?raw=true)

* **實際操作**<br>
![](https://github.com/ouo0725/MCU-project/blob/main/images/S__105578501.jpg?raw=true)
![](https://github.com/ouo0725/MCU-project/blob/main/images/S__105578503.jpg?raw=true)

<iframe width="997" height="561" src="https://www.youtube.com/embed/3ULOz2LzMw4" title="6" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

<iframe width="365" height="650" src="https://www.youtube.com/embed/tS6ctpU4K7I" title="2023年5月25日" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>.
* **程式碼**<br>

```
/*
 *  This sketch sends data via HTTP GET requests to thingspeak service every 10 minutes
 *  You have to set your wifi credentials and your thingspeak key.
 */

#include <ESP8266WiFi.h>
extern "C" {
  #include "user_interface.h"
}
#include "DHT.h"

#define DHTPIN D6     // NodeMCU pin D6 connected to DHT11 pin Data
DHT dht(DHTPIN, DHT11, 15);

const char* ssid     = "Your_SSID";
const char* password = "Your_Password";


const char* host = "api.thingspeak.com";
const char* thingspeak_key = "6BQ13YRF3BJ97VZR";

void turnOff(int pin) {
  pinMode(pin, OUTPUT);
  digitalWrite(pin, 1);
}

void setup() {
  Serial.begin(115200);

  // disable all output to save power
  turnOff(0);
  turnOff(2);
  turnOff(4);
  turnOff(5);
  turnOff(12);
  turnOff(13);
  turnOff(14);
  turnOff(15);

  dht.begin();
  delay(10);
  

  // We start by connecting to a WiFi network

  Serial.println();
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");  
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

int value = 0;

void loop() {
  delay(5000);
  ++value;

  Serial.print("connecting to ");
  Serial.println(host);
  
  // Use WiFiClient class to create TCP connections
  WiFiClient client;
  const int httpPort = 80;
  if (!client.connect(host, httpPort)) {
    Serial.println("connection failed");
    return;
  }

  String temp = String(dht.readTemperature());
  String humidity = String(dht.readHumidity());
  String voltage = String(system_get_free_heap_size());
  String url = "/update?key=";
  url += thingspeak_key;
  url += "&field1=";
  url += temp;
  url += "&field2=";
  url += humidity;
  
  Serial.print("Requesting URL: ");
  Serial.println(url);
  
  // This will send the request to the server
  client.print(String("GET ") + url + " HTTP/1.1\r\n" +
               "Host: " + host + "\r\n" + 
               "Connection: close\r\n\r\n");
  delay(10);
  
  // Read all the lines of the reply from server and print them to Serial
  while(client.available()){
    String line = client.readStringUntil('\r');
    Serial.print(line);
  }
  
  Serial.println();
  Serial.println("closing connection. going to sleep...");
  delay(1000);
  // go to deepsleep for 1 minutes
  //system_deep_sleep_set_option(0);
  //system_deep_sleep(1 * 60 * 1000000);
  delay(1*60*1000);
}
```
---
*This site was last updated {{ site.time | date: "%B %d, %Y" }}.*


