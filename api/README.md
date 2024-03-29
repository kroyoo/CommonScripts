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

## nginx + geoip2

### nginx.conf
```conf

http {
    map_hash_max_size 128;
    map_hash_bucket_size 128;

    map $arg_ip $custom_ip {
        "~^(([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){3}$)" $1;
        default $remote_addr;
   }

   ############  geoip begin ###############
   geoip2 /usr/local/nginx/geoip2/GeoLite2-Country.mmdb {
       #auto_reload 60m;
    $geoip2_metadata_country_build default=CN source=$custom_ip metadata build_epoch;
    $geoip2_data_country_code default=Cat source=$custom_ip country iso_code;
    $geoip2_data_country_name default=CatSoft source=$custom_ip country names en;
   }

   geoip2 /usr/local/nginx/geoip2/GeoLite2-City.mmdb {
        $geoip2_metadata_city_build metadata build_epoch;
        $geoip2_data_city source=$custom_ip city names en;
        $geoip2_data_city_name source=$custom_ip city names en;
        $geoip2_data_latitude source=$custom_ip location latitude;
        $geoip2_data_longitude source=$custom_ip location longitude;
        $geoip2_data_time_zone source=$custom_ip location time_zone;
        $geoip2_data_region source=$custom_ip subdivisions iso_code;
        $geoip2_data_region_name source=$custom_ip subdivisions names en;
        $geoip2_data_country_code source=$custom_ip country iso_code;
        $geoip2_data_country_name source=$custom_ip country names en;
        $geoip2_data_continent_code source=$custom_ip continent code;
   }
   geoip2 /usr/local/nginx/geoip2/GeoLite2-ASN.mmdb {
       $geoip2_data_asn_code default=77777 source=$custom_ip autonomous_system_number;
       $geoip2_data_asn_name default=Fungit.Co.Ltd. source=$custom_ip autonomous_system_organization;
   }

   ############  geoip end ###############

...
}

```

### location 
```conf
  location /ip {
    default_type "text/plain";
    echo "$custom_ip \n$geoip2_data_country_code / $geoip2_data_country_name  \n$geoip2_data_latitude / $geoip2_data_longitude  \nAS$geoip2_data_asn_code / $geoip2_data_asn_name \n$http_user_agent";
  }
```

### use

```
local ipv4 or ipv6

   # default ipv4
   https://api.fungit.org/ip

   # ipv4
   curl -4 api.fungit.org/ip

   # ipv6
   curl -6 api.fungit.org/ip

xx:xx:0:xx1::1
US / United States
46.49020 / -112.30040
AS77777 / Fungit.Co.Ltd.
curl/7.68.0


   custom ip
   curl api.fungit.org/ip?ip=1.1.1.1
1.1.1.1
AU / Australia
-33.49400 / 143.21040
AS13335 / CLOUDFLARENET
curl/7.68.0


```
   

