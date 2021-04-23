# 个人api



1. ### ip api

   ```
   https://api.fungit.org/ip
   浏览器打开
   # 测试ipv4
   curl -4 api.fungit.org/ip
   # 测试ipv6
   curl -6 api.fungit.org/ip
   
   # 带参数使用 cip
   https://api.fungit.org/ip?cip=11.11.2.33
   
   11.11.2.33
   US / United States
   AS8003 / GRS-DOD
   Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14.9; rv:78.6) Gecko/20100101 Firefox/78.6
   
   # 带参数 cip默认会使用参数ip，如果参数ip错误， 则会使用请求IP。
   ps 怎么判断ipv6和ipv4。ipv4问题不大，ipv6只要错的不太离谱就行了。随缘吧。
   
   https://api.fungit.org/ip?cip=::1::
   
   illegal ip! use client ip!!
   143.198.*.*
   SG / Singapore
   AS14061 / DIGITALOCEAN-ASN
   Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89 Safari/537.36
   ```

   

